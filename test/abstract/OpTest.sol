// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {OpTest as BaseOpTest} from "rainlang-0.2.30/test/abstract/OpTest.sol";
import {
    RainlangCompilerDeploymentTest as BaseRainlangCompilerDeploymentTest
} from "rainlang-0.2.30/test/abstract/RainlangCompilerDeploymentTest.sol";
import {BaseRainlangStore} from "rainlang-0.2.30/src/abstract/BaseRainlangStore.sol";
import {BaseRainlangParser} from "rainlang-0.2.30/src/abstract/BaseRainlangParser.sol";
import {BaseRainlangInterpreter} from "rainlang-0.2.30/src/abstract/BaseRainlangInterpreter.sol";
import {BaseRainlangCompiler} from "rainlang-0.2.30/src/abstract/BaseRainlangCompiler.sol";
import {RainlangCompilerDeploymentTest} from "./RainlangCompilerDeploymentTest.sol";

/// @title OpTest
/// @notice The `rainlang` package's `OpTest` bound to the deployed Rainlang
/// through `RainlangCompilerDeploymentTest`, for word and extern
/// repos that test against the live parser, store, interpreter and expression
/// compiler.
abstract contract OpTest is BaseOpTest, RainlangCompilerDeploymentTest {
    /// @inheritdoc RainlangCompilerDeploymentTest
    function deployRainlang()
        internal
        virtual
        override(BaseRainlangCompilerDeploymentTest, RainlangCompilerDeploymentTest)
        returns (BaseRainlangParser, BaseRainlangStore, BaseRainlangInterpreter, BaseRainlangCompiler)
    {
        return RainlangCompilerDeploymentTest.deployRainlang();
    }
}
