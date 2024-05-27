// SPDX-License-Identifier: MIT
// SettleMint.com

pragma solidity 0.8.26;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2771Context, Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title GenericTokenMeta
 * @notice This contract is a generic token adhering to the ERC20 standard,
 *  using the OpenZeppelin template libary for battletested functionality.
 *
 *  It incorporates the standard ERC20 functions, enhanced with Minting
 *  and Burning, Pausable in case of emergencies and AccessControl for locking
 *  down the administrative functions. It also implements ERC2771 to handle meta transactions
 *  and have a relayer pay for the gas fees.
 *
 *  For demonstrative purposes, 1 million GTM tokens are pre-mined to the address
 *  deploying this contract.
 */
contract GenericTokenMeta is
    ERC20,
    ERC20Burnable,
    ERC165,
    ERC2771Context,
    ERC20Pausable,
    Ownable
{
    constructor(
        string memory name_,
        string memory symbol_,
        address trustedForwarder_
    )
        ERC20(name_, symbol_)
        ERC2771Context(trustedForwarder_)
        Ownable(msg.sender)
    {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The sender of the transaction must have the DEFAULT_ADMIN_ROLE
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     * - The sender of the transaction must have the DEFAULT_ADMIN_ROLE
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     *
     * Emits a Transfer event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `msg.sender` needs the DEFAULT_ADMIN_ROLE.
     *
     * @param to           The address to mint the new tokens into
     * @param amount       The amount of tokens to mint, denominated by the decimals() function
     */
    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     *
     * Emits a Transfer event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     *
     * @param amount       The amount of tokens to burn from the sender of the transaction, denominated by the
     * decimals() function
     */
    function burn(uint256 amount) public virtual override {
        _burn(_msgSender(), amount);
    }

    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address sender)
    {
        sender = ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function msgData() public view returns (bytes calldata) {
        return _msgData();
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, amount);
    }

    function _contextSuffixLength()
        internal
        view
        override(Context, ERC2771Context)
        returns (uint256)
    {
        return super._contextSuffixLength();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(ERC20Burnable).interfaceId ||
            interfaceId == type(ERC20Pausable).interfaceId ||
            interfaceId == type(ERC2771Context).interfaceId ||
            super.supportsInterface(interfaceId); // ERC165, AccessControl
    }
}
