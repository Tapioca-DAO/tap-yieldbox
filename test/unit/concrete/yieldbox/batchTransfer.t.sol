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

contract batchTransfer is YieldBoxUnitConcreteTest {
    /////////////////////////////////////////////////////////////////////
    //                          STRUCTS                                //
    /////////////////////////////////////////////////////////////////////
    struct StateBeforeBatchTransfer {
        uint256[] assetIds;
        uint256[] amounts;
        uint256[] previousBalances;
    }

    /////////////////////////////////////////////////////////////////////
    //                          INTERNAL HELPERS                       //
    /////////////////////////////////////////////////////////////////////
    function _buildBatchTransferRequiredData(
        uint256[] memory assetIds,
        uint256[] memory amounts,
        uint256 amount
    ) internal view returns (address[] memory, uint256[] memory) {
        // Build array of asset Id's
        assetIds[0] = DAI_ASSET_ID;
        assetIds[1] = WRAPPED_NATIVE_ASSET_ID;
        assetIds[2] = USDT_ASSET_ID;

        // Build array of `amounts`
        amounts[0] = amount / 3;
        amounts[1] = amount / 3;
        amounts[2] = amount / 3;
    }

    function _assertExpectedBalances(
        uint256[] memory previousBalances,
        address to,
        uint256[] memory amounts,
        bool positive
    ) internal view returns (address[] memory, uint256[] memory) {
        for (uint256 i = 0; i < 3; i++) {
            assertEq(
                yieldBox.balanceOf(to, i + 1), // assetId is represented by i + 1
                positive
                    ? previousBalances[i] + amounts[i]
                    : previousBalances[i] - amounts[i]
            );
        }
    }

    function _fetchMultipleBalances(
        uint256[] memory previousBalances,
        address to
    ) internal view returns (uint256[] memory) {
        for (uint256 i; i < 3; i++) {
            previousBalances[i] = yieldBox.balanceOf(to, i + 1);
        }
    }

    function _triggerExpectEmit(
        address operator,
        address from,
        address to,
        uint256[] memory amounts
    ) internal {
        uint256[] memory ids = new uint256[](3);
        ids[0] = DAI_ASSET_ID;
        ids[1] = WRAPPED_NATIVE_ASSET_ID;
        ids[2] = USDT_ASSET_ID;
        vm.expectEmit();
        emit TransferBatch(operator, from, to, ids, amounts);
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

    /// @notice Tests the scenario where `from` is not allowed to batchTransfer.
    /// @dev `from not being allowed implies the following:
    ///     - `from` is different from `msg.sender`
    ///     - `from` has not approved `msg.sender` for the given asset ID's
    function test_batchTransferRevertWhen_CallerIsNotAllowed(
        uint64 depositAmount
    )
        public
        assumeGtE(depositAmount, 3)
        whenDepositedAll(users.alice, users.alice, 0, depositAmount)
    {
        // Prank malicious user. No approvals have been performed.
        _resetPrank({msgSender: users.eve});

        // Initialize required data
        StateBeforeBatchTransfer memory stateBeforeBatchTransfer;
        stateBeforeBatchTransfer.assetIds = new uint256[](3);
        stateBeforeBatchTransfer.amounts = new uint256[](3);

        _buildBatchTransferRequiredData(
            stateBeforeBatchTransfer.assetIds,
            stateBeforeBatchTransfer.amounts,
            depositAmount
        );

        // Try to transfer assets on behalf of impartial user
        vm.expectRevert("Transfer not allowed");
        yieldBox.batchTransfer(
            users.alice,
            users.bob,
            stateBeforeBatchTransfer.assetIds,
            stateBeforeBatchTransfer.amounts
        );
    }

    /// @notice Tests the scenario where one of `assetId`'s is not registered
    function test_batchTransferRevertWhen_AssetIdNotRegistered(
        uint64 depositAmount,
        uint16 rand
    ) public assumeGtE(depositAmount, 3) {
        // Initialize required data
        StateBeforeBatchTransfer memory stateBeforeBatchTransfer;
        stateBeforeBatchTransfer.assetIds = new uint256[](3);
        stateBeforeBatchTransfer.amounts = new uint256[](3);

        _buildBatchTransferRequiredData(
            stateBeforeBatchTransfer.assetIds,
            stateBeforeBatchTransfer.amounts,
            depositAmount
        );

        // Force one of assetId's to be unsupported
        stateBeforeBatchTransfer.assetIds[rand % 3] = 5; // 5 as assetId is unsupported

        // Try to transfer invalid asset ID.
        vm.expectRevert();
        yieldBox.batchTransfer(
            users.alice,
            users.bob,
            stateBeforeBatchTransfer.assetIds,
            stateBeforeBatchTransfer.amounts
        );
    }

    /// @notice Tests the scenario where `to` is address(0)
    function test_batchTransferRevertWhen_ToIsZeroAddress(
        uint64 depositAmount
    ) public assumeGtE(depositAmount, 3) {
        // Initialize required data
        StateBeforeBatchTransfer memory stateBeforeBatchTransfer;
        stateBeforeBatchTransfer.assetIds = new uint256[](3);
        stateBeforeBatchTransfer.amounts = new uint256[](3);

        _buildBatchTransferRequiredData(
            stateBeforeBatchTransfer.assetIds,
            stateBeforeBatchTransfer.amounts,
            depositAmount
        );

        // Try to transfer to address(0)
        vm.expectRevert(ZeroAddress.selector);
        yieldBox.batchTransfer(
            users.alice,
            address(0),
            stateBeforeBatchTransfer.assetIds,
            stateBeforeBatchTransfer.amounts
        );
    }

    /// @notice Tests the scenario where shares exceeds `from` balance
    function test_batchTransferRevertWhen_SharesExceedsBalance(
        uint64 depositAmount,
        uint16 rand
    )
        public
        assumeGtE(depositAmount, 3)
        whenDepositedAll(users.alice, users.alice, 0, depositAmount)
    {
        // Initialize required data
        StateBeforeBatchTransfer memory stateBeforeBatchTransfer;
        stateBeforeBatchTransfer.assetIds = new uint256[](3);
        stateBeforeBatchTransfer.amounts = new uint256[](3);

        _buildBatchTransferRequiredData(
            stateBeforeBatchTransfer.assetIds,
            stateBeforeBatchTransfer.amounts,
            depositAmount
        );

        // Force one of amounts to exceed balance be unsupported
        stateBeforeBatchTransfer.amounts[rand % 3] = uint256(depositAmount) + 1;

        // Try to transfer more assets than held.
        vm.expectRevert();
        yieldBox.batchTransfer(
            users.alice,
            users.bob,
            stateBeforeBatchTransfer.assetIds,
            stateBeforeBatchTransfer.amounts
        );
    }

    /// @notice Tests the scenario where shares are smaller or equal to `from` balance
    function test_batchTransfer_whenValueIsSmallerOrEqualToBalance(
        uint64 depositAmount
    )
        public
        assumeGtE(depositAmount, 3)
        whenDepositedAll(users.alice, users.alice, 0, depositAmount)
    {
        // Initialize required data
        StateBeforeBatchTransfer memory stateBeforeBatchTransferBob;
        stateBeforeBatchTransferBob.assetIds = new uint256[](3);
        stateBeforeBatchTransferBob.amounts = new uint256[](3);
        stateBeforeBatchTransferBob.previousBalances = new uint256[](3);

        StateBeforeBatchTransfer memory stateBeforeBatchTransferAlice;
        stateBeforeBatchTransferAlice.assetIds = new uint256[](3);
        stateBeforeBatchTransferAlice.amounts = new uint256[](3);
        stateBeforeBatchTransferAlice.previousBalances = new uint256[](3);

        _buildBatchTransferRequiredData(
            stateBeforeBatchTransferBob.assetIds,
            stateBeforeBatchTransferBob.amounts,
            depositAmount
        );

        // Fetch previous balances
        _fetchMultipleBalances(
            stateBeforeBatchTransferBob.previousBalances,
            users.bob
        );

        _fetchMultipleBalances(
            stateBeforeBatchTransferAlice.previousBalances,
            users.alice
        );

        // it should emit a `TransferBatch` event for each iteration
        _triggerExpectEmit({
            operator: users.alice,
            from: users.alice,
            to: users.bob,
            amounts: stateBeforeBatchTransferBob.amounts
        });

        // Transfer assets
        yieldBox.batchTransfer(
            users.alice,
            users.bob,
            stateBeforeBatchTransferBob.assetIds,
            stateBeforeBatchTransferBob.amounts
        );

        // it should increment `balanceOf` each assed ID by its respective `shares`
        _assertExpectedBalances(
            stateBeforeBatchTransferBob.previousBalances,
            users.bob,
            stateBeforeBatchTransferBob.amounts,
            true
        );

        // it should decrement `balanceOf` `from` by the total accumulated `_totalShares`
        _assertExpectedBalances(
            stateBeforeBatchTransferAlice.previousBalances,
            users.alice,
            stateBeforeBatchTransferBob.amounts,
            false
        );
    }

    /// @notice Tests the scenario where shares are smaller or equal to `from` balance via approval by asset ID
    function test_batchTransfer_whenValueIsSmallerOrEqualToBalanceViaApprovedForAssetId(
        uint64 depositAmount
    )
        public
        assumeGtE(depositAmount, 3)
        whenDepositedAll(users.alice, users.alice, 0, depositAmount)
        whenYieldBoxApprovedForMultipleAssetIDs(users.alice, users.owner)
    {
        // Initialize required data
        StateBeforeBatchTransfer memory stateBeforeBatchTransferBob;
        stateBeforeBatchTransferBob.assetIds = new uint256[](3);
        stateBeforeBatchTransferBob.amounts = new uint256[](3);
        stateBeforeBatchTransferBob.previousBalances = new uint256[](3);

        StateBeforeBatchTransfer memory stateBeforeBatchTransferAlice;
        stateBeforeBatchTransferAlice.assetIds = new uint256[](3);
        stateBeforeBatchTransferAlice.amounts = new uint256[](3);
        stateBeforeBatchTransferAlice.previousBalances = new uint256[](3);

        _buildBatchTransferRequiredData(
            stateBeforeBatchTransferBob.assetIds,
            stateBeforeBatchTransferBob.amounts,
            depositAmount
        );

        // Fetch previous balances
        _fetchMultipleBalances(
            stateBeforeBatchTransferBob.previousBalances,
            users.bob
        );

        _fetchMultipleBalances(
            stateBeforeBatchTransferAlice.previousBalances,
            users.alice
        );

        // Owner becomes operator
        _resetPrank(users.owner);

        // it should emit a `TransferBatch` event for each iteration
        _triggerExpectEmit({
            operator: users.owner,
            from: users.alice,
            to: users.bob,
            amounts: stateBeforeBatchTransferBob.amounts
        });

        // Transfer assets
        yieldBox.batchTransfer(
            users.alice,
            users.bob,
            stateBeforeBatchTransferBob.assetIds,
            stateBeforeBatchTransferBob.amounts
        );

        // it should increment `balanceOf` each assed ID by its respective `shares`
        _assertExpectedBalances(
            stateBeforeBatchTransferBob.previousBalances,
            users.bob,
            stateBeforeBatchTransferBob.amounts,
            true
        );

        // it should decrement `balanceOf` `from` by the total accumulated `_totalShares`
        _assertExpectedBalances(
            stateBeforeBatchTransferAlice.previousBalances,
            users.alice,
            stateBeforeBatchTransferBob.amounts,
            false
        );
    }
}
