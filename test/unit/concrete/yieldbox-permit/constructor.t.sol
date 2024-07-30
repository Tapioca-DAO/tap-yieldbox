// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Setup
import {BaseTest} from "../../../Base.t.sol";

// Contracts
import {YieldBox} from "contracts/YieldBox.sol";
import {TokenType} from "contracts/enums/YieldBoxTokenType.sol";

// Interfaces
import {IStrategy} from "contracts/interfaces/IStrategy.sol";
import "contracts/interfaces/IWrappedNative.sol";

contract ConstructorYieldBoxPermit is BaseTest {
    /////////////////////////////////////////////////////////////////////
    //                          SETUP                                  //
    /////////////////////////////////////////////////////////////////////
    function setUp() public override {
        super.setUp();
    }

    /////////////////////////////////////////////////////////////////////
    //                    INTERNAL HELPERS                             //
    /////////////////////////////////////////////////////////////////////

    function _buildExpectedDomainSeparator(
        string memory name,
        string memory version
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP_712_TYPE_HASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    block.chainid,
                    address(yieldBox)
                )
            );
    }

    /////////////////////////////////////////////////////////////////////
    //                         TESTS                                   //
    /////////////////////////////////////////////////////////////////////

    /// @notice Tests the constructor values for YieldBox permit
    /// @dev Due private immutability of permit variables, assertions will be performed by deriving the expected domain separator
    /// given a set of predetermined values.
    function test_constructorYieldBoxPermit() public view {
        // Initial assertions are derived from the expected values passed at the YieldBox deployment:
        //  - name: "YieldBox"
        //  - version: "1"
        //  - chain ID: `block.chainid`
        //  - _cachedDomainSeparator: `_buildExpectedDomainSeparator`
        assertEq(
            _buildExpectedDomainSeparator("YieldBox", "1"),
            yieldBox.DOMAIN_SEPARATOR()
        );
    }
}
