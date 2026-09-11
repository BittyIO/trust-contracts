// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.34;

// Compiled ONLY to produce the Gnosis Safe v1.4.1 artifacts (Safe, SafeProxyFactory,
// CompatibilityFallbackHandler). SafeOwner.t.sol deploys them by name via vm.deployCode instead of
// importing their source, so Safe's pre-memory-safe assembly never lands in the vault's via_ir
// compilation. This file and the Safe contracts are exempted to the legacy pipeline (via_ir = false)
// by the compilation_restrictions in foundry.toml; everything else in the safe profile keeps via_ir.
import {Safe} from "safe-contracts/Safe.sol";
import {SafeProxyFactory} from "safe-contracts/proxies/SafeProxyFactory.sol";
import {CompatibilityFallbackHandler} from "safe-contracts/handler/CompatibilityFallbackHandler.sol";
