pragma solidity ^0.5.0;
import "./PaymentGateway.sol";


/**
 * @title ERC20
 * @dev ERC20 token system.
 * This is just a quick prototype for GlobalHackaton.
 * Original version will implemented using Openzeppelin ERC20.
 *
 **/

contract ERC20 is PaymentGateway {
    
    // Balance mapped to receiver address.
    mapping(address => uint256) private _balance;

    // Total amount of minted coins.
    uint256 private _totalSupply;

    event MintEvent(address minter, uint256 amount);

    event TransferEvent(address sender, address receiver, uint256 amount);

    event BurnEvent(address communityAdd, uint256 amount);

    // Total amount of burned token for the given community.
    mapping(address => uint256) private _totalBurnedByCommunity;

    // Total amount of burned token for given registered ` validGatewayAddress` address.
    mapping(address => uint256) private _totalPaymentGatewayBurned;

    /**
     * @dev Create new token of `amount` into the contract.
     * Requirements:
     * -It cannot be address which is regstered as payment gateway,
     * check PaymentGateway.sol .
     *
     * emits {MintEvent}
     */

    function mint(uint256 amount) external onlyEligible {
        require(!paymentGatewayRegistered(msg.sender));
        _balance[msg.sender] = amount;
        _totalSupply += amount;
        emit MintEvent(msg.sender, amount);
    }

    /**
     * @dev Transfer `amount` from `receiver` to sender address.
     * Requirements:
     *-`receiver` should have sufficient balance `amount`.
     *
     * emits {TransferEvent}.
     */
    function transfer(uint256 amount, address receiver) external onlyEligible {
        require(_balance[msg.sender] >= amount, "Insuffcient balance.");

        if (paymentGatewayRegistered(receiver)) {
            _gatewayPayment(msg.sender, receiver, amount);
        } else {
            _balance[msg.sender] -= amount;
            _balance[receiver] += amount;
        }
        emit TransferEvent(msg.sender, receiver, amount);
    }

    /**
     * @dev If `sender` address is registered gateway `gatewayAdd` address, `amount` of
     * token transfered is destoryed through {_burn} method.
     */
    function _gatewayPayment(address sender, address gatewayAdd, uint256 amount)
        private
    {
        _burn(sender, amount);
        _totalBurnedByCommunity[sender] += amount;
        _totalPaymentGatewayBurned[gatewayAdd] += amount;
    }

    /**
     * @dev Destroy `amount` of token of given address `communityAdd`.
     * emits {BurnEvent} .
     */
    function _burn(address communityAdd, uint256 amount) internal {
        _balance[communityAdd] -= amount;
        _totalSupply -= amount;
        emit BurnEvent(communityAdd, amount);
    }

    /**
     *@dev Returns `totalSupply`.
     *
     */
    function getTotalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Get balance of `tokenOwner`.
     * @return uint256, balance of receiver.
     */
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return _balance[tokenOwner];
    }
}
