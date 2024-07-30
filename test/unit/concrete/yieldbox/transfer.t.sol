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

contract transfer is YieldBoxUnitConcreteTest {

    /////////////////////////////////////////////////////////////////////
    //                          STRUCT                                 //
    /////////////////////////////////////////////////////////////////////
    struct StateBeforeTransfer {
        uint256 aliceBalanceBeforeTransfer;
        uint256 bobBalanceBeforeTransfer;
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

    /// @notice Tests the scenario where `from` is not allowed to transfer.
    /// @dev `from not being allowed implies the following:
    ///     - `from` is different from `msg.sender`
    ///     - `from` has not approved `msg.sender` for the given asset ID
    ///     - `from` has not approved `msg.sender` for all assets
    function test_transferRevertWhen_CallerIsNotAllowed()
        public
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, MEDIUM_AMOUNT, 0)
    {
        uint256 balanceOfAfterDeposit = yieldBox.balanceOf(
            users.alice,
            DAI_ASSET_ID
        );

        // Prank malicious user. No approvals have been performed.
        _resetPrank({msgSender: users.eve});

        // Try to transfer assets on behalf of impartial user
        vm.expectRevert("Transfer not allowed");
        yieldBox.transfer(
            users.alice,
            users.eve,
            DAI_ASSET_ID,
            balanceOfAfterDeposit
        );
    }

    /// @notice Tests the scenario where `asset`is not registered in YieldBox.
    /// @dev Trying to transfer assets not registered relies on users not being able to have a positive balance of
    /// an asset that still has not been added to the protocol. Hence, zero-value transfers of non-registered assets
    /// are still allowed, although behave as a no-op.
    function test_transferRevertWhen_AssetIsNotRegistered(
        uint256 transferAmount
    ) public assumeNoZeroValue(transferAmount) {
        // Try to transfer asset not registered in YieldBox.
        vm.expectRevert();
        yieldBox.transfer(users.alice, users.bob, 5, transferAmount);
    }

    /// @notice Tests the scenario where `to` is address(0)
    function test_transferRevertWhen_ToIsZeroAddress(
        uint64 depositAmount
    )
        public
        assumeNoZeroValue(depositAmount)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, depositAmount, 0)
    {
        uint256 balanceOfAfterDeposit = yieldBox.balanceOf(
            users.alice,
            DAI_ASSET_ID
        );

        // Try to transfer assets to address(0)
        vm.expectRevert("No 0 address");
        yieldBox.transfer(
            users.alice,
            address(0),
            DAI_ASSET_ID,
            balanceOfAfterDeposit
        );
    }

    /// @notice Tests the scenario where amount transferred exceeds balance.
    function test_transferRevertWhen_ValueIsGreaterThanBalance(
        uint64 depositAmount,
        uint16 addition
    )
        public
        assumeNoZeroValue(addition)
        assumeNoZeroValue(depositAmount)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, depositAmount, 0)
    {
        uint256 balanceOfAfterDeposit = yieldBox.balanceOf(
            users.alice,
            DAI_ASSET_ID
        );

        // Try to transfer more assets than held. The expected error
        // is a panic (underflow) error. `expectRevert` does not include a custom way to handle such errors, so we
        // use an `expectRevert` without a reason.
        vm.expectRevert();
        yieldBox.transfer(
            users.alice,
            users.alice,
            DAI_ASSET_ID,
            balanceOfAfterDeposit + uint256(addition)
        );
    }

    /// @notice Tests the scenario where amount transferred exceeds balance, on behalf of shares owner, by approving asset.
    function test_transferRevertWhen_ValueIsGreaterThanBalanceWhenApprovedForAssetID(
        uint32 depositAmount
    )
        public
        assumeNoZeroValue(depositAmount)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, depositAmount, 0)
        whenYieldBoxApprovedForAssetID(users.alice, users.bob, DAI_ASSET_ID)
    { 
        {
            uint256 balanceOfAfterDeposit = yieldBox.balanceOf(
                users.alice,
                DAI_ASSET_ID
            );

            // PRank different user
            _resetPrank(users.bob);

            // Try to transfer more assets than held. The expected error
            // is a panic (underflow) error. `expectRevert` does not include a custom way to handle such errors, so we
            // use an `expectRevert` without a reason.
            vm.expectRevert();
            yieldBox.transfer(
                users.alice,
                users.bob,
                DAI_ASSET_ID,
                balanceOfAfterDeposit + 1
            );
        }
    }

    /// @notice Tests the scenario where amount transferred exceeds balance, on behalf of shares owner by approving all.
    function test_transferRevertWhen_ValueIsGreaterThanBalanceWhenApprovedForAll(
        uint32 depositAmount
    )
        public
        assumeNoZeroValue(depositAmount)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, depositAmount, 0)
        whenYieldBoxApprovedForAll(users.alice, users.bob)
    { 
        {
            uint256 balanceOfAfterDeposit = yieldBox.balanceOf(
                users.alice,
                DAI_ASSET_ID
            );

            // PRank different user
            _resetPrank(users.bob);

            // Try to transfer more assets than held. The expected error
            // is a panic (underflow) error. `expectRevert` does not include a custom way to handle such errors, so we
            // use an `expectRevert` without a reason.
            vm.expectRevert();
            yieldBox.transfer(
                users.alice,
                users.bob,
                DAI_ASSET_ID,
                balanceOfAfterDeposit + 1
            );
        }
    }

    /// @notice Tests the happy path, where amount transferred is smaller or equal to share balance.
    function test_transferWhen_ValueIsSmallerOrEqualToBalance(
        uint64 depositAmount,
        uint64 transferAmount
    )
        public
        assumeNoZeroValue(depositAmount)
        assumeNoZeroValue(transferAmount)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, 0, depositAmount)
    {
        
        // Ensure amount to transfer is valid.
        vm.assume(transferAmount <= depositAmount);

        // Fetch previous balances
        StateBeforeTransfer memory stateBeforeTransfer;

        stateBeforeTransfer.aliceBalanceBeforeTransfer = yieldBox.balanceOf(users.alice, DAI_ASSET_ID);
        stateBeforeTransfer.bobBalanceBeforeTransfer = yieldBox.balanceOf(users.bob, DAI_ASSET_ID);

        // It should emit `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(users.alice, users.alice, users.bob, DAI_ASSET_ID, transferAmount);

        // Transfer assets.
        yieldBox.transfer(
            users.alice,
            users.bob,
            DAI_ASSET_ID,
            transferAmount
        );

        // It should decrement `balanceOf` `from` by `value`
        assertEq(yieldBox.balanceOf(users.alice, DAI_ASSET_ID), stateBeforeTransfer.aliceBalanceBeforeTransfer - transferAmount);

        // It should increment `balanceOf` `to` by `value`
        assertEq(yieldBox.balanceOf(users.bob, DAI_ASSET_ID), stateBeforeTransfer.bobBalanceBeforeTransfer + transferAmount);
    }

    /// @notice Tests the happy path, where amount transferred is smaller or equal to share balance via asset ID approval.
    /// @dev Operator is set to `users.charlie`.
    function test_transferWhen_ValueIsSmallerOrEqualToBalanceWhenApprovedForAssetID(
        uint64 transferAmount
    )
        public
        assumeNoZeroValue(transferAmount)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, 0, MEDIUM_AMOUNT)
        whenYieldBoxApprovedForAssetID(users.alice, users.charlie, DAI_ASSET_ID)
    {
        // Set operator
        _resetPrank(users.charlie);


        // Ensure amount to transfer is valid.
        vm.assume(transferAmount <= MEDIUM_AMOUNT);

        // Fetch previous balances
        StateBeforeTransfer memory stateBeforeTransfer;

        stateBeforeTransfer.aliceBalanceBeforeTransfer = yieldBox.balanceOf(users.alice, DAI_ASSET_ID);
        stateBeforeTransfer.bobBalanceBeforeTransfer = yieldBox.balanceOf(users.bob, DAI_ASSET_ID);

        // It should emit `TransferSingle` event. Operator is set to Charlie.
        vm.expectEmit();
        emit TransferSingle(users.charlie, users.alice, users.bob, DAI_ASSET_ID, transferAmount);

        // Transfer assets.
        yieldBox.transfer(
            users.alice,
            users.bob,
            DAI_ASSET_ID,
            transferAmount
        );

        // It should decrement `balanceOf` `from` by `value`
        assertEq(yieldBox.balanceOf(users.alice, DAI_ASSET_ID), stateBeforeTransfer.aliceBalanceBeforeTransfer - transferAmount);

        // It should increment `balanceOf` `to` by `value`
        assertEq(yieldBox.balanceOf(users.bob, DAI_ASSET_ID), stateBeforeTransfer.bobBalanceBeforeTransfer + transferAmount);
    }

    /// @notice Tests the happy path, where amount transferred is smaller or equal to share balance via all approval.
    /// @dev Operator is set to `users.charlie`.
    function test_transferWhen_ValueIsSmallerOrEqualToBalanceWhenApprovedForAll(
        uint64 transferAmount
    )
        public
        assumeNoZeroValue(transferAmount)
        whenDeposited(DAI_ASSET_ID, users.alice, users.alice, 0, MEDIUM_AMOUNT)
        whenYieldBoxApprovedForAll(users.alice, users.charlie)
    {
        // Set operator
        _resetPrank(users.charlie);

        // Ensure amount to transfer is valid.
        vm.assume(transferAmount <= MEDIUM_AMOUNT);

        // Fetch previous balances
        StateBeforeTransfer memory stateBeforeTransfer;

        stateBeforeTransfer.aliceBalanceBeforeTransfer = yieldBox.balanceOf(users.alice, DAI_ASSET_ID);
        stateBeforeTransfer.bobBalanceBeforeTransfer = yieldBox.balanceOf(users.bob, DAI_ASSET_ID);

        // It should emit `TransferSingle` event. Operator is set to Charlie.
        vm.expectEmit();
        emit TransferSingle(users.charlie, users.alice, users.bob, DAI_ASSET_ID, transferAmount);

        // Transfer assets.
        yieldBox.transfer(
            users.alice,
            users.bob,
            DAI_ASSET_ID,
            transferAmount
        );

        // It should decrement `balanceOf` `from` by `value`
        assertEq(yieldBox.balanceOf(users.alice, DAI_ASSET_ID), stateBeforeTransfer.aliceBalanceBeforeTransfer - transferAmount);

        // It should increment `balanceOf` `to` by `value`
        assertEq(yieldBox.balanceOf(users.bob, DAI_ASSET_ID), stateBeforeTransfer.bobBalanceBeforeTransfer + transferAmount);
    }
}
