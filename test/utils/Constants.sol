// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// @notice Helper contract containing constants for testing.
abstract contract Constants {
    /////////////////////////////////////////////////////////////////////
    //                            GLOBAL                               //
    /////////////////////////////////////////////////////////////////////
    uint256 public constant WEI_AMOUNT = 1;
    uint256 public constant SMALL_AMOUNT = 10e18;
    uint256 public constant MEDIUM_AMOUNT = 100e18;
    uint256 public constant LARGE_AMOUNT = 1000e18;

    /////////////////////////////////////////////////////////////////////
    //                          PERMIT C                               //
    /////////////////////////////////////////////////////////////////////

    /// @dev Constant value representing the ERC721 token type for signatures and transfer hooks
    uint256 constant TOKEN_TYPE_ERC721 = 721;
    /// @dev Constant value representing the ERC1155 token type for signatures and transfer hooks
    uint256 constant TOKEN_TYPE_ERC1155 = 1155;
    /// @dev Constant value representing the ERC20 token type for signatures and transfer hooks
    uint256 constant TOKEN_TYPE_ERC20 = 20;

    /////////////////////////////////////////////////////////////////////
    //                       EIP 712                                   //
    /////////////////////////////////////////////////////////////////////
    bytes32 constant EIP_712_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /////////////////////////////////////////////////////////////////////
    //                       PERMIT                                    //
    /////////////////////////////////////////////////////////////////////
    bytes32 constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 assetId,uint256 nonce,uint256 deadline)"
        );
    bytes32 constant REVOKE_TYPEHASH =
        keccak256(
            "Revoke(address owner,address spender,uint256 assetId,uint256 nonce,uint256 deadline)"
        );

    bytes32 constant PERMIT_ALL_TYPEHASH =
        keccak256(
            "PermitAll(address owner,address spender,uint256 nonce,uint256 deadline)"
        );
    bytes32 constant REVOKE_ALL_TYPEHASH =
        keccak256(
            "RevokeAll(address owner,address spender,uint256 nonce,uint256 deadline)"
        );
}
