pragma solidity ^0.5.0;
import './VotingRemoval.sol';

/**
 * @title ERC20
 * @dev ERC20 token system.
 * This is just a quick prototype for GlobalHackaton.
 * Original version will implment Openzeppelin ERC20.
 * 
 */
 
contract ERC20 is VotingRemoval {
    
    mapping(address => uint) balance;
    
    uint totalSupply;
    
    event MintEvent(address minter, uint amount);
    
    event TransferEvent(address sender, address receiver, uint amount);
    
    event BurnEvent(address communityAdd, uint amount);

    function mint(uint amount) external onlyEligible {
        balance[msg.sender] = amount;
        emit MintEvent(msg.sender, amount);
    }
    
    function transfer(uint amount, address receiver) external onlyEligible{
        require(amount >= balance[msg.sender]);
        balance[msg.sender] -= amount;
        balance[receiver] += amount;
        emit TransferEvent(msg.sender, receiver, amount);
    }
    
    function getBalance(address receiver) external view returns(uint) {
        return balance[receiver];
    }
    
    function _burn(address communityAdd, uint amount) internal {
        balance[communityAdd] -= amount;
        emit BurnEvent(communityAdd, amount);
    }
}
