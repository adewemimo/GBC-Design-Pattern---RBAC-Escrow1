// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol';

contract Escrow is AccessControl {
    // Create a new role identifier for the agent, buyer and seller roles
    bytes32 public constant AGENT_ROLE = keccak256('AGENT_ROLE');
    bytes32 public constant BUYER_ROLE = keccak256('BUYER_ROLE');
    bytes32 public constant SELLER_ROLE = keccak256('SELLER_ROLE');
    
    
    enum state {Awaiting_Payment, Awaiting_Delivery, Complete}
    state public currentState;
    modifier inState(state expectedState){
        require(expectedState == currentState, 'incorrect state');
        _;
    }
    
    mapping(address => uint256) public deposits;
    
    constructor(address seller) {
        // Grant the agent and buyer roles to a specified account
        _setupRole(AGENT_ROLE, msg.sender);
        _setupRole(BUYER_ROLE, msg.sender);
        _setupRole(SELLER_ROLE, seller);
    }
    function depositPayment(address seller) inState(state.Awaiting_Payment) public payable {
        //The buyer deposits the money into the contract
        require(hasRole(BUYER_ROLE, msg.sender), 'Not the right buyer');
        require(hasRole(SELLER_ROLE, seller), 'Not the right seller');
        uint amount = msg.value;
        deposits[seller] += amount;
        currentState = state.Awaiting_Delivery;
    }
    
    function deliveryConfirmed(address payable seller, bool status) inState(state.Awaiting_Delivery) public {
        //agent confirms seller has delivered
        require(hasRole(AGENT_ROLE, msg.sender), 'Not the right agent');
        require(hasRole(SELLER_ROLE, seller), 'Not the right seller');
        require(status == true, 'delivery not confirmed');
        uint payment = deposits[seller];
        deposits[seller] = 0;
        seller.transfer(payment);
        currentState = state.Complete;
    }
}
