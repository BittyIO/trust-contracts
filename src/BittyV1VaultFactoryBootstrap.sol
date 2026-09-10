// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.34;

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IBittyV1Guard} from "guard-contracts/src/interfaces/IBittyV1Guard.sol";
import {BITTY_GUARD, CFG_OWNER} from "./logic/Constants.sol";

error NotOwner();

/**
 * @title BittyV1VaultFactoryBootstrap
 * @notice The implementation the factory proxy is BORN with, and leaves in the same transaction.
 *
 *         The factory is the CREATE2 deployer of every vault, so its address is baked into every vault
 *         address. If the factory were a plain contract, changing its logic would move the factory —
 *         and relocate every owner's vault. Being born on a CONSTANT bootstrap takes the factory's build
 *         out of its own address: the factory proxy sits at one address forever, and new factory logic
 *         is an upgrade rather than a new deployment, so vault addresses survive every future version.
 *
 *         The same reasoning as BittyV1VaultBootstrap and BittyV1ForwarderBootstrap.
 */
contract BittyV1VaultFactoryBootstrap is UUPSUpgradeable {
    /**
     * @dev Gated on the guard's configured owner: the proxy address is reproducible on every chain, so
     *      anyone could otherwise race the deploy on a chain Bitty has not reached yet and hand the
     *      factory an implementation of their own. Only the Bitty owner may perform the first upgrade;
     *      the factory's own owner (the same guard value) takes over the moment this contract stops being
     *      the implementation. An unconfigured guard (owner 0) fails closed — no upgrade at all.
     */
    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != IBittyV1Guard(BITTY_GUARD).getAddress(CFG_OWNER)) revert NotOwner();
    }
}
