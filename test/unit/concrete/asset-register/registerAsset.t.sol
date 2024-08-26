// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Setup
import {BaseTest} from "../../../Base.t.sol";

// Contracts
import {YieldBox, Pearlmit} from "contracts/YieldBox.sol";
import {YieldBoxRebase} from "contracts/YieldBoxRebase.sol";
import {TokenType} from "contracts/enums/YieldBoxTokenType.sol";
import {ERC721WithoutStrategy} from "contracts/strategies/ERC721WithoutStrategy.sol";
import {IYieldBox} from "contracts/interfaces/IYieldBox.sol";
import {IStrategy} from "contracts/interfaces/IStrategy.sol";
import {ERC20WithoutStrategy} from "contracts/strategies/ERC20WithoutStrategy.sol";
import {ERC721WithoutStrategy} from "contracts/strategies/ERC721WithoutStrategy.sol";

// Interfaces
import "contracts/interfaces/IWrappedNative.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

contract registerAsset is BaseTest {

    /////////////////////////////////////////////////////////////////////
    //                         STORAGE                                 //
    /////////////////////////////////////////////////////////////////////
    IStrategy daiStrategy;

    /////////////////////////////////////////////////////////////////////
    //                         SETUP                                   //
    /////////////////////////////////////////////////////////////////////

    function setUp() public override {
        super.setUp();

        // Deploy strategy
        ERC20WithoutStrategy strategy = new ERC20WithoutStrategy(
            IYieldBox(address(yieldBox)),
            IERC20(address(dai))
        );

        daiStrategy = IStrategy(address(strategy));
    }

    /////////////////////////////////////////////////////////////////////
    //                         TESTS                                   //
    /////////////////////////////////////////////////////////////////////

    /// @notice Tests the scenario where tokenType is NATIVE or NONE
    function test_registerAssetRevertWhen_TokenTypeIsNativeOrNone() public {
        // Try to set invalid type (Native).
        vm.expectRevert("AssetManager: cannot add Native");
        yieldBox.registerAsset(TokenType.Native, address(dai), daiStrategy, 0);

        // Try to set invalid type (None).
        vm.expectRevert("AssetManager: cannot add Native");
        yieldBox.registerAsset(TokenType.None, address(dai), daiStrategy, 0);
    }

    /// @notice Tests the scenario where tokenType is ERC20 and token ID is not set to zero.
    function test_registerAssetRevertWhen_ERC20WithNonZeroTokenId(
        uint256 tokenId
    ) public assumeNoZeroValue(tokenId) {
        // Try to set invalid token ID for ERC20.
        vm.expectRevert("YieldBox: No tokenId for ERC20");
        yieldBox.registerAsset(
            TokenType.ERC20,
            address(dai),
            daiStrategy,
            tokenId
        );
    }

    /// @notice Tests the scenario where strategy's tokenType differs from supplied token type
    function test_registerAssetRevertWhen_WrongStrategyTokenType() public {
        // Try to set invalid token type for the strategy
        vm.expectRevert("YieldBox: Strategy mismatch");
        yieldBox.registerAsset(
            TokenType.ERC721,
            address(dai),
            daiStrategy,
            1 // tokenId
        );
    }

    /// @notice Tests the scenario where strategy's contract address differs from supplied token address
    function test_registerAssetRevertWhen_WrongStrategyContractAddress()
        public
    {
        // Try to set invalid token type for the strategy
        vm.expectRevert("YieldBox: Strategy mismatch");
        yieldBox.registerAsset(
            TokenType.ERC20,
            makeAddr("random"), // random token to mistmatch with strategy
            daiStrategy,
            0
        );
    }

    /// @notice Tests the scenario where strategy's tokenId differs from supplied token ID
    function test_registerAssetRevertWhen_WrongStrategyTokenId(
        uint256 tokenIdStrategy,
        uint256 invalidTokenId
    ) public {
        // Assume different values
        vm.assume(tokenIdStrategy != invalidTokenId);

        // Deploy mock strategy for this specific scenario
        ERC721WithoutStrategy strategyERC721 = new ERC721WithoutStrategy(
            IYieldBox(address(yieldBox)),
            address(dai),
            tokenIdStrategy
        );
        // Try to set invalid token type for the strategy
        vm.expectRevert("YieldBox: Strategy mismatch");
        yieldBox.registerAsset(
            TokenType.ERC721,
            address(dai),
            daiStrategy,
            invalidTokenId // token Id
        );
    }

    /// @notice Tests the happy path scenario where all supplied data for new asset ID is valid.
    /// @dev Valid data includes:
    ///     - Valid TokenType
    ///     - Valid token contract address
    ///     - Valid strategy
    ///     - Valid token ID
    function test_registerAsset_ValidData() public {
        // Expect URI and AssetRegistered event to be triggered
        vm.expectEmit();
        emit URI("", 1); // exoected asset ID is 1

        vm.expectEmit();
        emit AssetRegistered(TokenType.ERC20, address(dai), daiStrategy, 0, 1);

        // Register new asset
        yieldBox.registerAsset(TokenType.ERC20, address(dai), daiStrategy, 0);

        // ensure `assets` has been updated with the proper data
        (
            TokenType tokenType,
            address contractAddress,
            IStrategy strategy,
            uint256 tokenId
        ) = yieldBox.assets(1);

        assertEq(uint256(tokenType), uint256(TokenType.ERC20));
        assertEq(contractAddress, address(dai));
        assertEq(address(strategy), address(daiStrategy));
        assertEq(tokenId, 0);

        // ensure `ids` has been pushed a new ID
        assertEq(yieldBox.assetCount(), 2);
        assertEq(
            yieldBox.ids(TokenType.ERC20, address(dai), daiStrategy, 0),
            1 // expected asset ID is 1 (0 is occupied by default)
        );
    }
}
