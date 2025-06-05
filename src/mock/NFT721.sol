// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RoyaltyFeatures.sol";

contract NFT721 is ERC721, RoyaltyFeatures, Ownable {
    uint256 private _tokenIdCounter;
    string private baseURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory defaultUri,
        address royaltyReceiver,
        uint96 feeNumerator,
        uint256 _mintSupply,
        address initialReceiver
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _setDefaultRoyalty(royaltyReceiver, feeNumerator);
        baseURI = defaultUri;
        uint256 mintSupply = _mintSupply;

        for (uint256 i = 0; i < mintSupply; i++) {
            _safeMint(initialReceiver, i);
            _tokenIdCounter++;
        }
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function setBaseURI(
        string memory newUri
    ) public onlyOwner {
        baseURI = newUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Required override to make ERC721 and ERC2981 work together
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
