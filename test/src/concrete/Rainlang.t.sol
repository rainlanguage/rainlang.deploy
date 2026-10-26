// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.17.0/src/Test.sol";
import {Rainlang} from "../../../src/concrete/Rainlang.sol";
import {LibInterpreterDeploy} from "../../../src/lib/deploy/LibInterpreterDeploy.sol";

contract RainlangTest is Test {
    function testCompilerAddress() external {
        Rainlang rainlang = new Rainlang();
        assertEq(rainlang.compiler(), LibInterpreterDeploy.COMPILER_DEPLOYED_ADDRESS);
        assertTrue(rainlang.compiler() != address(0));
    }

    function testInterpreterAddress() external {
        Rainlang rainlang = new Rainlang();
        assertEq(rainlang.interpreter(), LibInterpreterDeploy.INTERPRETER_DEPLOYED_ADDRESS);
        assertTrue(rainlang.interpreter() != address(0));
    }

    function testStoreAddress() external {
        Rainlang rainlang = new Rainlang();
        assertEq(rainlang.store(), LibInterpreterDeploy.STORE_DEPLOYED_ADDRESS);
        assertTrue(rainlang.store() != address(0));
    }

    function testParserAddress() external {
        Rainlang rainlang = new Rainlang();
        assertEq(rainlang.parser(), LibInterpreterDeploy.PARSER_DEPLOYED_ADDRESS);
        assertTrue(rainlang.parser() != address(0));
    }
}
