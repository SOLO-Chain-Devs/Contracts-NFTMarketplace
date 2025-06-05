// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../interface/IERC6909.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RoyaltyFeatures.sol";

/**
 * @title NFT6909
 * @dev Implementation of ERC6909 Multi-Token Standard with royalty support
 * @notice EIP-6909 Compliant Implementation with ERC2981 royalties
 */
contract NFT6909 is IERC6909, RoyaltyFeatures, Ownable {
    /// @dev Thrown when owner balance for id is insufficient.
    error InsufficientBalance(address owner, uint256 id);
    
    /// @dev Thrown when spender allowance for id is insufficient.
    error InsufficientPermission(address spender, uint256 id);

    string public name;
    string public symbol;
    string private baseURI;

    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public allowance;
    mapping(address => mapping(address => bool)) public isOperator;
    mapping(uint256 => uint256) public totalSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address royaltyReceiver,
        uint96 feeNumerator,
        uint256[] memory initialIds,
        uint256[] memory initialAmounts,
        address initialReceiver
    ) Ownable(msg.sender) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        _setDefaultRoyalty(royaltyReceiver, feeNumerator);
        
        // Initial minting
        for (uint256 i = 0; i < initialIds.length; i++) {
            _mint(initialReceiver, initialIds[i], initialAmounts[i]);
        }
    }

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

    function mint(address account, uint256 id, uint256 amount) public onlyOwner {
        _mint(account, id, amount);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyOwner {
        require(ids.length == amounts.length, "Arrays length mismatch");
        for (uint256 i = 0; i < ids.length; i++) {
            _mint(to, ids[i], amounts[i]);
        }
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function uri(uint256 id) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, _toString(id), ".json"));
    }

    function _mint(address receiver, uint256 id, uint256 amount) internal {
        balanceOf[receiver][id] += amount;
        totalSupply[id] += amount;
        emit Transfer(msg.sender, address(0), receiver, id, amount);
    }

    function _burn(address sender, uint256 id, uint256 amount) internal {
        if (balanceOf[sender][id] < amount) revert InsufficientBalance(sender, id);
        balanceOf[sender][id] -= amount;
        totalSupply[id] -= amount;
        emit Transfer(msg.sender, sender, address(0), id, amount);
    }

    /// @notice Checks if a contract implements an interface.
    function supportsInterface(bytes4 interfaceId) public view override(IERC6909, ERC2981) returns (bool) {
        return
            interfaceId == 0x0f632fb3 || // ERC6909
            interfaceId == 0x01ffc9a7 || // ERC165
            super.supportsInterface(interfaceId); // ERC2981
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
