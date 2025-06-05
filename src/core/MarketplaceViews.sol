// contracts/views/MarketplaceViews.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../MarketplaceStorage.sol";
import "../MarketplaceLibrary.sol";
import "../interface/IERC2981.sol";

contract MarketplaceViews is MarketplaceStorage {
    using MarketplaceLibrary for address;

    /**
     * @notice Retrieves all active listings from the marketplace
     * @return Array of active Listing structs
     * @dev A listing is considered active if its price is greater than 0
     */
    function getActiveListings() external view returns (IMarketplace.Listing[] memory) {
        uint256 activeCount = 0;
        // First, count active listings
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (listings[i].price > 0) {
                activeCount++;
            }
        }
        // Create array of active listings
        IMarketplace.Listing[] memory activeListings = new IMarketplace.Listing[](activeCount);
        uint256 currentIndex = 0;
        // Fill array
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (listings[i].price > 0) {
                activeListings[currentIndex] = listings[i];
                currentIndex++;
            }
        }
        return activeListings;
    }

    /**
     * @notice Retrieves all active bids for a specific token
     * @param _tokenAddress The address of the NFT contract
     * @param _tokenId The token ID to get bids for
     * @return activeBids Array of active Bid structs
     * @return amounts Array of token amounts corresponding to each bid
     * @dev Limited to first 1000 bids for gas efficiency
     */
    function getActiveBids(
        address _tokenAddress,
        uint256 _tokenId
    ) external view returns (IMarketplace.Bid[] memory, uint256[] memory) {
        uint256 activeCount = 0;
        uint256 maxAmount = 1000; // Reasonable limit for gas considerations
        // Count active bids up to maxAmount
        for (uint256 amount = 1; amount <= maxAmount; amount++) {
            if (bids[_tokenAddress][_tokenId][amount].amount > 0) {
                activeCount++;
            }
        }
        IMarketplace.Bid[] memory activeBids = new IMarketplace.Bid[](activeCount);
        uint256[] memory amounts = new uint256[](activeCount);
        uint256 currentIndex = 0;
        // Fill arrays
        for (uint256 amount = 1; amount <= maxAmount && currentIndex < activeCount; amount++) {
            if (bids[_tokenAddress][_tokenId][amount].amount > 0) {
                activeBids[currentIndex] = bids[_tokenAddress][_tokenId][amount];
                amounts[currentIndex] = amount;
                currentIndex++;
            }
        }
        return (activeBids, amounts);
    }

    /**
     * @notice Checks if a token address supports either ERC721 or ERC1155 standard
     * @param _tokenAddress The address of the token contract to check
     * @return bool True if the token is ERC721 or ERC1155 or ERC6909
     */
    function isTokenAccepted(
        address _tokenAddress
    ) external view returns (bool) {
        return _tokenAddress.isERC721() || _tokenAddress.isERC1155() || _tokenAddress.isERC6909();
    }

    /**
     * @notice Checks if token supports ERC2981 royalty standard
     * @param _tokenAddress The NFT contract address
     * @return bool True if the token supports ERC2981
     */
    function supportsRoyalties(
        address _tokenAddress
    ) public view returns (bool) {
        return _tokenAddress.isERC2981();
    }

    /**
     * @notice Gets royalty information for a token at a specific price
     * @param _tokenAddress The NFT contract address
     * @param _tokenId The NFT token ID
     * @param _salePrice The sale price to calculate royalties from
     * @param _amount The amount of tokens (relevant for ERC1155)
     * @return receiver The address that should receive royalties
     * @return royaltyAmount The amount of royalties to be paid
     * @return hasRoyalties Boolean indicating if valid royalties exist
     */
    function getRoyaltyInfo(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _salePrice,
        uint256 _amount
    ) public view returns (address receiver, uint256 royaltyAmount, bool hasRoyalties) {
        if (supportsRoyalties(_tokenAddress)) {
            (receiver, royaltyAmount) = IERC2981(_tokenAddress).royaltyInfo(_tokenId, _salePrice);

            if (_tokenAddress.isERC1155() || _tokenAddress.isERC6909()) {
                royaltyAmount = royaltyAmount * _amount;
            }

            hasRoyalties = (royaltyAmount > 0 && receiver != address(0));
            return (receiver, royaltyAmount, hasRoyalties);
        }
        return (address(0), 0, false);
    }
}
