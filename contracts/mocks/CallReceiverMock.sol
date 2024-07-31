// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CallReceiverMock is Ownable {
    event MockFunctionCalled();
    event MockFunctionCalledWithArgs(uint256 a, uint256 b);

    uint256[] private _array;

    constructor() payable Ownable(msg.sender) { }

    function mockFunction() public payable returns (string memory) {
        emit MockFunctionCalled();
        return "0x1234";
    }

    function mockFunctionEmptyReturn() public payable {
        emit MockFunctionCalled();
    }

    function mockFunctionWithArgs(uint256 a, uint256 b) public payable returns (string memory) {
        emit MockFunctionCalledWithArgs(a, b);
        return "0x1234";
    }

    function mockFunctionNonPayable() public returns (string memory) {
        emit MockFunctionCalled();
        return "0x1234";
    }

    function mockStaticFunction() public pure returns (string memory) {
        return "0x1234";
    }

    function mockFunctionRevertsNoReason() public payable {
        revert();
    }

    function mockFunctionRevertsReason() public payable {
        revert("CallReceiverMock: reverting");
    }

    function mockFunctionThrows() public payable {
        assert(false);
    }
}

contract CallReceiverMockTrustingForwarder is CallReceiverMock {
    address private _trustedForwarder;

    constructor(address trustedForwarder_) {
        _trustedForwarder = trustedForwarder_;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }
}
