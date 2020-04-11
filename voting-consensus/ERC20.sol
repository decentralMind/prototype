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
    
    string public name;
    string public symbol;
    uint8 public constant decimals = 10;
    
    constructor(string memory ERC20name, string memory ERC20symbol) public {
        name = ERC20name;
        symbol = ERC20symbol;
    }
    
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

    uint public tokenLimit = 20000;
    
    /**
    * @dev Create new token of `amount` into the contract.
    * Requirements:
    * -It cannot be address which is regstered as payment gateway,
    * check PaymentGateway.sol .
    * - New token creation limit is set to `tokenLimit` .
    * 
    * emits {MintEvent}
    */
    function mint(uint amount) external onlyEligible {
        require(amount <= 20000, 'Token amount exceed than restricted amount');
        require(!paymentGatewayRegistered(msg.sender));
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
        require(balance[msg.sender] >= amount, 'Insuffcient balance.');
        
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
     * @dev Destroy `amount` of token of given address `communityAdd`.
     * emits {BurnEvent} .
     */
    function _burn(address communityAdd, uint amount) private {
        balance[communityAdd] -= amount;
        totalSupply -= amount;
        emit BurnEvent(communityAdd, amount);
    }

    /**
     *@dev Returns `totalSupply`.
     *
     */
    function getTotalSupply() external view returns(uint) {
        return totalSupply;
    }

    /**
     * @dev Get balance of `tokenOwner`.
     * @return uint256, balance of receiver.
     */
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balance[tokenOwner];
    }
}
