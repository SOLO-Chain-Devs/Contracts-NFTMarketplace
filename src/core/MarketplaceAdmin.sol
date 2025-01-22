// src/core/MarketplaceAdmin.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IMarketplace.sol";
import "../MarketplaceStorage.sol";

contract MarketplaceAdmin is MarketplaceStorage, Ownable {
    /**
     * @notice Initializes the contract with ETH as an accepted currency
     * @dev Sets the contract owner and adds ETH (address(0)) to accepted currencies
     */
    constructor() Ownable(msg.sender) {
        acceptedCurrencies[address(0)] = true;
        currencyList.push(address(0));
    }

    /**
     * @notice Updates the accepted status of multiple currencies
     * @param _currencies Array of currency contract addresses
     * @param _accepted Array of boolean values indicating acceptance status
     * @dev Cannot modify ETH (address(0)) status. Updates currencyList accordingly
     */
    function setAcceptedCurrencies(address[] calldata _currencies, bool[] calldata _accepted) external onlyOwner {
        if (_currencies.length != _accepted.length) {
            revert ArrayLengthMismatch();
        }
        for (uint256 i = 0; i < _currencies.length; i++) {
            if (_currencies[i] != address(0)) {
                // Prevent changing ETH status
                if (_accepted[i] && !acceptedCurrencies[_currencies[i]]) {
                    currencyList.push(_currencies[i]);
                } else if (!_accepted[i] && acceptedCurrencies[_currencies[i]]) {
                    for (uint256 j = 0; j < currencyList.length; j++) {
                        if (currencyList[j] == _currencies[i]) {
                            currencyList[j] = currencyList[currencyList.length - 1];
                            currencyList.pop();
                            break;
                        }
                    }
                }
                acceptedCurrencies[_currencies[i]] = _accepted[i];
                emit IMarketplace.CurrencyStatusUpdated(_currencies[i], _accepted[i]);
            }
        }
    }

    /**
     * @notice Sets the duration for bids
     * @param _newDuration New duration in seconds
     * @dev Duration must be greater than 0 and less than MAX_BID_DURATION
     */
    function setBidDuration(
        uint256 _newDuration
    ) external onlyOwner {
        if (_newDuration == 0) revert BidDurationMustBeGreaterThanZero();
        if (_newDuration > MAX_BID_DURATION) revert BidDurationTooLong();
        bidDuration = _newDuration;
    }

    /**
     * @notice Sets the cancellation fee percentage for expired bids
     * @param _newPercentage New fee percentage (in basis points, e.g., 100 = 1%)
     * @dev Cannot exceed MAX_CANCELLATION_FEE_PERCENTAGE
     */
    function setCancellationFeePercentage(
        uint256 _newPercentage
    ) external onlyOwner {
        if (_newPercentage > MAX_CANCELLATION_FEE_PERCENTAGE) {
            revert CancellationFeeTooHigh();
        }
        cancellationFeePercentage = _newPercentage;
    }
}
