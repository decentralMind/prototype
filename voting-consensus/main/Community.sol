pragma solidity ^0.5.0;


contract Community {
    // Deployer of the address is automatically set to owner.
    address public owner;

    // No of total community registered.
    uint256 internal _totalCommunity;

    // No of total community labeled as trusted.
    uint256 internal _trustedCommunity;

    // After 90 days community can be trusted.
    uint256 private _trustedDate = 7776000;

    // Address registration.
    mapping(address => bool) internal _registered;

    // Trusted address.
    mapping(address => bool) internal _isTrusted;

    // Infomration on when community can be trusted.
    mapping(address => uint256) private _whenToTrust;

    // Community registration date.
    mapping(address => uint256) private _registeredDate;

    constructor() public {
        owner = msg.sender;
    }

    modifier isRegistered(address community) {
        require(_registered[community] == true, "Community not registered");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not an owner");
        _;
    }

    modifier onlyEligible() {
        require(
            owner == msg.sender ||
                (_registered[msg.sender] && _isTrusted[msg.sender]),
            "Must be owner or registered as trusted"
        );
        _;
    }

    modifier isAlreadyTrusted(address registeredCommunity) {
        require(
            !_isTrusted[registeredCommunity],
            "Community already registered"
        );
        _;
    }

    event NewOwnerEvent(address newOwner);
    event NewCommunityEvent(
        address newCommunity,
        uint256 registeredDate,
        uint256 whenToTrust
    );
    event NewTrustedCommunity(address registeredCommunity);
    event CommunityRemovedEvent(address oldCommunity);
    event NewTrustedDateEvent(uint256 newDate);

    /**
     *  @dev Returns owner.
     */
    function getOwner() public view returns (address) {
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
     * Requirements:
     * - Community should not be already registered.
     * emits a {NewCommunityEvent}.
     */
    function addCommunity(address newCommunity) external onlyEligible {
        require(!_registered[newCommunity], "Community already registered");
        _registered[newCommunity] = true;
        _whenToTrust[newCommunity] = block.timestamp + _trustedDate;
        _registeredDate[newCommunity] = block.timestamp;
        emit NewCommunityEvent(
            newCommunity,
            _registeredDate[newCommunity],
            _whenToTrust[newCommunity]
        );
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
        require(_registered[oldCommunity], "Commuinity is not registered");
        require(
            _whenToTrust[oldCommunity] <= block.timestamp,
            "Community can be only trusted after 90 days"
        );
        _isTrusted[oldCommunity] = true;
        _trustedCommunity++;
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
        _isTrusted[registeredCommunity] = true;
        _trustedCommunity++;
    }

    /**
     * @dev Set `trustedDate` to `newDate`.
     * Requirement:
     * - Must be owner.
     *
     * emits a {NewTrustedDateEvent}
     */
    function setTrustedDate(uint256 newDate) external onlyOwner {
        _trustedDate = newDate;
        emit NewTrustedDateEvent(newDate);
    }

    /**
     * @dev Returns true if `community` is regisitered and vice versa.
     */
    function checkIfRegistered(address community) public view returns (bool) {
        return _registered[community];
    }

    /**
     * @dev Returns true if `community` is trusted and vice versa.
     */
    function checkIfTrusted(address community) public view returns (bool) {
        return _isTrusted[community];
    }

    /**
     * @dev Returns date of the `community` that they can set as trusted.
     */
    function checkWhenToTrusted(address community)
        external
        view
        returns (uint256)
    {
        return _whenToTrust[community];
    }

    /**
     * @dev Returns `trustedDate`.
     */
    function getTrustedDate() external view returns (uint256) {
        return _trustedDate;
    }

    function numberOfTrustedCommunities() external view returns (uint256) {
        return _trustedCommunity;
    }
}
