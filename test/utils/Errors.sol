// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

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

  
}