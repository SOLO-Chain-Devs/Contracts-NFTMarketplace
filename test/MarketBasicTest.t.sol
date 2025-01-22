// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/core/NFTMarketplace.sol";
import {NFT721} from "../src/mock/NFT721.sol";
import {NFT1155} from "../src/mock/NFT1155.sol";

contract MarketTest is Test {
    NFTMarketplace public market;
    NFT721 public nft721;
    NFT1155 public nft1155;
    address public deployer;
    address public seller1 = vm.addr(1);
    address public buyer1 = vm.addr(2);
    address public seller2 = vm.addr(3);
    address public buyer2 = vm.addr(4);
    address public user5 = vm.addr(5);

    function setUp() public {
        deployer = msg.sender;
        vm.startPrank(deployer);
        market = new NFTMarketplace();
        nft721 = new NFT721("ERC721", "721", "", msg.sender, 0, 0, msg.sender);
        nft1155 = new NFT1155("ERC1155", "1155", "", msg.sender, 0, new uint256[](1), new uint256[](1), msg.sender);

        vm.stopPrank();
        vm.deal(deployer, 100 ether);
        vm.deal(seller1, 100 ether);
        vm.deal(seller2, 100 ether);
        vm.deal(buyer1, 100 ether);
        vm.deal(buyer2, 100 ether);
        vm.deal(user5, 100 ether);
    }

    function mint721(address _to, uint256 _id) internal {
        vm.startPrank(deployer);
        nft721.safeMint(_to, _id);
        vm.stopPrank();
    }

    function mint1155(address _to, uint256 _tokenId, uint256 _amount) internal {
        vm.startPrank(deployer);
        nft1155.mint(_to, _tokenId, _amount, "");
        vm.stopPrank();
    }

    function test_Create_Listing721() public {
        mint721(seller1, 1);

        address _tokenAddress = address(nft721);
        uint256 _tokenId = 1;
        uint256 _amount = 1;
        uint256 _price = 1 ether;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        (address seller, address tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address currency) =
            market.listings(1);

        assertEq(seller, seller1);
        assertEq(tokenAddress, _tokenAddress);
        assertEq(tokenId, _tokenId);
        assertEq(amount, _amount);
        assertEq(price, _price);
        assertEq(currency, _currency);
    }

    function test_Create_Listing1155() public {
        mint1155(seller1, 1, 1);

        address _tokenAddress = address(nft1155);
        uint256 _tokenId = 1;
        uint256 _amount = 1;
        uint256 _price = 1 ether;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft1155.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        (address seller, address tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address currency) =
            market.listings(1);

        assertEq(seller, seller1);
        assertEq(tokenAddress, _tokenAddress);
        assertEq(tokenId, _tokenId);
        assertEq(amount, _amount);
        assertEq(price, _price);
        assertEq(currency, _currency);
    }

    function test_Buy_Listing_721() public {
        mint721(seller1, 1);

        // Listing is created
        address _tokenAddress = address(nft721);
        uint256 _tokenId = 1;
        uint256 _amount = 1;
        uint256 _price = 1 ether;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        // Listing is purchased
        vm.startPrank(buyer1);
        market.buyListing{value: 1 ether}(1);
        vm.stopPrank();

        assert(nft721.ownerOf(1) == buyer1);
    }

    function test_Buy_Listing_1155() public {
        mint1155(seller1, 1, 1);
        assert(nft1155.balanceOf(seller1, 1) == 1);

        address _tokenAddress = address(nft1155);
        uint256 _tokenId = 1;
        uint256 _amount = 1;
        uint256 _price = 1 ether;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft1155.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        // Listing is purchased
        vm.startPrank(buyer1);
        market.buyListing{value: 1 ether}(1);
        vm.stopPrank();

        assert(nft1155.balanceOf(buyer1, 1) == 1);
    }

    function test_Cancel_Listing() public {
        mint721(seller1, 1);

        address _tokenAddress = address(nft721);
        uint256 _tokenId = 1;
        uint256 _amount = 1;
        uint256 _price = 1 ether;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        (address seller, address tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address currency) =
            market.listings(1);

        assertEq(seller, seller1);
        assertEq(tokenAddress, _tokenAddress);
        assertEq(tokenId, _tokenId);
        assertEq(amount, _amount);
        assertEq(price, _price);
        assertEq(currency, _currency);

        vm.startPrank(seller1);
        market.cancelListing(1);
        vm.stopPrank();

        (address seller_, address tokenAddress_, uint256 tokenId_, uint256 amount_, uint256 price_, address currency_) =
            market.listings(1);

        assertEq(seller_, address(0));
        assertEq(tokenAddress_, address(0));
        assertEq(tokenId_, 0);
        assertEq(amount_, 0);
        assertEq(price_, 0);
        assertEq(currency_, address(0));
    }
}
