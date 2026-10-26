// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {RainDeployVerifyDeclaration} from "rain-deploy-0.1.25/src/abstract/RainDeployVerifyDeclaration.sol";
import {ExternalDeployment} from "rain-deploy-0.1.25/src/abstract/RainDeployDeclarationChecks.sol";
import {RainlangDeploySuites} from "../../../src/abstract/RainlangDeploySuites.sol";
import {LibTOFUTokenDecimals} from "rain-tofu-erc20-decimals-0.1.4/src/lib/LibTOFUTokenDecimals.sol";
import {LibDecimalFloatDeploy} from "rain-math-float-deploy-0.1.7/src/lib/deploy/LibDecimalFloatDeploy.sol";
import {
    DEPLOYED_ADDRESS as LOG_TABLES_DEPLOYED_ADDRESS,
    BYTECODE_HASH as LOG_TABLES_BYTECODE_HASH
} from "rain-math-float-deploy-0.1.7/src/generated/0_1_3/LogTables.sol";
import {RainlangParser} from "../../../src/concrete/RainlangParser.sol";
import {RainlangStore} from "../../../src/concrete/RainlangStore.sol";
import {RainlangInterpreter} from "../../../src/concrete/RainlangInterpreter.sol";
import {RainlangExpressionDeployer} from "../../../src/concrete/RainlangExpressionDeployer.sol";
import {Rainlang} from "../../../src/concrete/Rainlang.sol";

contract RainlangDeployDeclarationTest is RainlangDeploySuites, RainDeployVerifyDeclaration {
    function sourceCreationCode(string memory suite) internal pure override returns (bytes memory) {
        bytes32 key = keccak256(bytes(suite));
        if (key == keccak256("parser")) return type(RainlangParser).creationCode;
        if (key == keccak256("store")) return type(RainlangStore).creationCode;
        if (key == keccak256("interpreter")) return type(RainlangInterpreter).creationCode;
        if (key == keccak256("expression-deployer")) return type(RainlangExpressionDeployer).creationCode;
        if (key == keccak256("rainlang")) return type(Rainlang).creationCode;
        revert(string.concat("no source for suite: ", suite));
    }

    // The 0_1_9 interpreter reaches LogTables; the candidate does not.
    function externalDeployments() internal pure override returns (ExternalDeployment[] memory) {
        ExternalDeployment[] memory externals = new ExternalDeployment[](3);
        externals[0] = ExternalDeployment({
            deployedAddress: address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT),
            codeHash: LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH
        });
        externals[1] = ExternalDeployment({
            deployedAddress: LibDecimalFloatDeploy.ZOLTU_DEPLOYED_DECIMAL_FLOAT_ADDRESS,
            codeHash: LibDecimalFloatDeploy.DECIMAL_FLOAT_CONTRACT_HASH
        });
        externals[2] =
            ExternalDeployment({deployedAddress: LOG_TABLES_DEPLOYED_ADDRESS, codeHash: LOG_TABLES_BYTECODE_HASH});
        return externals;
    }
}
