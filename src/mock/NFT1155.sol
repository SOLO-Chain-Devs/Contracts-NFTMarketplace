// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RoyaltyFeatures.sol";

contract NFT1155 is ERC1155, RoyaltyFeatures, Ownable {
    string public name;
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address royaltyReceiver,
        uint96 feeNumerator,
        uint256[] memory initialIds,
        uint256[] memory initialAmounts,
        address initialReceiver
    ) ERC1155(_uri) Ownable(msg.sender) {
        name = _name;
        symbol = _symbol;
        _setDefaultRoyalty(royaltyReceiver, feeNumerator);
        _mintBatch(initialReceiver, initialIds, initialAmounts, "");
    }

    function setURI(
        string memory newuri
    ) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    // Interface support
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
