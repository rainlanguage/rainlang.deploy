// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {RainlangCompiler, INTEGRITY_FUNCTION_POINTERS} from "../../../src/concrete/RainlangCompiler.sol";

contract RainlangCompilerPointersTest is Test {
    function testIntegrityFunctionPointers() external {
        RainlangCompiler compiler = new RainlangCompiler();
        bytes memory expected = compiler.buildIntegrityFunctionPointers();
        bytes memory actual = INTEGRITY_FUNCTION_POINTERS;
        assertEq(actual, expected);
    }
}
