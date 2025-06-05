// contracts/libraries/MarketplaceLibrary.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./interface/IERC2981.sol";
import "./interface/IERC6909.sol";

library MarketplaceLibrary {
    function handleBidPayment(address _currency, uint256 _amount) internal returns (uint256) {
        if (_currency == address(0)) {
            if (msg.value == 0) revert InsufficientPayment();
            return msg.value;
        } else {
            if (_amount == 0) revert TokenAmountMustBeGreaterThanZero();
            if (msg.value != 0) revert EthNotAccepted();
            IERC20 token = IERC20(_currency);
            if (!token.transferFrom(msg.sender, address(this), _amount)) {
                revert TokenTransferFailed();
            }
            return _amount;
        }
    }

    function transferPaymentToAddress(address _currency, uint256 _amount, address _recipient) internal {
        if (_currency == address(0)) {
            payable(_recipient).transfer(_amount);
        } else {
            IERC20(_currency).transfer(_recipient, _amount);
        }
    }

    function isERC721(
        address _tokenAddress
    ) internal view returns (bool) {
        if (_isContract(_tokenAddress)) {
            return IERC165(_tokenAddress).supportsInterface(0x80ac58cd);
        }
        return false;
    }

    function isERC1155(
        address _tokenAddress
    ) internal view returns (bool) {
        if (_isContract(_tokenAddress)) {
            return IERC165(_tokenAddress).supportsInterface(0xd9b67a26);
        }
        return false;
    }

    function isERC2981(
        address _tokenAddress
    ) internal view returns (bool) {
        if (_isContract(_tokenAddress)) {
            return IERC2981(_tokenAddress).supportsInterface(0x2a55205a);
        }
        return false;
    }

    function isERC6909(
        address _tokenAddress
    ) internal view returns (bool) {
        if (_isContract(_tokenAddress)) {
            return IERC165(_tokenAddress).supportsInterface(0x0f632fb3);
        }
        return false;
    }

    function _isContract(
        address _addr
    ) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /**
     * @notice Handles the payment of royalties for a sale
     * @param _tokenAddress The NFT contract address
     * @param _tokenId The NFT token ID
     * @param _salePrice The sale price
     * @param _currency The currency used for payment
     * @param _amount The amount of tokens (for ERC1155)
     * @return netAmount The amount after deducting royalties
     */
    function handleRoyalties(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _salePrice,
        address _currency,
        uint256 _amount
    ) internal returns (uint256) {
        // We know royalties exist and are valid because we checked in getRoyaltyInfo
        (address receiver, uint256 royaltyAmount) = IERC2981(_tokenAddress).royaltyInfo(_tokenId, _salePrice);

        // If it's ERC1155 or ERC6909, multiply royalty by quantity
        if (isERC1155(_tokenAddress) || isERC6909(_tokenAddress)) {
            royaltyAmount = royaltyAmount * _amount;
        }

        if (royaltyAmount > 0) {
            if (royaltyAmount >= _salePrice) {
                revert RoyaltyTooHigh(royaltyAmount, _salePrice);
            }

            transferPaymentToAddress(_currency, royaltyAmount, receiver);
            return _salePrice - royaltyAmount;
        }

        return _salePrice;
    }

    error InsufficientPayment();
    error TokenAmountMustBeGreaterThanZero();
    error EthNotAccepted();
    error TokenTransferFailed();
    error RoyaltyTooHigh(uint256 royaltyAmount, uint256 salePrice);
}
