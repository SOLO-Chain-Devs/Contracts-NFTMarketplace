// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {NFT721Factory} from "../../src/mock/NFT721Factory.sol";
import {NFT1155Factory} from "../../src/mock/NFT1155Factory.sol";
import {NFT1155} from "../../src/mock/NFT1155.sol";

// Create some 721 with the 721 factory
contract Create721 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("OFFCHAIN_PRIVATE_KEY");
        address deployerAddress = vm.envAddress("OFFCHAIN_WALLET_ADDRESS");
        address factoryAddress = vm.envAddress("FACTORY_721_CA");

        // Connect to the deployed factory
        NFT721Factory factory = NFT721Factory(factoryAddress);

        // Arrays for funny names and symbols
        string[10] memory names = [
            "721 Banana Lord",
            "721 Pineapple Pizza",
            "721 Quantum Duck",
            "721 Couch Potato",
            "721 Spicy Pickle",
            "721 Flying Sausage",
            "721 Invisible Taco",
            "721 Space Donut",
            "721 Dancing Avocado",
            "721 Laughing Penguin"
        ];

        string[10] memory symbols =
            ["BANANA", "PIZZA", "DUCK", "POTATO", "PICKLE", "SAUSAGE", "TACO", "DONUT", "AVOCADO", "PENGUIN"];

        vm.startBroadcast(deployerPrivateKey);

        // Deploy 10 NFTs with unique funny names and symbols
        for (uint256 i = 0; i < 10; i++) {
            address newNFT = factory.createNFT721(
                names[i], // Unique funny name
                symbols[i], // Unique symbol
                "",
                deployerAddress, // Royalty receiver
                0, // Fee numerator
                10, // Mint supply
                deployerAddress // Initial receiver
            );

            console.log("721 deployed to:", newNFT);
        }

        vm.stopBroadcast();
    }
}

// Create some 1155 with the 1155 factory
contract Create1155 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("OFFCHAIN_PRIVATE_KEY");
        address deployerAddress = vm.envAddress("OFFCHAIN_WALLET_ADDRESS");
        address factoryAddress = vm.envAddress("FACTORY_1155_CA");

        // Connect to the deployed factory
        NFT1155Factory factory = NFT1155Factory(factoryAddress);

        // Arrays for funny 1155 weapon names and symbols
        string[10] memory names = [
            "1155 Flaming Banana Sword",
            "1155 Exploding Pineapple Grenade",
            "1155 Quantum Duck Bow",
            "1155 Potato Launcher",
            "1155 Pickle Sword of Fury",
            "1155 Flying Sausage Shield",
            "1155 Invisible Taco Blade",
            "1155 Space Donut Gun",
            "1155 Dancing Avocado Spear",
            "1155 Laughing Penguin Hammer"
        ];

        string[10] memory symbols = [
            "FLAMING_BANANA",
            "EXPLODING_PINEAPPLE",
            "QUANTUM_DUCK",
            "POTATO_LAUNCHER",
            "PICKLE_FURY",
            "FLYING_SAUSAGE",
            "INVISIBLE_TACO",
            "SPACE_DONUT",
            "DANCING_AVOCADO",
            "LAUGHING_PENGUIN"
        ];

        uint256[] memory initialAmounts = new uint256[](10);
        uint256[] memory initialIds = new uint256[](10);

        initialIds[0] = 1;
        initialIds[1] = 2;
        initialIds[2] = 5;
        initialIds[3] = 7;
        initialIds[4] = 11;
        initialIds[5] = 12;
        initialIds[6] = 13;
        initialIds[7] = 15;
        initialIds[8] = 18;
        initialIds[9] = 20;

        initialAmounts[0] = 100;
        initialAmounts[1] = 200;
        initialAmounts[2] = 505;
        initialAmounts[3] = 300;
        initialAmounts[4] = 400;
        initialAmounts[5] = 333;
        initialAmounts[6] = 222;
        initialAmounts[7] = 111;
        initialAmounts[8] = 125;
        initialAmounts[9] = 325;

        vm.startBroadcast(deployerPrivateKey);

        address initialReceiver = deployerAddress;

        // Deploy 10 NFTs 1155 with funny weapon names and symbols
        for (uint256 i = 0; i < 10; i++) {
            address nft = factory.createNFT1155(
                names[i], // Unique funny weapon name
                symbols[i], // Unique symbol
                "",
                initialReceiver, // Royalty receiver
                0, // Fee numerator
                initialIds, // Initial IDs for the weapons
                initialAmounts, // Initial amounts for each weapon
                initialReceiver // Initial receiver
            );

            console.log("1155 deployed to:", nft);
        }
    }
}

// List all 721
contract ListAll721 is Script {
    function run() external {
        address factoryAddress = vm.envAddress("FACTORY_721_CA");

        vm.startBroadcast();

        // Connect to the deployed factory
        NFT721Factory factory = NFT721Factory(factoryAddress);

        address[] memory addresses = factory.getAllNFTContracts();

        // Get and log the total number of NFT contracts
        uint256 totalNFTs = factory.getTotalNFTContracts();
        console.log("Total NFTs Created:", totalNFTs);

        // Log each address in the array
        for (uint256 i = 0; i < addresses.length; i++) {
            console.log(addresses[i]);
        }

        vm.stopBroadcast();
    }
}

// List all 1155
contract ListAll1155 is Script {
    address[] public deployedNFTs; // Array to hold deployed NFT contract addresses
    uint256[] public initialIds; // Array to hold initial token IDs
    address public initialReceiver; // Receiver address for balance queries

    function run() external {
        address factoryAddress = vm.envAddress("FACTORY_1155_CA");

        vm.startBroadcast();

        // Connect to the deployed factory
        NFT1155Factory factory = NFT1155Factory(factoryAddress);

        address[] memory addresses = factory.getAllNFTContracts();

        // Get and log the total number of NFT contracts
        uint256 totalNFTs = factory.getTotalNFTContracts();
        console.log("Total 1155 Created:", totalNFTs);

        // Log each address in the array and their balances
        for (uint256 i = 0; i < addresses.length; i++) {
            console.log("Contract Address:", addresses[i]);
        }

        vm.stopBroadcast();
    }
}
