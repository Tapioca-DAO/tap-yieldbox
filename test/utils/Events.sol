// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Contracts
import {TokenType} from "contracts/enums/YieldBoxTokenType.sol";
import {IStrategy} from "contracts/interfaces/IStrategy.sol";

/// @notice Helper contract containing events for testing.
abstract contract Events {
    /////////////////////////////////////////////////////////////////////
    //                          OZ OWNABLE                             //
    /////////////////////////////////////////////////////////////////////

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /////////////////////////////////////////////////////////////////////
    //                      YIELDBOX - ERC155                          //
    /////////////////////////////////////////////////////////////////////
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );

    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event ApprovalForAsset(address indexed sender, address indexed operator, uint256 assetId, bool approved);
    event URI(string _value, uint256 indexed _id);

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

    event PearlmitUpdated(address oldPearlmit, address newPearlmit);

    event AssetRegistered(
        TokenType indexed tokenType,
        address indexed contractAddress,
        IStrategy strategy,
        uint256 indexed tokenId,
        uint256 assetId
    );
}
