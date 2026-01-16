// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AssetToken} from "./AssetToken.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title AssetTokenV2
 * @dev V2 implementation of AssetToken with pause functionality
 * @notice This version adds the ability to pause token transfers
 */
contract AssetTokenV2 is AssetToken, PausableUpgradeable {
    /**
     * @dev Initializes V2 with pause functionality
     * @notice This function should be called after upgrading to V2
     */
    function initializeV2() public reinitializer(2) {
        __Pausable_init();
    }

    /**
     * @dev Pauses all token transfers
     * @notice Only addresses with DEFAULT_ADMIN_ROLE can pause
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
        emit AdminAction("Contract paused", msg.sender);
    }

    /**
     * @dev Unpauses token transfers
     * @notice Only addresses with DEFAULT_ADMIN_ROLE can unpause
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
        emit AdminAction("Contract unpaused", msg.sender);
    }

    /**
     * @dev Hook that is called before any transfer of tokens
     * @param from Address tokens are transferred from
     * @param to Address tokens are transferred to
     * @param amount Amount of tokens to transfer
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused {
        super._update(from, to, amount);
    }
}

