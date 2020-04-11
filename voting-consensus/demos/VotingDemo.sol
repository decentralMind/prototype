pragma solidity ^0.5.0;


interface VotingData {
    function openCommunityRemoval(address commAdd, string calldata reason)
        external;

    function voteForCommunityRemoval(address commAdd) external;

    function changeCommunityNumber(uint256 newNumber) external;
}


contract VotingDemo {
    VotingData vd;

    constructor(address deployAddress) public {
        vd = VotingData(deployAddress);
    }

    function openCommunityRemoval(address commAdd, string calldata reason)
        external
    {
        vd.openCommunityRemoval(commAdd, reason);
    }

    function voteForCommunityRemoval(address commAdd) external {
        vd.voteForCommunityRemoval(commAdd);
    }

    function changeCommunityNumber(uint256 newNumber) external {
        vd.changeCommunityNumber(newNumber);
    }
}
