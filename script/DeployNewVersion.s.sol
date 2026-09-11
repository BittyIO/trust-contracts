// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.34;

import {Deploy} from "./Deploy.s.sol";
import {console2} from "forge-std/console2.sol";
import {BittyV1Vault} from "../src/BittyV1Vault.sol";
import {BITTY_GUARD} from "../src/logic/Constants.sol";
import {IBittyV1Guard, IMPLEMENTATION_VAULT} from "guard-contracts/src/interfaces/IBittyV1Guard.sol";

/**
 * @title DeployNewVersion
 * @notice Ship a NEW vault implementation for an UPGRADE (e.g. v1.0.1) — the version-bearing chain only
 *         (logic libraries → shared DeFi facet → sub-vault impl → main-vault impl). It does NOT touch the
 *         forwarder, keeper or factory (those don't change between vault versions).
 * @dev This script only DEPLOYS. It never registers the new implementation with the guard, because
 *      `setImplementation` is gated on IMPLEMENTATION_MANAGER_ROLE, which is held by a Safe multisig /
 *      governance `TimelockController` — not by a deploy key. Auto-registering from a command-line
 *      broadcast would either fail (the key lacks the role) or, worse, imply the role sits on a hot EOA.
 *      So instead the script PRINTS the exact registration transaction (target + calldata) for the role
 *      holder to submit through the Safe / governance flow.
 *
 *      Nothing is redeployed unless its bytecode actually changed: every piece is deterministic CREATE2,
 *      its address is a hash of its init code, so an unchanged contract is already at its address and is
 *      skipped; only what changed gets deployed (see {Deploy-deployImplementationChain}).
 *
 *      Run:  forge script script/DeployNewVersion.s.sol:DeployNewVersion --broadcast -vvvv
 */
contract DeployNewVersion is Deploy {
    function deploy() public override {
        address vaultImpl = deployImplementationChain();

        console2.log("----------------------------------------");
        console2.log("new vault implementation      ", vaultImpl);
        console2.log("version                       ", BittyV1Vault(payable(vaultImpl)).versionName());

        _printGuardRegistration(vaultImpl);

        console2.log("----------------------------------------");
        console2.log("after the guard registers it: each vault owner calls upgrade(newImpl),");
        console2.log("then update the web config's implementation address.");
    }

    /**
     * @dev The registration step is NOT executed here — it is the role holder's (Safe / governance)
     *      transaction. A `view` check reports whether it is already blessed; otherwise the exact
     *      transaction to submit is printed: `to` = guard, `data` = setImplementation(impl, VAULT).
     *      Paste that target + calldata into the Safe transaction builder or a governance proposal.
     */
    function _printGuardRegistration(address vaultImpl) private view {
        IBittyV1Guard guard = IBittyV1Guard(BITTY_GUARD);
        if (guard.isImplementationRegisteredFor(vaultImpl, IMPLEMENTATION_VAULT)) {
            console2.log("guard: already registered (nothing to submit)");
            return;
        }
        console2.log("GUARD REGISTRATION - submit from the IMPLEMENTATION_MANAGER_ROLE holder");
        console2.log("(a Safe multisig or governance timelock, NOT this deploy key):");
        console2.log("  to (guard) ", BITTY_GUARD);
        console2.log("  function   setImplementation(address,uint8)");
        console2.log("  args       ", vaultImpl, uint256(IMPLEMENTATION_VAULT));
        console2.log("  calldata:");
        console2.logBytes(abi.encodeCall(IBittyV1Guard.setImplementation, (vaultImpl, IMPLEMENTATION_VAULT)));
    }
}
