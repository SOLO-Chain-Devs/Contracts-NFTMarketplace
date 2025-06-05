// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {IMarketplace} from "../../src/interface/IMarketplace.sol";
import {NFTMarketplace} from "../../src/core/NFTMarketplace.sol";
import {NFT721Factory} from "../../src/mock/NFT721Factory.sol";
import {NFT1155Factory} from "../../src/mock/NFT1155Factory.sol";
import {NFT721} from "../../src/mock/NFT721.sol";
import {NFT1155} from "../../src/mock/NFT1155.sol";

contract CreateListing is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("OFFCHAIN_PRIVATE_KEY");
        address marketplaceAddress = vm.envAddress("MARKETPLACE_CA");

        // Connect to the deployed marketplace
        NFTMarketplace marketplace = NFTMarketplace(marketplaceAddress);
        NFT721 NFT = NFT721(0x0000000000000000000000000000000000000000);

        vm.startBroadcast(deployerPrivateKey);

        NFT.setApprovalForAll(marketplaceAddress, true);

        marketplace.createListing(
            0x0000000000000000000000000000000000000000,
            0,
            1,
            5_000_000_000_000_000_000,
            0x0000000000000000000000000000000000000000
        );

        // Get active listings
        IMarketplace.Listing[] memory activeListings = marketplace.getActiveListings();

        // Log the active listings
        for (uint256 i = 0; i < activeListings.length; i++) {
            console.log("Listing %d:", i + 1);
            console.log("  Seller: %s", activeListings[i].seller);
            console.log("  Token Address: %s", activeListings[i].tokenAddress);
            console.log("  Token ID: %d", activeListings[i].tokenId);
            console.log("  Amount: %d", activeListings[i].amount);
            console.log("  Price: %d", activeListings[i].price);
            console.log("  Currency: %s", activeListings[i].currency);
        }

        vm.stopBroadcast();
    }
}

contract ActiveListing is Script {
    function run() external {
        vm.startBroadcast();

        address marketplaceAddress = vm.envAddress("MARKETPLACE_CA");

        NFTMarketplace marketplace = NFTMarketplace(marketplaceAddress);

        // Get active listings
        IMarketplace.Listing[] memory activeListings = marketplace.getActiveListings();

        // Log the active listings
        if (activeListings.length == 0) console.log("No active listings");
        for (uint256 i = 0; i < activeListings.length; i++) {
            console.log("Listing %d:", i + 1);
            console.log("  Seller: %s", activeListings[i].seller);
            console.log("  Token Address: %s", activeListings[i].tokenAddress);
            console.log("  Token ID: %d", activeListings[i].tokenId);
            console.log("  Amount: %d", activeListings[i].amount);
            console.log("  Price: %d", activeListings[i].price);
            console.log("  Currency: %s", activeListings[i].currency);
        }

        vm.stopBroadcast();
    }
}

contract CancelListing is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("OFFCHAIN_PRIVATE_KEY");

        address marketplaceAddress = vm.envAddress("MARKETPLACE_CA");

        NFTMarketplace marketplace = NFTMarketplace(marketplaceAddress);

        vm.startBroadcast(deployerPrivateKey);

        console.log("================");
        console.log("Before Cancel");
        console.log("================");

        // Get active listings
        IMarketplace.Listing[] memory activeListings1 = marketplace.getActiveListings();

        // Log the active listings
        for (uint256 i = 0; i < activeListings1.length; i++) {
            console.log("Listing %d:", i + 1);
            console.log("  Seller: %s", activeListings1[i].seller);
            console.log("  Token Address: %s", activeListings1[i].tokenAddress);
            console.log("  Token ID: %d", activeListings1[i].tokenId);
            console.log("  Amount: %d", activeListings1[i].amount);
            console.log("  Price: %d", activeListings1[i].price);
            console.log("  Currency: %s", activeListings1[i].currency);
        }

        //        marketplace.cancelListing(1);
        //        marketplace.cancelListing(2);
        //        marketplace.cancelListing(3);
        marketplace.cancelListing(4);

        console.log("================");
        console.log("After cancel");
        console.log("================");

        IMarketplace.Listing[] memory activeListings2 = marketplace.getActiveListings();

        for (uint256 i = 0; i < activeListings2.length; i++) {
            console.log("Listing %d:", i + 1);
            console.log("  Seller: %s", activeListings2[i].seller);
            console.log("  Token Address: %s", activeListings2[i].tokenAddress);
            console.log("  Token ID: %d", activeListings2[i].tokenId);
            console.log("  Amount: %d", activeListings2[i].amount);
            console.log("  Price: %d", activeListings2[i].price);
            console.log("  Currency: %s", activeListings2[i].currency);
        }

        vm.stopBroadcast();
    }
}

contract CreateAndListNFT is Script {
    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("OFFCHAIN_PRIVATE_KEY");
        address deployerAddress = vm.envAddress("OFFCHAIN_WALLET_ADDRESS");
        address marketplaceAddress = vm.envAddress("MARKETPLACE_CA");
        address factoryAddress = vm.envAddress("FACTORY_721_CA");

        // Connect to the deployed contracts
        NFTMarketplace marketplace = NFTMarketplace(marketplaceAddress);
        NFT721Factory factory = NFT721Factory(factoryAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Create a single NFT721
        address newNFTAddress = factory.createNFT721(
            "Test NFT Collection", // name
            "TEST", // symbol
            "", // baseURI
            deployerAddress, // royaltyReceiver
            0, // feeNumerator
            10, // mintSupply
            deployerAddress // initialReceiver
        );

        console.log("Created new NFT at address:", newNFTAddress);

        // Create NFT instance
        NFT721 nft = NFT721(newNFTAddress);

        // Approve marketplace for NFT trading
        nft.setApprovalForAll(marketplaceAddress, true);

        // Create listing for the first token (ID 0)
        marketplace.createListing(
            newNFTAddress, // nftContract
            0, // tokenId
            1, // amount
            5 ether, // price (5 ETH)
            address(0) // paymentToken (ETH)
        );

        console.log("Created listing for NFT token 0");

        // Place a bid (optional)
        marketplace.placeBid{value: 0.001 ether}(
            newNFTAddress, // nftContract
            0, // tokenId
            1, // amount
            address(0), // paymentToken
            1 ether, // bidAmount
            1 days // expirationTime
        );

        console.log("Placed bid for NFT token 0");

        // Create a new bidder account for testing

        // Place higher bid with new bidder
        marketplace.placeBid{value: 0.002 ether}(
            newNFTAddress,
            0,
            1,
            address(0),
            0.002 ether,
            2 days // Different duration to verify in event
        );

        console.log("Placed outbidding bid for NFT token 0");

        vm.stopBroadcast();
    }
}

contract PlaceBid is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("OFFCHAIN_PRIVATE_KEY");
        address marketplaceAddress = vm.envAddress("MARKETPLACE_CA");

        // Connect to the deployed marketplace
        NFTMarketplace marketplace = NFTMarketplace(marketplaceAddress);

        vm.startBroadcast(deployerPrivateKey);

        marketplace.placeBid{value: 1 ether}(
            0x0000000000000000000000000000000000000000,
            0,
            1,
            0x0000000000000000000000000000000000000000,
            5_000_000_000_000_000_000, // Amount
            32_323
        );

        vm.stopBroadcast();
    }
}

contract GetActiveBids is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("OFFCHAIN_PRIVATE_KEY");
        address marketplaceAddress = vm.envAddress("MARKETPLACE_CA");

        // Connect to the deployed marketplace
        NFTMarketplace marketplace = NFTMarketplace(marketplaceAddress);

        vm.startBroadcast(deployerPrivateKey);

        marketplace.getActiveBids(0x0000000000000000000000000000000000000000, 0);

        vm.stopBroadcast();
    }
}
