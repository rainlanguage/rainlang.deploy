// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {
    RainlangCompilerDeploymentTest as BaseRainlangCompilerDeploymentTest
} from "rainlang-0.2.23/test/abstract/RainlangCompilerDeploymentTest.sol";
import {BaseRainlangStore} from "rainlang-0.2.23/src/abstract/BaseRainlangStore.sol";
import {BaseRainlangParser} from "rainlang-0.2.23/src/abstract/BaseRainlangParser.sol";
import {BaseRainlangInterpreter} from "rainlang-0.2.23/src/abstract/BaseRainlangInterpreter.sol";
import {BaseRainlangCompiler} from "rainlang-0.2.23/src/abstract/BaseRainlangCompiler.sol";
import {LibInterpreterDeploy} from "../../src/lib/deploy/LibInterpreterDeploy.sol";

/// @title RainlangCompilerDeploymentTest
/// @notice The `rainlang` package's deployment test bound to the deployed
/// Rainlang: the candidate records under `src/generated/` are etched at their
/// Zoltu addresses instead of the package's source-built test concretes.
abstract contract RainlangCompilerDeploymentTest is BaseRainlangCompilerDeploymentTest {
    /// @inheritdoc BaseRainlangCompilerDeploymentTest
    function deployRainlang()
        internal
        virtual
        override
        returns (BaseRainlangParser, BaseRainlangStore, BaseRainlangInterpreter, BaseRainlangCompiler)
    {
        LibInterpreterDeploy.etchRainlang(vm);
        return (
            BaseRainlangParser(LibInterpreterDeploy.PARSER_DEPLOYED_ADDRESS),
            BaseRainlangStore(LibInterpreterDeploy.STORE_DEPLOYED_ADDRESS),
            BaseRainlangInterpreter(LibInterpreterDeploy.INTERPRETER_DEPLOYED_ADDRESS),
            BaseRainlangCompiler(LibInterpreterDeploy.COMPILER_DEPLOYED_ADDRESS)
        );
    }
}
