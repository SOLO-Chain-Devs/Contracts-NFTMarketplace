// src/interface/IMarketplace.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IMarketplace {
    struct Listing {
        address seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address currency;
    }

    struct Bid {
        address bidder;
        uint256 amount;
        address currency;
        uint256 timeout;
        uint256 tokenAmount;
    }

    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        address currency
    );
    event ListingCancelled(uint256 indexed listingId);
    event ListingSold(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed seller,
        uint256 price,
        address currency,
        uint256 royaltyAmount,
        address royaltyReceiver
    );
    event BidPlaced(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 indexed tokenAmount,
        address bidder,
        uint256 amount,
        address currency,
        uint256 duration
    );
    event BidAccepted(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 indexed tokenAmount,
        address seller,
        address bidder,
        uint256 amount,
        address currency,
        uint256 royaltyAmount,
        address royaltyReceiver
    );
    event BidCancelled(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 indexed tokenAmount,
        address bidder,
        uint256 amount,
        address currency,
        address canceller,
        uint256 cancellationFee
    );
    event BidOutbid(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 tokenAmount,
        address previousBidder,
        address newBidder,
        uint256 previousAmount,
        uint256 newAmount,
        address currency,
        uint256 previousTimeout,
        uint256 newTimeout
    );
    event CurrencyStatusUpdated(address indexed currency, bool accepted);
    event CurationEnabled(bool enabled);
    event CurationValidatorUpdated(address indexed newValidator, address indexed oldValidator);

    function createListing(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        address _currency
    ) external;
    function cancelListing(
        uint256 _listingId
    ) external;
    function buyListing(
        uint256 _listingId
    ) external payable;
    function placeBid(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        address _currency,
        uint256 _amount,
        uint256 _customDuration
    ) external payable;
    function acceptBid(address _tokenAddress, uint256 _tokenId, uint256 _tokenAmount) external;
    function cancelBid(address _tokenAddress, uint256 _tokenId, uint256 _tokenAmount) external;
}
