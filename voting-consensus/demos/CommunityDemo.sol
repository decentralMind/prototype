pragma solidity ^0.5.0;


interface CommunityData {
    //Add community
    function addCommunity(address newCommunity) external;
    function setTrustedDate(uint256 newDate) external;
    function checkWhenToTrusted(address community)
        external
        view
        returns (uint256);
        
    function addToTrusted(address oldCommunity) external;
    function directlyTrustedByOwner(address registeredCommunity) external;
    function getTrustedDate() external view returns (uint256);
    function numberOfTrustedCommunities() external view returns (uint256);
}

contract CommunityDemo {
    CommunityData cd;

    constructor(address deployAddress) public {
        cd = CommunityData(deployAddress);
    }

    function registerCommunity(address newCommunity) external {
        cd.addCommunity(newCommunity);
    }

    function setTrustedDate(uint256 newDate) external {
        cd.setTrustedDate(newDate);
    }

    function checkWhenToTrusted(address community)
        external
        view
        returns (uint256)
    {
        cd.checkWhenToTrusted(community);
    }

    function directlyTrustedByOwner(address registeredCommunity) external {
        cd.directlyTrustedByOwner(registeredCommunity);
    }

    function getTrustedDate() external view returns (uint256) {
        cd.getTrustedDate();
    }

    function numberOfTrustedCommunities() external view returns (uint256) {
        cd.numberOfTrustedCommunities();
    }
}
