// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

abstract contract Events {
    /////////////////////////////////////////////////////////////////////
    //                          OZ OWNABLE                             //
    /////////////////////////////////////////////////////////////////////

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /////////////////////////////////////////////////////////////////////
    //                      YIELDBOX - ERC155                          //
    /////////////////////////////////////////////////////////////////////
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /////////////////////////////////////////////////////////////////////
    //                      YIELDBOX - GLOBAL                          //
    /////////////////////////////////////////////////////////////////////
    event Deposited(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 assetId,
        uint256 amountIn,
        uint256 shareIn,
        uint256 amountOut,
        uint256 shareOut,
        bool isNFT
    );

    event Withdraw(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 assetId,
        uint256 amountIn,
        uint256 shareIn,
        uint256 amountOut,
        uint256 shareOut
    );
}
