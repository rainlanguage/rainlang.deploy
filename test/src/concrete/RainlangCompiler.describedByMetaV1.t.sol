// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {RainlangCompiler} from "../../../src/concrete/RainlangCompiler.sol";
import {RainlangInterpreter} from "../../../src/concrete/RainlangInterpreter.sol";
import {RainlangStore} from "../../../src/concrete/RainlangStore.sol";
import {RainlangParser} from "../../../src/concrete/RainlangParser.sol";
string constant COMPILER_META_PATH = "meta/RainlangCompiler.rain.meta";

contract RainlangCompilerDescribedByMetaV1Test is Test {
    function testRainlangCompilerDescribedByMetaV1Happy() external {
        bytes memory describedByMeta = vm.readFileBinary(COMPILER_META_PATH);
        RainlangCompiler compiler = new RainlangCompiler();

        assertEq(keccak256(describedByMeta), compiler.describedByMetaV1());
    }
}
