// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./NFT1155.sol";

contract NFT1155Factory {
    event NFT1155Created(address indexed nftAddress, address indexed owner, string name, string symbol);

    address[] public nftContracts;
    mapping(address => address[]) public creatorToContracts;

    function createNFT1155(
        string memory _name,
        string memory _symbol,
        string memory _uri, 
        address _royaltyReceiver,
        uint96 _feeNumerator,
        uint256[] memory _initialIds,
        uint256[] memory _initialAmounts,
        address _initialReceiver
    ) external returns (address) {
        NFT1155 newNFT =
            new NFT1155(_name, _symbol, _uri, _royaltyReceiver, _feeNumerator, _initialIds, _initialAmounts, _initialReceiver);

        nftContracts.push(address(newNFT));
        creatorToContracts[msg.sender].push(address(newNFT));

        emit NFT1155Created(address(newNFT), msg.sender, _name, _symbol);

        return address(newNFT);
    }

    // Function to get all NFT contracts created by this factory
    function getAllNFTContracts() external view returns (address[] memory) {
        return nftContracts;
    }

    // Function to get all NFT contracts created by a specific address
    function getContractsByCreator(
        address creator
    ) external view returns (address[] memory) {
        return creatorToContracts[creator];
    }

    // Function to get the total number of NFT contracts created
    function getTotalNFTContracts() external view returns (uint256) {
        return nftContracts.length;
    }
}
