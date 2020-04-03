pragma solidity ^0.5.0;


contract Community {
    
    // Deployer of the address is automatically set to owner.
    address public owner;

    // No of total community registered.
    uint256 totalCommunity;

    uint256 trustedCommunity;

    // After 90 days community can be trusted.
    uint256 trustedDate = 7776000;

    mapping(address => bool) registered;

    mapping(address => bool) isTrusted;

    mapping(address => uint256) whenToTrust;
    
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
    event NewCommunityEvent(address newCommunity, uint256 whenToTrust);
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
     * emits a {NewCommunityEvent}.
     */
    function addCommunity(address newCommunity) external onlyEligible {
        registered[newCommunity] = true;
        whenToTrust[newCommunity] = block.timestamp + trustedDate;
        emit NewCommunityEvent(newCommunity, whenToTrust[newCommunity]);
    }

    /**
     * @dev Registerd `registeredCommunity` as trusted.
     *
     * Requirements:
     * - Must be 90 days old.
     *
     * emits a {NewTrustedCommunity}
     */
    function addtoTrusted(address registeredCommunity) external {
        require(registered[registeredCommunity]);
        if (whenToTrust[registeredCommunity] > block.timestamp) {
            isTrusted[registeredCommunity] = true;
        }

        emit NewTrustedCommunity(registeredCommunity);
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
     * - `newDate` should be greater than current `block.timestamp`.
     * 
     * emits a {NewTrustedDateEvent}
     */
    function setTrustedDate(uint newDate) public onlyOwner {
        require(newDate > block.timestamp);
        trustedDate = newDate;
        emit NewTrustedDateEvent(newDate);
    }
}
