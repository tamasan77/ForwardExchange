// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../forward/ForwardContract.sol";

contract ForwardContractMock is ForwardContract {

    constructor() ForwardContract(
        "Mock Forward",
        "MFD",
        1000,
        1733030926,
        "Fake API URL",
        "FAKE.PATH",
        100,
        payable(0x01BE23585060835E02B77ef475b0Cc51aA1e0709),
        payable(0x01BE23585060835E02B77ef475b0Cc51aA1e0709)
    ) {}

    //set short and long wallets
    function setPersonalWallets(address shortWallet, address longWallet) public {
        shortPersonalWallet = shortWallet;
        longPersonalWallet = longWallet;
    }
}