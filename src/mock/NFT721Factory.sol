// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./NFT721.sol";

contract NFT721Factory {
    event NFT721Created(address indexed nftAddress, address indexed owner, string name, string symbol);

    address[] public nftContracts;
    mapping(address => address[]) public creatorToContracts;

    function createNFT721(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _royaltyReceiver,
        uint96 _feeNumerator,
        uint256 _mintSupply,
        address _initialReceiver
    ) external returns (address) {
        NFT721 newNFT =
            new NFT721(_name, _symbol, _baseURI, _royaltyReceiver, _feeNumerator, _mintSupply, _initialReceiver);

        nftContracts.push(address(newNFT));
        creatorToContracts[msg.sender].push(address(newNFT));

        emit NFT721Created(address(newNFT), msg.sender, _name, _symbol);

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
