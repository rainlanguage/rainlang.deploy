// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";

import {RainlangCompiler} from "../../../src/concrete/RainlangCompiler.sol";
import {RainlangStore} from "../../../src/concrete/RainlangStore.sol";
import {RainlangParser} from "../../../src/concrete/RainlangParser.sol";
import {RainlangInterpreter} from "../../../src/concrete/RainlangInterpreter.sol";

/// @title RainlangCompilerDeployCheckTest
/// @notice Test that the RainlangCompiler deploy check reverts if the
/// passed config does not match expectations.
contract RainlangCompilerDeployCheckTest is Test {
    /// Test the compiler can deploy if everything is valid.
    function testRainlangCompilerDeployNoEIP1820() external {
        new RainlangCompiler();
    }
}
