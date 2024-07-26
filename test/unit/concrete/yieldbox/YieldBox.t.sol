// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Utilities
import {BaseTest} from "../../../Base.t.sol";

import {TokenType} from "contracts/enums/YieldBoxTokenType.sol";
import {ERC20WithoutStrategy} from "contracts/strategies/ERC20WithoutStrategy.sol";
import {IYieldBox} from "contracts/interfaces/IYieldBox.sol";
import {IStrategy} from "contracts/interfaces/IStrategy.sol";

import {IERC20} from "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

contract YieldBoxUnitConcreteTest is BaseTest {
    /////////////////////////////////////////////////////////////////////
    //                         STORAGE                                 //
    /////////////////////////////////////////////////////////////////////

    // Asset ID's
    uint256 public DAI_ASSET_ID;
    uint256 public WRAPPED_NATIVE_ASSET_ID;
    uint256 public USDT_ASSET_ID;

    // Strategies
    ERC20WithoutStrategy daiStrategy;
    ERC20WithoutStrategy wrappedNativeStrategy;
    ERC20WithoutStrategy usdtStrategy;

    /////////////////////////////////////////////////////////////////////
    //                      YIELDBOX CUSTOM SETUP                      //
    /////////////////////////////////////////////////////////////////////

    function setUp() public virtual override {
        super.setUp();

        // Create strategies
        daiStrategy = new ERC20WithoutStrategy(
            IYieldBox(address(yieldBox)),
            IERC20(address(dai))
        );
        wrappedNativeStrategy = new ERC20WithoutStrategy(
            IYieldBox(address(yieldBox)),
            IERC20(address(wrappedNative))
        );
        usdtStrategy = new ERC20WithoutStrategy(
            IYieldBox(address(yieldBox)),
            IERC20(address(usdt))
        );

        // Register assets in YieldBox

        // Register DAI
        DAI_ASSET_ID = yieldBox.registerAsset(
            TokenType.ERC20,
            address(dai),
            IStrategy(address(daiStrategy)),
            0 // `tokenId` is 0 for ERC20 assets
        );

        // Register Wrapped native
        WRAPPED_NATIVE_ASSET_ID = yieldBox.registerAsset(
            TokenType.ERC20,
            address(wrappedNative),
            IStrategy(address(wrappedNativeStrategy)),
            0
        );

        // Register USDT
        USDT_ASSET_ID = yieldBox.registerAsset(
            TokenType.ERC20,
            address(usdt),
            IStrategy(address(usdtStrategy)),
            0
        );

        // Prank impartial user
        _resetPrank({msgSender: users.alice});
    }

    /////////////////////////////////////////////////////////////////////
    //                           MODIFIERS                             //
    /////////////////////////////////////////////////////////////////////

    modifier whenDeposited(
        uint256 _assetId,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _share
    ) {
        _whenDeposited({
            assetId: _assetId,
            from: _from,
            to: _to,
            amount: _amount,
            share: _share
        });
        _;
    }

    modifier whenDepositedAll(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _share
    ) {
        for (uint256 assetID = 1; assetID <= 3; assetID++) {
            _whenDeposited({
                assetId: assetID,
                from: _from,
                to: _to,
                amount: _amount,
                share: _share
            });
        }

        _;
    }

    modifier simulateYieldBoxDeposits(
        uint256 _assetId,
        uint256 _amount,
        uint256 _share
    ) {
        _simulateYieldBoxDeposits({
            assetId: _assetId,
            amount: _amount,
            share: _share
        });
        // Reset prank to default impartial user
        _resetPrank(users.alice);
        _;
    }

    /////////////////////////////////////////////////////////////////////
    //                       INTERNAL HELPERS                          //
    /////////////////////////////////////////////////////////////////////
    function _whenDeposited(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) internal {
        // Approve yieldBox to transfer `from` assets
        _approveViaPearlmit({
            from: from,
            operator: address(yieldBox),
            amount: amount == 0 ? share : amount,
            expiration: type(uint48).max
        });

        // Deposit assets in YieldBox
        yieldBox.depositAsset({
            assetId: assetId,
            from: from,
            to: to,
            amount: amount,
            share: share
        });
    }

    function _simulateYieldBoxDeposits(
        uint256 assetId,
        uint256 amount,
        uint256 share
    ) internal {
        // Skip alice address
        for (uint i = 1; i < userAddresses.length; i++) {
            _whenDeposited({
                assetId: assetId,
                from: userAddresses[i],
                to: userAddresses[i],
                amount: amount,
                share: share
            });
        }
    }
}
