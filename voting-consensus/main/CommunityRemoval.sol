pragma solidity ^0.5.0;

import './Community.sol';
import './ERC20.sol';

contract CommunityRemoval is Community, ERC20 {
    /**
     * @dev Owner directly remove `oldCommunity`.
     * If `oldCommunity` has balance, burned it.
     * Requirements:
     * - Must be owner
     * - Community shoud already be registered.
     */
    function directlyRemoveCommunity(address oldCommunity) external onlyOwner {
        if(balanceOf(oldCommunity) > 0) {
            _burn(oldCommunity, balanceOf(oldCommunity));
        }
        
        _removeCommunity(oldCommunity);
        assert(
            _registered[oldCommunity] == false &&
                _isTrusted[oldCommunity] == false
        );
    }

    /**
     * @dev Removes already Registered `oldCommunity`.
     * If `oldCommunity` has balance, burned it.
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
        _registered[oldCommunity] = false;
        _totalCommunity -= 1;
        
         if(balanceOf(oldCommunity) > 0) {
            _burn(oldCommunity, balanceOf(oldCommunity));
        }
        
        if (_isTrusted[oldCommunity]) {
            _isTrusted[oldCommunity] = false;
            _trustedCommunity -= 1;
        }
        emit CommunityRemovedEvent(oldCommunity);
    }
}