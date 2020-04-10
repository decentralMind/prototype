pragma solidity ^0.5.0;
import './PaymentGateway.sol';

/**
 * @title ERC20
 * @dev ERC20 token system.
 * This is just a quick prototype for GlobalHackaton.
 * Original version will implement using Openzeppelin ERC20.
 * 
 */
 
contract ERC20 is PaymentGateway {
    
    mapping(address => uint) balance;
    
    uint totalSupply;
    
    event MintEvent(address minter, uint amount);
    
    event TransferEvent(address sender, address receiver, uint amount);
    
    event BurnEvent(address communityAdd, uint amount);

    // Total amount of burned token for the given community.
    mapping(address => uint) totalBurnedByCommunity;
    
    // Total amonnt of burned token for given registered ` validGatewayAddress` address.
    mapping(address => uint) totalPaymentGatewayBurned;
    
    //Should not be gateway.
    function mint(uint amount) external onlyEligible {
        balance[msg.sender] = amount;
        emit MintEvent(msg.sender, amount);
    }
    
    function transfer(uint amount, address receiver) external onlyEligible {
        require(amount >= balance[msg.sender]);
        balance[msg.sender] -= amount;
        
        if(paymentGatewayRegistered(receiver)) {
            _gatewayPayment(msg.sender, receiver, amount);
        } else {
             balance[receiver] += amount;
        }
        emit TransferEvent(msg.sender, receiver, amount);
    }
    
    function _gatewayPayment(address sender, address gatewayAdd, uint amount) private {
        _burn(sender, amount);
        totalBurnedByCommunity[sender] += amount;
        totalPaymentGatewayBurned[gatewayAdd] += amount;
    }
    
    function getBalance(address receiver) external view returns(uint) {
        return balance[receiver];
    }
    
    function _burn(address communityAdd, uint amount) internal {
        balance[communityAdd] -= amount;
        emit BurnEvent(communityAdd, amount);
    }
}
