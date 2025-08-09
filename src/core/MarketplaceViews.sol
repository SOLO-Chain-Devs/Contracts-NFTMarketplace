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
     * @notice Returns active listings in a paginated range by listing id
     * @param startId The starting listing id (use 1 for the beginning)
     * @param pageSize Maximum number of records to scan from startId (upper bound on results)
     * @dev Scans ids [startId, min(listingCounter, startId + pageSize - 1)] and compacts active ones
     */
    function getActiveListingsPaged(
        uint256 startId,
        uint256 pageSize
    ) external view returns (IMarketplace.Listing[] memory) {
        if (pageSize == 0) {
            return new IMarketplace.Listing[](0);
        }
        uint256 fromId = startId == 0 ? 1 : startId;
        if (fromId > listingCounter) {
            return new IMarketplace.Listing[](0);
        }
        uint256 lastId = fromId + pageSize - 1;
        if (lastId > listingCounter) {
            lastId = listingCounter;
        }

        IMarketplace.Listing[] memory results = new IMarketplace.Listing[](lastId - fromId + 1);
        uint256 count = 0;
        for (uint256 i = fromId; i <= lastId; i++) {
            if (listings[i].price > 0) {
                results[count] = listings[i];
                count++;
            }
        }
        assembly {
            mstore(results, count)
        }
        return results;
    }

    /**
     * @notice Returns active listing ids in a paginated range (lighter payload than full structs)
     */
    function getActiveListingIdsPaged(
        uint256 startId,
        uint256 pageSize
    ) external view returns (uint256[] memory) {
        if (pageSize == 0) {
            return new uint256[](0);
        }
        uint256 fromId = startId == 0 ? 1 : startId;
        if (fromId > listingCounter) {
            return new uint256[](0);
        }
        uint256 lastId = fromId + pageSize - 1;
        if (lastId > listingCounter) {
            lastId = listingCounter;
        }

        uint256[] memory ids = new uint256[](lastId - fromId + 1);
        uint256 count = 0;
        for (uint256 i = fromId; i <= lastId; i++) {
            if (listings[i].price > 0) {
                ids[count] = i;
                count++;
            }
        }
        assembly {
            mstore(ids, count)
        }
        return ids;
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
        for (uint256 amount = 1; amount <= maxAmount; amount++) {
            if (bids[_tokenAddress][_tokenId][amount].amount > 0) {
                activeCount++;
            }
        }
        IMarketplace.Bid[] memory activeBids = new IMarketplace.Bid[](activeCount);
        uint256[] memory amounts = new uint256[](activeCount);
        uint256 currentIndex = 0;
        for (uint256 amount = 1; amount <= maxAmount; amount++) {
            if (bids[_tokenAddress][_tokenId][amount].amount > 0) {
                activeBids[currentIndex] = bids[_tokenAddress][_tokenId][amount];
                amounts[currentIndex] = amount;
                currentIndex++;
            }
        }
        return (activeBids, amounts);
    }

    /**
     * @notice Returns bids in a specific tokenAmount range to avoid scanning from 1
     */
    function getActiveBidsRange(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _startAmount,
        uint256 _endAmount
    ) external view returns (IMarketplace.Bid[] memory, uint256[] memory) {
        if (_endAmount < _startAmount) {
            return (new IMarketplace.Bid[](0), new uint256[](0));
        }
        uint256 span = _endAmount - _startAmount + 1;
        IMarketplace.Bid[] memory rangeBids = new IMarketplace.Bid[](span);
        uint256[] memory amounts = new uint256[](span);
        uint256 count = 0;
        for (uint256 amount = _startAmount; amount <= _endAmount; amount++) {
            IMarketplace.Bid storage bidRef = bids[_tokenAddress][_tokenId][amount];
            if (bidRef.amount > 0) {
                rangeBids[count] = bidRef;
                amounts[count] = amount;
                count++;
            }
        }
        assembly {
            mstore(rangeBids, count)
            mstore(amounts, count)
        }
        return (rangeBids, amounts);
    }

    /**
     * @notice Returns a single bid by amount
     */
    function getBid(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _tokenAmount
    ) external view returns (IMarketplace.Bid memory) {
        return bids[_tokenAddress][_tokenId][_tokenAmount];
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
     * @notice Gets royalty information per EIP-2981 for a given total sale price
     * @param _tokenAddress The NFT contract address
     * @param _tokenId The NFT token ID
     * @param _salePrice The total sale price used to calculate royalties
     * @return receiver The address that should receive royalties
     * @return royaltyAmount The amount of royalties to be paid
     * @return hasRoyalties Boolean indicating if valid royalties exist
     */
    function getRoyaltyInfo(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _salePrice,
        uint256 /* _amount */
    ) public view returns (address receiver, uint256 royaltyAmount, bool hasRoyalties) {
        if (supportsRoyalties(_tokenAddress)) {
            (receiver, royaltyAmount) = IERC2981(_tokenAddress).royaltyInfo(_tokenId, _salePrice);

            hasRoyalties = (royaltyAmount > 0 && receiver != address(0));
            return (receiver, royaltyAmount, hasRoyalties);
        }
        return (address(0), 0, false);
    }

    /**
     * @notice Returns the list of accepted currency addresses
     */
    function getAcceptedCurrencies() external view returns (address[] memory) {
        return currencyList;
    }
}
