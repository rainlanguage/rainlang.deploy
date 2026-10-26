// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {RainlangCompiler, DESCRIBED_BY_META_HASH} from "../../../src/concrete/RainlangCompiler.sol";

contract RainlangCompilerMetaTest is Test {
    /// The deployed concrete describes itself by the generated meta hash.
    function testRainlangCompilerExpectedConstructionMetaHash() external {
        RainlangCompiler compiler = new RainlangCompiler();
        assertEq(compiler.describedByMetaV1(), DESCRIBED_BY_META_HASH);
    }
}
