// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AssetRegister.sol";
import "./BoringMath.sol";

struct NativeToken {
    string name;
    string symbol;
    uint8 decimals;
    string uri;
}

/// @title NativeTokenFactory
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The NativeTokenFactory is a token factory to create ERC1155 tokens. This is used by YieldBox to create
/// native tokens in YieldBox. These have many benefits:
/// - low and predictable gas usage
/// - simplified approval
/// - no hidden features, all these tokens behave the same

contract NativeTokenFactory is AssetRegister {
    using BoringMath for uint256;

    mapping(uint256 => NativeToken) public nativeTokens;
    mapping(uint256 => address) public owner;

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    /// Modifier to check if the msg.sender is allowed to use funds belonging to the 'from' address.
    /// If 'from' is msg.sender, it's allowed.
    /// If 'msg.sender' is an address (an operator) that is approved by 'from', it's allowed.
    modifier allowed(address _from, uint256 _id) {
        _requireTransferAllowed(_from, isApprovedForAsset[_from][msg.sender][_id]);
        _;
    }

    /// @notice Only allows the `owner` to execute the function.
    /// @param tokenId The `tokenId` that the sender has to be owner of.
    modifier onlyOwner(uint256 tokenId) {
        require(msg.sender == owner[tokenId], "NTF: caller is not the owner");
        _;
    }
}
