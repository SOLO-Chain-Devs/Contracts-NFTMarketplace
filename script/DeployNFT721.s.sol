// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/mock/NFT721.sol";

contract DeployNFT721 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        NFT721 nft = new NFT721(
            "Test", // name
            "Test1", // symbol
            "",
            0x0000000000000000000000000000000000000000, // royaltyReceiver
            0, // feeNumerator
            1, // mintSupply
            0x0000000000000000000000000000000000000000 // initialReceiver
        );

        console.log("NFT721 deployed to:", address(nft));

        vm.stopBroadcast();
    }
}
