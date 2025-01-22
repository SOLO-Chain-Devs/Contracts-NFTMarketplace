// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/core/NFTMarketplace.sol";

contract MarketplaceDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy NFTMarketplace
        NFTMarketplace marketplace = new NFTMarketplace();
        console.log("NFTMarketplace deployed to:", address(marketplace));

        vm.stopBroadcast();
    }
}
