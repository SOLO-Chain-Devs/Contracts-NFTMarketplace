// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/mock/NFT1155.sol";

contract DeployNFT1155 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Setup initial IDs and amounts
        uint256[] memory initialIds = new uint256[](4);
        initialIds[0] = 1;
        initialIds[1] = 2;
        initialIds[2] = 5;
        initialIds[3] = 7;

        uint256[] memory initialAmounts = new uint256[](4);
        initialAmounts[0] = 100;
        initialAmounts[1] = 200;
        initialAmounts[2] = 505;
        initialAmounts[3] = 0;

        NFT1155 nft = new NFT1155(
            "Test1155", // name
            "TST1155", // symbol
            "",
            0x0000000000000000000000000000000000000000, // royaltyReceiver
            0, // feeNumerator
            initialIds, // initialIds
            initialAmounts, // initialAmounts
            0x0000000000000000000000000000000000000000 // initialReceiver
        );

        console.log("NFT1155 deployed to:", address(nft));

        vm.stopBroadcast();
    }
}
