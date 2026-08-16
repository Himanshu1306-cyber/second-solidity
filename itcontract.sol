// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract signalTipwall{
     error notProvide();
     error EmptyField(string fieldName);
     
    // mapping(address => uint256[]) public msgid;

    struct trade{
        uint256 msgId;
        address payable sender;
        address payable receiver;
        uint256 amt;
        string description;
        string commodities_Name;
        string action;
        uint256 TargetProfit;
        uint256 StopLoss;
        string Reason;

    }
    struct YearlyReturn{
        uint256 year;
        uint256 totalReturn;
    }


    struct invest{
        uint256 msgId;
        address payable sender;
        address payable receiver;
        uint256 amt;
        string description;
        string commodities_Name;
        string action;
        string reason;
        uint256 period;
        YearlyReturn[]returnss;
    }


    trade[] public trde;
    invest[] public investo;
 
    uint256 public tradeCount;
    uint256 public investCount;



    function createMsgforTrade(
    uint256 amount,
    string memory name,
    string memory description,
    uint256 Target,
    string memory action,
    string memory reason,
    uint256 Stop) public {
            if(amount == 0){
                revert notProvide();
            }
            if(bytes(name).length==0){
                revert EmptyField("fill first this");
            }
            if(bytes(action).length==0){
                revert EmptyField("fill first this");
            }
            if(bytes(reason).length==0){
                revert EmptyField("fill first this");
            }
            if(bytes(description).length==0){
                revert EmptyField("fill first this");
            }            
            if(Stop == 0){
                revert notProvide();
            }
            if(Target == 0){
                revert notProvide();
            }
            if(Target == Stop){
                revert EmptyField("both are same");
            }
        


        tradeCount++;
        trde.push(trade(
            tradeCount,
            payable (msg.sender),
            payable (address(0)),
            amount,
            description,
            name,
            action,
            Target,
            Stop,
            reason));
    
    }
    function createMsgforInvest(uint256 amount,
    string memory description,
    string memory name,
    string memory action,
    string memory reason,
    uint256 period_in_years,
    uint256 year,
    uint256 ret,
    uint256 year2,
    uint256 ret2,
    uint256 year3,
    uint256 ret3)public{

        if(amount == 0){
            revert notProvide();
        }
        if(bytes(name).length == 0){
            revert EmptyField("fill this first");
        }
        if(bytes(description).length ==0){
            revert EmptyField("fill this first");
        }
        if(bytes(action).length==0){
            revert EmptyField("fill this first");
        }
        if(bytes(reason).length==0){
            revert EmptyField("fill this first");
        }
        if(period_in_years==0){
            revert notProvide();
        }
        if(year ==0||year2==0||year3==0){
            revert notProvide();
        }
        if(ret==0||ret2==0||ret3==0){
            revert notProvide();
        }



      investCount++;

      //struct ke andar jab koi struct push karna ho to uske liye storage pehle define karni padti hai
      invest storage newinvest=investo.push();
      newinvest.msgId=investCount;
      newinvest.sender=payable(msg.sender);
      newinvest.receiver=payable(address(0));
      newinvest.amt=amount;
      newinvest.description=description;
      newinvest.commodities_Name=name;
      newinvest.action=action;
      newinvest.reason=reason;
      newinvest.period=period_in_years;

      //struct ke andar aise dusra struct push karte hai
      newinvest.returnss.push(YearlyReturn(year,ret));
      newinvest.returnss.push(YearlyReturn(year2,ret2));
      newinvest.returnss.push(YearlyReturn(year3,ret3));
    }


    // function viewMsgforTrade(uint256 index)public payable returns(address sender,
    //        string memory description,
    //        string memory commodities_Name,
    //        string memory action,
    //        uint256 Target,
    //        uint256 Stop,
    //        string memory reason){
    //     //    uint256 msgId= index;                    
    //     //    msgid[sender][index];
    //        if(msg.sender!=trade[index].sender||msg.sender!=invest[index].sender){
    //         require(trade[index].sender.transfer(trade[index].amt),"u have to pay first to see this msg");
    //        }
           
    //         return (trade[index].sender,
    //        trade[index].description,
    //        trade[index].commodities_Name,
    //        trade[index].action,
    //        trade[index].Target,
    //        trade[index].Stop,
    //        trade[index].reason);
    //     }
    //     // else{
            
    //     // }
    function viewmsgFortrade(uint256 index)public payable returns(address sender,
    string memory description,
    string memory commodities_Name,
    string memory action,
    uint256 TargetProfit,
    uint256 StopLoss,
    string memory Reason){
        
        require(index<trde.length,"this trade is not created yet");
        if(msg.sender!=trde[index].sender){
             require(msg.value >=trde[index].amt,"you need to pay the fee");
             trde[index].sender.transfer(msg.value);
             return(
                trde[index].sender,
                trde[index].description,
                trde[index].commodities_Name,
                trde[index].action,
                trde[index].TargetProfit,
                trde[index].StopLoss,
                trde[index].Reason
             );
             
        }
        else{return(trde[index].sender,
                trde[index].description,
                trde[index].commodities_Name,
                trde[index].action,
                trde[index].TargetProfit,
                trde[index].StopLoss,
                trde[index].Reason

        );

        }

    }
    function viewmsgForinvest(uint256 index)public payable returns(address sender,
    string memory description,
    string memory commodities_Name,
    string memory action,
    string memory reason,
    uint256 period,
    YearlyReturn[] memory returnss){

    }
    }

