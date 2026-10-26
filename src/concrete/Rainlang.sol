// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibInterpreterDeploy} from "../lib/deploy/LibInterpreterDeploy.sol";
import {BaseRainlang} from "rainlang-0.2.23/src/abstract/BaseRainlang.sol";
// Referenced by NatSpec only.
//forge-lint: disable-next-line(unused-import)
import {IRainlangV2} from "rainlang-0.2.23/src/interface/IRainlangV2.sol";

/// @title Rainlang
/// @notice `BaseRainlang` bound to the deterministic Zoltu deploy addresses of
/// the four core interpreter components. Deployed via the same Zoltu pattern
/// so that external tooling can discover all component addresses from a
/// single known Rainlang address.
contract Rainlang is BaseRainlang {
    /// @inheritdoc IRainlangV2
    function compiler() external pure virtual override returns (address) {
        return LibInterpreterDeploy.COMPILER_DEPLOYED_ADDRESS;
    }

    /// @inheritdoc IRainlangV2
    function interpreter() external pure virtual override returns (address) {
        return LibInterpreterDeploy.INTERPRETER_DEPLOYED_ADDRESS;
    }

    /// @inheritdoc IRainlangV2
    function store() external pure virtual override returns (address) {
        return LibInterpreterDeploy.STORE_DEPLOYED_ADDRESS;
    }

    /// @inheritdoc IRainlangV2
    function parser() external pure virtual override returns (address) {
        return LibInterpreterDeploy.PARSER_DEPLOYED_ADDRESS;
    }
}
