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