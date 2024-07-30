// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Setup
import {YieldBoxUnitConcreteTest} from "../yieldbox/YieldBox.t.sol";

// Contracts
import {YieldBox} from "contracts/YieldBox.sol";
import {TokenType} from "contracts/enums/YieldBoxTokenType.sol";

// Interfaces
import {IStrategy} from "contracts/interfaces/IStrategy.sol";
import "contracts/interfaces/IWrappedNative.sol";

contract permit is YieldBoxUnitConcreteTest {
    /////////////////////////////////////////////////////////////////////
    //                          SETUP                                  //
    /////////////////////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();
    }

    /////////////////////////////////////////////////////////////////////
    //                         TESTS                                   //
    /////////////////////////////////////////////////////////////////////

    /// @notice Checks the scenario where `deadline` is smaller than `block.timestamp`
    function test_permitRevertWhen_DeadlineIsWrong(uint256 deadline) public {
        // Fast-forward time
        vm.warp(1 weeks);

        // Force incorrect deadline
        vm.assume(deadline < block.timestamp);

        // Alice signs data
        (uint8 v, bytes32 r, bytes32 s) = _signPermit({
            isForAssetId: true,
            isPermit: true,
            owner: users.alice,
            spender: users.bob,
            assetId: DAI_ASSET_ID,
            nonce: yieldBox.nonces(users.alice),
            deadline: deadline,
            privateKey: privateKeys.alicePK
        });

        // Trigger permit
        vm.expectRevert("YieldBoxPermit: expired deadline");
        yieldBox.permit(
            users.alice,
            users.bob,
            DAI_ASSET_ID,
            deadline,
            v,
            r,
            s
        );
    }

    /// @notice Checks the scenario where recovered signer is different from owner
    /// @dev Eve will sign, but Alice will be set as owner
    function test_permitRevertWhen_SignatureIsInvalid() public {
        // Eve signs data
        (uint8 v, bytes32 r, bytes32 s) = _signPermit({
            isForAssetId: true,
            isPermit: true,
            owner: users.alice, // signed by eve
            spender: users.bob,
            assetId: DAI_ASSET_ID,
            nonce: yieldBox.nonces(users.alice),
            deadline: block.timestamp,
            privateKey: privateKeys.evePK
        });

        // Trigger permit
        vm.expectRevert("YieldBoxPermit: invalid signature");
        yieldBox.permit(
            users.alice,
            users.bob,
            DAI_ASSET_ID,
            block.timestamp,
            v,
            r,
            s
        );
    }

    /// @notice Checks the scenario where asset ID is bigger or equal to asset count
    function test_permitRevertWhen_AssetIdIsInvalid(uint256 invalidID) public {
        // Assume ID is bigger or equal to asset count
        vm.assume(invalidID >= 4);

        // Sign data
        (uint8 v, bytes32 r, bytes32 s) = _signPermit({
            isForAssetId: true,
            isPermit: true,
            owner: users.alice,
            spender: users.bob,
            assetId: invalidID, // 4 total assets
            nonce: yieldBox.nonces(users.alice),
            deadline: block.timestamp,
            privateKey: privateKeys.alicePK
        });

        // Trigger permit
        vm.expectRevert(AssetNotValid.selector);
        yieldBox.permit(
            users.alice,
            users.bob,
            invalidID,
            block.timestamp,
            v,
            r,
            s
        );
    }

    /// @notice Checks the scenario where asset ID is valid
    /// @dev Transaction is triggered by a third-party user different from the signer.
    function test_permit_AssetIdIsValid() public {
        // Fetch nonce
        uint256 currentNonce = yieldBox.nonces(users.alice);

        // Sign data
        (uint8 v, bytes32 r, bytes32 s) = _signPermit({
            isForAssetId: true,
            isPermit: true,
            owner: users.alice,
            spender: users.bob,
            assetId: DAI_ASSET_ID,
            nonce: currentNonce,
            deadline: block.timestamp,
            privateKey: privateKeys.alicePK
        });

        // Check approval status before
        assertEq(
            yieldBox.isApprovedForAsset(users.alice, users.bob, DAI_ASSET_ID),
            false
        );

        // Switch sender
        _resetPrank(users.charlie);

        vm.expectEmit();
        emit ApprovalForAsset(users.alice, users.bob, DAI_ASSET_ID, true);

        // Trigger permit.
        yieldBox.permit(
            users.alice,
            users.bob,
            DAI_ASSET_ID,
            block.timestamp,
            v,
            r,
            s
        );

        // Ensure user is approved after transaction
        assertEq(
            yieldBox.isApprovedForAsset(users.alice, users.bob, DAI_ASSET_ID),
            true
        );

        // Ensure nonce is incremented
        assertEq(currentNonce + 1, yieldBox.nonces(users.alice));
    }
}
