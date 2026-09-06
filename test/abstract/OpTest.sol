// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {OpTest as BaseOpTest} from "rainlang-0.2.0/test/abstract/OpTest.sol";
import {
    RainlangExpressionDeployerDeploymentTest as BaseRainlangExpressionDeployerDeploymentTest
} from "rainlang-0.2.0/test/abstract/RainlangExpressionDeployerDeploymentTest.sol";
import {BaseRainlangStore} from "rainlang-0.2.0/src/abstract/BaseRainlangStore.sol";
import {BaseRainlangParser} from "rainlang-0.2.0/src/abstract/BaseRainlangParser.sol";
import {BaseRainlangInterpreter} from "rainlang-0.2.0/src/abstract/BaseRainlangInterpreter.sol";
import {BaseRainlangExpressionDeployer} from "rainlang-0.2.0/src/abstract/BaseRainlangExpressionDeployer.sol";
import {RainlangExpressionDeployerDeploymentTest} from "./RainlangExpressionDeployerDeploymentTest.sol";

/// @title OpTest
/// @notice The `rainlang` package's `OpTest` bound to the deployed Rainlang
/// through `RainlangExpressionDeployerDeploymentTest`, for word and extern
/// repos that test against the live parser, store, interpreter and expression
/// deployer.
abstract contract OpTest is BaseOpTest, RainlangExpressionDeployerDeploymentTest {
    /// @inheritdoc RainlangExpressionDeployerDeploymentTest
    function deployRainlang()
        internal
        virtual
        override(BaseRainlangExpressionDeployerDeploymentTest, RainlangExpressionDeployerDeploymentTest)
        returns (BaseRainlangParser, BaseRainlangStore, BaseRainlangInterpreter, BaseRainlangExpressionDeployer)
    {
        return RainlangExpressionDeployerDeploymentTest.deployRainlang();
    }
}
