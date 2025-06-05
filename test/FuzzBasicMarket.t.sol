// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/core/NFTMarketplace.sol";
import {NFT721} from "../src/mock/NFT721.sol";
import {NFT1155} from "../src/mock/NFT1155.sol";
import {NFT6909} from "../src/mock/NFT6909.sol";

contract MarketFuzzTest is Test {
    NFTMarketplace public market;
    NFT721 public nft721;
    NFT1155 public nft1155;
    NFT6909 public nft6909;
    address public deployer;
    address public seller1;
    address public buyer1;

    function setUp() public {
        deployer = msg.sender;
        seller1 = vm.addr(1);
        buyer1 = vm.addr(2);

        vm.startPrank(deployer);
        market = new NFTMarketplace();
        nft721 = new NFT721("ERC721", "721", "", msg.sender, 0, 0, msg.sender);
        nft1155 = new NFT1155("ERC1155", "1155", "", msg.sender, 0, new uint256[](1), new uint256[](1), msg.sender);

        // Setup ERC6909 with initial tokens for testing
        uint256[] memory initialIds = new uint256[](1);
        uint256[] memory initialAmounts = new uint256[](1);
        initialIds[0] = 1;
        initialAmounts[0] = 1000; // Large initial supply for fuzz testing
        
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
        vm.deal(buyer1, 100 ether);
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

    // Fuzz test for creating an ERC721 listing
    function testFuzz_Create_Listing721(uint256 _tokenId, uint256 _price) public {
        // Constraints on the fuzzed values
        vm.assume(_price > 0 && _price < 100 ether); // Price should be positive and realistic
        vm.assume(_tokenId > 0); // Token ID should be positive

        mint721(seller1, _tokenId);

        address _tokenAddress = address(nft721);
        uint256 _amount = 1;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        (address seller, address tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address currency) =
            market.listings(1);

        // Assert that the listing has been created correctly
        assertEq(seller, seller1);
        assertEq(tokenAddress, _tokenAddress);
        assertEq(tokenId, _tokenId);
        assertEq(amount, _amount);
        assertEq(price, _price);
        assertEq(currency, _currency);
    }

    // Fuzz test for creating an ERC1155 listing
    function testFuzz_Create_Listing1155(uint256 _tokenId, uint256 _amount, uint256 _price) public {
        // Constraints on the fuzzed values
        vm.assume(_price > 0 && _price < 100 ether); // Price should be positive and realistic
        vm.assume(_amount > 0 && _amount <= 100); // Amount should be positive and limited for practicality
        vm.assume(_tokenId > 0); // Token ID should be positive

        mint1155(seller1, _tokenId, _amount);

        address _tokenAddress = address(nft1155);
        address _currency = address(0);

        vm.startPrank(seller1);
        nft1155.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        (address seller, address tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address currency) =
            market.listings(1);

        // Assert that the listing has been created correctly
        assertEq(seller, seller1);
        assertEq(tokenAddress, _tokenAddress);
        assertEq(tokenId, _tokenId);
        assertEq(amount, _amount);
        assertEq(price, _price);
        assertEq(currency, _currency);
    }

    // Fuzz test for creating an ERC6909 listing
    function testFuzz_Create_Listing6909(uint256 _tokenId, uint256 _amount, uint256 _price) public {
        // Constraints on the fuzzed values
        vm.assume(_price > 0 && _price < 100 ether); // Price should be positive and realistic
        vm.assume(_amount > 0 && _amount <= 100); // Amount should be positive and limited for practicality
        vm.assume(_tokenId > 0); // Token ID should be positive

        mint6909(seller1, _tokenId, _amount);

        address _tokenAddress = address(nft6909);
        address _currency = address(0);

        vm.startPrank(seller1);
        nft6909.setOperator(address(market), true); // ERC6909 uses setOperator
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        (address seller, address tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address currency) =
            market.listings(1);

        // Assert that the listing has been created correctly
        assertEq(seller, seller1);
        assertEq(tokenAddress, _tokenAddress);
        assertEq(tokenId, _tokenId);
        assertEq(amount, _amount);
        assertEq(price, _price);
        assertEq(currency, _currency);
    }

    // Fuzz test for buying an ERC721 listing
    function testFuzz_Buy_Listing_721(uint256 _tokenId, uint256 _price) public {
        vm.assume(_price > 0 && _price < 100 ether); // Price should be positive and realistic
        vm.assume(_tokenId > 0); // Token ID should be positive

        mint721(seller1, _tokenId);

        // Create a listing for ERC721
        address _tokenAddress = address(nft721);
        uint256 _amount = 1;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        // Buyer purchases the listing
        vm.startPrank(buyer1);
        market.buyListing{value: _price}(1);
        vm.stopPrank();

        // Assert that the buyer is now the owner of the token
        assertEq(nft721.ownerOf(_tokenId), buyer1);
    }

    // Fuzz test for buying an ERC1155 listing
    function testFuzz_Buy_Listing_1155(uint256 _tokenId, uint256 _amount, uint256 _price) public {
        vm.assume(_price > 0 && _price < 100 ether); // Price should be positive and realistic
        vm.assume(_amount > 0 && _amount <= 100); // Amount should be positive and limited for practicality
        vm.assume(_tokenId > 0); // Token ID should be positive

        mint1155(seller1, _tokenId, _amount);

        // Create a listing for ERC1155
        address _tokenAddress = address(nft1155);
        address _currency = address(0);

        vm.startPrank(seller1);
        nft1155.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        // Buyer purchases the listing
        vm.startPrank(buyer1);
        market.buyListing{value: _price}(1);
        vm.stopPrank();

        // Assert that the buyer now owns the listed amount of tokens
        assertEq(nft1155.balanceOf(buyer1, _tokenId), _amount);
    }

    // Fuzz test for buying an ERC6909 listing
    function testFuzz_Buy_Listing_6909(uint256 _tokenId, uint256 _amount, uint256 _price) public {
        vm.assume(_price > 0 && _price < 100 ether); // Price should be positive and realistic
        vm.assume(_amount > 0 && _amount <= 100); // Amount should be positive and limited for practicality
        vm.assume(_tokenId > 0); // Token ID should be positive

        mint6909(seller1, _tokenId, _amount);

        // Create a listing for ERC6909
        address _tokenAddress = address(nft6909);
        address _currency = address(0);

        vm.startPrank(seller1);
        nft6909.setOperator(address(market), true); // ERC6909 uses setOperator
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        // Buyer purchases the listing
        vm.startPrank(buyer1);
        market.buyListing{value: _price}(1);
        vm.stopPrank();

        // Assert that the buyer now owns the listed amount of tokens
        assertEq(nft6909.balanceOf(buyer1, _tokenId), _amount);
    }

    // Fuzz test for canceling a listing
    function testFuzz_Cancel_Listing(uint256 _tokenId, uint256 _price) public {
        vm.assume(_price > 0 && _price < 100 ether); // Price should be positive and realistic
        vm.assume(_tokenId > 0); // Token ID should be positive

        mint721(seller1, _tokenId);

        // Create a listing for ERC721
        address _tokenAddress = address(nft721);
        uint256 _amount = 1;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        (address seller,,,,,) = market.listings(1);

        // Assert that the listing was created correctly
        assertEq(seller, seller1);

        // Cancel the listing
        vm.startPrank(seller1);
        market.cancelListing(1);
        vm.stopPrank();

        // Check that the listing no longer exists (all values should be default)
        (address seller_, address tokenAddress_, uint256 tokenId_, uint256 amount_, uint256 price_, address currency_) =
            market.listings(1);

        assertEq(seller_, address(0));
        assertEq(tokenAddress_, address(0));
        assertEq(tokenId_, 0);
        assertEq(amount_, 0);
        assertEq(price_, 0);
        assertEq(currency_, address(0));
    }

    // Fuzz test for ERC6909 bidding scenarios
    function testFuzz_ERC6909_Bidding(uint256 _tokenId, uint256 _amount, uint256 _bidAmount) public {
        vm.assume(_bidAmount > 0 && _bidAmount < 100 ether);
        vm.assume(_amount > 0 && _amount <= 50); // Reduced upper limit
        vm.assume(_tokenId > 0); // Removed upper limit

        mint6909(seller1, _tokenId, _amount + 10); // Mint extra to ensure sufficient balance

        vm.startPrank(buyer1);
        market.placeBid{value: _bidAmount}(address(nft6909), _tokenId, _amount, address(0), _bidAmount, 0);
        vm.stopPrank();

        // Verify bid was placed correctly
        (address bidder, uint256 bidAmountStored, address currency,, uint256 tokenAmount) = 
            market.bids(address(nft6909), _tokenId, _amount);

        assertEq(bidder, buyer1);
        assertEq(bidAmountStored, _bidAmount);
        assertEq(currency, address(0));
        assertEq(tokenAmount, _amount);

        // Test bid acceptance
        vm.startPrank(seller1);
        nft6909.setOperator(address(market), true);
        market.acceptBid(address(nft6909), _tokenId, _amount);
        vm.stopPrank();

        // Verify token transfer
        assertEq(nft6909.balanceOf(buyer1, _tokenId), _amount);
    }

    // Fuzz test for ERC6909 multiple bid amounts on same token
    function testFuzz_ERC6909_Multiple_Bids(uint256 _tokenId, uint256 _amount1, uint256 _amount2) public {
        _tokenId = bound(_tokenId, 1, type(uint256).max);  // Ensure tokenId > 0
        _amount1 = bound(_amount1, 1, 25);  // Ensure 1 <= _amount1 <= 25
        _amount2 = bound(_amount2, 1, 25);  // Ensure 1 <= _amount2 <= 25
        
        // Ensure different amounts for the bids
        if (_amount1 == _amount2) {
            _amount2 = _amount1 == 25 ? _amount2 - 1 : _amount2 + 1;
        }

        uint256 _bid1 = 1 ether; // Fixed values to reduce constraint complexity
        uint256 _bid2 = 2 ether;

        mint6909(seller1, _tokenId, _amount1 + _amount2 + 10);

        // Place two different bids on different amounts of the same token
        vm.startPrank(buyer1);
        market.placeBid{value: _bid1}(address(nft6909), _tokenId, _amount1, address(0), _bid1, 0);
        market.placeBid{value: _bid2}(address(nft6909), _tokenId, _amount2, address(0), _bid2, 0);
        vm.stopPrank();

        // Verify both bids exist independently
        (address bidder1, uint256 bidAmount1,,, uint256 tokenAmount1) = 
            market.bids(address(nft6909), _tokenId, _amount1);
        (address bidder2, uint256 bidAmount2,,, uint256 tokenAmount2) = 
            market.bids(address(nft6909), _tokenId, _amount2);

        assertEq(bidder1, buyer1);
        assertEq(bidAmount1, _bid1);
        assertEq(tokenAmount1, _amount1);

        assertEq(bidder2, buyer1);
        assertEq(bidAmount2, _bid2);
        assertEq(tokenAmount2, _amount2);
    }

    // Comprehensive fuzz test for ERC6909 marketplace operations
        function testFuzz_ERC6909_Complete_Flow(uint256 _tokenId, uint256 _listAmount, uint256 _bidAmount) public {
        _tokenId = bound(_tokenId, 1, type(uint256).max);  // Ensure tokenId > 0
        _listAmount = bound(_listAmount, 1, 25);  // Ensure 1 <= _listAmount <= 25
        _bidAmount = bound(_bidAmount, 1, 25);    // Ensure 1 <= _bidAmount <= 25
        
        // Ensure different amounts for listing vs bidding
        if (_listAmount == _bidAmount) {
            _bidAmount = _listAmount == 25 ? _bidAmount - 1 : _bidAmount + 1;
        }

        uint256 _listPrice = 1 ether;  // Fixed values to reduce constraint complexity
        uint256 _bidPrice = 2 ether;

        uint256 totalMint = _listAmount + _bidAmount + 20;
        mint6909(seller1, _tokenId, totalMint);

        // Test listing creation
        vm.startPrank(seller1);
        nft6909.setOperator(address(market), true);
        market.createListing(address(nft6909), _tokenId, _listAmount, _listPrice, address(0));
        vm.stopPrank();

        // Test bid placement on different amount
        vm.startPrank(buyer1);
        market.placeBid{value: _bidPrice}(address(nft6909), _tokenId, _bidAmount, address(0), _bidPrice, 0);
        vm.stopPrank();

        // Verify listing exists
        (address listingSeller, address listingToken, uint256 listingTokenId, uint256 listingAmount, uint256 listingPrice,) =
            market.listings(1);
        assertEq(listingSeller, seller1);
        assertEq(listingToken, address(nft6909));
        assertEq(listingTokenId, _tokenId);
        assertEq(listingAmount, _listAmount);
        assertEq(listingPrice, _listPrice);

        // Verify bid exists
        (address bidder, uint256 bidAmountStored,,, uint256 bidTokenAmount) = 
            market.bids(address(nft6909), _tokenId, _bidAmount);
        assertEq(bidder, buyer1);
        assertEq(bidAmountStored, _bidPrice);
        assertEq(bidTokenAmount, _bidAmount);

        // Test bid acceptance
        vm.startPrank(seller1);
        market.acceptBid(address(nft6909), _tokenId, _bidAmount);
        vm.stopPrank();

        // Verify bid was accepted and tokens transferred
        assertEq(nft6909.balanceOf(buyer1, _tokenId), _bidAmount);
        assertEq(nft6909.balanceOf(seller1, _tokenId), totalMint - _bidAmount);
    }
}
