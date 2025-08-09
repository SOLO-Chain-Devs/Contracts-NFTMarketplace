// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import {NFTMarketplace} from "src/core/NFTMarketplace.sol";
import {NFT721} from "src/mock/NFT721.sol";
import {NFT1155} from "src/mock/NFT1155.sol";
import {IMarketplace} from "src/interface/IMarketplace.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract RoyaltyTest is Test {
    NFTMarketplace marketplace;
    address seller = address(0xA11CE);
    address buyer = address(0xB0B);
    address royaltyReceiver = address(0xFEE);

    function setUp() public {
        vm.deal(buyer, 100 ether);
        vm.deal(seller, 1 ether);
        // Deploy marketplace
        marketplace = new NFTMarketplace();
        // Accept ETH already set in constructor
    }

    function testRoyaltyERC721() public {
        // Deploy ERC721 with 10% royalty
        NFT721 nft = new NFT721("Col", "COL", "ipfs://base/", royaltyReceiver, 1000, 1, seller);

        // Seller approves marketplace
        vm.prank(seller);
        nft.setApprovalForAll(address(marketplace), true);

        // Create listing: price 1 ether, amount 1, currency ETH
        vm.prank(seller);
        marketplace.createListing(address(nft), 0, 1, 1 ether, address(0));

        // Expect royaltyReceiver to get 0.1 ether and seller to get 0.9 ether
        uint256 sellerBefore = seller.balance;
        uint256 royaltyBefore = royaltyReceiver.balance;

        vm.prank(buyer);
        marketplace.buyListing{value: 1 ether}(1);

        assertEq(royaltyReceiver.balance - royaltyBefore, 0.1 ether, "ERC721 royalty incorrect");
        assertEq(seller.balance - sellerBefore, 0.9 ether, "ERC721 seller proceeds incorrect");
        assertEq(nft.ownerOf(0), buyer, "ERC721 ownership not transferred");
    }

    function testRoyaltyERC1155() public {
        // Deploy ERC1155 with 5% royalty and mint 10 units of id 1 to seller
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        uint256[] memory amts = new uint256[](1);
        amts[0] = 10;
        NFT1155 nft = new NFT1155("Col", "COL", "ipfs://base/{id}", royaltyReceiver, 500, ids, amts, seller);

        // Seller approves marketplace
        vm.prank(seller);
        nft.setApprovalForAll(address(marketplace), true);

        // Create listing for 4 units at total price 2 ether (salePrice is total per EIP-2981 semantics)
        vm.prank(seller);
        marketplace.createListing(address(nft), 1, 4, 2 ether, address(0));

        uint256 sellerBefore = seller.balance;
        uint256 royaltyBefore = royaltyReceiver.balance;

        vm.prank(buyer);
        marketplace.buyListing{value: 2 ether}(1);

        // 5% of 2 ether = 0.1 ether
        assertEq(royaltyReceiver.balance - royaltyBefore, 0.1 ether, "ERC1155 royalty incorrect");
        assertEq(seller.balance - sellerBefore, 1.9 ether, "ERC1155 seller proceeds incorrect");
        assertEq(IERC1155(address(nft)).balanceOf(buyer, 1), 4, "ERC1155 balance not transferred");
    }
}


