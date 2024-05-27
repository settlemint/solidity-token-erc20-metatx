// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/Forwarder.sol";
import "../contracts/GenericTokenMeta.sol";

contract ForwarderTest is Test {
    Forwarder forwarder;
    GenericTokenMeta token;
    address owner;
    address signer;
    uint256 privateKey;

    function setUp() public {
        forwarder = new Forwarder();
        owner = address(this);
        token = new GenericTokenMeta(
            "GenericTokenMeta",
            "GMT",
            address(forwarder)
        );
        privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        signer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        token.mint(signer, 20);
    }

    function testMetaTransactionExecution() public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("MinimalForwarder")), // Name
                keccak256(bytes("0.0.1")), // Version
                block.chainid,
                address(forwarder)
            )
        );

        bytes4 transferSelector = bytes4(
            keccak256("transfer(address,uint256)")
        );
        bytes memory data = abi.encodeWithSelector(transferSelector, owner, 10);

        uint256 nonce = forwarder.getNonce(signer);

        Forwarder.ForwardRequest memory req = Forwarder.ForwardRequest({
            from: signer,
            to: address(token),
            value: 0,
            gas: 300_000,
            nonce: nonce,
            data: data
        });

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)"
                ),
                req.from,
                req.to,
                req.value,
                req.gas,
                req.nonce,
                keccak256(req.data)
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // Adjust the `v` value if necessary
        if (v == 0 || v == 1) {
            v += 27;
        }

        bytes memory signature = abi.encodePacked(r, s, v);

        // Execute the forwarder request with the signature
        (bool success, ) = forwarder.execute(req, signature);
        assertTrue(success, "Meta transaction execution failed");
    }
}
