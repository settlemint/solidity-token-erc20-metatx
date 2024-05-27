// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../contracts/GenericTokenMeta.sol";
import "../contracts/Forwarder.sol";

contract GenericTokenMetaTest is Test {
    address owner;
    address recipient;
    GenericTokenMeta token;
    Forwarder forwarder;
    address trustedForwarder = address(0x1); // Example forwarder address, replace with a real one if needed

    function setUp() public {
        owner = address(this);
        recipient = address(0x123);
        forwarder = new Forwarder();
        token = new GenericTokenMeta(
            "GenericTokenMeta",
            "GTM",
            address(forwarder)
        );
    }

    function testMint() public {
        uint256 mintAmount = 1000 * 10 ** token.decimals();
        address to = address(0x2);

        token.mint(to, mintAmount);

        assertEq(token.balanceOf(to), mintAmount);
    }

    function testBurn() public {
        uint256 mintAmount = 1000 * 10 ** token.decimals();

        token.mint(recipient, mintAmount);
        vm.prank(recipient);
        token.burn(mintAmount / 2);

        assertEq(token.balanceOf(recipient), mintAmount / 2);
    }

    function testPauseUnpause() public {
        token.pause();
        assertTrue(token.paused());

        token.unpause();
        assertFalse(token.paused());
    }
}
