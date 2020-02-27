pragma solidity ^0.5.0;

/**
 * @title CommunityERC20
 * @dev Each community has it's own set of token name, batch number and balance map to owner.
 */
contract CommunityERC20 {
    // Batch number is expected to increase monthly basis.
    // Resistered community can only mint token once in a given batch.
    uint256 public batch = 1;

    // Each community has own set to record batch number, total and balance of it's receiver.
    struct Create {
        uint256 batch; //record batch number
        uint256 total; // record total amount of token created
        mapping(address => uint256) balance; // balance mapped to it's receiver.
    }

    // Total number of registered community.
    uint256 public totalCommunity = 1;

    // Record Community with it's index number.
    mapping(address => uint256) communityIndex;

    // Get community address with repective index.
    mapping(uint256 => address) getCommunityFromIndex;

    // Balance array records community index and batch numb.
    // for each reciever address.
    // If receiver has array elements [1, 2] at index 0 of balance that means,
    // it has token created by registered community at index 1(getCommunityFromIndex) during
    // batch number 2.
    mapping(address => uint256[2][]) public balance;

    // Receiver total balance.
    mapping(address => uint256) public totalBalance;

    // Map every token creation and transfer of community created token.
    // Community address => batch number => struct map.
    mapping(address => mapping(uint256 => Create)) tokenStructList;

    /**
     * @dev Check if community address is registered. 
     * @param community registered address.
     */
    modifier isRegistered(address community) {
        require(communityIndex[community] > 0, "community not registered");
        _;
    }

    /**
     * @dev Retrieve total number of registered community.
     * totalCommunity is also used for community index so it is initialise at 1.
     * @return 'totalCommunity'
     */
    function getTotalCommunity() public view returns (uint256) {
        return totalCommunity - 1;
    }

    /**
     * @dev Return current batch number.
     * @return 'batch'
     */
    function getCurrentBatch() public view returns (uint256) {
        return batch;
    }

    /**
     * @dev Check if community address is registered. 
     * @param owner addres.
     */
    function _reduceBalanceArray(address owner, uint256 reduceNum)
        private
        returns (bool)
    {
        require(
            reduceNum <= balance[owner].length || balance[owner].length > 0,
            "reduceNum is higher than array lenght or balance length is zero"
        );
        balance[owner].length = balance[owner].length - reduceNum;
        return true;
    }

    /**
     * @dev Readjust sender and receiver balance in specific community and batch number.
     * @param community address.
     * @param getBatch batch number in which token is created by the community.
     * @param sender address.
     * @param receiver address.
     * @param amount request to be sent to receiver address.
     */
    function _balanceShift(
        address community,
        uint256 getBatch,
        address sender,
        address receiver,
        uint256 amount
    ) private returns (bool) {
        tokenStructList[community][getBatch].balance[sender] -= amount;
        tokenStructList[community][getBatch].balance[receiver] += amount;
        return true;
    }

    /**
     * @dev Length of balance array.
     * @param owner address.
     */
    function getBalanceLength(address owner) public view returns (uint256) {
        return balance[owner].length;
    }

    /**
     * @dev Get total balance of owner, this is cummulative of all balances within each community.
     * @param owner address of those who held tokens.
     * @return uint256 total balance.
     */
    function getTotalBalance(address owner) public view returns (uint256) {
        return totalBalance[owner];
    }

    /**
     * @dev Incease batch number.
     * @return uint256 batch number.
     */
    function increaseBatchNumber() public returns (uint256) {
        batch += 1;
        return batch;
    }

    /**
     * @dev Check if community address is registered. 
     * @param community registered address..
     */
    function specificBalance(address community, uint256 getBatch, address user)
        public
        view
        isRegistered(community)
        returns (uint256)
    {
        return tokenStructList[community][getBatch].balance[user];
    }

    /**
     * @dev register new community.
     * @param newCommunity address of newly requested community.
     * @return bool.
     */
    function addCommunity(address newCommunity) public returns (bool) {
        require(
            communityIndex[newCommunity] == 0,
            "Error:Community already registered"
        );
        communityIndex[newCommunity] = totalCommunity;
        getCommunityFromIndex[totalCommunity] = newCommunity;
        totalCommunity++;
        return true;
    }

    /**
     * @dev Find registered community index.
     * @param newCommunity address of community.
     * @return uint256 community index.
     */
    function findCommunityIndex(address newCommunity)
        public
        view
        returns (uint256)
    {
        return communityIndex[newCommunity];
    }

    /**
     * @dev Retrieve community address from index.
     * @param index of the registered community.
     * @return address community.
     */
    function getAddressFromIndex(uint256 index) public view returns (address) {
        return getCommunityFromIndex[index];
    }

    /**
     * @dev check if the current latest receiver 'balance[receiver address]' balance array is same
     * as sender 'balance[sender address]' balance array.
     * @param senderArrayBal require array returns by 'balance[sender address]`.
     * @param receiverArrayBal require array returns by 'balance[receiver address]`.
     * @return bool
     */
    function checkBalanceArray(
        uint256[2] memory senderArrayBal,
        uint256[2] memory receiverArrayBal
    ) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(senderArrayBal)) !=
            keccak256(abi.encodePacked(receiverArrayBal));
    }

    /**
     * @dev get the last element of array 'balance[address]'.
     * If array has not been intilised, it returns [0,0].
     * @param owner address.
     * @return array length of 2. e.g. [1, 2] or [0,0].
     */
    function getLastArrayIndex(address owner)
        public
        view
        returns (uint256[2] memory)
    {
        if (getBalanceLength(owner) == 0) {
            //For unassigned array, it returns array literals initialize with 0 element at index 0 for uint[2]
            //Useful for comparision check
            return [uint256(0), 0];
        } else if (getBalanceLength(owner) > 0) {
            return balance[owner][getBalanceLength(owner) - 1];
        }
    }

    /**
     * @dev allow registered community to create new token and tranfer to given address.
     * If registered community has minted token in a given batch it needs to wait for the batch number to increase
     * in order to mint new token.
     * @param receiver address to send newly minted otken.
     * @return book.
     */
    function mint(address receiver, uint256 amount)
        public
        // Check if community is registered.
        isRegistered(msg.sender)
        returns (bool)
    {
        // Community can only mint token once in a given batch number.
        require(
            tokenStructList[msg.sender][batch].batch != batch,
            "Already created token for this batch, wait until next batch increase"
        );

        // Record community token creation and transfer.
        Create storage c = tokenStructList[msg.sender][batch];

        // Current batch number
        c.batch = batch;

        // Total amount
        c.total = amount;

        // Map reciever bbalance
        c.balance[receiver] = amount;

        // Store the origin of current balance in array.
        // Community origin is stored as index.
        balance[receiver].push([communityIndex[msg.sender], batch]);

        // Total available balance of user address from all the community.
        totalBalance[receiver] += amount;

        return true;
    }

    // Use for internal propose while transferring token.
    // Only loaded into memory.
    struct Internal {
        uint256 indexDepth; // store how many arrays looped 'balance[address]'.
        uint256 currentBatch; // store current batch.
        uint256 currentBalance; // store current balance.
        uint256 balanceLength; // store 'balance[address]' array length.
        address currentComm; // store current community address.
    }

    /**
     * @dev If sender 'balance[address]' last index respective to it's 
     * commuinity address and batch has insufficient balance than the requested
     * transfe amount, 'balance[address]' index needs to be shift in descending order
     * to get sender token address in different batch or community and transfer 
     * to receiver address.
     * @param amount request transfer amount.
     * @param receiver address.
     * @return true.
     */
    function loopAndTransfer(uint256 amount, address receiver)
        public
        returns (bool)
    {
        Internal memory c;

        while (amount > 0) {
            uint256[2] memory senderArrayBal = getLastArrayIndex(msg.sender);
            uint256[2] memory receiverArrayBal = getLastArrayIndex(receiver);
            c.currentComm = getCommunityFromIndex[senderArrayBal[0]];
            c.currentBatch = senderArrayBal[1];
            c.currentBalance = specificBalance(
                c.currentComm,
                c.currentBatch,
                msg.sender
            );

            if (c.currentBalance <= amount) {
                amount -= c.currentBalance;
                _balanceShift(
                    c.currentComm,
                    c.currentBatch,
                    msg.sender,
                    receiver,
                    c.currentBalance
                );

                // Record how many array index shifted in receiver 'balance[address]'.
                c.indexDepth++;
                totalBalance[receiver] += c.currentBalance;
                if (checkBalanceArray(senderArrayBal, receiverArrayBal)) {
                    balance[receiver].push(senderArrayBal);
                }

                // Remove empty sender balance array.
                _reduceBalanceArray(msg.sender, 1);

            } else if (c.currentBalance > amount) {
                amount = 0;
                _balanceShift(
                    c.currentComm,
                    c.currentBatch,
                    msg.sender,
                    receiver,
                    amount
                );
                totalBalance[receiver] += amount;

                if (checkBalanceArray(senderArrayBal, receiverArrayBal)) {
                    balance[receiver].push(senderArrayBal);
                }
            }

        }
        return true;
    }

    /**
     * @dev Transfer token from sender to receiver address.
     * @param receiver address.
     * @param amount requested to be transferred.
     * @return bool.
     */
    function transfer(address receiver, uint256 amount) public returns (bool) {
        // Sender has sufficient balance.
        require(totalBalance[msg.sender] >= amount);

        // Remove balance from sender total amount.
        totalBalance[msg.sender] -= amount;

        // Grab last array element from senders 'balance[sender address]'.
        uint256[2] memory senderArrayBal = getLastArrayIndex(msg.sender);

        // Grab last array element from reciver 'balance[sender address0]'.
        uint256[2] memory receiverArrayBal = getLastArrayIndex(receiver);

        Internal memory c;

        c.balanceLength = getBalanceLength(msg.sender);

        // Get community address.
        c.currentComm = getCommunityFromIndex[senderArrayBal[0]];

        // Get sendert batch number.
        c.currentBatch = senderArrayBal[1];

        // Sender current balance at specific communtiy address and batch number.
        c.currentBalance = specificBalance(
            c.currentComm,
            c.currentBatch,
            msg.sender
        );

        if (c.currentBalance > amount) {
            // Remove the balance from sender address and add it to receiver address.
            _balanceShift(
                c.currentComm,
                c.currentBatch,
                msg.sender,
                receiver,
                amount
            );

            totalBalance[receiver] += amount;

            // New array with community index and batch number is added to sender
            // 'balance[sender address]', only if the last array elements of sender and receiver is not same.
            // If sender last array index balance[sender address] is [1,3] and reciever 'balance[receiver address]' is [1,3,],
            // There is no point of adding new elements to receiver 'balance[address]'.
            if (checkBalanceArray(senderArrayBal, receiverArrayBal)) {
                balance[receiver].push(senderArrayBal);
                return true;
            }

            // If the sender last array element 'balance[array]' has balance equal to requested transfer
            // amount, it needs to be remove from sender 'balance[array]'.

        } else if (c.currentBalance == amount) {
            _balanceShift(
                c.currentComm,
                c.currentBatch,
                msg.sender,
                receiver,
                amount
            );

            totalBalance[receiver] += amount;

            // Remove the last array element of sender 'balance[sender]'.
            _reduceBalanceArray(msg.sender, 1);

            if (checkBalanceArray(senderArrayBal, receiverArrayBal)) {
                balance[receiver].push(senderArrayBal);
                return true;
            }

        } else if (c.currentBalance < amount) {
            loopAndTransfer(amount, receiver);
        }
    }
}
