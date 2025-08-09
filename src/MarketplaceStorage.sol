// src/MarketplaceStorage.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./interface/IMarketplace.sol";
import "./interface/ICurationValidator.sol";

abstract contract MarketplaceStorage {
    mapping(uint256 => IMarketplace.Listing) public listings;
    uint256 public listingCounter;

    // Unified mapping for ERC721, ERC1155 and ERC6909 bids
    mapping(address => mapping(uint256 => mapping(uint256 => IMarketplace.Bid))) public bids;

    mapping(address => bool) public acceptedCurrencies;
    address[] public currencyList;

    uint256 public bidDuration = 7 days;
    uint256 public constant MAX_BID_DURATION = 365 days;
    uint256 public cancellationFeePercentage = 100; // 1% fee (100 basis points)
    uint256 public constant MAX_CANCELLATION_FEE_PERCENTAGE = 3000; // 30% max fee (3000 basis points)
    bool public curationEnabled;
    address public curationValidator;

    // ERC165 interface IDs
    bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 internal constant INTERFACE_ID_ERC6909 = 0x0f632fb3;

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
    error NotBidder();
    error DurationExceedsMaximum();
    error BidDurationTooLong();
    error CollectionNotApproved(address tokenContract);
    error InvalidCurationValidator();
    error InvalidCurrency(address currency);
}
