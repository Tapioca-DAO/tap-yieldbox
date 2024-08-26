// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {YieldBoxUnitConcreteTest} from "./YieldBox.t.sol";

// Contracts
import {YieldBox, Pearlmit} from "contracts/YieldBox.sol";
import {YieldBoxRebase} from "contracts/YieldBoxRebase.sol";
import {TokenType} from "contracts/enums/YieldBoxTokenType.sol";
import {ERC721WithoutStrategy} from "contracts/strategies/ERC721WithoutStrategy.sol";
import {IYieldBox} from "contracts/interfaces/IYieldBox.sol";
import {IStrategy} from "contracts/interfaces/IStrategy.sol";

// Interfaces
import "contracts/interfaces/IWrappedNative.sol";

contract depositETHAsset is YieldBoxUnitConcreteTest {

    /////////////////////////////////////////////////////////////////////
    //                         SETUP                                   //
    /////////////////////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();
    }

    /////////////////////////////////////////////////////////////////////
    //                         TESTS                                   //
    /////////////////////////////////////////////////////////////////////

    /// @notice Tests the scenario where `assetId` is not ERC20
    function test_depositETHAssetRevertWhen_AssetIsNotERC20(uint64 depositAmount) public {

        // Try to deposit an incorrect asset
        vm.expectRevert(InvalidTokenType.selector);
        yieldBox.depositETHAsset{value: depositAmount}(
            0, // assetId 0 is not ERC20
            users.alice,
            depositAmount
        );
 
        // Create mock strategy
        ERC721WithoutStrategy erc721Strategy = new ERC721WithoutStrategy(
            IYieldBox(address(yieldBox)),
            address(dai), // mock,
            1
        );

        // Register asset with token type ERC721

        uint256 erc721AssetId = yieldBox.registerAsset(
            TokenType.ERC721,
            address(dai),
            IStrategy(address(erc721Strategy)),
            1
        );

        // Try to deposit an incorrect asset
        vm.expectRevert(InvalidTokenType.selector);
        yieldBox.depositETHAsset{value: depositAmount}(
            erc721AssetId,
            users.alice,
            depositAmount
        );
    }

    /// @notice Tests the scenario where `contractAddress` from asset is not `wrappedNative`
    function test_depositETHAssetRevertWhen_AssetIsNotWrappedNative(uint64 depositAmount) public {

        // Try to deposit an incorrect asset
        vm.expectRevert(NotWrapped.selector);
        yieldBox.depositETHAsset{value: depositAmount}(
            DAI_ASSET_ID,
            users.alice,
            depositAmount
        );
    }

    /// @notice Tests the scenario where `amount` is greater than the passed value
    function test_depositETHAssetRevertWhen_AmountIsGreaterThanValue() public {
        // Try to deposit a low amount
        vm.expectRevert(AmountTooLow.selector);
        yieldBox.depositETHAsset{value: WEI_AMOUNT}(
            WRAPPED_NATIVE_ASSET_ID,
            users.alice,
            MEDIUM_AMOUNT
        );
    }

    /// @notice Tests the scenario where asset is correct and amount is not greater than value
    function test_depositETHAsset_AssetIsSupported(uint64 depositAmount) public {

        (uint256 totalShare, uint256 totalAmount) = yieldBox.assetTotals(
            WRAPPED_NATIVE_ASSET_ID
        );

        // Compute expected amount of shares
        uint256 expectedShare = YieldBoxRebase._toShares({
            amount: depositAmount,
            totalShares_: totalShare,
            totalAmount: totalAmount,
            roundUp: false
        });

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(
            users.alice,
            address(0),
            users.alice,
            WRAPPED_NATIVE_ASSET_ID,
            expectedShare
        );


        // It should emit a `Deposited` event
        vm.expectEmit();
        emit Deposited(
            users.alice,
            users.alice,
            users.alice,
            WRAPPED_NATIVE_ASSET_ID,
            depositAmount,
            expectedShare,
            0,
            0,
            false
        );

        yieldBox.depositETHAsset{value: depositAmount}(
            WRAPPED_NATIVE_ASSET_ID,
            users.alice,
            depositAmount
        );

        // Shares should be minted to `to`
        assertEq(yieldBox.balanceOf(users.alice, WRAPPED_NATIVE_ASSET_ID), expectedShare);

        // Strategy's wrapped native balance should have increased by deposited amount
        assertEq(wrappedNative.balanceOf(address(wrappedNativeStrategy)), depositAmount);

    }

    /// @notice Tests the scenario where value is greater than passed amount and refund fails
    function test_depositETHAssetRevertWhen_ValueRefundFails(uint64 depositAmount, uint64 specifiedAmount) public {

        vm.assume(specifiedAmount != 0 && specifiedAmount < depositAmount);
        // We prank DAI as it is a contract without `receive` function. Hence, it can't receive ETH so we force the low-level call to fail
        _resetPrank(address(dai));
        deal(address(dai), depositAmount);

        // Force refunds to a receiver that can't receive ether. We force a refund by transferring `MEDIUM_AMOUNT` of value, but only
        // settnig `WEI_AMOUNT` as amount.
        vm.expectRevert(RefundFailed.selector);
        yieldBox.depositETHAsset{value: depositAmount}(
            WRAPPED_NATIVE_ASSET_ID,
            users.alice,
            WEI_AMOUNT
        );
    }

     /// @notice Tests the scenario where asset is correct and amount is not greater than value
    function test_depositETHAsset_ExcessOfValueIsRefunded(uint64 depositAmount) public {

        (uint256 totalShare, uint256 totalAmount) = yieldBox.assetTotals(
            WRAPPED_NATIVE_ASSET_ID
        );

        // Compute expected amount of shares
        uint256 expectedShare = YieldBoxRebase._toShares({
            amount: depositAmount,
            totalShares_: totalShare,
            totalAmount: totalAmount,
            roundUp: false
        });
        
        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(
            users.alice,
            address(0),
            users.alice,
            WRAPPED_NATIVE_ASSET_ID,
            expectedShare
        );

        // It should emit a `Deposited` event
        vm.expectEmit();
        emit Deposited(
            users.alice,
            users.alice,
            users.alice,
            WRAPPED_NATIVE_ASSET_ID,
            depositAmount,
            expectedShare,
            0,
            0,
            false
        );

        uint256 callerBalanceBeforeDeposit = users.alice.balance;

        // We send more value than the submitted by `amount`
        yieldBox.depositETHAsset{value: uint256(depositAmount) + 1}(
            WRAPPED_NATIVE_ASSET_ID,
            users.alice,
            depositAmount
        );
        

        // Shares should be minted to `to`
        assertEq(yieldBox.balanceOf(users.alice, WRAPPED_NATIVE_ASSET_ID), expectedShare);

        // Strategy's wrapped native balance should have increased by deposited amount
        assertEq(wrappedNative.balanceOf(address(wrappedNativeStrategy)), depositAmount);

        

        // Caller balance has only decreased by amount specified by `amount` parameter
        assertEq(users.alice.balance, callerBalanceBeforeDeposit - depositAmount);
    }
}
