pragma solidity ^0.5.0;

import "./VotingRemoval.sol";


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
     * @dev Throw if provided `paymentAddress` is registered or trusted community and
     * already registered as payment gatement.
     */
    modifier addressValidation(address paymentAddress) {
        require(!validGatewayAddress[paymentAddress], 'Address already registered as payment gateway.');
        require(!checkIfRegistered(paymentAddress), 'Address already registered as community');
        require(!checkIfTrusted(paymentAddress), 'Address already registered as trusted');
        _;
    }

    /**
     * @dev Communities needs to `registerGateway` address  if they
     * want to receive payment.
     *
     */
    function registerGateway(address gatewayAdd)
        external
        onlyEligible
        addressValidation(gatewayAdd)
    {
        gatewayToCommunity[gatewayAdd] = msg.sender;
        validGatewayAddress[gatewayAdd] = true;
        gatewayList[msg.sender].push(gatewayAdd);
    }

    /**
     * @dev Remove registered `gateWayAdd` address.
     */
    function removeGateway(address gatewayAdd)
        external
        onlyEligible
        isGatewayReg(gatewayAdd)
    {
        validGatewayAddress[gatewayAdd] = false;
    }

    /**
     * @dev Remove registered `gateWayAdd` address.
     */
    function paymentGatewayRegistered(address receiver)
        public
        view
        returns (bool)
    {
        return validGatewayAddress[receiver];
    }

    /**
     * @dev Returns length of respective `gatewayList` of given `community`.
     */
    function getGetwayListLength(address community)
        external
        view
        returns (uint256)
    {
        return gatewayList[community].length;
    }

    /**
     * @dev Returns registered address as payment gateway by `community` by provided `index`.
     */
    function accessGatewayList(address community, uint256 index)
        external
        view
        returns (address)
    {
        return gatewayList[community][index];
    }
}
