// RoyaltyFeatures.sol
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/common/ERC2981.sol";

abstract contract RoyaltyFeatures is ERC2981 {
    event RoyaltyUpdated(address receiver, uint96 feeNumerator);
    event TokenRoyaltyUpdated(uint256 tokenId, address receiver, uint96 feeNumerator);

    modifier validRoyalty(address receiver, uint96 feeNumerator) {
        require(receiver != address(0), "Invalid receiver");
        require(feeNumerator <= 10_000, "Fee exceeds 100%");
        _;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) 
        public 
        virtual 
        validRoyalty(receiver, feeNumerator) 
    {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit RoyaltyUpdated(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public virtual {
        _deleteDefaultRoyalty();
        emit RoyaltyUpdated(address(0), 0);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public virtual validRoyalty(receiver, feeNumerator) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit TokenRoyaltyUpdated(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public virtual {
        _resetTokenRoyalty(tokenId);
        emit TokenRoyaltyUpdated(tokenId, address(0), 0);
    }
}
