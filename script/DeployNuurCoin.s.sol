// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {NuurCoin} from "../src/NuurCoin.sol";

/**
 * @title DeployNuurCoin
 * @notice Local / public-testnet deployer. Production chain IDs are rejected.
 *
 * @dev Environment:
 *      INITIAL_RECIPIENT  — treasury address that receives the genesis mint
 *      INITIAL_SUPPLY     — optional; defaults to 1_000_000_000e18
 *
 *      Local:
 *        anvil
 *        forge script script/DeployNuurCoin.s.sol --rpc-url anvil --broadcast --private-key <anvil-key>
 *
 *      Public testnet (example: Sepolia):
 *        forge script script/DeployNuurCoin.s.sol --rpc-url sepolia --broadcast --verify
 */
contract DeployNuurCoin is Script {
    /// @dev 1 billion NC, 18 decimals.
    uint256 public constant DEFAULT_SUPPLY = 1_000_000_000 ether;

    error ProductionDeploymentForbidden(uint256 chainId);
    error MissingInitialRecipient();

    function run() external returns (NuurCoin token) {
        _forbidProductionChains();

        address initialRecipient = vm.envAddress("INITIAL_RECIPIENT");
        if (initialRecipient == address(0)) revert MissingInitialRecipient();

        uint256 initialSupply = vm.envOr("INITIAL_SUPPLY", DEFAULT_SUPPLY);

        vm.startBroadcast();
        token = new NuurCoin(initialRecipient, initialSupply);
        vm.stopBroadcast();

        console2.log("NuurCoin deployed", address(token));
        console2.log("chainId", block.chainid);
        console2.log("initialRecipient", initialRecipient);
        console2.log("initialSupply", initialSupply);
        console2.log("cap", token.cap());
    }

    /// @dev Hard-stop known production networks. Extend this list before any
    ///      new public deployment workflow is added.
    function _forbidProductionChains() internal view {
        uint256 id = block.chainid;
        if (
            id == 1 // Ethereum
                || id == 10 // OP Mainnet
                || id == 56 // BNB Smart Chain
                || id == 137 // Polygon
                || id == 8453 // Base
                || id == 42161 // Arbitrum One
                || id == 43114 // Avalanche C-Chain
        ) {
            revert ProductionDeploymentForbidden(id);
        }
    }
}
