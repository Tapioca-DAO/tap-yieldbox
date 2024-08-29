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

contract withdraw is YieldBoxUnitConcreteTest {
    /////////////////////////////////////////////////////////////////////
    //                         STRUCTS                                 //
    /////////////////////////////////////////////////////////////////////

    /// @notice Tracks state prior to withdrawing.
    struct StateBeforeWithdrawal {
        uint256 userShareBalanceBeforeWithdrawal;
        uint256 totalSupplyBeforeWithdrawal;
        uint256 strategyAssetBalanceBeforeWithdrawal;
        uint256 totalShare;
        uint256 totalAmount;
        uint256 expectedShares;
        uint256 expectedAmount;
    }

    /////////////////////////////////////////////////////////////////////
    //                          SETUP                                  //
    /////////////////////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();
    }

    /////////////////////////////////////////////////////////////////////
    //                         TESTS                                   //
    /////////////////////////////////////////////////////////////////////

    /// @notice Tests the scenario where `from` is not allowed
    /// @dev `from not being allowed implies the following:
    ///     - `from` is different from `msg.sender`
    ///     - `from` has not approved `msg.sender` for the given asset ID
    ///     - `from` has not approved `msg.sender` for all assets
    function test_withdrawRevertWhen_CallerIsNotAllowed(uint64 withdrawAmount)
        public
        assumeNoZeroValue(withdrawAmount)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, 0, withdrawAmount)
    {
        // Prank malicious user
        _resetPrank({msgSender: users.eve});

        // Try to withdraw on behalf of impartial user without approval.
        vm.expectRevert("Transfer not allowed");
        yieldBox.withdraw(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.eve, // `to`
            withdrawAmount, // `amount`
            0 // `share`
        );
    }

    /// @notice Tests the scenario where `asset` to withdraw is native
    function test_withdrawRevertWhen_AssetIsNative(uint64 withdrawAmount)
        public
        assumeNoZeroValue(withdrawAmount)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, 0, withdrawAmount)
    {
        // Create native asset
        uint256 nativeAssetId = yieldBox.createToken("native", "nat", 18, "");

        // Try to withdraw on behalf of impartial user
        vm.expectRevert(InvalidTokenType.selector);
        yieldBox.withdraw(
            nativeAssetId, // `assetId`
            users.alice, // `from`
            users.alice, // `to`
            0, // `amount`
            withdrawAmount // `share`
        );
    }

    /// @notice Tests the scenario where shares are properly computed given a certain amount.
    function test_withdraw_SharesAreCorrectGivenAmount(uint64 depositAmount, uint64 withdrawAmount)
        public
        assumeNoZeroValue(depositAmount)
        assumeNoZeroValue(withdrawAmount)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, withdrawAmount, 0)
    {
        // Bound withdrawal amount to the max amount deposited
        vm.assume(withdrawAmount <= depositAmount);

        // Fetch data prior to withdrawing
        StateBeforeWithdrawal memory stateBeforeWithdrawal;

        (stateBeforeWithdrawal.totalShare, stateBeforeWithdrawal.totalAmount) = yieldBox.assetTotals(DAI_ASSET_ID);

        // Compute expected shares to withdraw (rounding up for withdrawals)
        stateBeforeWithdrawal.expectedShares = YieldBoxRebase._toShares({
            amount: withdrawAmount,
            totalShares_: stateBeforeWithdrawal.totalShare,
            totalAmount: stateBeforeWithdrawal.totalAmount,
            roundUp: true
        });

        // Fetch impartial user's share balance
        stateBeforeWithdrawal.userShareBalanceBeforeWithdrawal = yieldBox.balanceOf(users.alice, DAI_ASSET_ID);

        // Fetch total supply
        stateBeforeWithdrawal.totalSupplyBeforeWithdrawal = yieldBox.totalSupply(DAI_ASSET_ID);

        // Fetch strategy asset balance
        stateBeforeWithdrawal.strategyAssetBalanceBeforeWithdrawal = dai.balanceOf(address(daiStrategy));

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(users.alice, users.alice, address(0), DAI_ASSET_ID, stateBeforeWithdrawal.expectedShares);

        vm.expectEmit();
        emit Withdraw(
            users.alice,
            users.alice,
            users.alice,
            DAI_ASSET_ID,
            withdrawAmount,
            stateBeforeWithdrawal.expectedShares,
            0,
            0
        );

        // Trigger withdrawal
        yieldBox.withdraw(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.alice, // `to`
            withdrawAmount, // `amount`
            0 // `share`
        );

        // It should decrement `balanceOf` of `to` by `share`
        assertEq(
            stateBeforeWithdrawal.userShareBalanceBeforeWithdrawal,
            yieldBox.balanceOf(users.alice, DAI_ASSET_ID) + stateBeforeWithdrawal.expectedShares
        );

        // It should decrement `totalSupply` by `share`
        assertEq(
            stateBeforeWithdrawal.totalSupplyBeforeWithdrawal,
            yieldBox.totalSupply(DAI_ASSET_ID) + stateBeforeWithdrawal.expectedShares
        );

        // It should decrement `strategy`'s balance by `amount`
        assertEq(
            stateBeforeWithdrawal.strategyAssetBalanceBeforeWithdrawal,
            dai.balanceOf(address(daiStrategy)) + withdrawAmount
        );
    }

    /// @notice Tests the scenario where shares are properly computed given a certain amount managed via an operator for a given asset ID.
    /// @dev Precondition: Alice has deposited assets.
    /// @dev Precondition: Alice has approved Bob for asset ID
    function test_withdraw_SharesAreCorrectGivenAmountViaApprovedAssetID()
        public
        whenYieldBoxApprovedForAssetID(users.alice, users.bob, DAI_ASSET_ID)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, LARGE_AMOUNT, 0)
        resetPrank(users.bob)
    {
        // Fetch data prior to withdrawing
        StateBeforeWithdrawal memory stateBeforeWithdrawal;

        (stateBeforeWithdrawal.totalShare, stateBeforeWithdrawal.totalAmount) = yieldBox.assetTotals(DAI_ASSET_ID);

        // Compute expected shares to withdraw (rounding up for withdrawals)
        stateBeforeWithdrawal.expectedShares = YieldBoxRebase._toShares({
            amount: MEDIUM_AMOUNT,
            totalShares_: stateBeforeWithdrawal.totalShare,
            totalAmount: stateBeforeWithdrawal.totalAmount,
            roundUp: true
        });

        // Fetch impartial user's share balance
        stateBeforeWithdrawal.userShareBalanceBeforeWithdrawal = yieldBox.balanceOf(users.alice, DAI_ASSET_ID);

        // Fetch total supply
        stateBeforeWithdrawal.totalSupplyBeforeWithdrawal = yieldBox.totalSupply(DAI_ASSET_ID);

        // Fetch strategy asset balance
        stateBeforeWithdrawal.strategyAssetBalanceBeforeWithdrawal = dai.balanceOf(address(daiStrategy));

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(users.bob, users.alice, address(0), DAI_ASSET_ID, stateBeforeWithdrawal.expectedShares);

        vm.expectEmit();
        emit Withdraw(
            users.bob, users.alice, users.bob, DAI_ASSET_ID, MEDIUM_AMOUNT, stateBeforeWithdrawal.expectedShares, 0, 0
        );

        // Trigger withdrawal
        yieldBox.withdraw(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.bob, // `to`
            MEDIUM_AMOUNT, // `amount`
            0 // `share`
        );

        // It should decrement `balanceOf` of `from` by `share`
        assertEq(
            stateBeforeWithdrawal.userShareBalanceBeforeWithdrawal,
            yieldBox.balanceOf(users.alice, DAI_ASSET_ID) + stateBeforeWithdrawal.expectedShares
        );

        // It should decrement `totalSupply` by `share`
        assertEq(
            stateBeforeWithdrawal.totalSupplyBeforeWithdrawal,
            yieldBox.totalSupply(DAI_ASSET_ID) + stateBeforeWithdrawal.expectedShares
        );

        // It should decrement `strategy`'s balance by `amount`
        assertEq(
            stateBeforeWithdrawal.strategyAssetBalanceBeforeWithdrawal,
            dai.balanceOf(address(daiStrategy)) + MEDIUM_AMOUNT
        );
    }

    /// @notice Tests the scenario where shares are properly computed given a certain amount managed via an operator for all.
    /// @dev Precondition: Alice has deposited assets.
    /// @dev Precondition: Alice has approved Bob for all
    function test_withdraw_SharesAreCorrectGivenAmountViaApprovedForAll()
        public
        whenYieldBoxApprovedForAll(users.alice, users.bob)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, LARGE_AMOUNT, 0)
        resetPrank(users.bob)
    {
        // Fetch data prior to withdrawing
        StateBeforeWithdrawal memory stateBeforeWithdrawal;

        (stateBeforeWithdrawal.totalShare, stateBeforeWithdrawal.totalAmount) = yieldBox.assetTotals(DAI_ASSET_ID);

        // Compute expected shares to withdraw (rounding up for withdrawals)
        stateBeforeWithdrawal.expectedShares = YieldBoxRebase._toShares({
            amount: MEDIUM_AMOUNT,
            totalShares_: stateBeforeWithdrawal.totalShare,
            totalAmount: stateBeforeWithdrawal.totalAmount,
            roundUp: true
        });

        // Fetch impartial user's share balance
        stateBeforeWithdrawal.userShareBalanceBeforeWithdrawal = yieldBox.balanceOf(users.alice, DAI_ASSET_ID);

        // Fetch total supply
        stateBeforeWithdrawal.totalSupplyBeforeWithdrawal = yieldBox.totalSupply(DAI_ASSET_ID);

        // Fetch strategy asset balance
        stateBeforeWithdrawal.strategyAssetBalanceBeforeWithdrawal = dai.balanceOf(address(daiStrategy));

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(users.bob, users.alice, address(0), DAI_ASSET_ID, stateBeforeWithdrawal.expectedShares);

        vm.expectEmit();
        emit Withdraw(
            users.bob, users.alice, users.bob, DAI_ASSET_ID, MEDIUM_AMOUNT, stateBeforeWithdrawal.expectedShares, 0, 0
        );

        // Trigger withdrawal
        yieldBox.withdraw(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.bob, // `to`
            MEDIUM_AMOUNT, // `amount`
            0 // `share`
        );

        // It should decrement `balanceOf` of `from` by `share`
        assertEq(
            stateBeforeWithdrawal.userShareBalanceBeforeWithdrawal,
            yieldBox.balanceOf(users.alice, DAI_ASSET_ID) + stateBeforeWithdrawal.expectedShares
        );

        // It should decrement `totalSupply` by `share`
        assertEq(
            stateBeforeWithdrawal.totalSupplyBeforeWithdrawal,
            yieldBox.totalSupply(DAI_ASSET_ID) + stateBeforeWithdrawal.expectedShares
        );

        // It should decrement `strategy`'s balance by `amount`
        assertEq(
            stateBeforeWithdrawal.strategyAssetBalanceBeforeWithdrawal,
            dai.balanceOf(address(daiStrategy)) + MEDIUM_AMOUNT
        );
    }

    /// @notice Tests the scenario where amount is properly computed given certain shares.
    function test_withdraw_AmountIsCorrectGivenShares(uint64 depositAmount, uint64 withdrawShares)
        public
        assumeNoZeroValue(depositAmount)
        assumeNoZeroValue(withdrawShares)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, 0, depositAmount)
    {
        // Bound withdrawal amount to the max amount deposited
        vm.assume(withdrawShares <= depositAmount);

        // Fetch data prior to withdrawing
        StateBeforeWithdrawal memory stateBeforeWithdrawal;

        (stateBeforeWithdrawal.totalShare, stateBeforeWithdrawal.totalAmount) = yieldBox.assetTotals(DAI_ASSET_ID);

        // Compute expected amount to withdraw (rounding down for withdrawals)
        stateBeforeWithdrawal.expectedAmount = YieldBoxRebase._toAmount({
            share: withdrawShares,
            totalShares_: stateBeforeWithdrawal.totalShare,
            totalAmount: stateBeforeWithdrawal.totalAmount,
            roundUp: false
        });

        // Fetch impartial user's share balance
        stateBeforeWithdrawal.userShareBalanceBeforeWithdrawal = yieldBox.balanceOf(users.alice, DAI_ASSET_ID);

        // Fetch total supply
        stateBeforeWithdrawal.totalSupplyBeforeWithdrawal = yieldBox.totalSupply(DAI_ASSET_ID);

        // Fetch strategy asset balance
        stateBeforeWithdrawal.strategyAssetBalanceBeforeWithdrawal = dai.balanceOf(address(daiStrategy));

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(users.alice, users.alice, address(0), DAI_ASSET_ID, withdrawShares);

        vm.expectEmit();
        emit Withdraw(
            users.alice,
            users.alice,
            users.alice,
            DAI_ASSET_ID,
            stateBeforeWithdrawal.expectedAmount,
            withdrawShares,
            0,
            0
        );

        // Trigger withdrawal
        yieldBox.withdraw(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.alice, // `to`
            0, // `amount`
            withdrawShares // `share`
        );

        // It should decrement `balanceOf` of `to` by `share`
        assertEq(
            stateBeforeWithdrawal.userShareBalanceBeforeWithdrawal,
            yieldBox.balanceOf(users.alice, DAI_ASSET_ID) + uint256(withdrawShares)
        );

        // It should decrement `totalSupply` by `share`
        assertEq(
            stateBeforeWithdrawal.totalSupplyBeforeWithdrawal,
            yieldBox.totalSupply(DAI_ASSET_ID) + uint256(withdrawShares)
        );

        // It should decrement `strategy`'s balance by `amount`
        assertEq(
            stateBeforeWithdrawal.strategyAssetBalanceBeforeWithdrawal,
            dai.balanceOf(address(daiStrategy)) + uint256(stateBeforeWithdrawal.expectedAmount)
        );
    }

    /// @notice Tests the scenario where amount is properly computed given certain shares.
    /// @dev Precondition: Alice has deposited assets.
    /// @dev Precondition: Alice has approved Bob for asset ID
    function test_withdraw_AmountIsCorrectGivenSharesViaApprovedAssetID()
        public
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, 0, LARGE_AMOUNT)
        whenYieldBoxApprovedForAssetID(users.alice, users.bob, DAI_ASSET_ID)
        resetPrank(users.bob)
    {
        // Fetch data prior to withdrawing
        StateBeforeWithdrawal memory stateBeforeWithdrawal;

        (stateBeforeWithdrawal.totalShare, stateBeforeWithdrawal.totalAmount) = yieldBox.assetTotals(DAI_ASSET_ID);

        // Compute expected amount to withdraw (rounding down for withdrawals)
        stateBeforeWithdrawal.expectedAmount = YieldBoxRebase._toAmount({
            share: MEDIUM_AMOUNT,
            totalShares_: stateBeforeWithdrawal.totalShare,
            totalAmount: stateBeforeWithdrawal.totalAmount,
            roundUp: false
        });

        // Fetch impartial user's share balance
        stateBeforeWithdrawal.userShareBalanceBeforeWithdrawal = yieldBox.balanceOf(users.alice, DAI_ASSET_ID);

        // Fetch total supply
        stateBeforeWithdrawal.totalSupplyBeforeWithdrawal = yieldBox.totalSupply(DAI_ASSET_ID);

        // Fetch strategy asset balance
        stateBeforeWithdrawal.strategyAssetBalanceBeforeWithdrawal = dai.balanceOf(address(daiStrategy));

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(users.bob, users.alice, address(0), DAI_ASSET_ID, MEDIUM_AMOUNT);

        vm.expectEmit();
        emit Withdraw(
            users.bob, users.alice, users.bob, DAI_ASSET_ID, stateBeforeWithdrawal.expectedAmount, MEDIUM_AMOUNT, 0, 0
        );

        // Trigger withdrawal
        yieldBox.withdraw(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.bob, // `to`
            0, // `amount`
            MEDIUM_AMOUNT // `share`
        );

        // It should decrement `balanceOf` of `from` by `share`
        assertEq(
            stateBeforeWithdrawal.userShareBalanceBeforeWithdrawal,
            yieldBox.balanceOf(users.alice, DAI_ASSET_ID) + uint256(MEDIUM_AMOUNT)
        );

        // It should decrement `totalSupply` by `share`
        assertEq(
            stateBeforeWithdrawal.totalSupplyBeforeWithdrawal,
            yieldBox.totalSupply(DAI_ASSET_ID) + uint256(MEDIUM_AMOUNT)
        );

        // It should decrement `strategy`'s balance by `amount`
        assertEq(
            stateBeforeWithdrawal.strategyAssetBalanceBeforeWithdrawal,
            dai.balanceOf(address(daiStrategy)) + uint256(stateBeforeWithdrawal.expectedAmount)
        );
    }

    /// @notice Tests the scenario where amount is properly computed given certain shares.
    /// @dev Precondition: Alice has deposited assets.
    /// @dev Precondition: Alice has approved Bob for all
    function test_withdraw_AmountIsCorrectGivenSharesViaApprovedForAll()
        public
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, 0, LARGE_AMOUNT)
        whenYieldBoxApprovedForAll(users.alice, users.bob)
        resetPrank(users.bob)
    {
        // Fetch data prior to withdrawing
        StateBeforeWithdrawal memory stateBeforeWithdrawal;

        (stateBeforeWithdrawal.totalShare, stateBeforeWithdrawal.totalAmount) = yieldBox.assetTotals(DAI_ASSET_ID);

        // Compute expected amount to withdraw (rounding down for withdrawals)
        stateBeforeWithdrawal.expectedAmount = YieldBoxRebase._toAmount({
            share: MEDIUM_AMOUNT,
            totalShares_: stateBeforeWithdrawal.totalShare,
            totalAmount: stateBeforeWithdrawal.totalAmount,
            roundUp: false
        });

        // Fetch impartial user's share balance
        stateBeforeWithdrawal.userShareBalanceBeforeWithdrawal = yieldBox.balanceOf(users.alice, DAI_ASSET_ID);

        // Fetch total supply
        stateBeforeWithdrawal.totalSupplyBeforeWithdrawal = yieldBox.totalSupply(DAI_ASSET_ID);

        // Fetch strategy asset balance
        stateBeforeWithdrawal.strategyAssetBalanceBeforeWithdrawal = dai.balanceOf(address(daiStrategy));

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(users.bob, users.alice, address(0), DAI_ASSET_ID, MEDIUM_AMOUNT);

        vm.expectEmit();
        emit Withdraw(
            users.bob, users.alice, users.bob, DAI_ASSET_ID, stateBeforeWithdrawal.expectedAmount, MEDIUM_AMOUNT, 0, 0
        );

        // Trigger withdrawal
        yieldBox.withdraw(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.bob, // `to`
            0, // `amount`
            MEDIUM_AMOUNT // `share`
        );

        // It should decrement `balanceOf` of `from` by `share`
        assertEq(
            stateBeforeWithdrawal.userShareBalanceBeforeWithdrawal,
            yieldBox.balanceOf(users.alice, DAI_ASSET_ID) + uint256(MEDIUM_AMOUNT)
        );

        // It should decrement `totalSupply` by `share`
        assertEq(
            stateBeforeWithdrawal.totalSupplyBeforeWithdrawal,
            yieldBox.totalSupply(DAI_ASSET_ID) + uint256(MEDIUM_AMOUNT)
        );

        // It should decrement `strategy`'s balance by `amount`
        assertEq(
            stateBeforeWithdrawal.strategyAssetBalanceBeforeWithdrawal,
            dai.balanceOf(address(daiStrategy)) + uint256(stateBeforeWithdrawal.expectedAmount)
        );
    }
}
