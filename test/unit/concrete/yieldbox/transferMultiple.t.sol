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

contract transferMultiple is YieldBoxUnitConcreteTest {
    /////////////////////////////////////////////////////////////////////
    //                          STRUCTS                                //
    /////////////////////////////////////////////////////////////////////
    struct StateBeforeTransferMultiple {
        address[] tos;
        uint256[] amounts;
        uint256[] previousBalances;
    }

    /////////////////////////////////////////////////////////////////////
    //                          INTERNAL HELPERS                       //
    /////////////////////////////////////////////////////////////////////
    function _buildTransferMultipleRequiredData(address[] memory tos, uint256[] memory amounts, uint256 amount)
        internal
        view
        returns (address[] memory, uint256[] memory)
    {
        // Build array of `tos`
        tos[0] = users.bob;
        tos[1] = users.charlie;
        tos[2] = users.david;
        tos[3] = users.eve;

        // Build array of `amounts`
        amounts[0] = amount / 4;
        amounts[1] = amount / 4;
        amounts[2] = amount / 4;
        amounts[3] = amount / 4;
    }

    function _assertExpectedBalances(uint256[] memory previousBalances, address[] memory tos, uint256[] memory amounts)
        internal
        view
        returns (address[] memory, uint256[] memory)
    {
        for (uint256 i; i < tos.length; i++) {
            assertEq(yieldBox.balanceOf(tos[i], DAI_ASSET_ID), previousBalances[i] + amounts[i]);
        }
    }

    function _triggerMultipleExpectEmits(address operator, address from, address[] memory tos, uint256[] memory amounts)
        internal
    {
        for (uint256 i; i < tos.length; i++) {
            vm.expectEmit();
            emit TransferSingle(operator, from, tos[i], DAI_ASSET_ID, amounts[i]);
        }
    }

    function _fetchMultipleBalances(uint256[] memory previousBalances, address[] memory tos)
        internal
        view
        returns (uint256[] memory)
    {
        for (uint256 i; i < 4; i++) {
            previousBalances[i] = yieldBox.balanceOf(tos[i], DAI_ASSET_ID);
        }
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

    /// @notice Tests the scenario where `from` is not allowed to transferMultiple.
    /// @dev `from not being allowed implies the following:
    ///     - `from` is different from `msg.sender`
    ///     - `from` has not approved `msg.sender` for the given asset ID
    ///     - `from` has not approved `msg.sender` for all assets
    function test_transfeMultipleRevertWhen_CallerIsNotAllowed(uint64 depositAmount)
        public
        assumeGtE(depositAmount, 5)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, 0, depositAmount)
    {
        // Prank malicious user. No approvals have been performed.
        _resetPrank({msgSender: users.eve});

        StateBeforeTransferMultiple memory stateBeforeTransferMultiple;

        // Initialize required data
        stateBeforeTransferMultiple.tos = new address[](4);
        stateBeforeTransferMultiple.amounts = new uint256[](4);

        // Build required data
        _buildTransferMultipleRequiredData(
            stateBeforeTransferMultiple.tos, stateBeforeTransferMultiple.amounts, depositAmount
        );

        // Try to transfer assets on behalf of impartial user
        vm.expectRevert("Transfer not allowed");
        yieldBox.transferMultiple(
            users.alice, stateBeforeTransferMultiple.tos, DAI_ASSET_ID, stateBeforeTransferMultiple.amounts
        );
    }

    /// @notice Tests the scenario where `from` is not allowed to transferMultiple.
    /// @dev `from not being allowed implies the following:
    ///     - `from` is different from `msg.sender`
    ///     - `from` has not approved `msg.sender` for the given asset ID
    ///     - `from` has not approved `msg.sender` for all assets
    function test_transfeMultipleRevertWhen__AssetIsNotRegistered(uint64 depositAmount)
        public
        assumeGtE(depositAmount, 5)
    {
        StateBeforeTransferMultiple memory stateBeforeTransferMultiple;

        // Fill required data
        stateBeforeTransferMultiple.tos = new address[](4);
        stateBeforeTransferMultiple.amounts = new uint256[](4);

        // Build required data
        _buildTransferMultipleRequiredData(
            stateBeforeTransferMultiple.tos, stateBeforeTransferMultiple.amounts, depositAmount
        );
        // Try to transfer asset not registered in YieldBox.
        vm.expectRevert();
        yieldBox.transferMultiple(
            users.alice,
            stateBeforeTransferMultiple.tos,
            5, // invalid asset ID
            stateBeforeTransferMultiple.amounts
        );
    }

    /// @notice Tests the scenario where any of `tos` is address(0)
    function test_transfeMultipleRevertWhen__AssetIsNotRegistered(uint64 depositAmount, uint8 rand)
        public
        assumeGtE(depositAmount, 5)
    {
        StateBeforeTransferMultiple memory stateBeforeTransferMultiple;

        // Fill required data
        stateBeforeTransferMultiple.tos = new address[](4);
        stateBeforeTransferMultiple.amounts = new uint256[](4);

        // Build required data
        _buildTransferMultipleRequiredData(
            stateBeforeTransferMultiple.tos, stateBeforeTransferMultiple.amounts, depositAmount
        );

        // Set one of `tos` to address(0)
        stateBeforeTransferMultiple.tos[rand % 4] = address(0);

        // Try to transfer shares to zero address.
        vm.expectRevert(ZeroAddress.selector);
        yieldBox.transferMultiple(
            users.alice,
            stateBeforeTransferMultiple.tos,
            DAI_ASSET_ID, // invalid asset ID
            stateBeforeTransferMultiple.amounts
        );
    }

    /// @notice Tests the scenario where `_totalShares` is bigger than `balanceOf` `from`
    function test_transfeMultipleRevertWhen__AmountIsBiggerThanBalanceOfFrom(uint64 depositAmount, uint8 rand)
        public
        assumeGtE(depositAmount, 5)
    {
        StateBeforeTransferMultiple memory stateBeforeTransferMultiple;

        // Fill required data
        stateBeforeTransferMultiple.tos = new address[](4);
        stateBeforeTransferMultiple.amounts = new uint256[](4);

        // Build required data
        _buildTransferMultipleRequiredData(
            stateBeforeTransferMultiple.tos, stateBeforeTransferMultiple.amounts, depositAmount
        );

        // Inflate amounts
        stateBeforeTransferMultiple.amounts[rand % 4] = stateBeforeTransferMultiple.amounts[rand % 4] * 5;

        // Try to transfer asset not registered in YieldBox.
        vm.expectRevert();
        yieldBox.transferMultiple(
            users.alice,
            stateBeforeTransferMultiple.tos,
            DAI_ASSET_ID, // invalid asset ID
            stateBeforeTransferMultiple.amounts
        );
    }

    /// @notice Tests the scenario where `_totalShares` is bigger than `balanceOf` `from`
    function test_transferMultipleWhen_ValueIsSmallerOrEqualToBalance(uint64 depositAmount)
        public
        assumeGtE(depositAmount, 5)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, 0, depositAmount)
    {
        StateBeforeTransferMultiple memory stateBeforeTransferMultiple;

        // Fill required data
        stateBeforeTransferMultiple.tos = new address[](4);
        stateBeforeTransferMultiple.amounts = new uint256[](4);
        stateBeforeTransferMultiple.previousBalances = new uint256[](4);

        // Build required data
        _buildTransferMultipleRequiredData(
            stateBeforeTransferMultiple.tos, stateBeforeTransferMultiple.amounts, depositAmount
        );

        // Fetch previous state
        _fetchMultipleBalances(stateBeforeTransferMultiple.previousBalances, stateBeforeTransferMultiple.tos);

        uint256 aliceBalanceBefore = yieldBox.balanceOf(users.alice, DAI_ASSET_ID);

        // it should emit a `TransferSingle` event for each iteration
        _triggerMultipleExpectEmits({
            operator: users.alice,
            from: users.alice,
            tos: stateBeforeTransferMultiple.tos,
            amounts: stateBeforeTransferMultiple.amounts
        });

        // Try to transfer asset not registered in YieldBox.
        yieldBox.transferMultiple(
            users.alice,
            stateBeforeTransferMultiple.tos,
            DAI_ASSET_ID, // invalid asset ID
            stateBeforeTransferMultiple.amounts
        );

        // it should increment `balanceOf` each `to` by its respective `shares`
        _assertExpectedBalances(
            stateBeforeTransferMultiple.previousBalances,
            stateBeforeTransferMultiple.tos,
            stateBeforeTransferMultiple.amounts
        );

        // it should decrement `balanceOf` `from` by the total accumulated `_totalShares`
        assertEq(
            yieldBox.balanceOf(users.alice, DAI_ASSET_ID),
            aliceBalanceBefore - stateBeforeTransferMultiple.amounts[0] * 4 // all transferred amounts are equal
        );
    }

    /// @notice Tests the scenario where `_totalShares` is bigger than `balanceOf` `from` via asset ID approval.
    function test_transferMultipleWhen_ValueIsSmallerOrEqualToBalanceViaApprovedForAssetID(uint64 depositAmount)
        public
        assumeGtE(depositAmount, 5)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, 0, depositAmount)
        whenYieldBoxApprovedForAssetID(users.alice, users.owner, DAI_ASSET_ID)
    {
        StateBeforeTransferMultiple memory stateBeforeTransferMultiple;

        // Fill required data
        stateBeforeTransferMultiple.tos = new address[](4);
        stateBeforeTransferMultiple.amounts = new uint256[](4);
        stateBeforeTransferMultiple.previousBalances = new uint256[](4);

        // Build required data
        _buildTransferMultipleRequiredData(
            stateBeforeTransferMultiple.tos, stateBeforeTransferMultiple.amounts, depositAmount
        );

        // Fetch previous state
        _fetchMultipleBalances(stateBeforeTransferMultiple.previousBalances, stateBeforeTransferMultiple.tos);

        uint256 aliceBalanceBefore = yieldBox.balanceOf(users.alice, DAI_ASSET_ID);

        // Owner becomes operator
        _resetPrank(users.owner);

        // it should emit a `TransferSingle` event for each iteration
        _triggerMultipleExpectEmits({
            operator: users.owner,
            from: users.alice,
            tos: stateBeforeTransferMultiple.tos,
            amounts: stateBeforeTransferMultiple.amounts
        });

        // Try to transfer asset not registered in YieldBox.
        yieldBox.transferMultiple(
            users.alice,
            stateBeforeTransferMultiple.tos,
            DAI_ASSET_ID, // invalid asset ID
            stateBeforeTransferMultiple.amounts
        );

        // it should increment `balanceOf` each `to` by its respective `shares`
        _assertExpectedBalances(
            stateBeforeTransferMultiple.previousBalances,
            stateBeforeTransferMultiple.tos,
            stateBeforeTransferMultiple.amounts
        );

        // it should decrement `balanceOf` `from` by the total accumulated `_totalShares`
        assertEq(
            yieldBox.balanceOf(users.alice, DAI_ASSET_ID),
            aliceBalanceBefore - stateBeforeTransferMultiple.amounts[0] * 4 // all transferred amounts are equal
        );
    }

    /// @notice Tests the scenario where `_totalShares` is bigger than `balanceOf` `from` via approval for all.
    function test_transferMultipleWhen_ValueIsSmallerOrEqualToBalanceViaApprovedForAll(uint64 depositAmount)
        public
        assumeGtE(depositAmount, 5)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, 0, depositAmount)
        whenYieldBoxApprovedForAll(users.alice, users.owner)
    {
        StateBeforeTransferMultiple memory stateBeforeTransferMultiple;

        // Fill required data
        stateBeforeTransferMultiple.tos = new address[](4);
        stateBeforeTransferMultiple.amounts = new uint256[](4);
        stateBeforeTransferMultiple.previousBalances = new uint256[](4);

        // Build required data
        _buildTransferMultipleRequiredData(
            stateBeforeTransferMultiple.tos, stateBeforeTransferMultiple.amounts, depositAmount
        );

        // Fetch previous state
        _fetchMultipleBalances(stateBeforeTransferMultiple.previousBalances, stateBeforeTransferMultiple.tos);

        uint256 aliceBalanceBefore = yieldBox.balanceOf(users.alice, DAI_ASSET_ID);

        // Owner becomes operator
        _resetPrank(users.owner);

        // it should emit a `TransferSingle` event for each iteration
        _triggerMultipleExpectEmits({
            operator: users.owner,
            from: users.alice,
            tos: stateBeforeTransferMultiple.tos,
            amounts: stateBeforeTransferMultiple.amounts
        });

        // Try to transfer asset not registered in YieldBox.
        yieldBox.transferMultiple(
            users.alice,
            stateBeforeTransferMultiple.tos,
            DAI_ASSET_ID, // invalid asset ID
            stateBeforeTransferMultiple.amounts
        );

        // it should increment `balanceOf` each `to` by its respective `shares`
        _assertExpectedBalances(
            stateBeforeTransferMultiple.previousBalances,
            stateBeforeTransferMultiple.tos,
            stateBeforeTransferMultiple.amounts
        );

        // it should decrement `balanceOf` `from` by the total accumulated `_totalShares`
        assertEq(
            yieldBox.balanceOf(users.alice, DAI_ASSET_ID),
            aliceBalanceBefore - stateBeforeTransferMultiple.amounts[0] * 4 // all transferred amounts are equal
        );
    }
}
