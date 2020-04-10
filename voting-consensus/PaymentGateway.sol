pragma solidity ^0.5.0;

import './VotingRemoval.sol';

contract PaymentGateway is VotingRemoval {
    
    // New payment address is set to true.
    mapping(address => bool) validGatewayAddress;
    
    // New address is mapped to community.
    mapping(address => address) gatewayToCommunity;
    
    // All the list of address registered by the given community.
    mapping(address => address[]) gatewayList;
    
    
    /**
     * @dev Throw if address is not registered at `validGatewayAddress`.
     */
    modifier isGatewayReg(address gateway) {
        require(validGatewayAddress[gateway]);
        _;
    }
    
    /**
     * @dev Communities needs to `registerGateway` address  if they
     * want to receive payment.
     * 
     */
    function registerGateway(address gatewayAdd) external onlyEligible {
        require(!validGatewayAddress[gatewayAdd]);
        gatewayToCommunity[gatewayAdd] = msg.sender;
        validGatewayAddress[gatewayAdd] = true;
        gatewayList[msg.sender].push(gatewayAdd);
    }
    
    /**
     * @dev Remove registered `gateWayAdd` address.
     */
    function removeGateWay(address gatewayAdd) external onlyEligible isGatewayReg(gatewayAdd) {
        validGatewayAddress[gatewayAdd] = false;
    }
    
     /**
     * @dev Remove registered `gateWayAdd` address.
     */
    function paymentGatewayRegistered(address receiver) public view returns(bool) {
        return validGatewayAddress[receiver];
    }
    
    /**
     * @dev Returns length of respective `gatewayList` of given `community`.
     */
    function getGetwayListLength(address community) public view returns(uint) {
        return gatewayList[community].length;
    }
    
    /**
     * @dev Returns registered address as payment gateway by `community` by provided `index`.
     */
    function accessGatewayList(address community, uint index) public view returns(address) {
        return gatewayList[community][index];
    }

}



