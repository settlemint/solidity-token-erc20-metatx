// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../contracts/Forwarder.sol";
import "../contracts/GenericTokenMeta.sol";

contract ForwarderTest is Test {
    Forwarder forwarder;
    GenericTokenMeta token;
    address owner;
    address signer;
    address signer2;
    uint256 privateKey;
    uint256 privateKey2;

    function setUp() public {
        forwarder = new Forwarder();
        owner = address(this);
        token = new GenericTokenMeta(
            "GenericTokenMeta",
            "GMT",
            address(forwarder)
        );
        privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        privateKey2 = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        signer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        signer2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        token.mint(signer, 20);
    }

    function testNonce() public view {
        uint256 nonce = forwarder.getNonce(signer);
        assertEq(nonce, 0);
    }

    function testVerify() public view {
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
        forwarder.verify(req, signature);

        //signing with a different private key
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(privateKey2, digest);

        // Adjust the `v` value if necessary
        if (v1 == 0 || v1 == 1) {
            v1 += 27;
        }

        bytes memory signature1 = abi.encodePacked(r1, s1, v1);
        bool result = forwarder.verify(req, signature1);
        assertEq(result, false);

        //changing the request
        req.nonce++;
        result = forwarder.verify(req, signature);
        assertEq(result, false);
    }

    function testExecuteInvalidSignature() public {
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

        v++;
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectRevert();
        forwarder.execute(req, signature);
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
        assertEq(token.balanceOf(signer), 10);
    }

    function testSupportsInterface() public view {
        bool result = forwarder.supportsInterface(type(IERC165).interfaceId);
        assertTrue(
            result,
            "supportsInterface should return true for IERC165 interface"
        );
    }
}
