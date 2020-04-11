pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./VotingRemoval.sol";


contract SimpleToken is ERC20, VotingRemoval {}
