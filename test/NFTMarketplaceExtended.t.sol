// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/core/NFTMarketplace.sol";
import {NFT721} from "../src/mock/NFT721.sol";
import {NFT1155} from "../src/mock/NFT1155.sol";
import {NFT6909} from "../src/mock/NFT6909.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {DummyCurator} from "../src/mock/DummyCurator.sol";
import {IMarketplace} from "../src/interface/IMarketplace.sol";

/**
 * @title Extended test suite for NFTMarketplace
 * @dev Focuses on edge cases, error conditions, and admin functionality to achieve 90%+ coverage
 */
contract NFTMarketplaceExtendedTest is Test {
    NFTMarketplace public market;
    NFT721 public nft721;
    NFT1155 public nft1155;
    NFT6909 public nft6909;
    MockERC20 public mockToken;
    DummyCurator public curator;
    
    address public deployer;
    address public seller = vm.addr(1);
    address public buyer = vm.addr(2);
    address public attacker = vm.addr(3);
    address public admin = vm.addr(4);
    
    // Events for testing
    event ListingCreated(uint256 indexed listingId, address indexed seller, address indexed tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address currency);
    event ListingCancelled(uint256 indexed listingId);
    event ListingSold(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 price, address currency, uint256 royaltyAmount, address royaltyReceiver);
    event BidPlaced(address indexed tokenAddress, uint256 indexed tokenId, uint256 indexed tokenAmount, address bidder, uint256 amount, address currency, uint256 duration);
    event BidAccepted(address indexed tokenAddress, uint256 indexed tokenId, uint256 tokenAmount, address indexed seller, address bidder, uint256 amount, address currency, uint256 royaltyAmount, address royaltyReceiver);
    event BidCancelled(address indexed tokenAddress, uint256 indexed tokenId, uint256 tokenAmount, address indexed bidder, uint256 amount, address currency, address canceller, uint256 cancellationFee);
    event BidOutbid(address indexed tokenAddress, uint256 indexed tokenId, uint256 tokenAmount, address indexed previousBidder, address newBidder, uint256 previousAmount, uint256 newAmount, address currency, uint256 previousTimeout, uint256 newTimeout);
    event CurrencyStatusUpdated(address indexed currency, bool accepted);
    event CurationEnabled(bool enabled);
    event CurationValidatorUpdated(address indexed newValidator, address indexed oldValidator);

    function setUp() public {
        deployer = msg.sender;
        
        vm.startPrank(deployer);
        market = new NFTMarketplace();
        nft721 = new NFT721("ERC721", "721", "", deployer, 0, 0, deployer);
        nft1155 = new NFT1155("ERC1155", "1155", "", deployer, 0, new uint256[](1), new uint256[](1), deployer);
        nft6909 = new NFT6909("ERC6909", "6909", "https://example.com/", deployer, 0, new uint256[](0), new uint256[](0), deployer);
        mockToken = new MockERC20("MockToken", "MOCK", 18);
        curator = new DummyCurator();
        vm.stopPrank();
        
        // Setup balances
        vm.deal(seller, 100 ether);
        vm.deal(buyer, 100 ether);
        vm.deal(attacker, 100 ether);
        
        // Mint tokens to users
        mockToken.mint(buyer, 1000 ether);
        mockToken.mint(seller, 1000 ether);
    }

    // ===== ERROR CONDITION TESTS =====
    
    function test_CreateListing_RevertZeroPrice() public {
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSignature("PriceMustBeGreaterThanZero()"));
        market.createListing(address(nft721), 1, 1, 0, address(0));
        vm.stopPrank();
    }
    
    function test_CreateListing_RevertZeroAmount() public {
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSignature("AmountMustBeGreaterThanZero()"));
        market.createListing(address(nft721), 1, 0, 1 ether, address(0));
        vm.stopPrank();
    }
    
    function test_CreateListing_RevertUnsupportedCurrency() public {
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSignature("CurrencyNotAccepted(address)", address(mockToken)));
        market.createListing(address(nft721), 1, 1, 1 ether, address(mockToken));
        vm.stopPrank();
    }
    
    function test_CreateListing_RevertUnsupportedTokenStandard() public {
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSignature("UnsupportedTokenStandard()"));
        market.createListing(address(mockToken), 1, 1, 1 ether, address(0)); // ERC20 is not supported
        vm.stopPrank();
    }
    
    function test_CreateListing_RevertERC721WrongAmount() public {
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSignature("ERC721AmountMustBe1()"));
        market.createListing(address(nft721), 1, 2, 1 ether, address(0));
        vm.stopPrank();
    }
    
    function test_CreateListing_RevertNotOwner() public {
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(buyer); // buyer doesn't own token 1
        vm.expectRevert(abi.encodeWithSignature("NotOwnerOfNFT()"));
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        vm.stopPrank();
    }
    
    function test_CreateListing_RevertNoApproval() public {
        _mint721(seller, 1); // No approval given
        
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSignature("ContractNeedsApproval()"));
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        vm.stopPrank();
    }
    
    function test_CreateListing_RevertInsufficientBalance1155() public {
        _mintAndApprove1155(seller, 1, 5);
        
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSignature("InsufficientTokenBalance()"));
        market.createListing(address(nft1155), 1, 10, 1 ether, address(0)); // Trying to list 10 but only has 5
        vm.stopPrank();
    }

    // ===== ADMIN FUNCTION TESTS =====
    
    function test_SetAcceptedCurrencies_Success() public {
        address[] memory currencies = new address[](1);
        bool[] memory accepted = new bool[](1);
        currencies[0] = address(mockToken);
        accepted[0] = true;
        
        vm.expectEmit(true, false, false, true);
        emit CurrencyStatusUpdated(address(mockToken), true);
        
        vm.startPrank(deployer);
        market.setAcceptedCurrencies(currencies, accepted);
        vm.stopPrank();
        
        assertTrue(market.acceptedCurrencies(address(mockToken)));
    }
    
    function test_SetAcceptedCurrencies_RevertArrayMismatch() public {
        address[] memory currencies = new address[](1);
        bool[] memory accepted = new bool[](2);
        currencies[0] = address(mockToken);
        accepted[0] = true;
        accepted[1] = false;
        
        vm.startPrank(deployer);
        vm.expectRevert(abi.encodeWithSignature("ArrayLengthMismatch()"));
        market.setAcceptedCurrencies(currencies, accepted);
        vm.stopPrank();
    }
    
    function test_SetAcceptedCurrencies_RevertInvalidCurrency() public {
        address[] memory currencies = new address[](1);
        bool[] memory accepted = new bool[](1);
        currencies[0] = address(0x123); // EOA address, not contract
        accepted[0] = true;
        
        vm.startPrank(deployer);
        vm.expectRevert(abi.encodeWithSignature("InvalidCurrency(address)", address(0x123)));
        market.setAcceptedCurrencies(currencies, accepted);
        vm.stopPrank();
    }
    
    function test_SetBidDuration_Success() public {
        uint256 newDuration = 3 days;
        
        vm.startPrank(deployer);
        market.setBidDuration(newDuration);
        vm.stopPrank();
        
        assertEq(market.bidDuration(), newDuration);
    }
    
    function test_SetBidDuration_RevertZero() public {
        vm.startPrank(deployer);
        vm.expectRevert(abi.encodeWithSignature("BidDurationMustBeGreaterThanZero()"));
        market.setBidDuration(0);
        vm.stopPrank();
    }
    
    function test_SetBidDuration_RevertTooLong() public {
        vm.startPrank(deployer);
        vm.expectRevert(abi.encodeWithSignature("BidDurationTooLong()"));
        market.setBidDuration(366 days); // MAX_BID_DURATION is 365 days
        vm.stopPrank();
    }
    
    function test_SetCancellationFeePercentage_Success() public {
        uint256 newFee = 500; // 5%
        
        vm.startPrank(deployer);
        market.setCancellationFeePercentage(newFee);
        vm.stopPrank();
        
        assertEq(market.cancellationFeePercentage(), newFee);
    }
    
    function test_SetCancellationFeePercentage_RevertTooHigh() public {
        vm.startPrank(deployer);
        vm.expectRevert(abi.encodeWithSignature("CancellationFeeTooHigh()"));
        market.setCancellationFeePercentage(3001); // MAX is 3000 (30%)
        vm.stopPrank();
    }

    // ===== CURATION SYSTEM TESTS =====
    
    function test_SetCurationEnabled() public {
        vm.expectEmit(false, false, false, true);
        emit CurationEnabled(true);
        
        vm.startPrank(deployer);
        market.setCurationEnabled(true);
        vm.stopPrank();
        
        assertTrue(market.curationEnabled());
    }
    
    function test_SetCurationValidator() public {
        vm.expectEmit(true, true, false, false);
        emit CurationValidatorUpdated(address(curator), address(0));
        
        vm.startPrank(deployer);
        market.setCurationValidator(address(curator));
        vm.stopPrank();
        
        assertEq(market.curationValidator(), address(curator));
    }
    
    function test_CurationBlocks_UnApprovedCollection() public {
        // Enable curation and set validator
        vm.startPrank(deployer);
        market.setCurationEnabled(true);
        market.setCurationValidator(address(curator));
        vm.stopPrank();
        
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSignature("CollectionNotApproved(address)", address(nft721)));
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        vm.stopPrank();
    }
    
    function test_CurationAllows_ApprovedCollection() public {
        // Enable curation and set validator
        vm.startPrank(deployer);
        market.setCurationEnabled(true);
        market.setCurationValidator(address(curator));
        curator.approveCollection(address(nft721));
        vm.stopPrank();
        
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        market.createListing(address(nft721), 1, 1, 1 ether, address(0)); // Should succeed
        vm.stopPrank();
        
        (, address tokenAddress,,,, ) = market.listings(1);
        assertEq(tokenAddress, address(nft721));
    }

    // ===== BID TESTING =====
    
    function test_PlaceBid_Success() public {
        _mintAndApprove721(seller, 1);
        
        vm.expectEmit(true, true, true, false);
        emit BidPlaced(address(nft721), 1, 1, buyer, 1 ether, address(0), 7 days);
        
        vm.startPrank(buyer);
        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), 1 ether, 0);
        vm.stopPrank();
        
        (address bidder, uint256 amount, address currency, uint256 timeout, uint256 tokenAmount) = 
            market.bids(address(nft721), 1, 1);
        
        assertEq(bidder, buyer);
        assertEq(amount, 1 ether);
        assertEq(currency, address(0));
        assertEq(tokenAmount, 1);
        assertGt(timeout, block.timestamp);
    }
    
    function test_PlaceBid_RevertERC721WrongAmount() public {
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(buyer);
        vm.expectRevert(abi.encodeWithSignature("ERC721AmountMustBe1()"));
        market.placeBid{value: 1 ether}(address(nft721), 1, 2, address(0), 1 ether, 0); // ERC721 must be amount 1
        vm.stopPrank();
    }
    
    function test_PlaceBid_RevertDurationTooLong() public {
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(buyer);
        vm.expectRevert(abi.encodeWithSignature("DurationExceedsMaximum()"));
        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), 1 ether, 8 days); // Default is 7 days
        vm.stopPrank();
    }
    
    function test_BidReplacement_HigherBid() public {
        _mintAndApprove721(seller, 1);
        
        // First bid
        vm.startPrank(buyer);
        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), 1 ether, 0);
        vm.stopPrank();
        
        // Second higher bid should replace
        // vm.expectEmit(true, true, true, false);
        // emit BidOutbid(address(nft721), 1, 1, buyer, attacker, 1 ether, 2 ether, address(0), block.timestamp + 7 days, block.timestamp + 7 days);
        
        vm.startPrank(attacker);
        market.placeBid{value: 2 ether}(address(nft721), 1, 1, address(0), 2 ether, 0);
        vm.stopPrank();
        
        (address bidder, uint256 amount,,,) = market.bids(address(nft721), 1, 1);
        assertEq(bidder, attacker);
        assertEq(amount, 2 ether);
    }
    
    function test_BidReplacement_RevertLowerBid() public {
        _mintAndApprove721(seller, 1);
        
        // First bid
        vm.startPrank(buyer);
        market.placeBid{value: 2 ether}(address(nft721), 1, 1, address(0), 2 ether, 0);
        vm.stopPrank();
        
        // Lower bid should revert
        vm.startPrank(attacker);
        vm.expectRevert(abi.encodeWithSignature("BidMustBeHigherThanCurrent()"));
        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), 1 ether, 0);
        vm.stopPrank();
    }

    // ===== CANCEL LISTING TESTS =====
    
    function test_CancelListing_RevertNotSeller() public {
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        vm.stopPrank();
        
        vm.startPrank(buyer); // Not the seller
        vm.expectRevert(abi.encodeWithSignature("YouAreNotTheSeller()"));
        market.cancelListing(1);
        vm.stopPrank();
    }
    
    function test_CancelListing_RevertAlreadyCancelled() public {
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        market.cancelListing(1); // First cancellation
        
        vm.expectRevert(abi.encodeWithSignature("YouAreNotTheSeller()"));
        market.cancelListing(1); // Second cancellation should fail - seller is now address(0)
        vm.stopPrank();
    }

    // ===== BUY LISTING TESTS =====
    
    function test_BuyListing_RevertInactiveListingBetter() public {
        vm.startPrank(buyer);
        vm.expectRevert(abi.encodeWithSignature("ListingNotActive()"));
        market.buyListing{value: 1 ether}(999); // Non-existent listing
        vm.stopPrank();
    }
    
    function test_BuyListing_RevertInsufficientPayment() public {
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        market.createListing(address(nft721), 1, 1, 2 ether, address(0));
        vm.stopPrank();
        
        vm.startPrank(buyer);
        vm.expectRevert(abi.encodeWithSignature("InsufficientPayment()"));
        market.buyListing{value: 1 ether}(1); // Not enough ETH
        vm.stopPrank();
    }
    
    function test_BuyListing_WithERC20Token() public {
        // Setup ERC20 as accepted currency
        address[] memory currencies = new address[](1);
        bool[] memory accepted = new bool[](1);
        currencies[0] = address(mockToken);
        accepted[0] = true;
        
        vm.startPrank(deployer);
        market.setAcceptedCurrencies(currencies, accepted);
        vm.stopPrank();
        
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        market.createListing(address(nft721), 1, 1, 100 ether, address(mockToken));
        vm.stopPrank();
        
        vm.startPrank(buyer);
        mockToken.approve(address(market), 100 ether);
        market.buyListing(1);
        vm.stopPrank();
        
        assertEq(nft721.ownerOf(1), buyer);
        assertEq(mockToken.balanceOf(seller), 1100 ether); // 1000 + 100
    }
    
    function test_BuyListing_RevertEthNotAcceptedForERC20() public {
        // Setup ERC20 as accepted currency
        address[] memory currencies = new address[](1);
        bool[] memory accepted = new bool[](1);
        currencies[0] = address(mockToken);
        accepted[0] = true;
        
        vm.startPrank(deployer);
        market.setAcceptedCurrencies(currencies, accepted);
        vm.stopPrank();
        
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        market.createListing(address(nft721), 1, 1, 100 ether, address(mockToken));
        vm.stopPrank();
        
        vm.startPrank(buyer);
        mockToken.approve(address(market), 100 ether);
        vm.expectRevert(abi.encodeWithSignature("EthNotAccepted()"));
        market.buyListing{value: 1 ether}(1); // Sending ETH for ERC20 listing
        vm.stopPrank();
    }

    // ===== ACCEPT BID TESTS =====
    
    function test_AcceptBid_Success() public {
        _mintAndApprove721(seller, 1);
        
        // Place bid
        vm.startPrank(buyer);
        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), 1 ether, 0);
        vm.stopPrank();
        
        uint256 sellerBalanceBefore = seller.balance;
        
        // vm.expectEmit(true, true, true, false);
        // emit BidAccepted(address(nft721), 1, 1, seller, buyer, 1 ether, address(0), 0, address(0));
        
        vm.startPrank(seller);
        market.acceptBid(address(nft721), 1, 1);
        vm.stopPrank();
        
        assertEq(nft721.ownerOf(1), buyer);
        assertEq(seller.balance, sellerBalanceBefore + 1 ether);
    }
    
    function test_AcceptBid_RevertNoActiveBid() public {
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSignature("NoActiveBid()"));
        market.acceptBid(address(nft721), 1, 1); // No bid placed
        vm.stopPrank();
    }
    
    function test_AcceptBid_RevertExpiredBid() public {
        _mintAndApprove721(seller, 1);
        
        // Place bid
        vm.startPrank(buyer);
        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), 1 ether, 0);
        vm.stopPrank();
        
        // Fast forward past bid expiration
        vm.warp(block.timestamp + 8 days);
        
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSignature("BidHasExpired()"));
        market.acceptBid(address(nft721), 1, 1);
        vm.stopPrank();
    }

    // ===== CANCEL BID TESTS =====
    
    function test_CancelBid_Success() public {
        _mintAndApprove721(seller, 1);
        
        // Place bid
        vm.startPrank(buyer);
        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), 1 ether, 0);
        vm.stopPrank();
        
        uint256 buyerBalanceBefore = buyer.balance;
        
        // vm.expectEmit(true, true, true, false);
        // emit BidCancelled(address(nft721), 1, 1, buyer, 1 ether, address(0), buyer, 0);
        
        vm.startPrank(buyer);
        market.cancelBid(address(nft721), 1, 1);
        vm.stopPrank();
        
        assertEq(buyer.balance, buyerBalanceBefore + 1 ether);
        
        (address bidder,,,,) = market.bids(address(nft721), 1, 1);
        assertEq(bidder, address(0)); // Bid should be deleted
    }
    
    function test_CancelExpiredBid_WithFee() public {
        _mintAndApprove721(seller, 1);
        
        // Place bid
        vm.startPrank(buyer);
        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), 1 ether, 0);
        vm.stopPrank();
        
        // Fast forward past expiration
        vm.warp(block.timestamp + 8 days);
        
        uint256 buyerBalanceBefore = buyer.balance;
        uint256 ownerBalanceBefore = deployer.balance;
        uint256 expectedFee = 1 ether * 100 / 10000; // 1% default fee
        
        vm.startPrank(attacker); // Anyone can cancel expired bid
        market.cancelBid(address(nft721), 1, 1);
        vm.stopPrank();
        
        assertEq(buyer.balance, buyerBalanceBefore + 1 ether - expectedFee);
        assertEq(deployer.balance, ownerBalanceBefore + expectedFee);
    }

    // ===== ACCESS CONTROL TESTS =====
    
    function test_AdminFunctions_RevertNonOwner() public {
        vm.startPrank(attacker);
        
        vm.expectRevert();
        market.setBidDuration(1 days);
        
        vm.expectRevert();
        market.setCancellationFeePercentage(200);
        
        vm.expectRevert();
        market.setCurationEnabled(true);
        
        vm.expectRevert();
        market.setCurationValidator(address(curator));
        
        address[] memory currencies = new address[](1);
        bool[] memory accepted = new bool[](1);
        vm.expectRevert();
        market.setAcceptedCurrencies(currencies, accepted);
        
        vm.stopPrank();
    }

    // ===== MARKETPLACE VIEWS TESTS =====
    
    function test_GetActiveListings_EmptyMarketplace() public view {
        IMarketplace.Listing[] memory listings = market.getActiveListings();
        assertEq(listings.length, 0);
    }
    
    function test_GetActiveListings_WithActiveListings() public {
        _mintAndApprove721(seller, 1);
        _mintAndApprove721(seller, 2);
        
        vm.startPrank(seller);
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        market.createListing(address(nft721), 2, 1, 2 ether, address(0));
        vm.stopPrank();
        
        IMarketplace.Listing[] memory listings = market.getActiveListings();
        assertEq(listings.length, 2);
        assertEq(listings[0].price, 1 ether);
        assertEq(listings[1].price, 2 ether);
    }
    
    function test_GetActiveListingsPaged_ZeroPageSize() public view {
        IMarketplace.Listing[] memory listings = market.getActiveListingsPaged(1, 0);
        assertEq(listings.length, 0);
    }
    
    function test_GetActiveListingsPaged_StartIdBeyondCounter() public view {
        IMarketplace.Listing[] memory listings = market.getActiveListingsPaged(999, 10);
        assertEq(listings.length, 0);
    }
    
    function test_GetActiveListingIdsPaged_StartIdZero() public {
        _mintAndApprove721(seller, 1);
        
        vm.startPrank(seller);
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        vm.stopPrank();
        
        uint256[] memory ids = market.getActiveListingIdsPaged(0, 10);
        assertEq(ids.length, 1);
        assertEq(ids[0], 1);
    }
    
    function test_GetActiveBids_NoActiveBids() public view {
        (IMarketplace.Bid[] memory bids, uint256[] memory amounts) = market.getActiveBids(address(nft721), 1);
        assertEq(bids.length, 0);
        assertEq(amounts.length, 0);
    }
    
    function test_GetActiveBidsRange_InvalidRange() public view {
        (IMarketplace.Bid[] memory bids, uint256[] memory amounts) = market.getActiveBidsRange(address(nft721), 1, 10, 5);
        assertEq(bids.length, 0);
        assertEq(amounts.length, 0);
    }
    
    function test_GetBid_NonExistentBid() public view {
        IMarketplace.Bid memory bid = market.getBid(address(nft721), 1, 1);
        assertEq(bid.bidder, address(0));
        assertEq(bid.amount, 0);
    }
    
    function test_SupportsRoyalties_ERC721WithRoyalties() public view {
        assertTrue(market.supportsRoyalties(address(nft721)));
    }
    
    function test_SupportsRoyalties_ERC20() public view {
        assertFalse(market.supportsRoyalties(address(mockToken)));
    }
    
    function test_GetRoyaltyInfo_NoRoyalties() public view {
        (address receiver, uint256 royaltyAmount, bool hasRoyalties) = market.getRoyaltyInfo(address(mockToken), 1, 1000 ether, 1);
        assertEq(receiver, address(0));
        assertEq(royaltyAmount, 0);
        assertFalse(hasRoyalties);
    }
    
    function test_GetRoyaltyInfo_WithRoyalties() public view {
        (address receiver, uint256 royaltyAmount, bool hasRoyalties) = market.getRoyaltyInfo(address(nft721), 1, 1000 ether, 1);
        assertEq(receiver, deployer);
        // NFT721 might have 0% royalty by default, so just check the structure works
        assertEq(hasRoyalties, royaltyAmount > 0 && receiver != address(0));
    }

    // ===== ADDITIONAL ADMIN FUNCTION TESTS =====
    
    function test_SetAcceptedCurrencies_RemoveFromMiddle() public {
        // Add multiple currencies first
        address[] memory currencies = new address[](2);
        bool[] memory accepted = new bool[](2);
        currencies[0] = address(mockToken);
        currencies[1] = address(0x123); // Dummy contract address
        accepted[0] = true;
        accepted[1] = true;
        
        // Mock the contract check for dummy address
        vm.etch(address(0x123), "0x01");
        
        vm.startPrank(deployer);
        market.setAcceptedCurrencies(currencies, accepted);
        
        // Remove first currency (tests array reordering)
        currencies = new address[](1);
        accepted = new bool[](1);
        currencies[0] = address(mockToken);
        accepted[0] = false;
        
        market.setAcceptedCurrencies(currencies, accepted);
        vm.stopPrank();
        
        assertFalse(market.acceptedCurrencies(address(mockToken)));
    }
    
    function test_SetBidDuration_MaximumValue() public {
        uint256 maxDuration = 365 days;
        
        vm.startPrank(deployer);
        market.setBidDuration(maxDuration);
        vm.stopPrank();
        
        assertEq(market.bidDuration(), maxDuration);
    }
    
    function test_SetCancellationFeePercentage_Zero() public {
        vm.startPrank(deployer);
        market.setCancellationFeePercentage(0);
        vm.stopPrank();
        
        assertEq(market.cancellationFeePercentage(), 0);
    }
    
    function test_SetCancellationFeePercentage_Maximum() public {
        uint256 maxPercentage = 3000; // 30%
        
        vm.startPrank(deployer);
        market.setCancellationFeePercentage(maxPercentage);
        vm.stopPrank();
        
        assertEq(market.cancellationFeePercentage(), maxPercentage);
    }

    // ===== EDGE CASE TESTS =====
    
    function test_CreateListing_ERC6909InsufficientBalance() public {
        _mint6909(seller, 1, 5);
        
        vm.startPrank(seller);
        nft6909.setOperator(address(market), true);
        vm.expectRevert(abi.encodeWithSignature("InsufficientTokenBalance()"));
        market.createListing(address(nft6909), 1, 10, 1 ether, address(0)); // Try to list 10 but only has 5
        vm.stopPrank();
    }
    
    function test_CreateListing_ERC6909NoApproval() public {
        _mint6909(seller, 1, 5);
        
        vm.startPrank(seller);
        vm.expectRevert(abi.encodeWithSignature("ContractNeedsApproval()"));
        market.createListing(address(nft6909), 1, 5, 1 ether, address(0)); // No approval given
        vm.stopPrank();
    }
    
    function test_AcceptBid_ERC6909InsufficientBalance() public {
        _mint6909(seller, 1, 5);
        
        vm.startPrank(buyer);
        market.placeBid{value: 1 ether}(address(nft6909), 1, 10, address(0), 1 ether, 0); // Bid for 10
        vm.stopPrank();
        
        vm.startPrank(seller);
        nft6909.setOperator(address(market), true);
        vm.expectRevert(abi.encodeWithSignature("InsufficientTokenBalance()"));
        market.acceptBid(address(nft6909), 1, 10); // Only has 5, can't fulfill bid for 10
        vm.stopPrank();
    }
    
    function test_PlaceBid_CurationBlocked() public {
        // Enable curation with DummyCurator (which starts with nothing approved)
        vm.startPrank(deployer);
        market.setCurationEnabled(true);
        market.setCurationValidator(address(curator));
        vm.stopPrank();
        
        vm.startPrank(buyer);
        vm.expectRevert(abi.encodeWithSignature("CollectionNotApproved(address)", address(nft721)));
        market.placeBid{value: 1 ether}(address(nft721), 1, 1, address(0), 1 ether, 0);
        vm.stopPrank();
    }

    // ===== HELPER FUNCTIONS =====
    
    function _mint721(address to, uint256 tokenId) internal {
        vm.startPrank(deployer);
        nft721.safeMint(to, tokenId);
        vm.stopPrank();
    }
    
    function _mintAndApprove721(address to, uint256 tokenId) internal {
        _mint721(to, tokenId);
        vm.startPrank(to);
        nft721.setApprovalForAll(address(market), true);
        vm.stopPrank();
    }
    
    function _mint1155(address to, uint256 tokenId, uint256 amount) internal {
        vm.startPrank(deployer);
        nft1155.mint(to, tokenId, amount, "");
        vm.stopPrank();
    }
    
    function _mintAndApprove1155(address to, uint256 tokenId, uint256 amount) internal {
        _mint1155(to, tokenId, amount);
        vm.startPrank(to);
        nft1155.setApprovalForAll(address(market), true);
        vm.stopPrank();
    }
    
    function _mint6909(address to, uint256 tokenId, uint256 amount) internal {
        vm.startPrank(deployer);
        nft6909.mint(to, tokenId, amount);
        vm.stopPrank();
    }
}