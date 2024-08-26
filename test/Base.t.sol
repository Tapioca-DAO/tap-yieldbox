// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Utilities
import {Users, PrivateKeys} from "./utils/Types.sol";
import {Utils} from "./utils/Utils.sol";
import {Events} from "./utils/Events.sol";
import {Errors} from "./utils/Errors.sol";
import {Constants} from "./utils/Constants.sol";

// Mocks
import {ERC20Mock} from "./mocks/erc20/ERC20Mock.sol";
import {WrappedNativeMock} from "./mocks/erc20/WrappedNativeMock.sol";
import {ERC20MissingReturn} from "./mocks/erc20/ERC20MissingReturn.sol";

// Contracts
import {YieldBox, Pearlmit} from "contracts/YieldBox.sol";
import {YieldBoxURIBuilder} from "contracts/YieldBoxURIBuilder.sol";

// Interfaces
import "contracts/interfaces/IWrappedNative.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract BaseTest is Utils, Events, Errors, Constants {
    /////////////////////////////////////////////////////////////////////
    //                             STORAGE                             //
    /////////////////////////////////////////////////////////////////////

    /// @notice Protocol users
    Users internal users;
    PrivateKeys internal privateKeys;
    address[] internal userAddresses;

    /// @notice Tokens
    ERC20Mock internal dai;
    WrappedNativeMock internal wrappedNative;
    ERC20MissingReturn internal usdt;

    /// @notice Protocol contracts
    YieldBox internal yieldBox;
    YieldBoxURIBuilder internal yieldBoxUriBuilder;
    Pearlmit internal pearlmit;

    /////////////////////////////////////////////////////////////////////
    //                             SETUP                               //
    /////////////////////////////////////////////////////////////////////

    function setUp() public virtual {
        // Deploy mock tokens.
        dai = new ERC20Mock("Dai Stablecoin", "DAI");
        usdt = new ERC20MissingReturn("Tether USD", "USDT", 6);
        wrappedNative = new WrappedNativeMock();

        // Label the base test contracts.
        vm.label({account: address(dai), newLabel: "DAI"});
        vm.label({account: address(usdt), newLabel: "USDT"});
        vm.label({account: address(wrappedNative), newLabel: "WETH"});

        // Create users.
        _initializeUsers();

        // Deploy protocol.
        _deployYieldBox();
    }

    /////////////////////////////////////////////////////////////////////
    //                           MODIFIERS                             //
    /////////////////////////////////////////////////////////////////////

    /// @notice Modifier to approve an operator in YB via Pearlmit.
    modifier whenApprovedViaPearlmit(
        address _from,
        address _operator,
        uint256 _amount,
        uint256 _expiration
    ) {
        _approveViaPearlmit({
            from: _from,
            operator: _operator,
            amount: _amount,
            expiration: _expiration
        });
        _;
    }

    /// @notice Modifier to approve an operator via regular ERC20.
    modifier whenApprovedViaERC20(
        address _from,
        address _operator,
        uint256 _amount
    ) {
        _approveViaERC20({from: _from, operator: _operator, amount: _amount});
        _;
    }

    /// @notice Modifier to approve an operator for a specific asset ID via YB.
    modifier whenYieldBoxApprovedForAssetID(
        address _from,
        address _operator,
        uint256 _assetId
    ) {
        _approveYieldBoxAssetId(_from, _operator, _assetId);
        _;
    }

    /// @notice Modifier to approve an operator for a specific asset ID via YB.
    modifier whenYieldBoxApprovedForMultipleAssetIDs(
        address _from,
        address _operator
    ) {
        for (uint256 i = 1; i <= 3; i++) {
            _approveYieldBoxAssetId(_from, _operator, i);
        }

        _;
    }

    /// @notice Modifier to approve an operator for all via YB.
    modifier whenYieldBoxApprovedForAll(address _from, address _operator) {
        _approveYieldBoxForAll(_from, _operator);
        _;
    }

    /// @notice Modifier to changea user's prank.
    modifier resetPrank(address user) {
        _resetPrank(user);
        _;
    }

    /// @notice Modifier to verify a value is not zero.
    modifier assumeNoZeroValue(uint256 value) {
        vm.assume(value != 0);
        _;
    }

    /// @notice Modifier to verify a value is greater than or equal to a certain number.
    modifier assumeGtE(uint256 value, uint256 toCompare) {
        vm.assume(value >= toCompare);
        _;
    }

    /////////////////////////////////////////////////////////////////////
    //                      INTERNAL HELPERS                           //
    /////////////////////////////////////////////////////////////////////

    /// @notice Initializes test users.
    function _initializeUsers() internal {
        // Create users
        (users.owner, privateKeys.ownerPK) = _createUser("owner");
        (users.alice, privateKeys.alicePK)  = _createUser("alice");
        (users.bob, privateKeys.bobPK)  = _createUser("bob");
        (users.charlie, privateKeys.charliePK)  = _createUser("charlie");
        (users.david, privateKeys.davidPK)  = _createUser("david");
        (users.eve, privateKeys.evePK)  = _createUser("eve");

        // Fill users array
        userAddresses.push(users.alice);
        userAddresses.push(users.bob);
        userAddresses.push(users.charlie);
        userAddresses.push(users.david);
        userAddresses.push(users.eve);
    }

    /// @notice Deploys YieldBox together with its required contracts.
    function _deployYieldBox() internal {
        // Deploy Pearlmit
        pearlmit = new Pearlmit("Pearlmit", "1.0", users.owner, 0);

        // Deploy YieldBox URI builder
        yieldBoxUriBuilder = new YieldBoxURIBuilder();

        // Deploy YieldBox
        yieldBox = new YieldBox(
            IWrappedNative(address(wrappedNative)),
            yieldBoxUriBuilder,
            pearlmit,
            users.owner
        );
    }

    /// @notice Approves all YieldBox contracts to spend assets from the address passed using Pearlmit.
    function _approveViaPearlmit(
        address from,
        address operator,
        uint256 amount,
        uint256 expiration
    ) internal {
        // Reset prank
        _resetPrank({msgSender: from});

        // Set approvals to pearlmit
        dai.approve(address(pearlmit), amount);
        wrappedNative.approve(address(pearlmit), amount);
        usdt.approve(address(pearlmit), amount);

        // Approve via pearlmit
        pearlmit.approve(
            TOKEN_TYPE_ERC20,
            address(dai),
            0,
            operator,
            uint200(amount),
            uint48(expiration)
        );
        pearlmit.approve(
            TOKEN_TYPE_ERC20,
            address(wrappedNative),
            0,
            operator,
            uint200(amount),
            uint48(expiration)
        );
        pearlmit.approve(
            TOKEN_TYPE_ERC20,
            address(usdt),
            0,
            operator,
            uint200(amount),
            uint48(expiration)
        );
    }

    /// @notice Approves all YieldBox contracts to spend assets from the address passed using regular ERC20.
    function _approveViaERC20(
        address from,
        address operator,
        uint256 amount
    ) internal {
        // Reset prank
        _resetPrank({msgSender: from});
        // Set approvals to pearlmit
        dai.approve(address(operator), amount);
        wrappedNative.approve(address(operator), amount);
        usdt.approve(address(operator), amount);
    }

    /// @notice Approves a YieldBox asset ID to an `operator` given a `from` address.
    function _approveYieldBoxAssetId(
        address from,
        address operator,
        uint256 assetId
    ) internal {
        _resetPrank({msgSender: from});
        yieldBox.setApprovalForAsset(operator, assetId, true);
    }

    /// @notice Approves all YieldBox assets  to an `operator` given a `from` address.
    function _approveYieldBoxForAll(address from, address operator) internal {
        _resetPrank({msgSender: from});
        yieldBox.setApprovalForAll(operator, true);
    }

    /// @notice Generates a user, labels its address, funds it with test assets, and approves the protocol contracts.
    function _createUser(
        string memory name
    ) internal returns (address payable, uint256) {
        (address user, uint256 privateKey) = makeAddrAndKey(name);

        vm.deal({account: user, newBalance: type(uint128).max});
        deal({token: address(dai), to: user, give: type(uint128).max});
        deal({
            token: address(wrappedNative),
            to: user,
            give: type(uint128).max
        });
        deal({token: address(usdt), to: user, give: type(uint128).max});
        return (payable(user), privateKey);
    }
}
