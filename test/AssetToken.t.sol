// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AssetToken} from "../src/AssetToken.sol";
import {AssetTokenV2} from "../src/AssetTokenV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title AssetTokenTest
 * @dev Comprehensive test suite for AssetToken upgrade lifecycle
 */
contract AssetTokenTest is Test {
    AssetToken public implementationV1;
    AssetTokenV2 public implementationV2;
    ERC1967Proxy public proxy;
    AssetToken public token; // Proxy as AssetToken interface

    address public admin = address(0x1);
    address public minter = address(0x2);
    address public user = address(0x3);
    address public otherUser = address(0x4);

    uint256 public constant MAX_SUPPLY = 1_000_000e18;
    uint256 public constant MINT_AMOUNT = 100e18;

    event TokensMinted(address indexed to, uint256 amount);
    event AdminAction(string action, address indexed admin);
    event Paused(address account);
    event Unpaused(address account);
    event Upgraded(address indexed implementation);

    function setUp() public {
        // Deploy V1 implementation
        implementationV1 = new AssetToken();

        // Deploy proxy with V1 implementation
        bytes memory initData =
            abi.encodeWithSelector(AssetToken.initialize.selector, "Asset Token", "AST", MAX_SUPPLY, admin);

        proxy = new ERC1967Proxy(address(implementationV1), initData);
        token = AssetToken(payable(address(proxy)));

        // Setup roles
        vm.startPrank(admin);
        token.grantRole(token.MINTER_ROLE(), minter);
        vm.stopPrank();
    }

    /**
     * @dev Test V1 deployment and initialization
     */
    function test_DeployV1() public {
        assertEq(token.name(), "Asset Token");
        assertEq(token.symbol(), "AST");
        assertEq(token.maxSupply(), MAX_SUPPLY);
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(token.MINTER_ROLE(), admin));
        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));
    }

    /**
     * @dev Test minting tokens
     */
    function test_MintTokens() public {
        vm.prank(minter);
        token.mint(user, MINT_AMOUNT);

        assertEq(token.balanceOf(user), MINT_AMOUNT);
        assertEq(token.totalSupply(), MINT_AMOUNT);
    }

    /**
     * @dev Test minting emits event
     */
    function test_MintEmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit TokensMinted(user, MINT_AMOUNT);

        vm.prank(minter);
        token.mint(user, MINT_AMOUNT);
    }

    /**
     * @dev Test minting exceeds max supply reverts
     */
    function test_MintExceedsMaxSupply() public {
        uint256 excessAmount = MAX_SUPPLY + 1;

        vm.prank(minter);
        vm.expectRevert(AssetToken.MaxSupplyExceeded.selector);
        token.mint(user, excessAmount);
    }

    /**
     * @dev Test only minter can mint
     */
    function test_OnlyMinterCanMint() public {
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, MINT_AMOUNT);
    }

    /**
     * @dev Test standard token transfer
     */
    function test_Transfer() public {
        vm.prank(minter);
        token.mint(user, MINT_AMOUNT);

        vm.prank(user);
        token.transfer(otherUser, 50e18);

        assertEq(token.balanceOf(user), 50e18);
        assertEq(token.balanceOf(otherUser), 50e18);
    }

    /**
     * @dev Test upgrade to V2
     */
    function test_UpgradeToV2() public {
        // First mint some tokens
        vm.prank(minter);
        token.mint(user, MINT_AMOUNT);
        assertEq(token.balanceOf(user), MINT_AMOUNT);

        // Deploy V2 implementation
        implementationV2 = new AssetTokenV2();

        // Upgrade proxy to V2
        vm.prank(admin);
        token.upgradeToAndCall(address(implementationV2), abi.encodeWithSelector(AssetTokenV2.initializeV2.selector));

        // Verify upgrade
        assertEq(
            address(
                uint160(
                    uint256(vm.load(address(proxy), 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc))
                )
            ),
            address(implementationV2)
        );

        // Cast proxy to V2 interface
        AssetTokenV2 tokenV2 = AssetTokenV2(payable(address(proxy)));

        // Verify balance persisted
        assertEq(tokenV2.balanceOf(user), MINT_AMOUNT);

        // Verify V2 functionality exists
        assertTrue(address(tokenV2).code.length > 0);
    }

    /**
     * @dev Test upgrade lifecycle: deploy, mint, upgrade, verify persistence
     */
    function test_UpgradeLifecycle() public {
        // Step 1: Deploy V1 via proxy (done in setUp)
        assertEq(token.maxSupply(), MAX_SUPPLY);

        // Step 2: Mint 100 tokens to user
        vm.prank(minter);
        token.mint(user, MINT_AMOUNT);
        assertEq(token.balanceOf(user), MINT_AMOUNT);

        // Step 3: Deploy V2
        implementationV2 = new AssetTokenV2();

        // Step 4: Upgrade proxy to V2
        vm.prank(admin);
        token.upgradeToAndCall(address(implementationV2), abi.encodeWithSelector(AssetTokenV2.initializeV2.selector));

        AssetTokenV2 tokenV2 = AssetTokenV2(payable(address(proxy)));

        // Step 5: Verify balance persisted
        assertEq(tokenV2.balanceOf(user), MINT_AMOUNT);

        // Step 6: Test pause functionality
        vm.prank(admin);
        tokenV2.pause();

        // Step 7: Verify transfers revert when paused
        vm.prank(user);
        vm.expectRevert();
        tokenV2.transfer(otherUser, 50e18);
    }

    /**
     * @dev Test pause functionality on V2
     */
    function test_PauseFunctionality() public {
        // Upgrade to V2
        implementationV2 = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(implementationV2), abi.encodeWithSelector(AssetTokenV2.initializeV2.selector));

        AssetTokenV2 tokenV2 = AssetTokenV2(payable(address(proxy)));

        // Mint tokens
        vm.prank(minter);
        tokenV2.mint(user, MINT_AMOUNT);

        // Pause contract
        vm.prank(admin);
        tokenV2.pause();

        // Verify transfers revert
        vm.prank(user);
        vm.expectRevert();
        tokenV2.transfer(otherUser, 50e18);

        // Unpause
        vm.prank(admin);
        tokenV2.unpause();

        // Verify transfers work again
        vm.prank(user);
        tokenV2.transfer(otherUser, 50e18);
        assertEq(tokenV2.balanceOf(otherUser), 50e18);
    }

    /**
     * @dev Test only admin can pause
     */
    function test_OnlyAdminCanPause() public {
        implementationV2 = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(implementationV2), abi.encodeWithSelector(AssetTokenV2.initializeV2.selector));

        AssetTokenV2 tokenV2 = AssetTokenV2(payable(address(proxy)));

        vm.prank(user);
        vm.expectRevert();
        tokenV2.pause();
    }

    /**
     * @dev Test only admin can upgrade
     */
    function test_OnlyAdminCanUpgrade() public {
        implementationV2 = new AssetTokenV2();

        vm.prank(user);
        vm.expectRevert();
        token.upgradeToAndCall(address(implementationV2), abi.encodeWithSelector(AssetTokenV2.initializeV2.selector));
    }

    /**
     * @dev Test pause emits event
     */
    function test_PauseEmitsEvent() public {
        implementationV2 = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(implementationV2), abi.encodeWithSelector(AssetTokenV2.initializeV2.selector));

        AssetTokenV2 tokenV2 = AssetTokenV2(payable(address(proxy)));

        vm.expectEmit(true, false, false, true);
        emit Paused(admin);

        vm.prank(admin);
        tokenV2.pause();
    }

    /**
     * @dev Test minting still works after upgrade
     */
    function test_MintingAfterUpgrade() public {
        // Upgrade to V2
        implementationV2 = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(implementationV2), abi.encodeWithSelector(AssetTokenV2.initializeV2.selector));

        AssetTokenV2 tokenV2 = AssetTokenV2(payable(address(proxy)));

        // Mint should still work
        vm.prank(minter);
        tokenV2.mint(user, MINT_AMOUNT);

        assertEq(tokenV2.balanceOf(user), MINT_AMOUNT);
    }

    /**
     * @dev Test max supply constraint persists after upgrade
     */
    function test_MaxSupplyAfterUpgrade() public {
        // Mint up to max supply
        vm.prank(minter);
        token.mint(user, MAX_SUPPLY);

        // Upgrade to V2
        implementationV2 = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(implementationV2), abi.encodeWithSelector(AssetTokenV2.initializeV2.selector));

        AssetTokenV2 tokenV2 = AssetTokenV2(payable(address(proxy)));

        // Try to mint more - should revert
        vm.prank(minter);
        vm.expectRevert(AssetToken.MaxSupplyExceeded.selector);
        tokenV2.mint(otherUser, 1);
    }
}
