// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.34;

import {BittyV1AccountBase} from "../BittyV1AccountBase.sol";
import {BittyStorage} from "../logic/BittyStorage.sol";
import {NotParentVault, OwnershipNotRenounceable} from "../interfaces/IBittyV1SubVault.sol";

/**
 * @title BittyV1SubVaultBase
 * @notice The sub vault's base: 1-step ownership (the parent is the backstop, so a bad sub owner is
 *         recoverable) and UUPS upgrades driven by the PARENT, not the sub owner — to a guard-blessed
 *         implementation, immediately (the guard holds the timelock). A sub owner can never upgrade its
 *         own code, which would let it add an exfiltration path and break the payout monopoly.
 */
abstract contract BittyV1SubVaultBase is BittyV1AccountBase {
    modifier onlyParent() {
        if (msg.sender != BittyStorage.subVault().vault) revert NotParentVault();
        _;
    }

    /**
     * @dev Renouncing would drop the sub owner to address(0) — freezing the sub's DeFi and, once the
     *      parent is renounced too, cutting off `returnToVault` so the funds can never get home.
     *      Ownership rotates only through the parent's setSubOwner / the owner's own transferOwnership,
     *      neither of which can reach the zero address.
     */
    function renounceOwnership() public pure override {
        revert OwnershipNotRenounceable();
    }
}
