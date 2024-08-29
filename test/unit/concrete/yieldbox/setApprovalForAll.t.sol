// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {YieldBoxUnitConcreteTest} from "./YieldBox.t.sol";

// Contracts
import {Pearlmit} from "tap-utils/pearlmit/Pearlmit.sol";

contract setApprovalForAll is YieldBoxUnitConcreteTest {
    /////////////////////////////////////////////////////////////////////
    //                          SETUP                                  //
    /////////////////////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();
    }

    /////////////////////////////////////////////////////////////////////
    //                         TESTS                                   //
    /////////////////////////////////////////////////////////////////////

    /// @notice Tests the scenario where `operator` is address(0)
    function test_setApprovalForAllRevertWhen_OpeartorIsAddressZero() public {
        // Try to approve an invalid address.
        vm.expectRevert(NotSet.selector);
        yieldBox.setApprovalForAll(address(0), true);
    }

    /// @notice Tests the scenario where `operator` is address(YieldBox)
    function test_setApprovalForAllRevertWhen_OpeartorIsYieldBox() public {
        // Try to approve an invalid address.
        vm.expectRevert(ForbiddenAction.selector);
        yieldBox.setApprovalForAll(address(yieldBox), true);
    }

    /// @notice Tests the happy path scenario where `operator` is approved for all.
    function test_setApprovalForAll_SetApprovalToCorrectOperator(address operator, bool value)
        public
        assumeNoZeroValue(uint256(uint160(operator)))
    {
        // Emit expected event
        vm.expectEmit();
        emit ApprovalForAll(users.alice, operator, value);

        // Set approval
        yieldBox.setApprovalForAll(operator, value);

        // Check new approval for all has been properly added.
        assertEq(yieldBox.isApprovedForAll(users.alice, operator), value);
    }
}
