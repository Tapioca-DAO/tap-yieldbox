// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

import {ERC20WithoutStrategy} from "yieldbox/strategies/ERC20WithoutStrategy.sol";
import {IWrappedNative} from "yieldbox/interfaces/IWrappedNative.sol";
import {YieldBoxURIBuilder} from "yieldbox/YieldBoxURIBuilder.sol";
import {TokenType} from "yieldbox/enums/YieldBoxTokenType.sol";
import {Pearlmit} from "tapioca-periph/pearlmit/Pearlmit.sol";
import {IYieldBox} from "yieldbox/interfaces/IYieldBox.sol";
import {IStrategy} from "yieldbox/interfaces/IStrategy.sol";
import {YieldBox} from "yieldbox/YieldBox.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";

contract YieldBoxTest {

    ERC20Mock weth;
    YieldBox yieldBox;
    Pearlmit pearlmit;

    function createErc20Mock() public returns (ERC20Mock) {
        return new ERC20Mock();
    }

    function createPearlmit() public returns (Pearlmit) {
        return new Pearlmit("Test", "1", address(this), 0);
    }

    function createYieldBox(address _weth, address _pearlmit) public returns (YieldBox) {
        YieldBoxURIBuilder ybUri = new YieldBoxURIBuilder();
        return new YieldBox(IWrappedNative(_weth), ybUri, Pearlmit(_pearlmit), address(this));
    }

    function registerAsset(address _yieldBox, address _asset) public returns (uint256) {
        ERC20WithoutStrategy assetStrategy = new ERC20WithoutStrategy(IYieldBox(_yieldBox), IERC20(_asset));
        return YieldBox(_yieldBox).registerAsset(TokenType.ERC20, _asset, IStrategy(address(assetStrategy)), 0);
    }

    function setUp() public { 
        weth = createErc20Mock();
        pearlmit = createPearlmit();
        yieldBox = createYieldBox(address(weth), address(pearlmit));
    }

    function testDepositUsingPearlmit() public {
        setUp();
        
        ERC20Mock asset = createErc20Mock();
        uint256 assetId = registerAsset(address(yieldBox), address(asset));
        uint256 amount = 1 ether;

        asset.mint(address(this), amount);

        pearlmit.approve(20, address(asset), 0, address(yieldBox), uint200(amount), uint48(block.timestamp));
        asset.approve(address(pearlmit), amount);

        yieldBox.depositAsset(assetId, address(this), address(this), amount, 0);
    }
}