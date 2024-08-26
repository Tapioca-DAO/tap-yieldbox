// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {YieldBoxUnitConcreteTest} from "./YieldBox.t.sol";

// Contracts
import {YieldBox, Pearlmit} from "contracts/YieldBox.sol";
import {YieldBoxRebase} from "contracts/YieldBoxRebase.sol";
import {TokenType} from "contracts/enums/YieldBoxTokenType.sol";
import {ERC721WithoutStrategy} from "contracts/strategies/ERC721WithoutStrategy.sol";
import {Pearlmit} from "tap-utils/pearlmit/Pearlmit.sol";

// Interfaces
import "contracts/interfaces/IWrappedNative.sol";

contract setPearlmit is YieldBoxUnitConcreteTest {

    /////////////////////////////////////////////////////////////////////
    //                          STORAGE                                //
    /////////////////////////////////////////////////////////////////////
    address newPearlmit;

    /////////////////////////////////////////////////////////////////////
    //                          SETUP                                  //
    /////////////////////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();

        // Create new pearlmit address.
        newPearlmit = makeAddr("pearlmit");
    }

    /////////////////////////////////////////////////////////////////////
    //                         TESTS                                   //
    /////////////////////////////////////////////////////////////////////

    /// @notice Tests the scenario where caller is not owner.
    function test_setPearlmitRevertWhen_CallerIsNotOwner() public {
        // Prank malicious user.
        _resetPrank(users.eve);

        // Try to reset Pearlmit.
        vm.expectRevert("Ownable: caller is not the owner");
        yieldBox.setPearlmit(Pearlmit(newPearlmit));
    }

    /// @notice Tests the happy path where owner resets Pearlmit.
    function test_setPearlmitWhen_CallerIsOwner() public  {
        // Prank owner.
        _resetPrank(users.owner);
        
        // Try to reset Pearlmit.
        vm.expectEmit();
        emit PearlmitUpdated(address(yieldBox.pearlmit()), newPearlmit);
        yieldBox.setPearlmit(Pearlmit(newPearlmit));

        // Ensure new address is properly set.
        assertEq(address(yieldBox.pearlmit()), newPearlmit);
    }
}
