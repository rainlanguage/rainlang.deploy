// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";
import {LibInterpreterDeploy} from "../../../../src/lib/deploy/LibInterpreterDeploy.sol";
import {RainlangParser} from "../../../../src/concrete/RainlangParser.sol";
import {RainlangStore} from "../../../../src/concrete/RainlangStore.sol";
import {RainlangInterpreter} from "../../../../src/concrete/RainlangInterpreter.sol";
import {RainlangExpressionDeployer} from "../../../../src/concrete/RainlangExpressionDeployer.sol";
import {Rainlang} from "../../../../src/concrete/Rainlang.sol";
import {LibExtrospectBytecode} from "rain-extrospection-0.1.14/src/lib/LibExtrospectBytecode.sol";
import {LibExtrospectMetamorphic} from "rain-extrospection-0.1.14/src/lib/LibExtrospectMetamorphic.sol";

/// @title LibInterpreterDeployTest
/// @notice What `LibInterpreterDeploy` asserts over and above the deploy
/// framework.
///
/// `RainlangDeploySnapshotTest` owns every pin assertion now: the recorded
/// address is the derived address, the recorded code hash is what the creation
/// code produces, the runtime code hashes to it, and every candidate still
/// matches current source. Restating any of that here would be a second
/// hard-coded copy of the same five records that could drift from the
/// declaration the deploy script reads.
///
/// What is left is the part the framework does not model. The bytecode
/// properties — no Solidity CBOR metadata, no reachable metamorphic opcode —
/// are constraints on the SOURCE of a contract this repo pins by address, not
/// on the record of it. `etchRainlang` is a published consumer
/// API with no analogue in `rain-deploy` at all.
contract LibInterpreterDeployTest is Test {
    /// Parser bytecode MUST NOT contain Solidity CBOR metadata.
    function testNoCborMetadataParser() external {
        RainlangParser parser = new RainlangParser();
        assertFalse(
            LibExtrospectBytecode.tryTrimSolidityCBORMetadata(address(parser).code),
            "Parser bytecode contains CBOR metadata"
        );
    }

    /// Store bytecode MUST NOT contain Solidity CBOR metadata.
    function testNoCborMetadataStore() external {
        RainlangStore store = new RainlangStore();
        assertFalse(
            LibExtrospectBytecode.tryTrimSolidityCBORMetadata(address(store).code),
            "Store bytecode contains CBOR metadata"
        );
    }

    /// Interpreter bytecode MUST NOT contain Solidity CBOR metadata.
    function testNoCborMetadataInterpreter() external {
        RainlangInterpreter interpreter = new RainlangInterpreter();
        assertFalse(
            LibExtrospectBytecode.tryTrimSolidityCBORMetadata(address(interpreter).code),
            "Interpreter bytecode contains CBOR metadata"
        );
    }

    /// ExpressionDeployer bytecode MUST NOT contain Solidity CBOR metadata.
    function testNoCborMetadataExpressionDeployer() external {
        RainlangExpressionDeployer expressionDeployer = new RainlangExpressionDeployer();
        assertFalse(
            LibExtrospectBytecode.tryTrimSolidityCBORMetadata(address(expressionDeployer).code),
            "ExpressionDeployer bytecode contains CBOR metadata"
        );
    }

    /// Rainlang bytecode MUST NOT contain Solidity CBOR metadata.
    function testNoCborMetadataRainlang() external {
        Rainlang rainlang = new Rainlang();
        assertFalse(
            LibExtrospectBytecode.tryTrimSolidityCBORMetadata(address(rainlang).code),
            "Rainlang bytecode contains CBOR metadata"
        );
    }

    /// Parser bytecode MUST NOT contain reachable metamorphic risk opcodes.
    function testNotMetamorphicParser() external {
        RainlangParser parser = new RainlangParser();
        LibExtrospectMetamorphic.checkNotMetamorphic(address(parser).code);
    }

    /// Store bytecode MUST NOT contain reachable metamorphic risk opcodes.
    function testNotMetamorphicStore() external {
        RainlangStore store = new RainlangStore();
        LibExtrospectMetamorphic.checkNotMetamorphic(address(store).code);
    }

    /// Interpreter bytecode MUST NOT contain reachable metamorphic risk opcodes.
    function testNotMetamorphicInterpreter() external {
        RainlangInterpreter interpreter = new RainlangInterpreter();
        LibExtrospectMetamorphic.checkNotMetamorphic(address(interpreter).code);
    }

    /// ExpressionDeployer bytecode MUST NOT contain reachable metamorphic risk
    /// opcodes.
    function testNotMetamorphicExpressionDeployer() external {
        RainlangExpressionDeployer expressionDeployer = new RainlangExpressionDeployer();
        LibExtrospectMetamorphic.checkNotMetamorphic(address(expressionDeployer).code);
    }

    /// Rainlang bytecode MUST NOT contain reachable metamorphic risk opcodes.
    function testNotMetamorphicRainlang() external {
        Rainlang rainlang = new Rainlang();
        LibExtrospectMetamorphic.checkNotMetamorphic(address(rainlang).code);
    }

    /// After calling etchRainlang, all five contracts MUST have the expected
    /// codehash at their expected addresses.
    function testEtchRainlang() external {
        LibInterpreterDeploy.etchRainlang(vm);

        assertEq(LibInterpreterDeploy.PARSER_DEPLOYED_ADDRESS.codehash, LibInterpreterDeploy.PARSER_DEPLOYED_CODEHASH);
        assertEq(LibInterpreterDeploy.STORE_DEPLOYED_ADDRESS.codehash, LibInterpreterDeploy.STORE_DEPLOYED_CODEHASH);
        assertEq(
            LibInterpreterDeploy.INTERPRETER_DEPLOYED_ADDRESS.codehash,
            LibInterpreterDeploy.INTERPRETER_DEPLOYED_CODEHASH
        );
        assertEq(
            LibInterpreterDeploy.EXPRESSION_DEPLOYER_DEPLOYED_ADDRESS.codehash,
            LibInterpreterDeploy.EXPRESSION_DEPLOYER_DEPLOYED_CODEHASH
        );
        assertEq(
            LibInterpreterDeploy.RAINLANG_DEPLOYED_ADDRESS.codehash, LibInterpreterDeploy.RAINLANG_DEPLOYED_CODEHASH
        );
    }

    /// Calling etchRainlang twice MUST be idempotent — codehashes remain
    /// correct on the second call.
    function testEtchRainlangIdempotent() external {
        LibInterpreterDeploy.etchRainlang(vm);
        LibInterpreterDeploy.etchRainlang(vm);

        assertEq(LibInterpreterDeploy.PARSER_DEPLOYED_ADDRESS.codehash, LibInterpreterDeploy.PARSER_DEPLOYED_CODEHASH);
        assertEq(LibInterpreterDeploy.STORE_DEPLOYED_ADDRESS.codehash, LibInterpreterDeploy.STORE_DEPLOYED_CODEHASH);
        assertEq(
            LibInterpreterDeploy.INTERPRETER_DEPLOYED_ADDRESS.codehash,
            LibInterpreterDeploy.INTERPRETER_DEPLOYED_CODEHASH
        );
        assertEq(
            LibInterpreterDeploy.EXPRESSION_DEPLOYER_DEPLOYED_ADDRESS.codehash,
            LibInterpreterDeploy.EXPRESSION_DEPLOYER_DEPLOYED_CODEHASH
        );
        assertEq(
            LibInterpreterDeploy.RAINLANG_DEPLOYED_ADDRESS.codehash, LibInterpreterDeploy.RAINLANG_DEPLOYED_CODEHASH
        );
    }
}
