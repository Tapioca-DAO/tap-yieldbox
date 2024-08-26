// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {YieldBoxUnitConcreteTest} from "./YieldBox.t.sol";

contract setApprovalForAsset is YieldBoxUnitConcreteTest {

    /////////////////////////////////////////////////////////////////////
    //                          SETUP                                  //
    /////////////////////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();
    }

    /////////////////////////////////////////////////////////////////////
    //                         TESTS                                   //
    /////////////////////////////////////////////////////////////////////

    /// @notice Tests the scenario where `operator` is address(0)
    function test_setApprovalForAssetRevertWhen_OpeartorIsAddressZero() public {
        // Try to approve an invalid address.
        vm.expectRevert(NotSet.selector);
        yieldBox.setApprovalForAsset(address(0), DAI_ASSET_ID, true);
    }

    /// @notice Tests the scenario where `operator` is YieldBox address
    function test_setApprovalForAssetRevertWhen_OpeartorIsYieldBox() public {
        // Try to approve an invalid address.
        vm.expectRevert(ForbiddenAction.selector);
        yieldBox.setApprovalForAsset(address(yieldBox), DAI_ASSET_ID, true);
    }

    /// @notice Tests the scenario where assert ID is not valid
    function test_setApprovalForAssetRevertWhen_AssetIdIsInvalid(uint256 assetId) public {

        // ID's greater than USDT asset ID are not valid.
        vm.assume(assetId > USDT_ASSET_ID);

        // Try to approve an invalid asset ID.
        vm.expectRevert(AssetNotValid.selector);
        yieldBox.setApprovalForAsset(address(users.charlie), assetId, true);
    }

    /// @notice Tests the happy path scenario where oeprator is valid and set to a correct value.
    function test_setApprovalForAssetRevertWhen_AssetIdIsInvalid(address operator, bool value) public assumeNoZeroValue(uint256(uint160(operator))) {

        // Emit expected event
        vm.expectEmit();
        emit ApprovalForAsset(users.alice, operator, DAI_ASSET_ID, value);
        
        // Set approval
        yieldBox.setApprovalForAsset(operator, DAI_ASSET_ID, value);

        // Check new approval for all has been properly added. Other approved assets have NOT been modifier
        assertEq(yieldBox.isApprovedForAll(users.alice, operator), false);
        assertEq(yieldBox.isApprovedForAsset(users.alice, operator, DAI_ASSET_ID), value);

    }
   
}
