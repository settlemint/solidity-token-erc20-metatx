// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/GenericTokenMeta.sol";
import "../contracts/Forwarder.sol";

contract GenericTokenMetaTest is Test {
    address owner;
    address recipient;
    GenericTokenMeta token;
    Forwarder forwarder;
    address trustedForwarder = address(0x1);

    error ERC20InsufficientBalance(address account, uint256 balance, uint256 amount);
    error EnforcedPause();

    function setUp() public {
        owner = address(this);
        recipient = address(0x123);
        forwarder = new Forwarder("ERC2771");
        token = new GenericTokenMeta("GenericTokenMeta", "GTM", address(forwarder));
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

    function testFailMintWhenPaused() public {
        token.pause();
        uint256 mintAmount = 1000 * 10 ** token.decimals();
        token.mint(owner, mintAmount);
    }

    function testFailBurnMoreThanBalance() public {
        uint256 burnAmount = 200_000 * 10 ** token.decimals();
        vm.prank(recipient);
        token.burn(burnAmount);
    }

    function testMsgData() public view {
        // Call the msgData function
        bytes memory data = token.msgData();
        // Check if the returned data matches the msg.data
        assertEq(data.length, msg.data.length, "msgData length mismatch");
    }
}
