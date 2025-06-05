// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./NFT6909.sol";

contract NFT6909Factory {
    event NFT6909Created(address indexed nftAddress, address indexed owner, string name, string symbol);

    address[] public nftContracts;
    mapping(address => address[]) public creatorToContracts;

    function createNFT6909(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _royaltyReceiver,
        uint96 _feeNumerator,
        uint256[] memory _initialIds,
        uint256[] memory _initialAmounts,
        address _initialReceiver
    ) external returns (address) {
        NFT6909 newNFT = new NFT6909(
            _name, _symbol, _baseURI, _royaltyReceiver, _feeNumerator, _initialIds, _initialAmounts, _initialReceiver
        );

        nftContracts.push(address(newNFT));
        creatorToContracts[msg.sender].push(address(newNFT));

        emit NFT6909Created(address(newNFT), msg.sender, _name, _symbol);

        return address(newNFT);
    }

    function getAllNFTContracts() external view returns (address[] memory) {
        return nftContracts;
    }

    function getContractsByCreator(
        address creator
    ) external view returns (address[] memory) {
        return creatorToContracts[creator];
    }

    function getTotalNFTContracts() external view returns (uint256) {
        return nftContracts.length;
    }
}
