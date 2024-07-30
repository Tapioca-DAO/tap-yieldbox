// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.22;

struct Users {
    // Default owner for all Yieldbox contracts
    address payable owner;
    // Impartial user 1.
    address payable alice;
    // Impartial user 2.
    address payable bob;
    // Impartial user 3.
    address payable charlie;
    // Impartial user 4.
    address payable david;
    // Malicious user.
    address payable eve;

}

struct PrivateKeys {
    // Default owner for all Yieldbox contracts
    uint256 ownerPK;
    // Impartial user 1's PK.
    uint256 alicePK;
    // Impartial user 2's PK.
    uint256 bobPK;
    // Impartial user 3's PK.
    uint256 charliePK;
    // Impartial user 4's PK.
    uint256 davidPK;
    // Malicious user's PK.
    uint256 evePK;

}
