//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

contract CrowdFunding{
    mapping(address=>uint) public contributors; 
    address public Manager; 
    uint public minContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;
    
    struct Request{
        string description;
        address payable recipient;
        uint value;                     //This is for manager to create different request so that contributors can vote and make the payment successful
        bool completed_request;         // also manager can describe their request to whom they are giving
        uint noOfVoters;
        mapping(address=>bool) voters;
    }
    mapping(uint=>Request) public requests;
    uint public numRequests;

    constructor(uint _target,uint _deadline) public{
        target=_target;
        deadline=block.timestamp+_deadline; 
        minContribution=100 wei;
        Manager=msg.sender;
    }
    
    function sendEth() public payable{
        require(block.timestamp < deadline,"Deadline has passed");
        require(msg.value >=minContribution,"Minimum Contribution is not met");
        
        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    function refund() public{
        require(block.timestamp>deadline && raisedAmount<target,"You are not eligible");
        require(contributors[msg.sender]>0);
        address payable user=msg.sender;                    //Using this function contributors can refund their wei if they are elligible
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
        
    }
    modifier onlyManger(){
        require(msg.sender==Manager,"Only manager can calll this function");
        _;
    }
    function createRequests(string memory _description,address payable _recipient,uint _value) public onlyManger{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;                //This is only for manager to create requests for help
        newRequest.value=_value;
        newRequest.completed_request=false;
        newRequest.noOfVoters=0;
    }
    function voteRequest(uint _requestNo) public{                    //This is for contributors to vote their request
        require(contributors[msg.sender]>0,"You have not contributed");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }
    function makePayment(uint _requestNo) public onlyManger{          //Only manager can call this function to make payment to the recipient
        require(raisedAmount>=target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed_request==false,"The request has been completed");
        require(thisRequest.noOfVoters > noOfContributors/2,"Majority does not supported");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed_request=true;
    }
}

