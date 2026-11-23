// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {RainDeployVerifyDeclaration} from "rain-deploy-0.1.38/src/abstract/RainDeployVerifyDeclaration.sol";
import {DeployDeclaration, DeploySuite} from "rain-deploy-0.1.38/src/abstract/RainDeploySuitesBase.sol";
import {LibRainDeploy} from "rain-deploy-0.1.38/src/lib/LibRainDeploy.sol";
import {UnreleasableVersion} from "rain-deploy-0.1.38/src/lib/LibRainDeploySnapshot.sol";
import {RainlangDeploySuites} from "../../../src/abstract/RainlangDeploySuites.sol";

contract RainlangDeployDeclarationTest is RainlangDeploySuites, RainDeployVerifyDeclaration {
    /// A wrapper so `notRequiredOnZerog` reverts at a depth `vm.expectRevert`
    /// reaches.
    /// @param suite The suite key.
    /// @return Whether `suite` is not required on `zerog`.
    function externalNotRequiredOnZerog(string memory suite) external pure returns (bool) {
        return notRequiredOnZerog(suite);
    }

    /// @param suite A suite key.
    /// @param tag A release tag.
    /// @return Whether `suite` is the release `tag` of its contract.
    function isRelease(string memory suite, string memory tag) internal pure returns (bool) {
        return keccak256(bytes(suite)) == keccak256(bytes(string.concat(suiteKeyName(suite), "@", tag)));
    }

    /// @param networks A roster.
    /// @param network A network name.
    /// @return Whether `networks` holds `network`.
    function holds(string[] memory networks, string memory network) internal pure returns (bool) {
        for (uint256 i = 0; i < networks.length; i++) {
            if (keccak256(bytes(networks[i])) == keccak256(bytes(network))) {
                return true;
            }
        }
        return false;
    }

    /// `zerog` requires the five contracts of the V1 `0_1_9` release and none
    /// of the V2 releases `0_1_10` to `0_1_15`, which keep the roster they
    /// were deployed for. The keys are named here, not selected with
    /// `notRequiredOnZerog`, so this checks the declaration and not the
    /// predicate.
    function testZerogRequiresTheRainlangV1ReleaseOnly() external pure {
        DeployDeclaration memory d = declaration();
        assertTrue(holds(d.networks, LibRainDeploy.ZEROG));
        assertGt(d.networks.length, networksBeforeZerog().length);
        uint256 v1 = 0;
        uint256 v2 = 0;
        for (uint256 i = 0; i < d.released.length; i++) {
            DeploySuite memory suite = d.released[i];
            if (
                isRelease(suite.suite, "0_1_10") || isRelease(suite.suite, "0_1_11") || isRelease(suite.suite, "0_1_12")
                    || isRelease(suite.suite, "0_1_13") || isRelease(suite.suite, "0_1_14")
                    || isRelease(suite.suite, "0_1_15")
            ) {
                v2++;
                assertEq(suite.networks, networksBeforeZerog(), suite.suite);
                assertFalse(requiresSuiteOn(suite, LibRainDeploy.ZEROG), suite.suite);
            } else {
                if (isRelease(suite.suite, "0_1_9")) {
                    v1++;
                }
                assertEq(suite.networks, d.networks, suite.suite);
                assertTrue(requiresSuiteOn(suite, LibRainDeploy.ZEROG), suite.suite);
            }
        }
        assertEq(v1, 5);
        assertEq(v2, 30);

        DeploySuite memory rainlangV1 = suiteByName(d, "rainlang@0_1_9");
        assertEq(rainlangV1.storedDeployedAddress, 0x820FB8ae43350f6F4F60117955751b0a6777aC54);
        assertTrue(requiresSuiteOn(rainlangV1, LibRainDeploy.ZEROG));
        assertTrue(requiresSuiteOn(suiteByName(d, "parser@0_1_9"), LibRainDeploy.ZEROG));
        assertTrue(requiresSuiteOn(suiteByName(d, "store@0_1_9"), LibRainDeploy.ZEROG));
        assertTrue(requiresSuiteOn(suiteByName(d, "interpreter@0_1_9"), LibRainDeploy.ZEROG));
        assertTrue(requiresSuiteOn(suiteByName(d, "compiler@0_1_9"), LibRainDeploy.ZEROG));
        assertFalse(requiresSuiteOn(suiteByName(d, "rainlang@0_1_10"), LibRainDeploy.ZEROG));
        assertFalse(requiresSuiteOn(suiteByName(d, "rainlang@0_1_15"), LibRainDeploy.ZEROG));
        assertFalse(requiresSuiteOn(suiteByName(d, "compiler@0_1_15"), LibRainDeploy.ZEROG));
    }

    /// `narrowReleasedNetworks` replaces the networks of the releases after
    /// `LAST_RAINLANG_V1_RELEASE` and up to `LAST_RELEASE_BEFORE_ZEROG` with
    /// `networksBeforeZerog()`, and leaves every other suite as it was,
    /// whatever the catalogue holds.
    function testNarrowReleasedNetworksReplacesOnlyTheReleasesBeforeZerog() external pure {
        string[] memory sentinel = new string[](1);
        sentinel[0] = "sentinel";
        string[7] memory keys = [
            "rainlang",
            "rainlang@0_1_9",
            "compiler@0_1_9",
            "rainlang@0_1_10",
            "interpreter@0_1_12",
            "parser@0_1_15",
            "rainlang@0_1_16"
        ];
        bool[7] memory narrowedKeys = [false, false, false, true, true, true, false];
        DeploySuite[] memory released = new DeploySuite[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            released[i].suite = keys[i];
            released[i].networks = sentinel;
        }
        DeploySuite[] memory narrowed = narrowReleasedNetworks(released);
        assertEq(narrowed.length, keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            assertEq(narrowed[i].suite, keys[i]);
            assertEq(narrowed[i].networks, narrowedKeys[i] ? networksBeforeZerog() : sentinel, keys[i]);
        }
    }

    /// The roster before `zerog` is the nine networks the pre-0G releases were
    /// deployed to, each still in the catalogue, and never `zerog`. It is
    /// pinned here rather than derived from the catalogue, which grows.
    function testNetworksBeforeZerogAreFrozenAndSupported() external pure {
        string[] memory before = networksBeforeZerog();
        string[9] memory frozen =
            ["arbitrum", "base", "base_sepolia", "bsc", "ethereum", "flare", "hyperevm", "polygon", "robinhood"];
        assertEq(before.length, frozen.length);
        string[] memory supported = LibRainDeploy.supportedNetworks();
        for (uint256 i = 0; i < before.length; i++) {
            assertEq(before[i], frozen[i]);
            assertTrue(holds(supported, before[i]), before[i]);
        }
        assertFalse(holds(before, LibRainDeploy.ZEROG));
    }

    /// `notRequiredOnZerog` selects the tags after `0_1_9` and up to `0_1_15`,
    /// comparing every component as a number.
    function testNotRequiredOnZerog() external pure {
        assertFalse(notRequiredOnZerog("rainlang"));
        assertFalse(notRequiredOnZerog("rainlang@0_1_9"));
        assertFalse(notRequiredOnZerog("compiler@0_1_8"));
        assertTrue(notRequiredOnZerog("rainlang@0_1_10"));
        assertTrue(notRequiredOnZerog("interpreter@0_1_12"));
        assertTrue(notRequiredOnZerog("parser@0_1_15"));
        assertFalse(notRequiredOnZerog("rainlang@0_1_16"));
        assertFalse(notRequiredOnZerog("rainlang@0_1_100"));
        assertFalse(notRequiredOnZerog("rainlang@0_2_0"));
        assertFalse(notRequiredOnZerog("rainlang@0_0_99"));
        assertFalse(notRequiredOnZerog("rainlang@1_1_10"));
        assertFalse(notRequiredOnZerog("rainlang@1_0_0"));
        assertFalse(notRequiredOnZerog("rainlang@0_11_0"));
        assertFalse(notRequiredOnZerog("rainlang@0_1_150"));
    }

    /// A key whose tag is not `X_Y_Z` digits is refused, not read as a version.
    function testNotRequiredOnZerogRefusesAMalformedTag() external {
        string[6] memory tags = ["0_1_1a", "0_1_10_1", "0_1_10@0_1_9", "0_1", "-0_1_10", ""];
        for (uint256 i = 0; i < tags.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(UnreleasableVersion.selector, tags[i]));
            this.externalNotRequiredOnZerog(string.concat("rainlang@", tags[i]));
        }
    }
}
