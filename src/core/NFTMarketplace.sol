// contracts/core/MarketplaceCore.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../interface/IMarketplace.sol";
import "../interface/IERC6909.sol";
import "./MarketplaceAdmin.sol";
import "./MarketplaceViews.sol";
import "../MarketplaceLibrary.sol";

contract NFTMarketplace is IMarketplace, MarketplaceAdmin, MarketplaceViews, ReentrancyGuard {
    using MarketplaceLibrary for address;

    /**
     * @notice Creates a new listing for an NFT
     * @param _tokenAddress The address of the NFT contract
     * @param _tokenId The token ID of the NFT
     * @param _amount The amount of tokens to list (must be 1 for ERC721)
     * @param _price The price for the listing
     * @param _currency The currency address (address(0) for native currency)
     * @dev Validates token ownership and approvals before creating listing
     */
    function createListing(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        address _currency
    ) external override nonReentrant {
        if (_price == 0) revert PriceMustBeGreaterThanZero();
        if (_amount == 0) revert AmountMustBeGreaterThanZero();
        if (!acceptedCurrencies[_currency]) {
            revert CurrencyNotAccepted(_currency);
        }

        bool _isERC721Token = _tokenAddress.isERC721();
        bool _isERC1155Token = _tokenAddress.isERC1155();
        bool _isERC6909Token = _tokenAddress.isERC6909();
        if (!_isERC721Token && !_isERC1155Token && !_isERC6909Token) revert UnsupportedTokenStandard();

        if (_isERC721Token) {
            if (_amount != 1) revert ERC721AmountMustBe1();
            IERC721 nft = IERC721(_tokenAddress);
            if (nft.ownerOf(_tokenId) != msg.sender) revert NotOwnerOfNFT();
            if (!nft.isApprovedForAll(msg.sender, address(this))) {
                revert ContractNeedsApproval();
            }
        } else if (_isERC1155Token) {
            IERC1155 nft = IERC1155(_tokenAddress);
            if (nft.balanceOf(msg.sender, _tokenId) < _amount) {
                revert InsufficientTokenBalance();
            }
            if (!nft.isApprovedForAll(msg.sender, address(this))) {
                revert ContractNeedsApproval();
            }
        } else {
            // ERC6909 handling
            IERC6909 nft = IERC6909(_tokenAddress);
            if (nft.balanceOf(msg.sender, _tokenId) < _amount) {
                revert InsufficientTokenBalance();
            }
            if (!nft.isOperator(msg.sender, address(this))) {
                revert ContractNeedsApproval();
            }
        }

        listingCounter++;
        listings[listingCounter] = IMarketplace.Listing(msg.sender, _tokenAddress, _tokenId, _amount, _price, _currency);

        emit ListingCreated(listingCounter, msg.sender, _tokenAddress, _tokenId, _amount, _price, _currency);
    }

    /**
     * @notice Cancels an existing listing
     * @param _listingId The ID of the listing to cancel
     * @dev Only the seller can cancel their own listing
     */
    function cancelListing(
        uint256 _listingId
    ) external override nonReentrant {
        IMarketplace.Listing storage listing = listings[_listingId];
        if (listing.seller != msg.sender) revert YouAreNotTheSeller();
        if (listing.price == 0) revert ListingAlreadyCancelled();

        delete listings[_listingId];
        emit ListingCancelled(_listingId);
    }

    /**
     * @notice Purchases a listed NFT
     * @param _listingId The ID of the listing to purchase
     * @dev Handles ERC721, ERC1155, and ERC6909 transfers, as well as payment in native or ERC20 tokens
     */
    function buyListing(
        uint256 _listingId
    ) external payable override nonReentrant {
        IMarketplace.Listing storage listing = listings[_listingId];
        if (listing.price == 0) revert ListingNotActive();

        if (listing.currency == address(0)) {
            if (msg.value < listing.price) revert InsufficientPayment();
        } else {
            if (msg.value != 0) revert EthNotAccepted();
            if (!IERC20(listing.currency).transferFrom(msg.sender, address(this), listing.price)) {
                revert TokenTransferFailed();
            }
        }

        if (listing.tokenAddress.isERC721()) {
            IERC721(listing.tokenAddress).transferFrom(listing.seller, msg.sender, listing.tokenId);
        } else if (listing.tokenAddress.isERC1155()) {
            IERC1155(listing.tokenAddress).safeTransferFrom(
                listing.seller, msg.sender, listing.tokenId, listing.amount, ""
            );
        } else {
            // ERC6909 handling
            IERC6909(listing.tokenAddress).transferFrom(
                listing.seller, msg.sender, listing.tokenId, listing.amount
            );
        }

        (address royaltyReceiver, uint256 royaltyAmount, bool hasRoyalties) =
            getRoyaltyInfo(listing.tokenAddress, listing.tokenId, listing.price, listing.amount);

        uint256 netAmount = listing.price; // Default to full amount

        // Only process royalties if they exist
        if (hasRoyalties) {
            netAmount = MarketplaceLibrary.handleRoyalties(
                listing.tokenAddress, listing.tokenId, listing.price, listing.currency, listing.amount
            );
        }

        MarketplaceLibrary.transferPaymentToAddress(listing.currency, netAmount, listing.seller);

        emit ListingSold(
            _listingId,
            msg.sender,
            listing.seller,
            listing.price,
            listing.currency,
            hasRoyalties ? royaltyAmount : 0,
            hasRoyalties ? royaltyReceiver : address(0)
        );

        delete listings[_listingId];
    }

    /**
     * @notice Accepts a bid on an NFT
     * @param _tokenAddress The address of the NFT contract
     * @param _tokenId The token ID of the NFT
     * @param _tokenAmount The amount of tokens in the bid
     * @dev Validates ownership and handles token transfer to bidder
     */
    function acceptBid(address _tokenAddress, uint256 _tokenId, uint256 _tokenAmount) external override nonReentrant {
        IMarketplace.Bid storage bid = bids[_tokenAddress][_tokenId][_tokenAmount];
        if (bid.amount == 0) revert NoActiveBid();
        if (block.timestamp > bid.timeout) revert BidHasExpired();

        bool isERC721Token = _tokenAddress.isERC721();

        if (isERC721Token) {
            if (_tokenAmount != 1) revert ERC721AmountMustBe1();
            IERC721 nft = IERC721(_tokenAddress);
            if (nft.ownerOf(_tokenId) != msg.sender) revert NotOwnerOfNFT();
            if (!nft.isApprovedForAll(msg.sender, address(this))) {
                revert ContractNeedsApproval();
            }
            nft.transferFrom(msg.sender, bid.bidder, _tokenId);
        } else if (_tokenAddress.isERC1155()) {
            IERC1155 nft = IERC1155(_tokenAddress);
            if (nft.balanceOf(msg.sender, _tokenId) < _tokenAmount) {
                revert InsufficientTokenBalance();
            }
            if (!nft.isApprovedForAll(msg.sender, address(this))) {
                revert ContractNeedsApproval();
            }
            nft.safeTransferFrom(msg.sender, bid.bidder, _tokenId, _tokenAmount, "");
        } else {
            // ERC6909 handling
            IERC6909 nft = IERC6909(_tokenAddress);
            if (nft.balanceOf(msg.sender, _tokenId) < _tokenAmount) {
                revert InsufficientTokenBalance();
            }
            if (!nft.isOperator(msg.sender, address(this))) {
                revert ContractNeedsApproval();
            }
            nft.transferFrom(msg.sender, bid.bidder, _tokenId, _tokenAmount);
        }

        (address royaltyReceiver, uint256 royaltyAmount, bool hasRoyalties) =
            getRoyaltyInfo(_tokenAddress, _tokenId, bid.amount, _tokenAmount);

        uint256 netAmount = bid.amount; // Default to full amount

        // Only process royalties if they exist
        if (hasRoyalties) {
            netAmount =
                MarketplaceLibrary.handleRoyalties(_tokenAddress, _tokenId, bid.amount, bid.currency, _tokenAmount);
        }

        // Transfer net amount to seller
        MarketplaceLibrary.transferPaymentToAddress(bid.currency, netAmount, msg.sender);

        emit BidAccepted(
            _tokenAddress,
            _tokenId,
            _tokenAmount,
            msg.sender,
            bid.bidder,
            bid.amount,
            bid.currency,
            hasRoyalties ? royaltyAmount : 0,
            hasRoyalties ? royaltyReceiver : address(0)
        );

        delete bids[_tokenAddress][_tokenId][_tokenAmount];
    }

    /**
     * @notice Places a bid on an NFT
     * @param _tokenAddress The address of the NFT contract
     * @param _tokenId The token ID of the NFT
     * @param _tokenAmount The amount of tokens to bid on (must be 1 for ERC721)
     * @param _currency The currency address for the bid
     * @param _amount The bid amount
     * @param _customDuration Custom duration for the bid (0 for default duration)
     * @dev Handles bid replacement, expired bid cancellation, and refunds for previous bidders
     */
    function placeBid(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        address _currency,
        uint256 _amount,
        uint256 _customDuration
    ) external payable override nonReentrant {
        if (!acceptedCurrencies[_currency]) revert CurrencyNotAcceptedForBid();
        if (_tokenAmount == 0) revert TokenAmountMustBeGreaterThanZero();
        if (_customDuration > bidDuration) revert DurationExceedsMaximum();

        uint256 actualDuration = _customDuration == 0 ? bidDuration : _customDuration;

        bool isERC721Token = _tokenAddress.isERC721();
        bool isERC1155Token = _tokenAddress.isERC1155();
        bool isERC6909Token = _tokenAddress.isERC6909();

        if (!isERC721Token && !isERC1155Token && !isERC6909Token) {
            revert UnsupportedTokenStandard();
        }

        if (isERC721Token && _tokenAmount != 1) revert ERC721AmountMustBe1();

        uint256 bidAmount = MarketplaceLibrary.handleBidPayment(_currency, _amount);

        IMarketplace.Bid storage currentBid = bids[_tokenAddress][_tokenId][_tokenAmount];
        if (currentBid.amount > 0) {
            if (block.timestamp > currentBid.timeout) {
                // Handle expired bid
                _handleBidCancellation(_tokenAddress, _tokenId, _tokenAmount, msg.sender);
            } else {
                // Handle active bid
                if (bidAmount <= currentBid.amount) {
                    revert BidMustBeHigherThanCurrent();
               }
                MarketplaceLibrary.transferPaymentToAddress(currentBid.currency, currentBid.amount, currentBid.bidder);
                emit BidOutbid(
                        _tokenAddress, _tokenId, _tokenAmount, currentBid.bidder, msg.sender, currentBid.amount, 
                        bidAmount, _currency, currentBid.timeout, block.timestamp + actualDuration
                );
            }
        }

        bids[_tokenAddress][_tokenId][_tokenAmount] =
            IMarketplace.Bid(msg.sender, bidAmount, _currency, block.timestamp + actualDuration, _tokenAmount);

        emit BidPlaced(_tokenAddress, _tokenId, _tokenAmount, msg.sender, bidAmount, _currency, actualDuration);
    }

    /**
     * @notice Internal function to handle bid cancellation logic
     * @param _tokenAddress The address of the NFT contract
     * @param _tokenId The token ID of the NFT
     * @param _tokenAmount The amount of tokens in the bid
     * @param _canceller The address initiating the cancellation
     * @return success Boolean indicating if the cancellation was successful
     * @dev Handles cancellation fees if bid has expired and is cancelled by non-bidder
     */
    function _handleBidCancellation(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        address _canceller
    ) internal returns (bool) {
        IMarketplace.Bid storage bid = bids[_tokenAddress][_tokenId][_tokenAmount];
        if (bid.amount == 0) return false;

        uint256 refundAmount = bid.amount;
        uint256 cancellationFee = 0;

        // Handle expired bid
        if (block.timestamp > bid.timeout && _canceller != bid.bidder) {
            cancellationFee = (bid.amount * cancellationFeePercentage) / 10_000;
            if (cancellationFee > 0) {
                refundAmount = bid.amount - cancellationFee;
                MarketplaceLibrary.transferPaymentToAddress(bid.currency, cancellationFee, owner());
            }
        } else if (block.timestamp <= bid.timeout && _canceller != bid.bidder) {
            return false; // Cannot cancel non-expired bid if not bidder
        }

        MarketplaceLibrary.transferPaymentToAddress(bid.currency, refundAmount, bid.bidder);

        emit BidCancelled(
            _tokenAddress, _tokenId, _tokenAmount, bid.bidder, bid.amount, bid.currency, _canceller, cancellationFee
        );

        delete bids[_tokenAddress][_tokenId][_tokenAmount];
        return true;
    }

    /**
     * @notice Cancels a bid on an NFT
     * @param _tokenAddress The address of the NFT contract
     * @param _tokenId The token ID of the NFT
     * @param _tokenAmount The amount of tokens in the bid
     * @dev Anyone can cancel an expired bid (with fee), only bidder can cancel active bid
     */
    function cancelBid(address _tokenAddress, uint256 _tokenId, uint256 _tokenAmount) external override nonReentrant {
        bool success = _handleBidCancellation(_tokenAddress, _tokenId, _tokenAmount, msg.sender);
        if (!success) revert NoActiveBid();
    }
}
