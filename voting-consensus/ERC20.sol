pragma solidity ^0.5.0;
import './PaymentGateway.sol';

/**
 * @title ERC20
 * @dev ERC20 token system.
 * This is just a quick prototype for GlobalHackaton.
 * Original version will implemented using Openzeppelin ERC20.
 * 
 **/

contract ERC20 is PaymentGateway {
    
    // Balance mapped to receiver address.
    mapping(address => uint) balance;
    
    // Total amount of minted coins.
    uint totalSupply;
    
    event MintEvent(address minter, uint amount);
    
    event TransferEvent(address sender, address receiver, uint amount);
    
    event BurnEvent(address communityAdd, uint amount);

    // Total amount of burned token for the given community.
    mapping(address => uint) totalBurnedByCommunity;
    
    // Total amount of burned token for given registered ` validGatewayAddress` address.
    mapping(address => uint) totalPaymentGatewayBurned;
    
    /**
    * @dev Create new token of `amount` into the contract.
    * Requirements:
    * -It cannot be address which is regstered as payment gateway,
    * check PaymentGateway.sol .
    *
    * emits {MintEvent}
    */
    function mint(uint amount) external onlyEligible {
        require(!paymentGatewayRegistered[msg.sender]);
        balance[msg.sender] = amount;
        totalSupply += amount;
        emit MintEvent(msg.sender, amount);
    }
    
    /**
     * @dev Transfer `amount` from `receiver` to sender address.
     * Requirements:
     *-`receiver` should have sufficient balance `amount`.
     * 
     * emits {TransferEvent}.
     */
    function transfer(uint amount, address receiver) external onlyEligible {
        require(amount >= balance[msg.sender]);
        
        if(paymentGatewayRegistered(receiver)) {
            _gatewayPayment(msg.sender, receiver, amount);
        } else {
             balance[msg.sender] -= amount;
             balance[receiver] += amount;
        }
        emit TransferEvent(msg.sender, receiver, amount);
    }
    
    /**
     * @dev If `sender` address is registered gateway `gatewayAdd` address, `amount` of
     * token transfered is destoryed through {_burn} method.
     */
    function _gatewayPayment(address sender, address gatewayAdd, uint amount) private {
        _burn(sender, amount);
        totalBurnedByCommunity[sender] += amount;
        totalPaymentGatewayBurned[gatewayAdd] += amount;
    }

    
    /**
     * @dev Get `receiver` token balance.
     * @return uint256, balance of receiver.
     */
    function getBalance(address receiver) external view returns(uint) {
        return balance[receiver];
    }
    
    /**
     * @dev Destroy `amount` of token of given address `communityAdd`.
     * emits {BurnEvent} .
     */
    function _burn(address communityAdd, uint amount) internal {
        balance[communityAdd] -= amount;
        emit BurnEvent(communityAdd, amount);
    }
}
