// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {
    RainlangExpressionDeployerDeploymentTest as BaseRainlangExpressionDeployerDeploymentTest
} from "rainlang-0.2.1/test/abstract/RainlangExpressionDeployerDeploymentTest.sol";
import {BaseRainlangStore} from "rainlang-0.2.1/src/abstract/BaseRainlangStore.sol";
import {BaseRainlangParser} from "rainlang-0.2.1/src/abstract/BaseRainlangParser.sol";
import {BaseRainlangInterpreter} from "rainlang-0.2.1/src/abstract/BaseRainlangInterpreter.sol";
import {BaseRainlangExpressionDeployer} from "rainlang-0.2.1/src/abstract/BaseRainlangExpressionDeployer.sol";
import {LibInterpreterDeploy} from "../../src/lib/deploy/LibInterpreterDeploy.sol";

/// @title RainlangExpressionDeployerDeploymentTest
/// @notice The `rainlang` package's deployment test bound to the deployed
/// Rainlang: the candidate records under `src/generated/` are etched at their
/// Zoltu addresses instead of the package's source-built test concretes.
abstract contract RainlangExpressionDeployerDeploymentTest is BaseRainlangExpressionDeployerDeploymentTest {
    /// @inheritdoc BaseRainlangExpressionDeployerDeploymentTest
    function deployRainlang()
        internal
        virtual
        override
        returns (BaseRainlangParser, BaseRainlangStore, BaseRainlangInterpreter, BaseRainlangExpressionDeployer)
    {
        LibInterpreterDeploy.etchRainlang(vm);
        return (
            BaseRainlangParser(LibInterpreterDeploy.PARSER_DEPLOYED_ADDRESS),
            BaseRainlangStore(LibInterpreterDeploy.STORE_DEPLOYED_ADDRESS),
            BaseRainlangInterpreter(LibInterpreterDeploy.INTERPRETER_DEPLOYED_ADDRESS),
            BaseRainlangExpressionDeployer(LibInterpreterDeploy.EXPRESSION_DEPLOYER_DEPLOYED_ADDRESS)
        );
    }
}
