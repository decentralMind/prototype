pragma solidity ^0.5.0;

import './ERC20.sol';

contract PaymentGateway is ERC20 {
    
    
    
    mapping(address => bool) setGatewayAdd;
    
    mapping(address => address) gatewayAddList;


    modifier isGateywayReg(address gateway) {
        require(setGatewayAdd[gateway]);
        _;
    }
    
    function registerGateway(address gatewayAdd) external onlyEligible {
        require(!setGatewayAdd[gatewayAdd]);
        gatewayAddList[msg.sender] = gatewayAdd;
        setGatewayAdd[gatewayAdd] = true;
    }
    
    function receivePayment(address receiver, uint amount) external {
        require(setGatewayAdd[receiver]);
        _burn(gatewayAddList[receiver], amount);
    }


    function removeGateWay(address gatewayAdd) external  isGateywayReg(gatewayAdd) {
        setGatewayAdd[gatewayAdd] = false;
    }
    
    
}