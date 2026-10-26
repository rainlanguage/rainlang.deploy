// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {BaseRainlangCompiler} from "rainlang-0.2.23/src/abstract/BaseRainlangCompiler.sol";
import {BaseRainlangParser} from "rainlang-0.2.23/src/abstract/BaseRainlangParser.sol";
import {INTEGRITY_FUNCTION_POINTERS, DESCRIBED_BY_META_HASH} from "../generated/RainlangCompilerPointers.sol";
import {LibInterpreterDeploy} from "../lib/deploy/LibInterpreterDeploy.sol";
// Referenced by NatSpec only.
//forge-lint: disable-next-line(unused-import)
import {IDescribedByMetaV1} from "rain-metadata-0.1.43/src/interface/IDescribedByMetaV1.sol";

/// @title RainlangCompiler
/// @notice `BaseRainlangCompiler` bound to the parser at its
/// deterministic Zoltu address, its generated integrity function pointer
/// table and its described-by meta hash.
contract RainlangCompiler is BaseRainlangCompiler {
    /// @inheritdoc BaseRainlangCompiler
    function parser() internal pure virtual override returns (BaseRainlangParser) {
        return BaseRainlangParser(LibInterpreterDeploy.PARSER_DEPLOYED_ADDRESS);
    }

    /// @inheritdoc BaseRainlangCompiler
    function integrityFunctionPointers() internal pure virtual override returns (bytes memory) {
        return INTEGRITY_FUNCTION_POINTERS;
    }

    /// @inheritdoc IDescribedByMetaV1
    function describedByMetaV1() external pure virtual override returns (bytes32) {
        return DESCRIBED_BY_META_HASH;
    }
}
