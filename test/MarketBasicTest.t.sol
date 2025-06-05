// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/core/NFTMarketplace.sol";
import {NFT721} from "../src/mock/NFT721.sol";
import {NFT1155} from "../src/mock/NFT1155.sol";
import {NFT6909} from "../src/mock/NFT6909.sol";

contract MarketTest is Test {
    NFTMarketplace public market;
    NFT721 public nft721;
    NFT1155 public nft1155;
    NFT6909 public nft6909;
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

        // Setup ERC6909 with initial tokens
        uint256[] memory initialIds = new uint256[](3);
        uint256[] memory initialAmounts = new uint256[](3);
        initialIds[0] = 1;
        initialIds[1] = 2;
        initialIds[2] = 3;
        initialAmounts[0] = 100;
        initialAmounts[1] = 200;
        initialAmounts[2] = 300;

        nft6909 = new NFT6909(
            "ERC6909", "6909", "https://example.com/", msg.sender, 0, initialIds, initialAmounts, msg.sender
        );

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

    function mint6909(address _to, uint256 _tokenId, uint256 _amount) internal {
        vm.startPrank(deployer);
        nft6909.mint(_to, _tokenId, _amount);
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

    function test_Create_Listing6909() public {
        mint6909(seller1, 1, 10);

        address _tokenAddress = address(nft6909);
        uint256 _tokenId = 1;
        uint256 _amount = 5;
        uint256 _price = 1 ether;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft6909.setOperator(address(market), true); // ERC6909 uses setOperator
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

    function test_Buy_Listing_6909() public {
        mint6909(seller1, 1, 10);
        assert(nft6909.balanceOf(seller1, 1) == 10);

        address _tokenAddress = address(nft6909);
        uint256 _tokenId = 1;
        uint256 _amount = 5;
        uint256 _price = 1 ether;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft6909.setOperator(address(market), true); // ERC6909 uses setOperator
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        // Listing is purchased
        vm.startPrank(buyer1);
        market.buyListing{value: 1 ether}(1);
        vm.stopPrank();

        assert(nft6909.balanceOf(buyer1, 1) == 5); // Buyer received 5 tokens
        assert(nft6909.balanceOf(seller1, 1) == 5); // Seller has 5 remaining
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

    function test_Cancel_Listing_6909() public {
        mint6909(seller1, 1, 10);

        address _tokenAddress = address(nft6909);
        uint256 _tokenId = 1;
        uint256 _amount = 7;
        uint256 _price = 2 ether;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft6909.setOperator(address(market), true);
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

        // Cancel the listing
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

        // Verify seller still owns the tokens
        assert(nft6909.balanceOf(seller1, 1) == 10);
    }

    function test_ERC6909_Multiple_Listings() public {
        mint6909(seller1, 1, 100);
        mint6909(seller1, 2, 50);

        vm.startPrank(seller1);
        nft6909.setOperator(address(market), true);

        // Create multiple listings for different token IDs
        market.createListing(address(nft6909), 1, 30, 1 ether, address(0));
        market.createListing(address(nft6909), 2, 20, 2 ether, address(0));

        // Create another listing for same token ID but different amount
        market.createListing(address(nft6909), 1, 40, 1.5 ether, address(0));

        vm.stopPrank();

        // Verify all listings exist
        (address seller1_1,, uint256 tokenId1_1, uint256 amount1_1, uint256 price1_1,) = market.listings(1);
        (address seller2_1,, uint256 tokenId2_1, uint256 amount2_1, uint256 price2_1,) = market.listings(2);
        (address seller3_1,, uint256 tokenId3_1, uint256 amount3_1, uint256 price3_1,) = market.listings(3);

        assertEq(seller1_1, seller1);
        assertEq(tokenId1_1, 1);
        assertEq(amount1_1, 30);
        assertEq(price1_1, 1 ether);

        assertEq(seller2_1, seller1);
        assertEq(tokenId2_1, 2);
        assertEq(amount2_1, 20);
        assertEq(price2_1, 2 ether);

        assertEq(seller3_1, seller1);
        assertEq(tokenId3_1, 1);
        assertEq(amount3_1, 40);
        assertEq(price3_1, 1.5 ether);
    }

    function test_ERC6909_Partial_Purchases() public {
        mint6909(seller1, 1, 100);

        vm.startPrank(seller1);
        nft6909.setOperator(address(market), true);
        market.createListing(address(nft6909), 1, 50, 2 ether, address(0));
        vm.stopPrank();

        uint256 sellerBalanceBefore = seller1.balance;
        uint256 buyerTokenBalanceBefore = nft6909.balanceOf(buyer1, 1);

        // Buy the listing
        vm.startPrank(buyer1);
        market.buyListing{value: 2 ether}(1);
        vm.stopPrank();

        // Verify balances after purchase
        assertEq(nft6909.balanceOf(buyer1, 1), buyerTokenBalanceBefore + 50);
        assertEq(nft6909.balanceOf(seller1, 1), 50); // 100 - 50 = 50 remaining
        assertEq(seller1.balance, sellerBalanceBefore + 2 ether);
    }

    function test_ERC6909_Interface_Detection() public view {
        // Test that the marketplace correctly recognizes ERC6909 tokens
        bool isAccepted = market.isTokenAccepted(address(nft6909));
        assertTrue(isAccepted);

        // Test other standards still work
        assertTrue(market.isTokenAccepted(address(nft721)));
        assertTrue(market.isTokenAccepted(address(nft1155)));

        // Test non-NFT address
        assertFalse(market.isTokenAccepted(address(0)));
    }
}
