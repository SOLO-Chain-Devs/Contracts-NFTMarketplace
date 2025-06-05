// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/mock/NFT721Factory.sol";
import "../src/mock/NFT1155Factory.sol";
import "../src/mock/NFT6909Factory.sol";

contract FactoryDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy NFT721Factory
        NFT721Factory nft721Factory = new NFT721Factory();
        console.log("NFT721Factory deployed to:", address(nft721Factory));

        // Deploy NFT1155Factory
        NFT1155Factory nft1155Factory = new NFT1155Factory();
        console.log("NFT1155Factory deployed to:", address(nft1155Factory));

        // Deploy NFT6909Factory
        NFT6909Factory nft6909Factory = new NFT6909Factory();
        console.log("NFT6909Factory deployed to:", address(nft6909Factory));

        vm.stopBroadcast();
    }
}
