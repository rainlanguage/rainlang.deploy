// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {RainDeployDeclarationChecks} from "rain-deploy-0.1.32/src/abstract/RainDeployDeclarationChecks.sol";
import {DeployDeclaration, ExternalDeployment} from "rain-deploy-0.1.32/src/abstract/RainDeploySuitesBase.sol";
import {RainlangDeploySuites} from "../../../src/abstract/RainlangDeploySuites.sol";
import {LibTOFUTokenDecimals} from "rain-tofu-erc20-decimals-0.1.5/src/lib/LibTOFUTokenDecimals.sol";
import {LibDecimalFloatDeploy} from "rain-math-float-deploy-0.1.9/src/lib/deploy/LibDecimalFloatDeploy.sol";
import {
    DEPLOYED_ADDRESS as LOG_TABLES_DEPLOYED_ADDRESS,
    BYTECODE_HASH as LOG_TABLES_BYTECODE_HASH
} from "rain-math-float-deploy-0.1.9/src/generated/0_1_3/LogTables.sol";
import {RainlangParser} from "../../../src/concrete/RainlangParser.sol";
import {RainlangStore} from "../../../src/concrete/RainlangStore.sol";
import {RainlangInterpreter} from "../../../src/concrete/RainlangInterpreter.sol";
import {RainlangCompiler} from "../../../src/concrete/RainlangCompiler.sol";
import {Rainlang} from "../../../src/concrete/Rainlang.sol";

// `RainlangDeploySuites.declaration()` is not virtual and sets neither field the checks read, so the checks run here.
contract RainlangDeployDeclarationTest is RainlangDeploySuites, RainDeployDeclarationChecks {
    function checkedDeclaration() internal pure returns (DeployDeclaration memory) {
        DeployDeclaration memory declared = declaration();
        declared.sourceCreationCode = sourceCreationCode;
        declared.externalDeployments = externalDeployments();
        return declared;
    }

    function testDispatchChoicesAreTheSuiteKeys() external view {
        checkDispatchChoicesAreTheSuiteKeys(checkedDeclaration());
    }

    function testCandidateArtifactPathsAreSource() external view {
        checkCandidateArtifactPathsAreSource(checkedDeclaration());
    }

    function testDependenciesAreNonZeroAndUnique() external pure {
        checkDependenciesAreNonZeroAndUnique(checkedDeclaration());
    }

    function testDependenciesAreTheEmbeddedDeployments() external pure {
        checkDependenciesAreTheEmbeddedDeployments(checkedDeclaration());
    }

    function testDependencyRuntimeCodeIsKnown() external pure {
        checkDependencyRuntimeCodeIsKnown(checkedDeclaration());
    }

    function testCandidateRuntimeCodeFitsEip170() external pure {
        checkCandidateRuntimeCodeFitsEip170(checkedDeclaration());
    }

    function sourceCreationCode(string memory suite) internal pure returns (bytes memory) {
        bytes32 key = keccak256(bytes(suite));
        if (key == keccak256("parser")) return type(RainlangParser).creationCode;
        if (key == keccak256("store")) return type(RainlangStore).creationCode;
        if (key == keccak256("interpreter")) return type(RainlangInterpreter).creationCode;
        if (key == keccak256("compiler")) return type(RainlangCompiler).creationCode;
        if (key == keccak256("rainlang")) return type(Rainlang).creationCode;
        revert(string.concat("no source for suite: ", suite));
    }

    // The 0_1_9 interpreter reaches LogTables; the candidate does not.
    function externalDeployments() internal pure returns (ExternalDeployment[] memory) {
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
