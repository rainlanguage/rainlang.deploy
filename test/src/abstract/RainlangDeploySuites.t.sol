// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {DeployCandidate, DeployDependency} from "../../../src/abstract/RainDeploySuitesBase.sol";
import {RainlangDeploySuites} from "../../../src/abstract/RainlangDeploySuites.sol";
import {LibTOFUTokenDecimals} from "rain-tofu-erc20-decimals-0.1.4/src/lib/LibTOFUTokenDecimals.sol";
import {LibDecimalFloatDeploy} from "rain-math-float-deploy-0.1.5/src/lib/deploy/LibDecimalFloatDeploy.sol";
import {RainlangParser} from "../../../src/concrete/RainlangParser.sol";
import {RainlangStore} from "../../../src/concrete/RainlangStore.sol";
import {RainlangInterpreter} from "../../../src/concrete/RainlangInterpreter.sol";
import {RainlangExpressionDeployer} from "../../../src/concrete/RainlangExpressionDeployer.sol";
import {Rainlang} from "../../../src/concrete/Rainlang.sol";

/// @title RainlangDeploySuitesTest
/// @notice The properties of this repo's ONE deploy declaration that
/// `rain-deploy` does not ship an assertion for.
///
/// `RainDeployVerifySnapshot` checks a candidate against its snapshot and
/// against source. It never checks the fields that only mean something outside
/// Solidity: the suite key, which is what `Manual sol artifacts` dispatches and
/// what a frozen release is keyed by forever, the artifact path, which is what
/// a verifier resolves to re-derive the creation code, and the dependency
/// list, which is what `LibRainDeploy.deployToNetworks` refuses to broadcast
/// without. A typo in any of the three compiles, snapshots and passes every
/// shipped assertion.
///
/// Inherits the declaration directly rather than through a harness: everything
/// read here is `internal pure` on the abstract, and unlike `script/Build.sol`
/// there is no second entry point that widening would expose.
contract RainlangDeploySuitesTest is Test, RainlangDeploySuites {
    uint256 constant EIP170_MAX_RUNTIME_CODE_SIZE = 0x6000;

    /// The `Manual sol artifacts` dispatch choices, transcribed from
    /// `.github/workflows/manual-sol-artifacts.yaml`. A second hard-coded list
    /// on purpose: the workflow is YAML that no Solidity test can read (the
    /// `.github` tree is outside `fs_permissions`, deliberately), so the only
    /// way a key that cannot be dispatched can be caught here is by writing the
    /// dispatchable set down and comparing.
    /// @return The dispatch choices, in the order the workflow lists them.
    function dispatchChoices() internal pure returns (string[] memory) {
        string[] memory choices = new string[](5);
        choices[0] = "parser";
        choices[1] = "store";
        choices[2] = "interpreter";
        choices[3] = "expression-deployer";
        choices[4] = "rainlang";
        return choices;
    }

    /// PROPERTY: the declared candidate keys and the workflow's dispatch
    /// choices are the same SET.
    ///
    /// A declared key with no choice is a suite nothing can deploy; a choice
    /// with no declared key is a dispatch that reaches
    /// `UnknownDeploymentSuite` after the job has already started and read the
    /// deploy key. Matched both ways because either half alone goes green on
    /// the other's omission.
    function testCandidateKeysAreExactlyTheDispatchChoices() external pure {
        DeployCandidate[] memory candidates = checkedCandidateSuites();
        string[] memory choices = dispatchChoices();

        assertEq(candidates.length, choices.length, "a candidate is not dispatchable, or a choice is not declared");

        for (uint256 i = 0; i < candidates.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < choices.length; j++) {
                if (keccak256(bytes(candidates[i].snapshot.suite)) == keccak256(bytes(choices[j]))) {
                    found = true;
                    break;
                }
            }
            assertTrue(
                found, string.concat("declared candidate is not a dispatch choice: ", candidates[i].snapshot.suite)
            );
        }

        for (uint256 j = 0; j < choices.length; j++) {
            bool found = false;
            for (uint256 i = 0; i < candidates.length; i++) {
                if (keccak256(bytes(candidates[i].snapshot.suite)) == keccak256(bytes(choices[j]))) {
                    found = true;
                    break;
                }
            }
            assertTrue(found, string.concat("dispatch choice is not a declared candidate: ", choices[j]));
        }
    }

    /// PROPERTY: every candidate's `artifactPath` resolves to the contract its
    /// suite key names, per `sourceCreationCode`.
    ///
    /// The path is declared text, never derived from the type, so it can name
    /// another contract or a contract that no longer exists and everything
    /// shipped still passes: nothing in `rain-deploy` dereferences it. It is
    /// what an explorer verification and a manual re-derivation resolve, so a
    /// wrong one is only found by hand, after the deployment.
    function testArtifactPathsResolveToTheCandidateSource() external view {
        DeployCandidate[] memory candidates = checkedCandidateSuites();
        for (uint256 i = 0; i < candidates.length; i++) {
            assertEq(
                keccak256(vm.getCode(candidates[i].snapshot.artifactPath)),
                keccak256(sourceCreationCode(candidates[i].snapshot.suite)),
                string.concat("artifact path is not this candidate's source: ", candidates[i].snapshot.suite)
            );
        }
    }

    /// PROPERTY: no dependency is the zero address, and no dependency list
    /// repeats one.
    ///
    /// `LibRainDeploy.deployToNetworks` refuses to broadcast on any network
    /// where a dependency has no code, and the zero address never has code on
    /// any of them — so a zero that reached the list would block that suite on
    /// every chain, and only at deploy time. A repeat is a second address
    /// meant to be there that is not.
    function testDependenciesAreNonZeroAndUnique() external pure {
        DeployCandidate[] memory candidates = checkedCandidateSuites();
        for (uint256 i = 0; i < candidates.length; i++) {
            DeployDependency[] memory deps = candidates[i].snapshot.dependencies;
            for (uint256 j = 0; j < deps.length; j++) {
                assertNotEq(
                    deps[j].deployedAddress,
                    address(0),
                    string.concat("zero dependency: ", candidates[i].snapshot.suite)
                );
                for (uint256 k = j + 1; k < deps.length; k++) {
                    assertNotEq(
                        deps[j].deployedAddress,
                        deps[k].deployedAddress,
                        string.concat("repeated dependency: ", candidates[i].snapshot.suite)
                    );
                }
            }
        }
    }

    /// PROPERTY: a candidate that reaches another candidate at its
    /// deterministic address declares it as a dependency.
    ///
    /// Every candidate's own deploy address is known here, so "does any other
    /// candidate's address appear in this one's creation code" is decidable
    /// without leaving the declaration. It is exactly the condition that makes
    /// the other one a precondition of this one's broadcast, and the list is
    /// hand-written per candidate — the expression deployer and `Rainlang`
    /// each name three or four siblings by hand, and a sibling added to a
    /// constructor but not to the list is a deployment that lands on a chain
    /// where the thing it calls is not there yet.
    function testCandidatesDependOnTheSiblingsTheyReach() external pure {
        DeployCandidate[] memory candidates = checkedCandidateSuites();
        for (uint256 i = 0; i < candidates.length; i++) {
            for (uint256 j = 0; j < candidates.length; j++) {
                if (i == j) {
                    continue;
                }
                if (!containsAddress(
                        sourceCreationCode(candidates[i].snapshot.suite), candidates[j].snapshot.storedDeployedAddress
                    )) {
                    continue;
                }
                assertTrue(
                    containsDependency(
                        candidates[i].snapshot.dependencies, candidates[j].snapshot.storedDeployedAddress
                    ),
                    string.concat(
                        candidates[i].snapshot.suite, " reaches an undeclared sibling: ", candidates[j].snapshot.suite
                    )
                );
            }
        }
    }

    /// PROPERTY: every declared dependency is an address the candidate's own
    /// bytecode actually bakes in.
    ///
    /// The converse of the property above, and the half a copied list fails.
    /// `LibRainDeploy.deployToNetworks` refuses to broadcast on any network
    /// where a declared dependency has no code, so a dependency the bytecode
    /// never carries is a chain this suite is blocked from for no reason. It is
    /// also worse than inert: `script/Build.sol` writes the list into the
    /// snapshot, a release freezes that snapshot into the append-only record,
    /// and the entry then states forever that the release required something it
    /// never touched.
    ///
    /// Sound here because every dependency is a compile-time constant and the
    /// Zoltu factory deploys with empty constructor args, so baking the address
    /// in is the only way a candidate can reach one. A future candidate handed
    /// a dependency it does not embed — a constructor argument, an address read
    /// from storage — is the case that fails this, and this is where the
    /// exemption gets written down rather than the lists quietly growing again.
    function testCandidatesReachEveryDependencyTheyDeclare() external pure {
        DeployCandidate[] memory candidates = checkedCandidateSuites();
        for (uint256 i = 0; i < candidates.length; i++) {
            DeployDependency[] memory deps = candidates[i].snapshot.dependencies;
            for (uint256 j = 0; j < deps.length; j++) {
                assertTrue(
                    containsAddress(sourceCreationCode(candidates[i].snapshot.suite), deps[j].deployedAddress),
                    string.concat(
                        candidates[i].snapshot.suite,
                        " declares a dependency it never reaches: ",
                        vm.toString(deps[j].deployedAddress)
                    )
                );
            }
        }
    }

    /// The deterministic deployments OUTSIDE this repo that a candidate here
    /// can reach. A second hard-coded list, for the same reason
    /// `dispatchChoices` is one: the reach property below has to compare the
    /// declaration against something the declaration did not supply, or it
    /// compares a list to itself.
    ///
    /// The address is imported from the package that deploys it and never
    /// transcribed, so a package that moves its deployment moves this with it.
    /// What is hand-maintained is the SET — a second external
    /// deployment reaching a candidate is a line that has to be added here as
    /// well as to that candidate's dependencies.
    /// @return The external deployment addresses.
    function externalDeployments() internal pure returns (address[] memory) {
        address[] memory externals = new address[](2);
        externals[0] = address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT);
        externals[1] = LibDecimalFloatDeploy.ZOLTU_DEPLOYED_DECIMAL_FLOAT_ADDRESS;
        return externals;
    }

    /// PROPERTY: a candidate that reaches an external deterministic deployment
    /// declares it as a dependency.
    ///
    /// `testCandidatesDependOnTheSiblingsTheyReach` is this same property over
    /// the siblings, and the externals are not siblings, so nothing there covers
    /// them. They are what a trimmed list gets wrong in the dangerous direction:
    /// with only the converse property standing over them, dropping TOFU from
    /// the interpreter would go green, the broadcast gate would stop asking for
    /// it, and the ERC20 opcodes would revert on the first chain that does not
    /// carry it.
    function testCandidatesDependOnTheExternalsTheyReach() external pure {
        DeployCandidate[] memory candidates = checkedCandidateSuites();
        address[] memory externals = externalDeployments();
        for (uint256 i = 0; i < candidates.length; i++) {
            for (uint256 j = 0; j < externals.length; j++) {
                if (!containsAddress(sourceCreationCode(candidates[i].snapshot.suite), externals[j])) {
                    continue;
                }
                assertTrue(
                    containsDependency(candidates[i].snapshot.dependencies, externals[j]),
                    string.concat(
                        candidates[i].snapshot.suite,
                        " reaches an undeclared external deployment: ",
                        vm.toString(externals[j])
                    )
                );
            }
        }
    }

    /// PROPERTY: every declared dependency's `runtimeCode` is the code that is
    /// deployed at its address — a sibling's recorded runtime code, or the code
    /// hash the TOFU or DecimalFloat package pins for its singleton.
    function testDependencyRuntimeCodeMatchesItsAddress() external pure {
        DeployCandidate[] memory candidates = checkedCandidateSuites();
        for (uint256 i = 0; i < candidates.length; i++) {
            DeployDependency[] memory deps = candidates[i].snapshot.dependencies;
            for (uint256 j = 0; j < deps.length; j++) {
                bytes32 expected = bytes32(0);
                if (deps[j].deployedAddress == address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT)) {
                    expected = LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH;
                }
                if (deps[j].deployedAddress == LibDecimalFloatDeploy.ZOLTU_DEPLOYED_DECIMAL_FLOAT_ADDRESS) {
                    expected = LibDecimalFloatDeploy.DECIMAL_FLOAT_CONTRACT_HASH;
                }
                for (uint256 k = 0; k < candidates.length; k++) {
                    if (deps[j].deployedAddress == candidates[k].snapshot.storedDeployedAddress) {
                        expected = keccak256(candidates[k].snapshot.storedRuntimeCode);
                    }
                }
                assertNotEq(expected, bytes32(0), string.concat("unknown dependency: ", candidates[i].snapshot.suite));
                assertEq(
                    keccak256(deps[j].runtimeCode),
                    expected,
                    string.concat("dependency runtime code mismatch: ", candidates[i].snapshot.suite)
                );
            }
        }
    }

    /// PROPERTY: every candidate's runtime code fits EIP-170.
    function testCandidateRuntimeCodeFitsEip170() external pure {
        DeployCandidate[] memory candidates = checkedCandidateSuites();
        for (uint256 i = 0; i < candidates.length; i++) {
            assertLe(
                candidates[i].snapshot.storedRuntimeCode.length,
                EIP170_MAX_RUNTIME_CODE_SIZE,
                string.concat("runtime code over EIP-170: ", candidates[i].snapshot.suite)
            );
        }
    }

    /// The creation code of the contract a suite key names, from the type
    /// rather than from anything the declaration carries.
    /// @param suite The suite key.
    /// @return The creation code.
    function sourceCreationCode(string memory suite) internal pure returns (bytes memory) {
        bytes32 key = keccak256(bytes(suite));
        if (key == keccak256("parser")) return type(RainlangParser).creationCode;
        if (key == keccak256("store")) return type(RainlangStore).creationCode;
        if (key == keccak256("interpreter")) return type(RainlangInterpreter).creationCode;
        if (key == keccak256("expression-deployer")) return type(RainlangExpressionDeployer).creationCode;
        if (key == keccak256("rainlang")) return type(Rainlang).creationCode;
        revert(string.concat("no source for suite: ", suite));
    }

    /// Whether `needle` appears in `deps`.
    /// @param deps The dependency list to search.
    /// @param needle The address to look for.
    /// @return Whether it is there.
    function containsDependency(DeployDependency[] memory deps, address needle) internal pure returns (bool) {
        for (uint256 i = 0; i < deps.length; i++) {
            if (deps[i].deployedAddress == needle) {
                return true;
            }
        }
        return false;
    }

    /// Whether `needle` appears in `haystack` in the form solc emits it.
    ///
    /// A constant address reaches bytecode as the immediate of the NARROWEST
    /// `PUSH` that zero-extends to it, so an address with leading zero bytes —
    /// `RainlangParser` has one — is never there at its full 20-byte width, and
    /// a 20-byte scan silently finds nothing for it. That is the whole failure
    /// mode this helper has to avoid: a scan that finds nothing makes the
    /// property above vacuous while it still reports green. So the search is
    /// for the leading-zero-stripped bytes, at whatever width that is.
    ///
    /// Word-compared rather than byte-compared because the creation codes run
    /// to tens of kilobytes and the caller is quadratic in the candidate count.
    /// The `mload` at `i` reads 32 bytes where only `width` are in bounds, and
    /// the mask drops the rest before the comparison; the loop bound is what
    /// keeps those `width` inside the array.
    /// @param haystack The creation code to scan.
    /// @param needle The address to look for.
    /// @return Whether it is there.
    function containsAddress(bytes memory haystack, address needle) internal pure returns (bool) {
        uint256 value = uint256(uint160(needle));
        uint256 width = 0;
        {
            uint256 remaining = value;
            while (remaining != 0) {
                remaining >>= 8;
                width++;
            }
        }
        // The zero address has no immediate at all — solc emits it as a
        // `PUSH0`/`0x00`, which is not a byte pattern to search for. Nothing
        // reaches here with one; `testDependenciesAreNonZeroAndUnique` is what
        // says so.
        if (width == 0 || haystack.length < width) {
            return false;
        }
        uint256 shift = 256 - width * 8;
        bytes32 target = bytes32(value << shift);
        bytes32 mask = bytes32(~uint256(0) << shift);
        uint256 last = haystack.length - width;
        for (uint256 i = 0; i <= last; i++) {
            bytes32 window;
            assembly ("memory-safe") {
                window := mload(add(add(haystack, 0x20), i))
            }
            if (window & mask == target) {
                return true;
            }
        }
        return false;
    }
}
