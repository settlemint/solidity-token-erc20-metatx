// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/mocks/CallReceiverMock.sol";

contract CallReceiverMockTest is Test {
    CallReceiverMock callReceiverMock;
    address owner = address(1);
    address nonOwner = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);
        vm.deal(nonOwner, 1 ether);
        vm.prank(owner);
        callReceiverMock = new CallReceiverMock();
    }

    function testMockFunction() public {
        vm.prank(nonOwner);
        string memory result = callReceiverMock.mockFunction{ value: 1 ether }();
        assertEq(result, "0x1234");
        assertEq(address(callReceiverMock).balance, 1 ether);
    }

    function testMockFunctionEmptyReturn() public {
        vm.prank(nonOwner);
        callReceiverMock.mockFunctionEmptyReturn{ value: 1 ether }();
        assertEq(address(callReceiverMock).balance, 1 ether);
    }

    function testMockFunctionWithArgs() public {
        vm.prank(nonOwner);
        string memory result = callReceiverMock.mockFunctionWithArgs{ value: 1 ether }(1, 2);
        assertEq(result, "0x1234");
        assertEq(address(callReceiverMock).balance, 1 ether);
    }

    function testMockFunctionNonPayable() public {
        vm.prank(nonOwner);
        string memory result = callReceiverMock.mockFunctionNonPayable();
        assertEq(result, "0x1234");
    }

    function testMockStaticFunction() public view {
        string memory result = callReceiverMock.mockStaticFunction();
        assertEq(result, "0x1234");
    }

    function testMockFunctionRevertsNoReason() public {
        vm.prank(nonOwner);
        vm.expectRevert();
        callReceiverMock.mockFunctionRevertsNoReason{ value: 1 ether }();
    }

    function testMockFunctionRevertsReason() public {
        vm.prank(nonOwner);
        vm.expectRevert("CallReceiverMock: reverting");
        callReceiverMock.mockFunctionRevertsReason{ value: 1 ether }();
    }

    function testMockFunctionThrows() public {
        vm.prank(nonOwner);
        vm.expectRevert();
        callReceiverMock.mockFunctionThrows{ value: 1 ether }();
    }
}

contract CallReceiverMockTrustingForwarderTest is Test {
    CallReceiverMockTrustingForwarder callReceiverMock;
    address owner = address(1);
    address nonOwner = address(2);
    address trustedForwarder = address(3);

    function setUp() public {
        vm.deal(owner, 1 ether);
        vm.deal(nonOwner, 1 ether);
        vm.prank(owner);
        callReceiverMock = new CallReceiverMockTrustingForwarder(trustedForwarder);
    }

    function testIsTrustedForwarder() public view {
        assertTrue(callReceiverMock.isTrustedForwarder(trustedForwarder));
        assertFalse(callReceiverMock.isTrustedForwarder(nonOwner));
    }
}
