// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SignalTipwall is ReentrancyGuard {
    error NotProvided();
    error EmptyField(string fieldName);
    error InsufficientPayment();
    error TransferFailed();
    error NotMirroring();

    uint256 public constant UNLOCK_THRESHOLD = 5;

    enum Kind { TRADE, INVEST }
    enum Action { BUY, SELL }

    struct Post {
        address sender;        // trader ya investor
        Kind kind;             // TRADE ya INVEST
        Action action;         // BUY / SELL
        uint256 price;         // message dekhne ki fee (wei)
        uint256 createdAt;
        string commodity;      // teaser: GOLD, SILVER, CRUDEOIL...
        string contentCid;     // IPFS CID: encrypted entry/target/stop/returns/reason
        bytes32 detailsHash;   // keccak256 of the encrypted JSON
    }

    Post[] public posts;

    // user => postId => paid?
    mapping(address => mapping(uint256 => bool)) public hasPaid;
    // follower => trader => unique paid posts ka count
    mapping(address => mapping(address => uint256)) public paidCount;

    // mirroring settings (follower => trader)
    mapping(address => mapping(address => bool)) public mirroring;
    mapping(address => mapping(address => uint256)) public mirrorEnabledAt;
    mapping(address => mapping(address => uint256)) public maxPerMessage;

    // follower ka vault balance (auto-pay ke liye)
    mapping(address => uint256) public userVault;

    // trader => followers (sirf off-chain bot ke jaanne ke liye)
    mapping(address => address[]) private _followers;
    mapping(address => mapping(address => bool)) private _isFollower;

    event PostCreated(
        uint256 indexed postId,
        address indexed sender,
        Kind kind,
        Action action,
        string commodity,
        uint256 price,
        string contentCid,
        bytes32 detailsHash
    );
    event PostUnlocked(uint256 indexed postId, address indexed user);
    event MirroringEnabled(address indexed follower, address indexed trader, uint256 cap);
    event MirroringDisabled(address indexed follower, address indexed trader);
    event AutoMirrorCharged(
        uint256 indexed postId,
        address indexed follower,
        address indexed trader,
        uint256 amount
    );

   

    function _createPost(
        Kind kind,
        Action action,
        uint256 price,
        string calldata commodity,
        string calldata contentCid,
        bytes32 detailsHash
    ) internal {
        if (price == 0) revert NotProvided();
        if (bytes(commodity).length == 0) revert EmptyField("commodity");
        if (bytes(contentCid).length == 0) revert EmptyField("content");
        if (detailsHash == bytes32(0)) revert EmptyField("hash");

        posts.push(Post(
            msg.sender, kind, action, price, block.timestamp,
            commodity, contentCid, detailsHash
        ));

        emit PostCreated(
            posts.length - 1, msg.sender, kind, action,
            commodity, price, contentCid, detailsHash
        );
    }

    
    function postTrade(
        string calldata commodity,
        Action action,
        uint256 price,
        string calldata contentCid,
        bytes32 detailsHash
    ) external {
        _createPost(Kind.TRADE, action, price, commodity, contentCid, detailsHash);
    }

   
    function postInvest(
        string calldata commodity,
        Action action,
        uint256 price,
        string calldata contentCid,
        bytes32 detailsHash
    ) external {
        _createPost(Kind.INVEST, action, price, commodity, contentCid, detailsHash);
    }

  

    function unlock(uint256 postId) external payable nonReentrant {
        require(postId < posts.length, "no such post");
        Post storage p = posts[postId];

        if (msg.sender == p.sender || hasPaid[msg.sender][postId]) {
            if (msg.value > 0) _refund(msg.sender, msg.value);
            return;
        }
        if (msg.value < p.price) revert InsufficientPayment();

        // Effects
        hasPaid[msg.sender][postId] = true;
        paidCount[msg.sender][p.sender] += 1;

        if (!_isFollower[p.sender][msg.sender]) {
            _isFollower[p.sender][msg.sender] = true;
            _followers[p.sender].push(msg.sender);
        }

        // Interactions
        (bool ok, ) = payable(p.sender).call{value: p.price}("");
        if (!ok) revert TransferFailed();

        uint256 extra = msg.value - p.price;
        if (extra > 0) _refund(msg.sender, extra);

        emit PostUnlocked(postId, msg.sender);
    }

    function _refund(address to, uint256 amount) internal {
        (bool ok, ) = payable(to).call{value: amount}("");
        if (!ok) revert TransferFailed();
    }

    // ---------- VAULT ----------

    function depositVault() external payable {
        userVault[msg.sender] += msg.value;
    }

    function withdrawVault(uint256 amount) external nonReentrant {
        require(userVault[msg.sender] >= amount, "low balance");
        userVault[msg.sender] -= amount;
        _refund(msg.sender, amount);
    }

    // ---------- AUTO MIRRORING ----------

    // 5 unique posts dekhne ke baad follower khud mirroring ON kare
    function enableMirroring(address trader, uint256 cap) external {
        require(paidCount[msg.sender][trader] >= UNLOCK_THRESHOLD, "view 5 posts first");
        require(cap > 0, "cap required");

        mirroring[msg.sender][trader] = true;
        mirrorEnabledAt[msg.sender][trader] = block.timestamp;
        maxPerMessage[msg.sender][trader] = cap;

        emit MirroringEnabled(msg.sender, trader, cap);
    }

    function disableMirroring(address trader) external {
        mirroring[msg.sender][trader] = false;
        emit MirroringDisabled(msg.sender, trader);
    }

    // Off-chain bot is function ko call karega har naye post ke liye
    function chargeMirror(uint256 postId, address follower) external nonReentrant {
        require(postId < posts.length, "no such post");
        Post storage p = posts[postId];

        if (!mirroring[follower][p.sender]) revert NotMirroring();
        // sirf mirroring ON hone ke BAAD ke posts charge ho sakte hain
        require(p.createdAt >= mirrorEnabledAt[follower][p.sender], "old post");
        require(!hasPaid[follower][postId], "already charged");
        require(p.price <= maxPerMessage[follower][p.sender], "above follower cap");
        require(userVault[follower] >= p.price, "vault low");

        hasPaid[follower][postId] = true;
        userVault[follower] -= p.price;

        (bool ok, ) = payable(p.sender).call{value: p.price}("");
        if (!ok) revert TransferFailed();

        emit AutoMirrorCharged(postId, follower, p.sender, p.price);
    }

    // ---------- VIEW HELPERS ----------

    function totalPosts() external view returns (uint256) {
        return posts.length;
    }

    function followersOf(address trader) external view returns (address[] memory) {
        return _followers[trader];
    }
}
