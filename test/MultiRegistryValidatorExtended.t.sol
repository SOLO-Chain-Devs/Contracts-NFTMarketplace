// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MultiRegistryValidator, ITokenRegistry} from "../src/curation/MultiRegistryValidator.sol";

/**
 * @title Extended test suite for MultiRegistryValidator
 * @dev Comprehensive tests to achieve 90%+ coverage including edge cases and error conditions
 */
contract MultiRegistryValidatorExtendedTest is Test {
    MultiRegistryValidator public validator;
    MockTokenRegistry public registry1;
    MockTokenRegistry public registry2;
    MockTokenRegistry public failingRegistry;
    
    address public owner = vm.addr(1);
    address public nonOwner = vm.addr(2);
    address public tokenA = vm.addr(3);
    address public tokenB = vm.addr(4);
    address public tokenC = vm.addr(5);
    
    // Events
    event RegistryAdded(address indexed registry);
    event RegistryRemoved(address indexed registry);
    
    function setUp() public {
        vm.startPrank(owner);
        validator = new MultiRegistryValidator(owner);
        
        registry1 = new MockTokenRegistry();
        registry2 = new MockTokenRegistry();
        failingRegistry = new MockTokenRegistry();
        failingRegistry.setShouldFail(true);
        vm.stopPrank();
    }

    // ===== CONSTRUCTOR TESTS =====
    
    function test_Constructor_SetsOwner() public {
        assertEq(validator.owner(), owner);
        assertEq(validator.getRegistryCount(), 0);
    }

    // ===== ADD REGISTRY TESTS =====
    
    function test_AddRegistry_Success() public {
        vm.expectEmit(true, false, false, false);
        emit RegistryAdded(address(registry1));
        
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        vm.stopPrank();
        
        assertTrue(validator.isRegistry(address(registry1)));
        assertEq(validator.getRegistryCount(), 1);
        
        address[] memory registries = validator.getRegistries();
        assertEq(registries.length, 1);
        assertEq(registries[0], address(registry1));
    }
    
    function test_AddRegistry_Multiple() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        validator.addRegistry(address(registry2));
        vm.stopPrank();
        
        assertTrue(validator.isRegistry(address(registry1)));
        assertTrue(validator.isRegistry(address(registry2)));
        assertEq(validator.getRegistryCount(), 2);
        
        address[] memory registries = validator.getRegistries();
        assertEq(registries.length, 2);
        assertEq(registries[0], address(registry1));
        assertEq(registries[1], address(registry2));
    }
    
    function test_AddRegistry_RevertInvalidRegistry() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid registry");
        validator.addRegistry(address(0));
        vm.stopPrank();
    }
    
    function test_AddRegistry_RevertAlreadyAdded() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        
        vm.expectRevert("Already added");
        validator.addRegistry(address(registry1)); // Adding same registry twice
        vm.stopPrank();
    }
    
    function test_AddRegistry_RevertNonOwner() public {
        vm.startPrank(nonOwner);
        vm.expectRevert();
        validator.addRegistry(address(registry1));
        vm.stopPrank();
    }

    // ===== REMOVE REGISTRY TESTS =====
    
    function test_RemoveRegistry_Success() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        validator.addRegistry(address(registry2));
        
        vm.expectEmit(true, false, false, false);
        emit RegistryRemoved(address(registry1));
        
        validator.removeRegistry(address(registry1));
        vm.stopPrank();
        
        assertFalse(validator.isRegistry(address(registry1)));
        assertTrue(validator.isRegistry(address(registry2)));
        assertEq(validator.getRegistryCount(), 1);
        
        address[] memory registries = validator.getRegistries();
        assertEq(registries.length, 1);
        assertEq(registries[0], address(registry2));
    }
    
    function test_RemoveRegistry_LastElement() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        validator.addRegistry(address(registry2));
        
        // Remove the last element
        validator.removeRegistry(address(registry2));
        vm.stopPrank();
        
        assertTrue(validator.isRegistry(address(registry1)));
        assertFalse(validator.isRegistry(address(registry2)));
        assertEq(validator.getRegistryCount(), 1);
        
        address[] memory registries = validator.getRegistries();
        assertEq(registries.length, 1);
        assertEq(registries[0], address(registry1));
    }
    
    function test_RemoveRegistry_OnlyRegistry() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        validator.removeRegistry(address(registry1));
        vm.stopPrank();
        
        assertFalse(validator.isRegistry(address(registry1)));
        assertEq(validator.getRegistryCount(), 0);
        
        address[] memory registries = validator.getRegistries();
        assertEq(registries.length, 0);
    }
    
    function test_RemoveRegistry_RevertNotRegistry() public {
        vm.startPrank(owner);
        vm.expectRevert("Not a registry");
        validator.removeRegistry(address(registry1)); // Never added
        vm.stopPrank();
    }
    
    function test_RemoveRegistry_RevertNonOwner() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        vm.stopPrank();
        
        vm.startPrank(nonOwner);
        vm.expectRevert();
        validator.removeRegistry(address(registry1));
        vm.stopPrank();
    }

    // ===== IS APPROVED COLLECTION TESTS =====
    
    function test_IsApprovedCollection_EmptyRegistries() public view {
        // No registries added, should return false
        assertFalse(validator.isApprovedCollection(tokenA));
    }
    
    function test_IsApprovedCollection_TokenNotInAnyRegistry() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        validator.addRegistry(address(registry2));
        vm.stopPrank();
        
        // Token not registered in any registry
        assertFalse(validator.isApprovedCollection(tokenA));
    }
    
    function test_IsApprovedCollection_TokenInFirstRegistry() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        validator.addRegistry(address(registry2));
        vm.stopPrank();
        
        registry1.registerToken(tokenA);
        
        assertTrue(validator.isApprovedCollection(tokenA));
    }
    
    function test_IsApprovedCollection_TokenInSecondRegistry() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        validator.addRegistry(address(registry2));
        vm.stopPrank();
        
        registry2.registerToken(tokenA);
        
        assertTrue(validator.isApprovedCollection(tokenA));
    }
    
    function test_IsApprovedCollection_TokenInMultipleRegistries() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        validator.addRegistry(address(registry2));
        vm.stopPrank();
        
        registry1.registerToken(tokenA);
        registry2.registerToken(tokenA);
        
        assertTrue(validator.isApprovedCollection(tokenA));
    }
    
    function test_IsApprovedCollection_WithFailingRegistry() public {
        vm.startPrank(owner);
        validator.addRegistry(address(failingRegistry));
        validator.addRegistry(address(registry2));
        vm.stopPrank();
        
        registry2.registerToken(tokenA);
        
        // Should still return true even though first registry fails
        assertTrue(validator.isApprovedCollection(tokenA));
    }
    
    function test_IsApprovedCollection_AllRegistriesFail() public {
        vm.startPrank(owner);
        validator.addRegistry(address(failingRegistry));
        vm.stopPrank();
        
        // Should return false when all registries fail
        assertFalse(validator.isApprovedCollection(tokenA));
    }
    
    function test_IsApprovedCollection_AfterRemoval() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        validator.addRegistry(address(registry2));
        vm.stopPrank();
        
        registry1.registerToken(tokenA);
        assertTrue(validator.isApprovedCollection(tokenA));
        
        // Remove the registry that has the token
        vm.startPrank(owner);
        validator.removeRegistry(address(registry1));
        vm.stopPrank();
        
        assertFalse(validator.isApprovedCollection(tokenA));
    }

    // ===== VIEW FUNCTION TESTS =====
    
    function test_GetRegistries_Empty() public view {
        address[] memory registries = validator.getRegistries();
        assertEq(registries.length, 0);
    }
    
    function test_GetRegistries_Multiple() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        validator.addRegistry(address(registry2));
        vm.stopPrank();
        
        address[] memory registries = validator.getRegistries();
        assertEq(registries.length, 2);
        assertEq(registries[0], address(registry1));
        assertEq(registries[1], address(registry2));
    }
    
    function test_GetRegistryCount_Updates() public {
        assertEq(validator.getRegistryCount(), 0);
        
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        assertEq(validator.getRegistryCount(), 1);
        
        validator.addRegistry(address(registry2));
        assertEq(validator.getRegistryCount(), 2);
        
        validator.removeRegistry(address(registry1));
        assertEq(validator.getRegistryCount(), 1);
        
        validator.removeRegistry(address(registry2));
        assertEq(validator.getRegistryCount(), 0);
        vm.stopPrank();
    }

    // ===== COMPLEX SCENARIO TESTS =====
    
    function test_ComplexScenario_AddRemoveMultiple() public {
        vm.startPrank(owner);
        
        // Add multiple registries
        validator.addRegistry(address(registry1));
        validator.addRegistry(address(registry2));
        validator.addRegistry(address(failingRegistry));
        
        // Register tokens in different registries
        registry1.registerToken(tokenA);
        registry1.registerToken(tokenB);
        registry2.registerToken(tokenB);
        registry2.registerToken(tokenC);
        
        // Verify approvals
        assertTrue(validator.isApprovedCollection(tokenA)); // Only in registry1
        assertTrue(validator.isApprovedCollection(tokenB)); // In both registries
        assertTrue(validator.isApprovedCollection(tokenC)); // Only in registry2
        
        // Remove registry1
        validator.removeRegistry(address(registry1));
        
        assertFalse(validator.isApprovedCollection(tokenA)); // No longer approved
        assertTrue(validator.isApprovedCollection(tokenB));  // Still in registry2
        assertTrue(validator.isApprovedCollection(tokenC));  // Still in registry2
        
        // Remove registry2
        validator.removeRegistry(address(registry2));
        
        assertFalse(validator.isApprovedCollection(tokenA));
        assertFalse(validator.isApprovedCollection(tokenB));
        assertFalse(validator.isApprovedCollection(tokenC));
        
        vm.stopPrank();
    }
    
    function test_EdgeCase_RemoveRegistryOrder() public {
        vm.startPrank(owner);
        
        validator.addRegistry(address(registry1));
        validator.addRegistry(address(registry2));
        validator.addRegistry(address(failingRegistry));
        
        // Remove middle registry (should swap with last)
        validator.removeRegistry(address(registry2));
        
        address[] memory registries = validator.getRegistries();
        assertEq(registries.length, 2);
        assertEq(registries[0], address(registry1));
        assertEq(registries[1], address(failingRegistry)); // Last element moved to middle
        
        vm.stopPrank();
    }

    // ===== GAS OPTIMIZATION TESTS =====
    
    function test_GasUsage_IsApprovedCollection() public {
        vm.startPrank(owner);
        validator.addRegistry(address(registry1));
        validator.addRegistry(address(registry2));
        vm.stopPrank();
        
        registry2.registerToken(tokenA); // Token in second registry
        
        uint256 gasBefore = gasleft();
        bool result = validator.isApprovedCollection(tokenA);
        uint256 gasUsed = gasBefore - gasleft();
        
        assertTrue(result);
        // Gas usage should be reasonable (less than 100k for 2 registries)
        assertLt(gasUsed, 100000);
    }
}

/**
 * @title Mock Token Registry for testing
 * @dev Simple implementation of ITokenRegistry for testing purposes
 */
contract MockTokenRegistry is ITokenRegistry {
    mapping(address => bool) private registered;
    bool private shouldFail;
    
    function registerToken(address token) external {
        registered[token] = true;
    }
    
    function unregisterToken(address token) external {
        registered[token] = false;
    }
    
    function setShouldFail(bool _shouldFail) external {
        shouldFail = _shouldFail;
    }
    
    function isTokenRegistered(address token) external view override returns (bool) {
        require(!shouldFail, "Registry call failed");
        return registered[token];
    }
}