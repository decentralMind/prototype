pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./VotingRemoval.sol";

/**
 * @title GaiaToken
 * @dev Prototype token name Gaia.
 */
contract GaiaToken is ERC20, VotingRemoval {

    /** 
     *@dev Construtor that intialize token name and symbol.
     *
     */
     
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    
    constructor(string memory tokenName, string memory tokenSymbol) public {
        name = tokenName;
        symbol = tokenSymbol;
    }
    
}
