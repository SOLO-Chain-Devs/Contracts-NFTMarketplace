// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/core/NFTMarketplace.sol";
import {NFT721} from "../src/mock/NFT721.sol";
import {NFT6909} from "../src/mock/NFT6909.sol";
import {DummyCurator} from "../src/mock/DummyCurator.sol";

// Import the error for testing
error CollectionNotApproved(address tokenContract);

contract CurationTest is Test {
    NFTMarketplace public market;
    DummyCurator public curator;
    NFT721 public nft721;
    NFT6909 public nft6909;

    address public deployer;
    address public seller1 = vm.addr(1);
    address public buyer1 = vm.addr(2);

    function setUp() public {
        deployer = msg.sender;

        vm.startPrank(deployer);

        // Deploy contracts
        market = new NFTMarketplace();
        curator = new DummyCurator();
        nft721 = new NFT721("ERC721", "721", "", msg.sender, 0, 0, msg.sender);

        uint256[] memory initialIds = new uint256[](1);
        uint256[] memory initialAmounts = new uint256[](1);
        initialIds[0] = 1;
        initialAmounts[0] = 100;
        nft6909 = new NFT6909(
            "ERC6909", "6909", "https://example.com/", msg.sender, 0, initialIds, initialAmounts, msg.sender
        );

        vm.stopPrank();

        vm.deal(seller1, 10 ether);
        vm.deal(buyer1, 10 ether);
    }

    function mint721(address _to, uint256 _id) internal {
        vm.startPrank(deployer);
        nft721.safeMint(_to, _id);
        vm.stopPrank();
    }

    function mint6909(address _to, uint256 _tokenId, uint256 _amount) internal {
        vm.startPrank(deployer);
        nft6909.mint(_to, _tokenId, _amount);
        vm.stopPrank();
    }

    // Test curation disabled (default state)
    function test_CurationDisabled_AllowsListing() public {
        mint721(seller1, 1);

        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        vm.stopPrank();

        (address seller,,,,,) = market.listings(1);
        assertEq(seller, seller1);
    }

    // Test enabling curation blocks unapproved collections
    function test_CurationEnabled_BlocksUnapprovedListing() public {
        mint721(seller1, 1);

        // Enable curation
        vm.startPrank(deployer);
        market.setCurationEnabled(true);
        market.setCurationValidator(address(curator));
        vm.stopPrank();

        // Should fail - collection not approved
        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        vm.expectRevert(abi.encodeWithSelector(CollectionNotApproved.selector, address(nft721)));
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        vm.stopPrank();
    }

    // Test approved collection can list
    function test_CurationEnabled_AllowsApprovedListing() public {
        mint721(seller1, 1);

        // Enable curation and approve collection
        vm.startPrank(deployer);
        market.setCurationEnabled(true);
        market.setCurationValidator(address(curator));
        curator.approveCollection(address(nft721));
        vm.stopPrank();

        // Should succeed
        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        vm.stopPrank();

        (address seller,,,,,) = market.listings(1);
        assertEq(seller, seller1);
    }

    // Test bidding with curation
    function test_CurationEnabled_BlocksUnapprovedBidding() public {
        mint6909(seller1, 1, 10);

        // Enable curation but don't approve collection
        vm.startPrank(deployer);
        market.setCurationEnabled(true);
        market.setCurationValidator(address(curator));
        vm.stopPrank();

        // Bidding should fail
        vm.startPrank(buyer1);
        vm.expectRevert(abi.encodeWithSelector(CollectionNotApproved.selector, address(nft6909)));
        market.placeBid{value: 1 ether}(address(nft6909), 1, 5, address(0), 1 ether, 0);
        vm.stopPrank();
    }

    // Test approved collection can receive bids
    function test_CurationEnabled_AllowsApprovedBidding() public {
        mint6909(seller1, 1, 10);

        // Enable curation and approve collection
        vm.startPrank(deployer);
        market.setCurationEnabled(true);
        market.setCurationValidator(address(curator));
        curator.approveCollection(address(nft6909));
        vm.stopPrank();

        // Bidding should succeed
        vm.startPrank(buyer1);
        market.placeBid{value: 1 ether}(address(nft6909), 1, 5, address(0), 1 ether, 0);
        vm.stopPrank();

        (address bidder,,,,) = market.bids(address(nft6909), 1, 5);
        assertEq(bidder, buyer1);
    }

    // Test dynamic approval changes
    function test_CurationDynamicApproval() public {
        mint721(seller1, 1);
        mint721(seller1, 2);

        // Enable curation and approve collection
        vm.startPrank(deployer);
        market.setCurationEnabled(true);
        market.setCurationValidator(address(curator));
        curator.approveCollection(address(nft721));
        vm.stopPrank();

        // First listing succeeds
        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        vm.stopPrank();

        // Disapprove collection
        vm.startPrank(deployer);
        curator.disapproveCollection(address(nft721));
        vm.stopPrank();

        // Second listing fails
        vm.startPrank(seller1);
        vm.expectRevert(abi.encodeWithSelector(CollectionNotApproved.selector, address(nft721)));
        market.createListing(address(nft721), 2, 1, 1 ether, address(0));
        vm.stopPrank();
    }

    // Test turning curation off and on
    function test_CurationToggle() public {
        mint721(seller1, 1);

        // Enable curation without approving collection
        vm.startPrank(deployer);
        market.setCurationEnabled(true);
        market.setCurationValidator(address(curator));
        vm.stopPrank();

        // Should fail
        vm.startPrank(seller1);
        nft721.setApprovalForAll(address(market), true);
        vm.expectRevert(abi.encodeWithSelector(CollectionNotApproved.selector, address(nft721)));
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        vm.stopPrank();

        // Disable curation
        vm.startPrank(deployer);
        market.setCurationEnabled(false);
        vm.stopPrank();

        // Should now succeed
        vm.startPrank(seller1);
        market.createListing(address(nft721), 1, 1, 1 ether, address(0));
        vm.stopPrank();

        (address seller,,,,,) = market.listings(1);
        assertEq(seller, seller1);
    }
}
