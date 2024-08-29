// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";

/// @notice Helper contract containing utilities.
abstract contract Utils is Test {
    /// @dev Stops the active prank and sets a new one.
    function _resetPrank(address msgSender) internal {
        vm.stopPrank();
        vm.startPrank(msgSender);
    }
}
