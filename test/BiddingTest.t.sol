// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/core/NFTMarketplace.sol";
import {NFT721} from "../src/mock/NFT721.sol";
import {NFT1155} from "../src/mock/NFT1155.sol";
import {NFT6909} from "../src/mock/NFT6909.sol";

// Custom errors
error ArrayLengthMismatch();
error PriceMustBeGreaterThanZero();
error AmountMustBeGreaterThanZero();
error CurrencyNotAccepted(address _currency);
error UnsupportedTokenStandard();
error ERC721AmountMustBe1();
error NotOwnerOfNFT();
error ContractNeedsApproval();
error InsufficientTokenBalance();
error YouAreNotTheSeller();
error ListingAlreadyCancelled();
error ListingNotActive();
error InsufficientPayment();
error EthNotAccepted();
error TokenTransferFailed();
error CurrencyNotAcceptedForBid();
error TokenAmountMustBeGreaterThanZero();
error BidMustBeHigherThanCurrent();
error NoActiveBid();
error BidHasExpired();
error BidNotTimedOut();
error BidDurationMustBeGreaterThanZero();
error CancellationFeeTooHigh();

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
            "ERC6909", 
            "6909", 
            "https://example.com/", 
            msg.sender, 
            0, 
            initialIds, 
            initialAmounts, 
            msg.sender
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
        nft6909.setOperator(address(market), true);  // ERC6909 uses setOperator instead of setApprovalForAll
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

    function test_Place_Bid_Errors() public {
        mint1155(seller1, 1, 1);
        mint721(seller1, 1);
        mint6909(seller1, 1, 10);

        vm.startPrank(buyer1);
        vm.expectRevert(InsufficientPayment.selector);
        market.placeBid(address(nft1155), 1, 1, address(0), 1 ether, 0);

        vm.expectRevert(UnsupportedTokenStandard.selector);
        market.placeBid{value: 1 ether}(address(0), 1, 1, address(0), 1 ether, 0);

        vm.expectRevert(ERC721AmountMustBe1.selector);
        market.placeBid{value: 1 ether}(address(nft721), 1, 2, address(0), 1 ether, 0);

        vm.expectRevert(TokenAmountMustBeGreaterThanZero.selector);
        market.placeBid{value: 1 ether}(address(nft721), 1, 0, address(0), 1 ether, 0);

        // Successful bids
        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), 1 ether, 0);
        market.placeBid{value: 1 ether}(address(nft6909), 1, 5, address(0), 1 ether, 0);

        vm.stopPrank();

        vm.startPrank(seller1);
        vm.expectRevert(ContractNeedsApproval.selector);
        market.acceptBid(address(nft721), 1, 1);
        
        vm.expectRevert(ContractNeedsApproval.selector);
        market.acceptBid(address(nft6909), 1, 5);
        vm.stopPrank();
    }

    function test_Place_Bid_Success() public {
        mint1155(seller1, 1, 1);
        mint721(seller1, 1);
        mint6909(seller1, 1, 10);

        vm.startPrank(buyer1);

        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), 1 ether, 0);
        market.placeBid{value: 1 ether}(address(nft1155), 1, 1, address(0), 1 ether, 0);
        market.placeBid{value: 1 ether}(address(nft6909), 1, 5, address(0), 1 ether, 0);

        vm.stopPrank();

        // Check ERC721 bid
        (address bidder721, uint256 amount721, address currency721,, uint256 tokenAmount721) = market.bids(address(nft721), 1, 1);
        assert(bidder721 == buyer1);
        assert(amount721 == 1 ether);
        assert(currency721 == address(0));
        assert(tokenAmount721 == 1);

        // Check ERC6909 bid
        (address bidder6909, uint256 amount6909, address currency6909,, uint256 tokenAmount6909) = market.bids(address(nft6909), 1, 5);
        assert(bidder6909 == buyer1);
        assert(amount6909 == 1 ether);
        assert(currency6909 == address(0));
        assert(tokenAmount6909 == 5);
    }

    function test_Accept_Bid_Errors() public {
        mint1155(seller1, 1, 1);
        mint721(seller1, 1);
        mint6909(seller1, 1, 10);

        vm.startPrank(seller1);
        vm.expectRevert(NoActiveBid.selector);
        market.acceptBid(address(nft721), 1, 1);
        
        vm.expectRevert(NoActiveBid.selector);
        market.acceptBid(address(nft6909), 1, 5);
        vm.stopPrank();

        vm.startPrank(buyer1);
        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), 1 ether, 0);
        market.placeBid{value: 1 ether}(address(nft6909), 1, 5, address(0), 1 ether, 0);
        vm.stopPrank();

        vm.startPrank(seller1);
        vm.expectRevert(ContractNeedsApproval.selector);
        market.acceptBid(address(nft721), 1, 1);

        vm.expectRevert(ContractNeedsApproval.selector);
        market.acceptBid(address(nft6909), 1, 5);

        vm.warp(block.timestamp + 8 days);
        vm.expectRevert(BidHasExpired.selector);
        market.acceptBid(address(nft721), 1, 1);
        
        vm.expectRevert(BidHasExpired.selector);
        market.acceptBid(address(nft6909), 1, 5);
        vm.stopPrank();
    }

    function test_Accept_Bid_Success() public {
        mint1155(seller1, 1, 1);
        mint721(seller1, 1);
        mint6909(seller1, 1, 10);

        uint256 sellPrice = 1 ether;
        uint256 buyerBalanceInitial = buyer1.balance;

        vm.startPrank(buyer1);
        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), sellPrice, 0);
        market.placeBid{value: 1 ether}(address(nft6909), 1, 5, address(0), sellPrice, 0);
        vm.stopPrank();

        assert(buyer1.balance == buyerBalanceInitial - (sellPrice * 2));

        // Test ERC721 bid acceptance
        assert(nft721.ownerOf(1) == seller1);
        uint256 sellerBalanceInitial = seller1.balance;

        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.acceptBid(address(nft721), 1, 1);
        vm.stopPrank();

        assert(nft721.ownerOf(1) == buyer1);
        assert(seller1.balance == sellerBalanceInitial + sellPrice);

        // Test ERC6909 bid acceptance
        assert(nft6909.balanceOf(seller1, 1) == 10);
        assert(nft6909.balanceOf(buyer1, 1) == 0);
        
        uint256 sellerBalance6909Initial = seller1.balance;

        vm.startPrank(seller1);
        nft6909.setOperator(address(market), true);  // ERC6909 uses setOperator
        market.acceptBid(address(nft6909), 1, 5);
        vm.stopPrank();

        assert(nft6909.balanceOf(seller1, 1) == 5);  // 10 - 5 = 5 remaining
        assert(nft6909.balanceOf(buyer1, 1) == 5);   // buyer received 5 tokens
        assert(seller1.balance == sellerBalance6909Initial + sellPrice);
    }

    function test_ERC6909_Multi_Token_Scenarios() public {
        mint6909(seller1, 1, 100);
        mint6909(seller1, 2, 50);

        vm.startPrank(buyer1);
        // Place bids on different amounts of the same token
        market.placeBid{value: 1 ether}(address(nft6909), 1, 10, address(0), 1 ether, 0);
        market.placeBid{value: 2 ether}(address(nft6909), 1, 20, address(0), 2 ether, 0);
        
        // Place bid on different token ID
        market.placeBid{value: 3 ether}(address(nft6909), 2, 25, address(0), 3 ether, 0);
        vm.stopPrank();

        // Verify all bids exist independently
        (address bidder1,,,, uint256 tokenAmount1) = market.bids(address(nft6909), 1, 10);
        (address bidder2,,,, uint256 tokenAmount2) = market.bids(address(nft6909), 1, 20);
        (address bidder3,,,, uint256 tokenAmount3) = market.bids(address(nft6909), 2, 25);

        assert(bidder1 == buyer1 && tokenAmount1 == 10);
        assert(bidder2 == buyer1 && tokenAmount2 == 20);
        assert(bidder3 == buyer1 && tokenAmount3 == 25);
    }
}
