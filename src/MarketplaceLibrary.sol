// contracts/libraries/MarketplaceLibrary.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interface/IERC2981.sol";
import "./interface/IERC6909.sol";

library MarketplaceLibrary {
    using SafeERC20 for IERC20;
    function handleBidPayment(address _currency, uint256 _amount) internal returns (uint256) {
        if (_currency == address(0)) {
            if (msg.value == 0) revert InsufficientPayment();
            return msg.value;
        } else {
            if (_amount == 0) revert TokenAmountMustBeGreaterThanZero();
            if (msg.value != 0) revert EthNotAccepted();
            IERC20 token = IERC20(_currency);
            // SafeERC20 handles non-standard ERC20s that return no boolean
            token.safeTransferFrom(msg.sender, address(this), _amount);
            return _amount;
        }
    }

    function transferPaymentToAddress(address _currency, uint256 _amount, address _recipient) internal {
        if (_currency == address(0)) {
            Address.sendValue(payable(_recipient), _amount);
        } else {
            IERC20(_currency).safeTransfer(_recipient, _amount);
        }
    }

    function isERC721(
        address _tokenAddress
    ) internal view returns (bool) {
        if (_isContract(_tokenAddress)) {
            return _supportsInterface(_tokenAddress, 0x80ac58cd);
        }
        return false;
    }

    function isERC1155(
        address _tokenAddress
    ) internal view returns (bool) {
        if (_isContract(_tokenAddress)) {
            return _supportsInterface(_tokenAddress, 0xd9b67a26);
        }
        return false;
    }

    function isERC2981(
        address _tokenAddress
    ) internal view returns (bool) {
        if (_isContract(_tokenAddress)) {
            return _supportsInterface(_tokenAddress, 0x2a55205a);
        }
        return false;
    }

    function isERC6909(
        address _tokenAddress
    ) internal view returns (bool) {
        if (_isContract(_tokenAddress)) {
            return _supportsInterface(_tokenAddress, 0x0f632fb3);
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

    function _supportsInterface(address target, bytes4 interfaceId) internal view returns (bool) {
        // Perform a safe staticcall to supportsInterface(bytes4) and decode
        (bool ok, bytes memory data) = target.staticcall(abi.encodeWithSelector(0x01ffc9a7, interfaceId));
        if (!ok || data.length < 32) {
            return false;
        }
        return abi.decode(data, (bool));
    }

    /**
     * @notice Handles the payment of royalties for a sale per EIP-2981 (salePrice is total for the sale)
     * @param _tokenAddress The NFT contract address
     * @param _tokenId The NFT token ID
     * @param _salePrice The total sale price (for multiples, pass unitPrice * quantity)
     * @param _currency The currency used for payment
     * @return netAmount The amount after deducting royalties
     */
    function handleRoyalties(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _salePrice,
        address _currency,
        uint256 /* _amount */
    ) internal returns (uint256) {
        // Royalty per EIP-2981: salePrice is the TOTAL price of the sale
        (address receiver, uint256 royaltyAmount) = IERC2981(_tokenAddress).royaltyInfo(_tokenId, _salePrice);

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
