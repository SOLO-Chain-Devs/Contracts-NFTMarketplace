// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../interface/ICurationValidator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DummyCurator
 * @dev Simple curation validator for testing marketplace gatekeeping
 */
contract DummyCurator is ICurationValidator, Ownable {
    mapping(address => bool) public approvedCollections;

    event CollectionApproved(address indexed collection, bool approved);

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Checks if a collection is approved for marketplace interactions
     * @param tokenContract The NFT contract address to validate
     * @return bool True if approved, false otherwise
     */
    function isApprovedCollection(
        address tokenContract
    ) external view override returns (bool) {
        return approvedCollections[tokenContract];
    }

    /**
     * @notice Approve or disapprove collections
     * @param collections Array of collection addresses
     * @param approved Array of approval statuses
     */
    function setApprovedCollections(address[] calldata collections, bool[] calldata approved) external onlyOwner {
        require(collections.length == approved.length, "Array length mismatch");

        for (uint256 i = 0; i < collections.length; i++) {
            approvedCollections[collections[i]] = approved[i];
            emit CollectionApproved(collections[i], approved[i]);
        }
    }

    /**
     * @notice Approve a single collection
     */
    function approveCollection(
        address collection
    ) external onlyOwner {
        approvedCollections[collection] = true;
        emit CollectionApproved(collection, true);
    }

    /**
     * @notice Disapprove a single collection
     */
    function disapproveCollection(
        address collection
    ) external onlyOwner {
        approvedCollections[collection] = false;
        emit CollectionApproved(collection, false);
    }
}
