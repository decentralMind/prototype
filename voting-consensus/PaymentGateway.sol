pragma solidity ^0.5.0;

import "./VotingRemoval.sol";


contract PaymentGateway is VotingRemoval {
    // New payment address is set to true.
    mapping(address => bool)  private _validGatewayAddress;

    // New address is mapped to community.
    mapping(address => address) private _gatewayToCommunity;


    /**
     * @dev Throw if address is not registered at `validGatewayAddress`.
     */
    modifier isGatewayReg(address gateway) {
        require(_validGatewayAddress[gateway]);
        _;
    }

    /**
     * @dev Throw if provided `paymentAddress` is registered or trusted community and
     * already registered as payment gatement.
     */
    modifier addressValidation(address paymentAddress) {
        require(!_validGatewayAddress[paymentAddress], 'Address already registered as payment gateway.');
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
        _gatewayToCommunity[gatewayAdd] = msg.sender;
        _validGatewayAddress[gatewayAdd] = true;
    }

    /**
     * @dev Remove registered `gateWayAdd` address.
     */
    function removeGateway(address gatewayAdd)
        external
        onlyEligible
        isGatewayReg(gatewayAdd)
    {
        _validGatewayAddress[gatewayAdd] = false;
    }

    /**
     * @dev Remove registered `gateWayAdd` address.
     */
    function paymentGatewayRegistered(address receiver)
        public
        view
        returns (bool)
    {
        return _validGatewayAddress[receiver];
    }

    /**
     * @dev Returns community address who registered `payment`.
     */
    function whoRegisteredPayment(address payment)
        external
        view
        returns (address)
    {
        return _gatewayToCommunity[payment];
    }

}
