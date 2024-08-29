// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Setup
import {BaseTest} from "../../../Base.t.sol";

// Contracts
import {YieldBox} from "contracts/YieldBox.sol";
import {TokenType} from "contracts/enums/YieldBoxTokenType.sol";

// Interfaces
import {IStrategy} from "contracts/interfaces/IStrategy.sol";
import "contracts/interfaces/IWrappedNative.sol";

contract ConstructorAssetRegister is BaseTest {
    /////////////////////////////////////////////////////////////////////
    //                         SETUP                                   //
    /////////////////////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();
    }

    /////////////////////////////////////////////////////////////////////
    //                         TESTS                                   //
    /////////////////////////////////////////////////////////////////////
    function test_constructorAssetRegister() public {
        // Deploy YieldBox (containing asset register)
        YieldBox yieldBoxTest = new YieldBox(
            IWrappedNative(address(wrappedNative)), // `wrappedNative_`
            yieldBoxUriBuilder, // `uriBuilder_`
            pearlmit, // `pearlmit_`
            users.owner // `owner_`
        );

        // ID zero is reserved for empty asset
        assertEq(yieldBox.ids(TokenType.None, address(0), IStrategy(address(0)), 0), 0);

        // `assets` should return a length of one
        assertEq(yieldBox.assetCount(), 1);
    }
}
