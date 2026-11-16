// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {BuildScript, GeneratedContract, RetiredContract} from "rain-deploy-0.1.32/src/abstract/BuildScript.sol";
import {LibRainDeploySnapshot} from "rain-deploy-0.1.32/src/lib/LibRainDeploySnapshot.sol";
import {LibRainDeploy} from "rain-deploy-0.1.32/src/lib/LibRainDeploy.sol";
import {LibCodeGen} from "rain-sol-codegen-0.1.39/src/lib/LibCodeGen.sol";
import {LibFs} from "rain-sol-codegen-0.1.39/src/lib/LibFs.sol";
import {LibGenParseMeta} from "rainlang-0.2.35/src/lib/codegen/LibGenParseMeta.sol";
import {DeployDeclaration} from "rain-deploy-0.1.32/src/abstract/RainDeploySuitesBase.sol";
import {RainlangDeploySuites} from "../src/abstract/RainlangDeploySuites.sol";
import {RainlangParser} from "../src/concrete/RainlangParser.sol";
import {PARSE_META_BUILD_DEPTH} from "rainlang-0.2.35/src/abstract/BaseRainlangParser.sol";
import {RainlangStore} from "../src/concrete/RainlangStore.sol";
import {RainlangInterpreter} from "../src/concrete/RainlangInterpreter.sol";
import {RainlangCompiler} from "../src/concrete/RainlangCompiler.sol";
import {LibAllStandardOps} from "rainlang-0.2.35/src/lib/op/LibAllStandardOps.sol";

/// @title Build
/// @notice Generates the deploy pins for every contract this repo deploys.
///
/// `run()` (what CI regenerates against) rewrites the rolling
/// `src/generated/candidate/` snapshots, the non-deploy codegen beside them
/// and the released-suites libs. `cutRelease()` freezes the candidates into
/// `src/generated/<tag>/` first. Frozen snapshots are append-only historical
/// records, never regenerated here.
///
/// `RainlangExpressionDeployer` is retired: the compiler's record name in
/// releases frozen before its rename, whose entries stay released.
///
/// There are no generated alias libs: `src/lib/deploy/LibInterpreterDeploy.sol`
/// is hand-written over the candidate snapshots because its constant names and
/// its `etchRainlang` helper are a published consumer API.
contract Build is BuildScript, RainlangDeploySuites {
    /// @inheritdoc BuildScript
    function generatedContracts(DeployDeclaration memory d)
        internal
        pure
        override
        returns (GeneratedContract[] memory)
    {
        GeneratedContract[] memory contracts = new GeneratedContract[](5);
        contracts[0] = GeneratedContract({
            contractName: "RainlangParser",
            constantPrefix: "",
            candidate: declaredCandidate(d, parserCandidate().snapshot.suite)
        });
        contracts[1] = GeneratedContract({
            contractName: "RainlangStore",
            constantPrefix: "",
            candidate: declaredCandidate(d, storeCandidate().snapshot.suite)
        });
        contracts[2] = GeneratedContract({
            contractName: "RainlangInterpreter",
            constantPrefix: "",
            candidate: declaredCandidate(d, interpreterCandidate().snapshot.suite)
        });
        contracts[3] = GeneratedContract({
            contractName: "RainlangCompiler",
            constantPrefix: "",
            candidate: declaredCandidate(d, compilerCandidate().snapshot.suite)
        });
        contracts[4] = GeneratedContract({
            contractName: "Rainlang",
            constantPrefix: "",
            candidate: declaredCandidate(d, rainlangCandidate().snapshot.suite)
        });
        return contracts;
    }

    /// @inheritdoc BuildScript
    function retiredContracts() internal pure override returns (RetiredContract[] memory) {
        RetiredContract[] memory retired = new RetiredContract[](1);
        retired[0] =
            RetiredContract({contractName: "RainlangExpressionDeployer", template: compilerCandidate().snapshot});
        return retired;
    }

    /// @inheritdoc BuildScript
    function regenerateSnapshots() internal override {
        GeneratedContract[] memory contracts = checkedGeneratedContracts(declaration());
        for (uint256 i = 0; i < contracts.length; i++) {
            LibRainDeploySnapshot.writeSnapshot(
                vm,
                recordRoot(),
                LibRainDeploySnapshot.CANDIDATE,
                contracts[i].contractName,
                vm.getCode(contracts[i].candidate.snapshot.artifactPath),
                contracts[i].candidate.snapshot.dependencies
            );
        }
        buildRainlangParserPointers();
        buildRainlangStorePointers();
        buildRainlangInterpreterPointers();
        buildRainlangCompilerPointers();
    }

    /// The parser's non-deploy codegen: parse meta, operand handler pointers
    /// and literal parser pointers.
    ///
    /// `LibRainDeploySnapshot.writeSnapshot` only ever emits deploy constants,
    /// so everything a contract needs to compile ITSELF lives in its own
    /// generated file — the usual committed-codegen cycle. The name is
    /// distinct from the contract's so the file cannot be taken for a snapshot
    /// of `RainlangParser`, and so it survives
    /// `LibFs.requireNoOrphanedArtifact` beside the candidate record.
    ///
    /// The instance read here is the one the `writeSnapshot` loop in
    /// `regenerateSnapshots` already deployed via the Zoltu factory, reached
    /// again through its deterministic address — deploying twice through the
    /// factory would collide.
    function buildRainlangParserPointers() internal {
        RainlangParser parser = RainlangParser(LibRainDeploy.zoltuAddress(type(RainlangParser).creationCode));

        LibFs.buildFileForContract(
            vm,
            address(parser),
            "RainlangParserPointers",
            string.concat(
                LibGenParseMeta.parseMetaConstantString(
                    vm, LibAllStandardOps.authoringMetaV2(), PARSE_META_BUILD_DEPTH
                ),
                LibCodeGen.operandHandlerFunctionPointersConstantString(vm, parser),
                LibCodeGen.literalParserFunctionPointersConstantString(vm, parser)
            )
        );
    }

    /// The store's only generated constant is the bytecode hash every
    /// generated file carries, which `RainlangStore` itself imports. It has no
    /// word tables, no parse meta and no function pointers, so the file is the
    /// header and nothing else.
    function buildRainlangStorePointers() internal {
        LibFs.buildFileForContract(
            vm, LibRainDeploy.zoltuAddress(type(RainlangStore).creationCode), "RainlangStorePointers", ""
        );
    }

    /// The interpreter's non-deploy codegen: its opcode function pointers.
    function buildRainlangInterpreterPointers() internal {
        RainlangInterpreter interpreter =
            RainlangInterpreter(LibRainDeploy.zoltuAddress(type(RainlangInterpreter).creationCode));

        LibFs.buildFileForContract(
            vm,
            address(interpreter),
            "RainlangInterpreterPointers",
            LibCodeGen.opcodeFunctionPointersConstantString(vm, interpreter)
        );
    }

    /// The compiler's non-deploy codegen: its described-by meta
    /// hash and integrity function pointers.
    function buildRainlangCompilerPointers() internal {
        RainlangCompiler compiler = RainlangCompiler(LibRainDeploy.zoltuAddress(type(RainlangCompiler).creationCode));

        LibFs.buildFileForContract(
            vm,
            address(compiler),
            "RainlangCompilerPointers",
            string.concat(
                LibCodeGen.describedByMetaHashConstantString(vm, "RainlangCompiler"),
                LibCodeGen.integrityFunctionPointersConstantString(vm, compiler)
            )
        );
    }
}
