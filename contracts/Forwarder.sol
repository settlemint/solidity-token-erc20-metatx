// SPDX-License-Identifier: FSL-1.1-MIT
// OpenZeppelin Contracts (last updated v5.0.0) (metatx/ERC2771Forwarder.sol)

pragma solidity 0.8.24;

import { ERC2771Forwarder } from "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";

contract Forwarder is ERC2771Forwarder {
    constructor(string memory name) payable ERC2771Forwarder(name) { }
}
