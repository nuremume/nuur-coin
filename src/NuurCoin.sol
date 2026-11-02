// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

/**
 * @title NuurCoin
 * @notice ERC-20 token for the Nuur ecosystem (symbol: NC).
 * @dev Stage 1 design:
 *      - Name and symbol are fixed in bytecode (`Nuur Coin` / `NC`).
 *      - The entire supply is minted once in the constructor.
 *      - {cap} is immutable and equal to that genesis mint.
 *      - There is no owner, minter, pauser, tax, or upgrade hook.
 *      - Holders may burn their own tokens (or tokens they are approved to spend).
 *
 *      Nuur Wallet and Nuur Exchange are off-chain / later products. They must
 *      not be implemented as privileged logic inside this contract.
 */
contract NuurCoin is ERC20, ERC20Burnable, ERC20Capped, ERC20Permit {
    /**
     * @notice Deploys Nuur Coin and mints the full supply to `initialRecipient`.
     * @param initialRecipient Address that receives every minted token. Use a
     *        dedicated treasury or multisig; this is the only privileged actor,
     *        and only because it holds the tokens — not because it has admin
     *        functions.
     * @param initialSupply Total token amount in base units (18 decimals).
     *        Also stored as the immutable {cap}. Must be greater than zero.
     *
     * @dev Reverts with {IERC20Errors-ERC20InvalidReceiver} if `initialRecipient`
     *      is the zero address. Reverts with {ERC20Capped-ERC20InvalidCap} if
     *      `initialSupply` is zero.
     */
    constructor(address initialRecipient, uint256 initialSupply)
        ERC20("Nuur Coin", "NC")
        ERC20Capped(initialSupply)
        ERC20Permit("Nuur Coin")
    {
        if (initialRecipient == address(0)) {
            revert IERC20Errors.ERC20InvalidReceiver(address(0));
        }

        _mint(initialRecipient, initialSupply);
    }

    /**
     * @notice Number of decimal places used for display and arithmetic.
     * @dev Fixed at 18, matching the ERC-20 default. One whole NC is 1e18 units.
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @dev OpenZeppelin requires an explicit override when both {ERC20} and
     *      {ERC20Capped} define `_update`. Cap enforcement runs on mint
     *      (`from == address(0)`). After construction there is no mint path,
     *      so the cap check is defense-in-depth for reviewers.
     */
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }
}
