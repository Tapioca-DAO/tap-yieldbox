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

contract revokeAll is YieldBoxUnitConcreteTest {
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
    function test_revokeAllRevertWhen_DeadlineIsWrong(uint256 deadline) public {
        // Fast-forward time
        vm.warp(1 weeks);

        // Force incorrect deadline
        vm.assume(deadline < block.timestamp);

        // Alice signs data
        (uint8 v, bytes32 r, bytes32 s) = _signPermit({
            isForAssetId: false,
            isPermit: false,
            owner: users.alice,
            spender: users.bob,
            assetId: 0, // not relevant in approval for alls.
            nonce: yieldBox.nonces(users.alice),
            deadline: deadline,
            privateKey: privateKeys.alicePK
        });

        // Trigger revokeAll
        vm.expectRevert("YieldBoxPermit: expired deadline");
        yieldBox.revokeAll(users.alice, users.bob, deadline, v, r, s);
    }

    /// @notice Checks the scenario where recovered signer is different from owner
    /// @dev Eve will sign, but Alice will be set as owner
    function test_revokeAllRevertWhen_SignatureIsInvalid() public {
        // Eve signs data
        (uint8 v, bytes32 r, bytes32 s) = _signPermit({
            isForAssetId: false,
            isPermit: false,
            owner: users.alice, // signed by eve
            spender: users.bob,
            assetId: 0, // not relevant in approval for alls.
            nonce: yieldBox.nonces(users.alice),
            deadline: block.timestamp,
            privateKey: privateKeys.evePK
        });

        // Trigger revokeAll.
        vm.expectRevert("YieldBoxPermit: invalid signature");
        yieldBox.revokeAll(users.alice, users.bob, block.timestamp, v, r, s);
    }

    /// @notice Checks the scenario where parameters passed are valid
    /// @dev Transaction is triggered by a third-party user different from the signer.
    function test_revokeAll_ValidExecution() public whenYieldBoxApprovedForAll(users.alice, users.bob) {
        // Fetch nonce
        uint256 currentNonce = yieldBox.nonces(users.alice);

        // Sign data
        (uint8 v, bytes32 r, bytes32 s) = _signPermit({
            isForAssetId: false,
            isPermit: false,
            owner: users.alice,
            spender: users.bob,
            assetId: 0, // not relevant in approval for alls.
            nonce: currentNonce,
            deadline: block.timestamp,
            privateKey: privateKeys.alicePK
        });

        // Check approval status before
        assertEq(yieldBox.isApprovedForAll(users.alice, users.bob), true);

        // Switch sender
        _resetPrank(users.charlie);

        vm.expectEmit();
        emit ApprovalForAll(users.alice, users.bob, false);

        // Trigger revokeAll.
        yieldBox.revokeAll(users.alice, users.bob, block.timestamp, v, r, s);

        // Ensure user is **NOT** approved after transaction
        assertEq(yieldBox.isApprovedForAll(users.alice, users.bob), false);

        // Ensure nonce is incremented
        assertEq(currentNonce + 1, yieldBox.nonces(users.alice));
    }
}
