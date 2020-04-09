pragma solidity ^0.5.0;


contract Community {
    
    // Deployer of the address is automatically set to owner.
    address public owner;

    // No of total community registered.
    uint totalCommunity;

    uint trustedCommunity;

    // After 90 days community can be trusted.
    uint trustedDate = 7776000;
    
    // Set limit for how much token can be minted by new community.
    // Can be set to new amount by owner or through community consensus.
    // Restriction can be removed after `trustedDate`.
    uint newCommunityMintAmount = 30000;
    
    mapping(address => bool) registered;

    mapping(address => bool) isTrusted; 

    mapping(address => uint256) whenToTrust;
     
    mapping(address => uint) registeredDate;
    
    constructor() public {
      owner = msg.sender;
    }

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
                (registered[msg.sender] && isTrusted[msg.sender])
        );
        _;
    }

    modifier isFullyAuthorized(address community) {
        require(registered[community] == true);
        _;
    }

    modifier isAlreadyTrusted(address registeredCommunity) {
        require(!isTrusted[registeredCommunity]);
        _;
    }

    event NewOwnerEvent(address newOwner);
    event NewCommunityEvent(address newCommunity, uint registeredDate, uint256 whenToTrust);
    event NewTrustedCommunity(address registeredCommunity);
    event CommunityRemovedEvent(address oldCommunity);
    event NewTrustedDateEvent(uint newDate);

    /**
     *  @dev Returns owner.
     */
    function getOwner() public view returns(address) {
        return owner;
    }
    /**
     * @dev Transfer ownership to `newOwner`.
     *
     * Requirements:
     * - Must be owner.
     *
     * emits a {NewOwnerEvent}
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _replaceOwner(newOwner);
    }

    /**
     * @dev Change ownership to `newOwner`.
     *
     * emits a {NewOwnerEvent}.
     */
    function _replaceOwner(address newOwner) internal {
        owner = newOwner;
        emit NewOwnerEvent(owner);
    }

    /**
     * @dev Register `newCommunity` with future timestamp that
     * it can be trusted.
     * 
     *
     * emits a {NewCommunityEvent}.
     */
    function addCommunity(address newCommunity) external onlyEligible {
        registered[newCommunity] = true;
        whenToTrust[newCommunity] = block.timestamp + trustedDate;
        registeredDate[newCommunity] = block.timestamp;
        emit NewCommunityEvent(newCommunity, registeredDate[newCommunity], whenToTrust[newCommunity]);
    }

    /**
     * @dev Registerd `registeredCommunity` as trusted.
     *
     * Requirements:
     * - Must be 90 days old.
     *
     * emits a {NewTrustedCommunity}
     */
    function addToTrusted(address oldCommunity) external {
        require(registered[oldCommunity]);
        require(whenToTrust[oldCommunity] <= block.timestamp);
        isTrusted[oldCommunity] = true;
        emit NewTrustedCommunity(oldCommunity);
    }

    /**
     * @dev Owner directly add already `registeredCommunity` to trusted list.
     *
     * Requirements:
     * - Must be owner
     * - Community shoud already be registered but not as trusted.
     */
    function directlyTrustedByOwner(address registeredCommunity)
        external
        onlyOwner
        isAlreadyTrusted(registeredCommunity)
    {
        isTrusted[registeredCommunity] = true;
    }

     /**
     * @dev Owner directly remove `oldCommunity`.
     * Requirements:
     * - Must be owner
     * - Community shoud already be registered.
     */
    function directlyRemoveCommunity(address oldCommunity) external onlyOwner {
        _removeCommunity(oldCommunity);
        assert(
            registered[oldCommunity] == false &&
                isTrusted[oldCommunity] == false
        );
    }

    /**
     * @dev Removes already Registered `oldCommunity`
     *
     * Requirements:
     * - Community shoud be already registered.
     * - Only be called by trusted communities.
     *
     * emits a {CommunityRemovedEvent}
     */
    function _removeCommunity(address oldCommunity)
        internal
        isRegistered(oldCommunity)
    {
        registered[oldCommunity] = false;

        if (isTrusted[oldCommunity]) {
            isTrusted[oldCommunity] = false;
        }

        emit CommunityRemovedEvent(oldCommunity);
    }
    
    /**
     * @dev Set `trustedDate` to `newDate`.
     * Requirement:
     * - Must be owner.
     * 
     * emits a {NewTrustedDateEvent}
     */
    function setTrustedDate(uint newDate) public onlyOwner {
        trustedDate = newDate;
        emit NewTrustedDateEvent(newDate);
    }
    
    /**
     * @dev Returns true if `community` is regisitered and vice versa.
     */
    function checkIfRegistered(address community) external view returns(bool){
        return registered[community];
    }
    
    /**
     * @dev Returns true if `community` is trusted and vice versa.
     */
    function checkIfTrusted(address community) external view returns(bool){
        return isTrusted[community];
    }
    
    /**
     * @dev Returns date of the `community` that they can set as trusted.
     */
    function checkWhenToTrusted(address community) external view returns(uint){
        return whenToTrust[community];
    }
    
    /**
     * @dev Returns `trustedDate`.
     */
    function getTrustedDate() external view returns(uint) {
        return trustedDate;
    }
    
}