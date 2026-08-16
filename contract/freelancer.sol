// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract freelance{
    enum status{
        Jobcreated,
        accepted,
        inProgress,
        completed,
        disputed, 
        resolved
    }
    struct Job{
        uint256 jobid;
        address payable client;
        address payable freelancer;
        address payable arbiter;
        uint amount;
        string description;
        status currentstatus;
    }
    Job[] public boj;
    uint256 public jid;
    mapping  (uint256  => Job) public jobs;
    function createjob(address payable add,string memory str) public payable {
        require(msg.value>0,"you have to pay some amount");
        
       boj.push(Job(jid,payable (msg.sender),payable(0),add,msg.value,str,status.Jobcreated));
        jid++;

    } 
    function acceptjob(uint256 index) public {
        require(msg.sender!=boj[index].client,"you are not allowed to accept the job");
        require(boj[index].currentstatus==status.Jobcreated,"job is not available");
        boj[index].freelancer=payable(msg.sender);
        boj[index].currentstatus=status.accepted;
       
        
    }
    function start(uint256 index) public {
        require(msg.sender==boj[index].freelancer,"you are not allowed to start the job");
        require(boj[index].currentstatus==status.accepted,"job is not accepted");
        boj[index].currentstatus=status.inProgress;
    }
    function complete(uint256 index) public {
        require(msg.sender==boj[index].freelancer,"you are not allowed to complete the job");
        
        require(boj[index].currentstatus==status.inProgress,"you have no authority to complete");
        boj[index].currentstatus=status.completed;
        boj[index].freelancer.transfer(boj[index].amount);
    }
    function dispute(uint256 index) public{
        require(msg.sender== boj[index].client || msg.sender== boj[index].freelancer,"you are able to raise any dispute on this job");
        require(boj[index].currentstatus==status.inProgress,"job has no authority to raise a dispute yet");
        boj[index].currentstatus=status.disputed;
    }
    function resolve(uint256 index,uint256 winnum)public{
        require(boj[index].currentstatus==status.disputed,"job is not disputed yet");
        require(msg.sender==boj[index].arbiter,"you are not allowed to resolve this dispute");
        if(winnum==1){
            boj[index].client.transfer(boj[index].amount);
        }
        else if(winnum==2){
            boj[index].freelancer.transfer(boj[index].amount);
        }
        else {
            revert("Invalid choice! Use 1 for Client, 2 for Freelancer"); // Sahi tarika
        }
         boj[index].currentstatus=status.resolved;
    }
   
}
// 0xB28Fed27af2bE4F9BFD8E317ab935e8145e0D685
// 