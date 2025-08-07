// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../interface/ICurationValidator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ITokenRegistry {
    function isTokenRegistered(address token) external view returns (bool);
}

/**
 * @title MultiRegistryValidator
 * @notice Validates collections against multiple TokenRegistry contracts
 * @dev Token is approved if it exists in ANY of the registries
 */
contract MultiRegistryValidator is ICurationValidator, Ownable {
    // Storage
    address[] public registries;
    mapping(address => bool) public isRegistry;
    
    // Events
    event RegistryAdded(address indexed registry);
    event RegistryRemoved(address indexed registry);
    
    constructor(address initialOwner) Ownable(initialOwner) {}
    
    /**
     * @notice Add a new registry
     * @param _registry Address of the TokenRegistry contract
     */
    function addRegistry(address _registry) external onlyOwner {
        require(_registry != address(0), "Invalid registry");
        require(!isRegistry[_registry], "Already added");
        
        registries.push(_registry);
        isRegistry[_registry] = true;
        
        emit RegistryAdded(_registry);
    }
    
    /**
     * @notice Remove a registry
     * @param _registry Address of the registry to remove
     */
    function removeRegistry(address _registry) external onlyOwner {
        require(isRegistry[_registry], "Not a registry");
        
        // Find and remove from array
        uint256 length = registries.length;
        for (uint256 i = 0; i < length; i++) {
            if (registries[i] == _registry) {
                registries[i] = registries[length - 1];
                registries.pop();
                break;
            }
        }
        
        isRegistry[_registry] = false;
        emit RegistryRemoved(_registry);
    }
    
    /**
     * @notice Check if a collection is approved (in ANY registry)
     * @param tokenContract The NFT contract address to validate
     * @return bool True if token is in any registry
     */
    function isApprovedCollection(address tokenContract) 
        external 
        view 
        override 
        returns (bool) 
    {
        uint256 length = registries.length;
        
        for (uint256 i = 0; i < length; i++) {
            try ITokenRegistry(registries[i]).isTokenRegistered(tokenContract) returns (bool registered) {
                if (registered) return true;
            } catch {
                // Continue if registry call fails
                continue;
            }
        }
        
        return false;
    }
    
    /**
     * @notice Get all registries
     */
    function getRegistries() external view returns (address[] memory) {
        return registries;
    }
    
    /**
     * @notice Get registry count
     */
    function getRegistryCount() external view returns (uint256) {
        return registries.length;
    }
}