// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;
import "../interface/IERC6909.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RoyaltyFeatures.sol";

/**
 * @title ERC6909
 * @dev Implementation of the ERC6909 Multi-Token Standard with Royalty Support
 * @notice EIP-6909 Compliant Implementation with ERC2981 royalties
 */
contract ERC6909 is IERC6909, RoyaltyFeatures, Ownable {
    /// @dev Thrown when owner balance for id is insufficient.
    error InsufficientBalance(address owner, uint256 id);
    
    /// @dev Thrown when spender allowance for id is insufficient.
    error InsufficientPermission(address spender, uint256 id);
    
    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public allowance;
    mapping(address => mapping(address => bool)) public isOperator;
    mapping(uint256 => uint256) public totalSupply;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool) {
        if (balanceOf[msg.sender][id] < amount) revert InsufficientBalance(msg.sender, id);
        balanceOf[msg.sender][id] -= amount;
        balanceOf[receiver][id] += amount;
        emit Transfer(msg.sender, msg.sender, receiver, id, amount);
        return true;
    }
    
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool) {
        if (sender != msg.sender && !isOperator[sender][msg.sender]) {
            uint256 senderAllowance = allowance[sender][msg.sender][id];
            if (senderAllowance < amount) revert InsufficientPermission(msg.sender, id);
            if (senderAllowance != type(uint256).max) {
                allowance[sender][msg.sender][id] = senderAllowance - amount;
            }
        }
        if (balanceOf[sender][id] < amount) revert InsufficientBalance(sender, id);
        balanceOf[sender][id] -= amount;
        balanceOf[receiver][id] += amount;
        emit Transfer(msg.sender, sender, receiver, id, amount);
        return true;
    }
    
    function approve(address spender, uint256 id, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender][id] = amount;
        emit Approval(msg.sender, spender, id, amount);
        return true;
    }
    
    function setOperator(address spender, bool approved) external returns (bool) {
        isOperator[msg.sender][spender] = approved;
        emit OperatorSet(msg.sender, spender, approved);
        return true;
    }

    /// @notice Checks if a contract implements an interface.
    /// @dev Overrides both IERC6909 and ERC2981 supportsInterface functions
    function supportsInterface(bytes4 interfaceId) public view override(IERC6909, ERC2981) returns (bool) {
        return
            interfaceId == 0x0f632fb3 || // ERC6909
            interfaceId == 0x01ffc9a7 || // ERC165
            super.supportsInterface(interfaceId); // ERC2981 and other inherited interfaces
    }

    function mint(address receiver, uint256 id, uint256 amount) external onlyOwner {
        _mint(receiver, id, amount);
    }

    function _mint(address receiver, uint256 id, uint256 amount) internal {
        balanceOf[receiver][id] += amount;
        totalSupply[id] += amount;
        emit Transfer(msg.sender, address(0), receiver, id, amount);
    }
    
    function _burn(address sender, uint256 id, uint256 amount) internal {
        balanceOf[sender][id] -= amount;
        totalSupply[id] -= amount;
        emit Transfer(msg.sender, sender, address(0), id, amount);
    }
}
