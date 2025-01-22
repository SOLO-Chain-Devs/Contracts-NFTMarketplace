// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/core/NFTMarketplace.sol";
import {NFT721} from "../src/mock/NFT721.sol";
import {NFT1155} from "../src/mock/NFT1155.sol";

contract MarketFuzzTest is Test {
    NFTMarketplace public market;
    NFT721 public nft721;
    NFT1155 public nft1155;
    address public deployer;
    address public seller1;
    address public buyer1;

    function setUp() public {
        deployer = msg.sender;
        seller1 = vm.addr(1);
        buyer1 = vm.addr(2);

        vm.startPrank(deployer);
        market = new NFTMarketplace();
        nft721 = new NFT721("ERC721", "721", "", msg.sender, 0, 0, msg.sender);
        nft1155 = new NFT1155("ERC1155", "1155", "", msg.sender, 0, new uint256[](1), new uint256[](1), msg.sender);

        vm.stopPrank();

        vm.deal(deployer, 100 ether);
        vm.deal(seller1, 100 ether);
        vm.deal(buyer1, 100 ether);
    }

    function mint721(address _to, uint256 _id) internal {
        vm.startPrank(deployer);
        nft721.safeMint(_to, _id);
        vm.stopPrank();
    }

    function mint1155(address _to, uint256 _tokenId, uint256 _amount) internal {
        vm.startPrank(deployer);
        nft1155.mint(_to, _tokenId, _amount, "");
        vm.stopPrank();
    }

    // Fuzz test for creating an ERC721 listing
    function testFuzz_Create_Listing721(uint256 _tokenId, uint256 _price) public {
        // Constraints on the fuzzed values
        vm.assume(_price > 0 && _price < 100 ether); // Price should be positive and realistic
        vm.assume(_tokenId > 0); // Token ID should be positive

        mint721(seller1, _tokenId);

        address _tokenAddress = address(nft721);
        uint256 _amount = 1;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        (address seller, address tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address currency) =
            market.listings(1);

        // Assert that the listing has been created correctly
        assertEq(seller, seller1);
        assertEq(tokenAddress, _tokenAddress);
        assertEq(tokenId, _tokenId);
        assertEq(amount, _amount);
        assertEq(price, _price);
        assertEq(currency, _currency);
    }

    // Fuzz test for creating an ERC1155 listing
    function testFuzz_Create_Listing1155(uint256 _tokenId, uint256 _amount, uint256 _price) public {
        // Constraints on the fuzzed values
        vm.assume(_price > 0 && _price < 100 ether); // Price should be positive and realistic
        vm.assume(_amount > 0 && _amount <= 100); // Amount should be positive and limited for practicality
        vm.assume(_tokenId > 0); // Token ID should be positive

        mint1155(seller1, _tokenId, _amount);

        address _tokenAddress = address(nft1155);
        address _currency = address(0);

        vm.startPrank(seller1);
        nft1155.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        (address seller, address tokenAddress, uint256 tokenId, uint256 amount, uint256 price, address currency) =
            market.listings(1);

        // Assert that the listing has been created correctly
        assertEq(seller, seller1);
        assertEq(tokenAddress, _tokenAddress);
        assertEq(tokenId, _tokenId);
        assertEq(amount, _amount);
        assertEq(price, _price);
        assertEq(currency, _currency);
    }

    // Fuzz test for buying an ERC721 listing
    function testFuzz_Buy_Listing_721(uint256 _tokenId, uint256 _price) public {
        vm.assume(_price > 0 && _price < 100 ether); // Price should be positive and realistic
        vm.assume(_tokenId > 0); // Token ID should be positive

        mint721(seller1, _tokenId);

        // Create a listing for ERC721
        address _tokenAddress = address(nft721);
        uint256 _amount = 1;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        // Buyer purchases the listing
        vm.startPrank(buyer1);
        market.buyListing{value: _price}(1);
        vm.stopPrank();

        // Assert that the buyer is now the owner of the token
        assertEq(nft721.ownerOf(_tokenId), buyer1);
    }

    // Fuzz test for buying an ERC1155 listing
    function testFuzz_Buy_Listing_1155(uint256 _tokenId, uint256 _amount, uint256 _price) public {
        vm.assume(_price > 0 && _price < 100 ether); // Price should be positive and realistic
        vm.assume(_amount > 0 && _amount <= 100); // Amount should be positive and limited for practicality
        vm.assume(_tokenId > 0); // Token ID should be positive

        mint1155(seller1, _tokenId, _amount);

        // Create a listing for ERC1155
        address _tokenAddress = address(nft1155);
        address _currency = address(0);

        vm.startPrank(seller1);
        nft1155.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        // Buyer purchases the listing
        vm.startPrank(buyer1);
        market.buyListing{value: _price}(1);
        vm.stopPrank();

        // Assert that the buyer now owns the listed amount of tokens
        assertEq(nft1155.balanceOf(buyer1, _tokenId), _amount);
    }

    // Fuzz test for canceling a listing
    function testFuzz_Cancel_Listing(uint256 _tokenId, uint256 _price) public {
        vm.assume(_price > 0 && _price < 100 ether); // Price should be positive and realistic
        vm.assume(_tokenId > 0); // Token ID should be positive

        mint721(seller1, _tokenId);

        // Create a listing for ERC721
        address _tokenAddress = address(nft721);
        uint256 _amount = 1;
        address _currency = address(0);

        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.createListing(_tokenAddress, _tokenId, _amount, _price, _currency);
        vm.stopPrank();

        (address seller,,,,,) = market.listings(1);

        // Assert that the listing was created correctly
        assertEq(seller, seller1);

        // Cancel the listing
        vm.startPrank(seller1);
        market.cancelListing(1);
        vm.stopPrank();

        // Check that the listing no longer exists (all values should be default)
        (address seller_, address tokenAddress_, uint256 tokenId_, uint256 amount_, uint256 price_, address currency_) =
            market.listings(1);

        assertEq(seller_, address(0));
        assertEq(tokenAddress_, address(0));
        assertEq(tokenId_, 0);
        assertEq(amount_, 0);
        assertEq(price_, 0);
        assertEq(currency_, address(0));
    }
}
