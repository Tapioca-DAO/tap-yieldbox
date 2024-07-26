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

contract depositAsset is YieldBoxUnitConcreteTest {
    /////////////////////////////////////////////////////////////////////
    //                         STRUCTS                                 //
    /////////////////////////////////////////////////////////////////////

    struct StateBeforeDeposit {
        uint256 totalShare;
        uint256 totalAmount;
        uint256 expectedShare;
        uint256 expectedAmount;
    }

    /////////////////////////////////////////////////////////////////////
    //                          SETUP                                  //
    /////////////////////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();
    } 

    /// @notice Tests the scenario where `from` is not allowed
    /// @dev `from not being allowed implies the following:
    ///     - `from` is different from `msg.sender`
    ///     - `from` has not approved `msg.sender` for the given asset ID
    ///     - `from` has not approved `msg.sender` for all assets
    function test_depositAssetRevertWhen_CallerIsNotAllowed() public {
        // Prank malicious user. No approvals have been performed.
        _resetPrank({msgSender: users.eve});

        // Try to deposit on behalf of impartial user
        vm.expectRevert("Transfer not allowed");
        yieldBox.depositAsset(
            1, // `assetId`
            users.alice, // `from`
            users.eve, // `to`
            1e18, // `amount`
            0 // `share`
        );
    }

    /// @notice Tests the scenario where asset is not registered in YieldBox
    function test_depositAssetRevertWhen_AssetIsNotRegistered() public {
        // Only assets with ID 1, 2 and 3 have been registered.
        // Try to deposit an asset not registered in YieldBox. For assets not existing in YieldBox, the expected error
        // is a panic (out-of-bounds) error. `expectRevert` does not include a custom way to handle such errors, so we
        // use an `expectRevert` without a reason.
        vm.expectRevert();
        yieldBox.depositAsset(
            4, // `assetId`
            users.alice, // `from`
            users.eve, // `to`
            1e18, // `amount`
            0 // `share`
        );

        // Asset with ID 0 is set as default in YieldBox, set with TokenType `None`. It can't be considered a valid asset.
        vm.expectRevert(InvalidTokenType.selector);
        yieldBox.depositAsset(
            0, // `assetId`
            users.alice, // `from`
            users.eve, // `to`
            1e18, // `amount`
            0 // `share`
        );
    }

    /// @notice Tests the scenario where asset is not an ERC1155 nor an ERC20
    function test_depositAssetRevertWhen_AssetIsNotERC1155NorERC20() public {
        // Create mock strategy
        ERC721WithoutStrategy erc721Strategy = new ERC721WithoutStrategy(
            IYieldBox(address(yieldBox)),
            address(dai), // mock,
            1
        );

        // Register assets with token type ERC721 and Native and try to deposit them

        // ERC721's arent't allowed
        uint256 erc721AssetId = yieldBox.registerAsset(
            TokenType.ERC721,
            address(dai),
            IStrategy(address(erc721Strategy)),
            1
        );

        vm.expectRevert(InvalidTokenType.selector);
        yieldBox.depositAsset(
            erc721AssetId, // `assetId`
            users.alice, // `from`
            users.eve, // `to`
            1e18, // `amount`
            0 // `share`
        );

        // Natives arent't allowed
        uint256 nativeAssetId = yieldBox.createToken("native", "nat", 18, "");
        vm.expectRevert(InvalidTokenType.selector);
        yieldBox.depositAsset(
            nativeAssetId, // `assetId`
            users.alice, // `from`
            users.eve, // `to`
            1e18, // `amount`
            0 // `share`
        );
    }

    /// @notice Tests the scenario where shares receiver is address(0)
    function test_depositAssetRevertWhen_ToIsAddressZero() public {
        vm.expectRevert("No 0 address");
        yieldBox.depositAsset(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            address(0), // `to`
            1e18, // `amount`
            0 // `share`
        );
    }

    /// @notice Tests the scenario where transfer is performed via pearlmit and pearlmit transfer fails
    /// @dev Precondition: Impartial user has approved the transfer via Pearlmit
    function test_depositAssetRevertWhen_PearlmitTransferFails()
        public
        whenApprovedViaPearlmit(
            users.alice,
            address(yieldBox),
            type(uint256).max,
            block.timestamp
        )
    {
        // Force pearlmit transfer failure by removing ERC20 (dai) approval from impartial user
        dai.approve(address(pearlmit), 0);

        // Pearlmit transfer must fail
        vm.expectRevert(PearlmitTransferFailed.selector);
        yieldBox.depositAsset(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.alice, // `to`
            1e18, // `amount`
            0 // `share`
        );
    }

    /// @notice Tests the scenario where transfer is performed directly via ERC20 and transfer fails
    function test_depositAssetRevertWhen_ERC20TransferFails() public {
        // Initial scenario where no approval is set to pearlmit (hence ERC20 transfer is performed).
        // Approval to yieldbox for the ERC20 is 0 by default, so transfer must fail by default unless an explicit approval is set.

        // ERC20 transfer must fail due to the lack of approval.
        vm.expectRevert("BoringERC20: TransferFrom failed");
        yieldBox.depositAsset(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.alice, // `to`
            1e18, // `amount`
            0 // `share`
        );
    }

    /// @notice Tests the scenario where the amount to deposit is 0
    /// @dev Precondition: Impartial user has approved the transfer via Pearlmit
    function test_depositAssetRevertWhen_ZeroDeposit()
        public
        whenApprovedViaPearlmit(
            users.alice,
            address(yieldBox),
            type(uint256).max,
            block.timestamp
        )
    {
        // ERC20 transfer must fail due to zero amount being deposited.
        vm.expectRevert(InvalidZeroAmounts.selector);
        yieldBox.depositAsset(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.alice, // `to`
            0, // `amount`
            0 // `share`
        );
    }

    /// @notice Tests happy path when depositing amount without approvals
    /// @dev Precondition: Impartial user has approved the transfer via Pearlmit
    function test_depositAsset_AmountGreaterThanZero(
        uint256 depositAmount
    )
        public
        whenApprovedViaPearlmit(
            users.alice,
            address(yieldBox),
            type(uint256).max,
            block.timestamp
        )
    {
        vm.assume(depositAmount > 0 && depositAmount <= LARGE_AMOUNT);

        StateBeforeDeposit memory stateBeforeDeposit;

        (
            stateBeforeDeposit.totalShare,
            stateBeforeDeposit.totalAmount
        ) = yieldBox.assetTotals(DAI_ASSET_ID);

        // Compute expected amount of shares
        stateBeforeDeposit.expectedShare = YieldBoxRebase._toShares({
            amount: depositAmount,
            totalShares_: stateBeforeDeposit.totalShare,
            totalAmount: stateBeforeDeposit.totalAmount,
            roundUp: false // it should round down
        });

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(
            users.alice,
            address(0),
            users.alice,
            DAI_ASSET_ID,
            stateBeforeDeposit.expectedShare
        );

        // It should emit a `Deposited` event
        vm.expectEmit();
        emit Deposited(
            users.alice,
            users.alice,
            users.alice,
            DAI_ASSET_ID,
            depositAmount,
            stateBeforeDeposit.expectedShare,
            0,
            0,
            false
        );
        // Perform 1 wei deposit specifying `amount`
        yieldBox.depositAsset(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.alice, // `to`
            depositAmount, // `amount`
            0 // `share`
        );

        // `balanceOf` of `to` should be incremented by `share`
        assertEq(
            yieldBox.balanceOf(users.alice, DAI_ASSET_ID),
            stateBeforeDeposit.expectedShare
        );

        // `totalSupply` should be incremented by `share`
        assertEq(
            yieldBox.totalSupply(DAI_ASSET_ID),
            stateBeforeDeposit.expectedShare
        );

        // `strategy`'s balance should be incremented by `amount`
        assertEq(dai.balanceOf(address(daiStrategy)), depositAmount);
    }

    /// @notice Tests happy path when depositing amount via an operator for a given asset ID
    /// @dev Precondition: Alice has approved the transfer via Pearlmit
    /// @dev Precondition: Alice has approved Bob for asset ID
    function test_depositAsset_AmountGreaterThanZeroViaApprovedAssetID(
        uint256 depositAmount
    )
        public
        whenApprovedViaPearlmit(
            users.alice,
            address(yieldBox),
            type(uint256).max,
            block.timestamp
        )
        whenYieldBoxApprovedForAssetID(users.alice, users.bob, DAI_ASSET_ID)
        resetPrank(users.bob)
    {
        vm.assume(depositAmount > 0 && depositAmount <= LARGE_AMOUNT);

        StateBeforeDeposit memory stateBeforeDeposit;

        (
            stateBeforeDeposit.totalShare,
            stateBeforeDeposit.totalAmount
        ) = yieldBox.assetTotals(DAI_ASSET_ID);

        // Compute expected amount of shares
        stateBeforeDeposit.expectedShare = YieldBoxRebase._toShares({
            amount: depositAmount,
            totalShares_: stateBeforeDeposit.totalShare,
            totalAmount: stateBeforeDeposit.totalAmount,
            roundUp: false // it should round down
        });

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(
            users.bob,
            address(0),
            users.bob,
            DAI_ASSET_ID,
            stateBeforeDeposit.expectedShare
        );

        // It should emit a `Deposited` event
        vm.expectEmit();
        emit Deposited(
            users.bob,
            users.alice,
            users.bob,
            DAI_ASSET_ID,
            depositAmount,
            stateBeforeDeposit.expectedShare,
            0,
            0,
            false
        );

        // Perform 1 wei deposit specifying `amount`
        yieldBox.depositAsset(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.bob, // `to`
            depositAmount, // `amount`
            0 // `share`
        );

        // `balanceOf` of `to` should be incremented by `share`
        assertEq(
            yieldBox.balanceOf(users.bob, DAI_ASSET_ID),
            stateBeforeDeposit.expectedShare
        );

        // `totalSupply` should be incremented by `share`
        assertEq(
            yieldBox.totalSupply(DAI_ASSET_ID),
            stateBeforeDeposit.expectedShare
        );

        // `strategy`'s balance should be incremented by `amount`
        assertEq(dai.balanceOf(address(daiStrategy)), depositAmount);
    }

    /// @notice Tests happy path when depositing amount via an operator for all
    /// @dev Precondition: Alice has approved the transfer via Pearlmit
    /// @dev Precondition: Alice has approved Bob for all
    function test_depositAsset_AmountGreaterThanZeroViaApprovedForAll(
        uint256 depositAmount
    )
        public
        whenApprovedViaPearlmit(
            users.alice,
            address(yieldBox),
            type(uint256).max,
            block.timestamp
        )
        whenYieldBoxApprovedForAll(users.alice, users.bob)
        resetPrank(users.bob)
    {
        vm.assume(depositAmount > 0 && depositAmount <= LARGE_AMOUNT);

        StateBeforeDeposit memory stateBeforeDeposit;

        (
            stateBeforeDeposit.totalShare,
            stateBeforeDeposit.totalAmount
        ) = yieldBox.assetTotals(DAI_ASSET_ID);

        // Compute expected amount of shares
        stateBeforeDeposit.expectedShare = YieldBoxRebase._toShares({
            amount: depositAmount,
            totalShares_: stateBeforeDeposit.totalShare,
            totalAmount: stateBeforeDeposit.totalAmount,
            roundUp: false // it should round down
        });

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(
            users.bob,
            address(0),
            users.bob,
            DAI_ASSET_ID,
            stateBeforeDeposit.expectedShare
        );

        // It should emit a `Deposited` event
        vm.expectEmit();
        emit Deposited(
            users.bob,
            users.alice,
            users.bob,
            DAI_ASSET_ID,
            depositAmount,
            stateBeforeDeposit.expectedShare,
            0,
            0,
            false
        );

        // Perform 1 wei deposit specifying `amount`
        yieldBox.depositAsset(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.bob, // `to`
            depositAmount, // `amount`
            0 // `share`
        );

        // `balanceOf` of `to` should be incremented by `share`
        assertEq(
            yieldBox.balanceOf(users.bob, DAI_ASSET_ID),
            stateBeforeDeposit.expectedShare
        );

        // `totalSupply` should be incremented by `share`
        assertEq(
            yieldBox.totalSupply(DAI_ASSET_ID),
            stateBeforeDeposit.expectedShare
        );

        // `strategy`'s balance should be incremented by `amount`
        assertEq(dai.balanceOf(address(daiStrategy)), depositAmount);
    }

    /// @notice Tests happy path when depositing shares
    /// @dev Precondition: Impartial user has approved the transfer via Pearlmit
    function test_depositAsset_SharesGreaterThanZero(
        uint256 depositShares
    )
        public
        whenApprovedViaPearlmit(
            users.alice,
            address(yieldBox),
            type(uint256).max,
            block.timestamp
        )
    {
        // Bound depositShares amount
        vm.assume(depositShares > 0 && depositShares <= LARGE_AMOUNT);

        StateBeforeDeposit memory stateBeforeDeposit;

        (
            stateBeforeDeposit.totalShare,
            stateBeforeDeposit.totalAmount
        ) = yieldBox.assetTotals(DAI_ASSET_ID);

        // Compute expected amount of asset
        stateBeforeDeposit.expectedAmount = YieldBoxRebase._toAmount({
            share: depositShares,
            totalShares_: stateBeforeDeposit.totalShare,
            totalAmount: stateBeforeDeposit.totalAmount,
            roundUp: true // it should round down
        });

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(
            users.alice,
            address(0),
            users.alice,
            DAI_ASSET_ID,
            depositShares
        );

        // It should emit a `Deposited` event
        vm.expectEmit();
        emit Deposited(
            users.alice,
            users.alice,
            users.alice,
            DAI_ASSET_ID,
            stateBeforeDeposit.expectedAmount,
            depositShares,
            0,
            0,
            false
        );

        // Perform 1 wei deposit specifying `shares`
        yieldBox.depositAsset(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.alice, // `to`
            0, // `amount`
            depositShares // `share`
        );

        // `balanceOf` of `to` should be incremented by `share`
        assertEq(yieldBox.balanceOf(users.alice, DAI_ASSET_ID), depositShares);

        // `totalSupply` should be incremented by `share`
        assertEq(yieldBox.totalSupply(DAI_ASSET_ID), depositShares);

        // `strategy`'s balance should be incremented by `amount`
        assertEq(
            dai.balanceOf(address(daiStrategy)),
            stateBeforeDeposit.expectedAmount
        );
    }

    /// @notice Tests happy path when depositing shares via an operator for a given asset ID
    /// @dev Precondition: Alice has approved the transfer via Pearlmit
    /// @dev Precondition: Alice has approved Bob for asset ID
    function test_depositAsset_SharesGreaterThanZeroViaApprovedAssetID(
        uint256 depositShares
    )
        public
        whenApprovedViaPearlmit(
            users.alice,
            address(yieldBox),
            type(uint256).max,
            block.timestamp
        )
        whenYieldBoxApprovedForAssetID(users.alice, users.bob, DAI_ASSET_ID)
        resetPrank(users.bob)
    {
        // Bound depositShares amount
        vm.assume(depositShares > 0 && depositShares <= LARGE_AMOUNT);

        StateBeforeDeposit memory stateBeforeDeposit;

        (
            stateBeforeDeposit.totalShare,
            stateBeforeDeposit.totalAmount
        ) = yieldBox.assetTotals(DAI_ASSET_ID);

        // Compute expected amount of asset
        stateBeforeDeposit.expectedAmount = YieldBoxRebase._toAmount({
            share: depositShares,
            totalShares_: stateBeforeDeposit.totalShare,
            totalAmount: stateBeforeDeposit.totalAmount,
            roundUp: true // it should round down
        });

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(
            users.bob,
            address(0),
            users.bob,
            DAI_ASSET_ID,
            depositShares
        );

        // It should emit a `Deposited` event
        vm.expectEmit();
        emit Deposited(
            users.bob,
            users.alice,
            users.bob,
            DAI_ASSET_ID,
            stateBeforeDeposit.expectedAmount,
            depositShares,
            0,
            0,
            false
        );

        // Perform 1 wei deposit specifying `shares`
        yieldBox.depositAsset(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.bob, // `to`
            0, // `amount`
            depositShares // `share`
        );

        // `balanceOf` of `to` should be incremented by `share`
        assertEq(yieldBox.balanceOf(users.bob, DAI_ASSET_ID), depositShares);

        // `totalSupply` should be incremented by `share`
        assertEq(yieldBox.totalSupply(DAI_ASSET_ID), depositShares);

        // `strategy`'s balance should be incremented by `amount`
        assertEq(
            dai.balanceOf(address(daiStrategy)),
            stateBeforeDeposit.expectedAmount
        );
    }

    /// @notice Tests happy path when depositing shares via an operator for all
    /// @dev Precondition: Alice has approved the transfer via Pearlmit
    /// @dev Precondition: Alice has approved Bob for all
    function test_depositAsset_SharesGreaterThanZeroViaApprovedForAll(
        uint256 depositShares
    )
        public
        whenApprovedViaPearlmit(
            users.alice,
            address(yieldBox),
            type(uint256).max,
            block.timestamp
        )
        whenYieldBoxApprovedForAll(users.alice, users.bob)
        resetPrank(users.bob)
    {
        // Bound depositShares amount
        vm.assume(depositShares > 0 && depositShares <= LARGE_AMOUNT);

        StateBeforeDeposit memory stateBeforeDeposit;

        (
            stateBeforeDeposit.totalShare,
            stateBeforeDeposit.totalAmount
        ) = yieldBox.assetTotals(DAI_ASSET_ID);

        // Compute expected amount of asset
        stateBeforeDeposit.expectedAmount = YieldBoxRebase._toAmount({
            share: depositShares,
            totalShares_: stateBeforeDeposit.totalShare,
            totalAmount: stateBeforeDeposit.totalAmount,
            roundUp: true // it should round down
        });

        // It should emit a `TransferSingle` event
        vm.expectEmit();
        emit TransferSingle(
            users.bob,
            address(0),
            users.bob,
            DAI_ASSET_ID,
            depositShares
        );

        // It should emit a `Deposited` event
        vm.expectEmit();
        emit Deposited(
            users.bob,
            users.alice,
            users.bob,
            DAI_ASSET_ID,
            stateBeforeDeposit.expectedAmount,
            depositShares,
            0,
            0,
            false
        );

        // Perform 1 wei deposit specifying `shares`
        yieldBox.depositAsset(
            DAI_ASSET_ID, // `assetId`
            users.alice, // `from`
            users.bob, // `to`
            0, // `amount`
            depositShares // `share`
        );

        // `balanceOf` of `to` should be incremented by `share`
        assertEq(yieldBox.balanceOf(users.bob, DAI_ASSET_ID), depositShares);

        // `totalSupply` should be incremented by `share`
        assertEq(yieldBox.totalSupply(DAI_ASSET_ID), depositShares);

        // `strategy`'s balance should be incremented by `amount`
        assertEq(
            dai.balanceOf(address(daiStrategy)),
            stateBeforeDeposit.expectedAmount
        );
    }
}
