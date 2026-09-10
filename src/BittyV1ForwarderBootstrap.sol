// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.34;

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IBittyV1Guard} from "guard-contracts/src/interfaces/IBittyV1Guard.sol";
import {BITTY_GUARD, CFG_OWNER} from "./logic/Constants.sol";

error NotOwner();

/**
 * @title BittyV1ForwarderBootstrap
 * @notice The implementation the forwarder proxy is BORN with, and leaves in the same transaction.
 *
 *         The forwarder is a compile-time constant in every vault, so its address moving costs a new
 *         vault implementation, a new factory, and a fresh vanity mine for both - which is exactly what
 *         happened when the forwarder gained two-step ownership after its first deployment. A proxy's
 *         init code embeds its implementation, so pointing one straight at the build would carry that
 *         cost forward to every future change.
 *
 *         Being born on a CONSTANT implementation takes the build out of the hash. The forwarder's
 *         address is then the same on every chain at every version, and a later change to the relay
 *         logic is an upgrade rather than a migration of the whole vault stack. It also keeps EIP-712
 *         signatures valid: the domain binds to the verifying contract, so a moving address would
 *         invalidate every signature ever made for this forwarder.
 *
 *         The same reasoning as BittyV1VaultBootstrap and BittyV1GuardBootstrap.
 */
contract BittyV1ForwarderBootstrap is UUPSUpgradeable {
    /**
     * @dev Gated on the guard's configured owner: the proxy address is reproducible on every chain, so
     *      anyone could otherwise race the deploy on a chain Bitty has not reached yet and hand the
     *      forwarder an implementation of their own. Only the Bitty owner may perform the first upgrade;
     *      the forwarder's own owner (the same guard value) takes over the moment this contract stops
     *      being the implementation. An unconfigured guard (owner 0) fails closed — no upgrade at all.
     */
    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != IBittyV1Guard(BITTY_GUARD).getAddress(CFG_OWNER)) revert NotOwner();
    }
}
