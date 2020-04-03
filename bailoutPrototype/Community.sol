pragma solidity ^0.5.0;


contract Community {
    address public owner;

    uint256 public totalCommunity;

    uint256 public trustedCommunity;

    mapping(address => bool) registered;

    mapping(address => bool) isTrusted;
    
    mapping(address => bool) fullAuthority;

    modifier isRegistered(address community) {
        require(registered[community] == true);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyEligible() {
        require(
            owner == msg.sender ||
                (registered[msg.sender] &&
                    isTrusted[msg.sender] &&
                    fullAuthority[msg.sender])
        );
        _;
    }
    
    modifier isFullyAuthorized(address community) {
        require(registered[community] == true);
        _;
    }
    

    function addOwner(address newOwner) public {
        owner = newOwner;
    }

    function addCommunity(address newCommunity) public onlyEligible {
        registered[newCommunity] = true;
    }

    function addtoTrusted(address oldCommunity) public onlyEligible {
        require(registered[oldCommunity]);
        isTrusted[oldCommunity] = true;
    }

    function giveFullAuthroity(address oldCommunity) public onlyEligible {
        fullAuthority[oldCommunity] = true;
    }

    function removeCommunity(address oldCommunity)
        public
        onlyOwner
        isRegistered(oldCommunity)
    {
        registered[oldCommunity] = false;

        if (isTrusted[oldCommunity]) {
            isTrusted[oldCommunity] = false;
        }

        if (fullAuthority[oldCommunity]) {
            fullAuthority[oldCommunity] = false;
        }
    }
}
