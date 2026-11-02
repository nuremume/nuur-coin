// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {NuurCoin} from "../src/NuurCoin.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract NuurCoinTest is Test {
    NuurCoin internal token;

    address internal treasury;
    address internal alice;
    address internal bob;

    uint256 internal alicePk;
    uint256 internal constant SUPPLY = 1_000_000_000 ether;

    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function setUp() public {
        treasury = makeAddr("treasury");
        alicePk = 0xA11CE;
        alice = vm.addr(alicePk);
        bob = makeAddr("bob");

        token = new NuurCoin(treasury, SUPPLY);
    }

    function test_Metadata() public view {
        assertEq(token.name(), "Nuur Coin");
        assertEq(token.symbol(), "NC");
        assertEq(token.decimals(), 18);
    }

    function test_GenesisMintEqualsCapAndRecipientBalance() public view {
        assertEq(token.cap(), SUPPLY);
        assertEq(token.totalSupply(), SUPPLY);
        assertEq(token.balanceOf(treasury), SUPPLY);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function test_RevertWhen_RecipientIsZero() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        new NuurCoin(address(0), SUPPLY);
    }

    function test_RevertWhen_SupplyIsZero() public {
        vm.expectRevert(abi.encodeWithSelector(ERC20Capped.ERC20InvalidCap.selector, 0));
        new NuurCoin(treasury, 0);
    }

    function test_TransferMovesFullAmountWithNoFee() public {
        uint256 amount = 1_000 ether;
        vm.prank(treasury);
        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(treasury), SUPPLY - amount);
        assertEq(token.totalSupply(), SUPPLY);
    }

    function test_RevertWhen_TransferExceedsBalance() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 0, uint256(1 ether))
        );
        token.transfer(bob, 1 ether);
    }

    function test_ApproveAndTransferFrom() public {
        uint256 amount = 50 ether;
        vm.prank(treasury);
        token.transfer(alice, amount);

        vm.prank(alice);
        token.approve(bob, 20 ether);

        vm.prank(bob);
        token.transferFrom(alice, bob, 20 ether);

        assertEq(token.balanceOf(bob), 20 ether);
        assertEq(token.balanceOf(alice), 30 ether);
        assertEq(token.allowance(alice, bob), 0);
    }

    function test_PermitSetsAllowance() public {
        uint256 amount = 10 ether;
        vm.prank(treasury);
        token.transfer(alice, amount);

        uint256 deadline = block.timestamp + 1 days;
        uint256 nonce = token.nonces(alice);
        bytes32 digest = _permitDigest(alice, bob, amount, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);

        token.permit(alice, bob, amount, deadline, v, r, s);

        assertEq(token.allowance(alice, bob), amount);
        assertEq(token.nonces(alice), nonce + 1);
    }

    function test_BurnReducesSupplyAndBalance() public {
        uint256 amount = 100 ether;
        vm.prank(treasury);
        token.transfer(alice, amount);

        vm.prank(alice);
        token.burn(40 ether);

        assertEq(token.balanceOf(alice), 60 ether);
        assertEq(token.totalSupply(), SUPPLY - 40 ether);
        assertEq(token.cap(), SUPPLY);
    }

    function test_BurnFromUsesAllowance() public {
        uint256 amount = 25 ether;
        vm.prank(treasury);
        token.transfer(alice, amount);

        vm.prank(alice);
        token.approve(bob, 25 ether);

        vm.prank(bob);
        token.burnFrom(alice, 25 ether);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.totalSupply(), SUPPLY - 25 ether);
    }

    function test_MintSelectorIsNotCallable() public {
        bytes memory data = abi.encodeWithSignature("mint(address,uint256)", alice, uint256(1));
        (bool success,) = address(token).call(data);
        assertFalse(success, "hidden mint must not exist");
    }

    function test_OwnerSelectorIsNotCallable() public {
        (bool success,) = address(token).call(abi.encodeWithSignature("owner()"));
        assertFalse(success, "token must not expose Ownable.owner");
    }

    function testFuzz_TransferConservesSupply(uint256 amount) public {
        amount = bound(amount, 0, SUPPLY);

        vm.prank(treasury);
        token.transfer(alice, amount);

        assertEq(token.totalSupply(), SUPPLY);
        assertEq(token.balanceOf(alice) + token.balanceOf(treasury), SUPPLY);
    }

    function _permitDigest(address owner, address spender, uint256 value, uint256 nonce, uint256 deadline)
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));
        return keccak256(abi.encodePacked("\x19\x01", IERC20Permit(address(token)).DOMAIN_SEPARATOR(), structHash));
    }
}
