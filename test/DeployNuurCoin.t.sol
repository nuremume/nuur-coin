// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployNuurCoin} from "../script/DeployNuurCoin.s.sol";
import {NuurCoin} from "../src/NuurCoin.sol";

contract DeployNuurCoinTest is Test {
    function test_RunDeploysOnLocalChain() public {
        address recipient = makeAddr("treasury");
        vm.setEnv("INITIAL_RECIPIENT", vm.toString(recipient));
        vm.setEnv("INITIAL_SUPPLY", vm.toString(uint256(1_000 ether)));

        DeployNuurCoin deployer = new DeployNuurCoin();
        NuurCoin token = deployer.run();

        assertEq(token.balanceOf(recipient), 1_000 ether);
        assertEq(token.cap(), 1_000 ether);
        assertEq(token.symbol(), "NC");
    }

    function test_RevertWhen_ProductionChain() public {
        vm.chainId(1);
        address recipient = makeAddr("treasury");
        vm.setEnv("INITIAL_RECIPIENT", vm.toString(recipient));

        DeployNuurCoin deployer = new DeployNuurCoin();
        vm.expectRevert(abi.encodeWithSelector(DeployNuurCoin.ProductionDeploymentForbidden.selector, uint256(1)));
        deployer.run();
    }
}
