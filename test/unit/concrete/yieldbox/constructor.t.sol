// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {YieldBoxUnitConcreteTest} from "./YieldBox.t.sol";

// Contracts
import {YieldBox, Pearlmit} from "contracts/YieldBox.sol";

// Interfaces
import "contracts/interfaces/IWrappedNative.sol";

contract ConstructorYB is YieldBoxUnitConcreteTest {
    /////////////////////////////////////////////////////////////////////
    //                         SETUP                                   //
    /////////////////////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();
    }

    /////////////////////////////////////////////////////////////////////
    //                          TESTS                                  //
    /////////////////////////////////////////////////////////////////////
    function test_constructorYieldBox() public {
        // It should emit an `OwnershipTransferred` event
        // Ownership is transferred from deployer to specified `owner_`
        vm.expectEmit();
        emit OwnershipTransferred(address(users.alice), address(users.owner));

        // Deploy YieldBox
        YieldBox yieldBoxTest = new YieldBox(
            IWrappedNative(address(wrappedNative)), // `wrappedNative_`
            yieldBoxUriBuilder, // `uriBuilder_`
            pearlmit, // `pearlmit_`
            users.owner // `owner_`
        );

        // `wrappedNative` should be set to `wrappedNative_`
        assertEq(address(yieldBoxTest.wrappedNative()), address(wrappedNative));

        // `uriBuilder` should be set to `uriBuilder_`
        assertEq(address(yieldBoxTest.uriBuilder()), address(yieldBoxUriBuilder));

        // `pearlmit` should be set to `pearlmit_`
        assertEq(address(yieldBoxTest.pearlmit()), address(pearlmit));

        // contract owner should be set to `owner_`
        assertEq(address(yieldBoxTest.contractOwner()), address(users.owner));
    }
}
