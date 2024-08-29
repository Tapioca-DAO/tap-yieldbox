// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// @notice Helper contract containing errors for testing.
abstract contract Errors {
    /////////////////////////////////////////////////////////////////////
    //                          YIELDBOX                               //
    /////////////////////////////////////////////////////////////////////

    error InvalidTokenType();
    error PearlmitTransferFailed();
    error InvalidZeroAmounts();
    error NotWrapped();
    error AmountTooLow();
    error RefundFailed();
    error ZeroAddress();
    error NotSet();
    error ForbiddenAction();
    error AssetNotValid();
}
