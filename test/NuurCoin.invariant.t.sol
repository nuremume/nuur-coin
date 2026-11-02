// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {NuurCoin} from "../src/NuurCoin.sol";

contract NuurCoinHandler is Test {
    NuurCoin public token;
    address[] public actors;

    constructor(NuurCoin token_, address[] memory actors_) {
        token = token_;
        actors = actors_;
    }

    function transfer(uint256 fromSeed, uint256 toSeed, uint256 amount) external {
        address from = actors[fromSeed % actors.length];
        address to = actors[toSeed % actors.length];
        uint256 balance = token.balanceOf(from);
        amount = bound(amount, 0, balance);
        vm.prank(from);
        token.transfer(to, amount);
    }

    function burn(uint256 fromSeed, uint256 amount) external {
        address from = actors[fromSeed % actors.length];
        uint256 balance = token.balanceOf(from);
        amount = bound(amount, 0, balance);
        vm.prank(from);
        token.burn(amount);
    }

    function approveAndTransferFrom(uint256 ownerSeed, uint256 spenderSeed, uint256 toSeed, uint256 amount) external {
        address owner_ = actors[ownerSeed % actors.length];
        address spender = actors[spenderSeed % actors.length];
        address to = actors[toSeed % actors.length];
        uint256 balance = token.balanceOf(owner_);
        amount = bound(amount, 0, balance);

        vm.prank(owner_);
        token.approve(spender, amount);

        vm.prank(spender);
        token.transferFrom(owner_, to, amount);
    }
}

contract NuurCoinInvariantTest is Test {
    NuurCoin internal token;
    NuurCoinHandler internal handler;
    address[] internal actors;

    uint256 internal constant SUPPLY = 1_000_000_000 ether;

    function setUp() public {
        actors.push(makeAddr("treasury"));
        actors.push(makeAddr("alice"));
        actors.push(makeAddr("bob"));
        actors.push(makeAddr("carol"));

        token = new NuurCoin(actors[0], SUPPLY);
        handler = new NuurCoinHandler(token, actors);

        targetContract(address(handler));
    }

    function invariant_TotalSupplyNeverExceedsCap() public view {
        assertLe(token.totalSupply(), token.cap());
    }

    function invariant_SumOfBalancesEqualsTotalSupply() public view {
        uint256 sum;
        for (uint256 i = 0; i < actors.length; ++i) {
            sum += token.balanceOf(actors[i]);
        }
        assertEq(sum, token.totalSupply());
    }

    function invariant_CapIsImmutableGenesisSupply() public view {
        assertEq(token.cap(), SUPPLY);
    }
}
