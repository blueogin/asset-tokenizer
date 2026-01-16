// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AssetToken} from "../src/AssetToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployAssetToken
 * @dev Deployment script for AssetToken V1 with ERC1967Proxy
 */
contract DeployAssetToken is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.envAddress("ADMIN_ADDRESS");
        uint256 maxSupply = vm.envOr("MAX_SUPPLY", uint256(1_000_000e18));

        vm.startBroadcast(deployerPrivateKey);

        // Deploy V1 implementation
        AssetToken implementation = new AssetToken();
        console.log("V1 Implementation deployed at:", address(implementation));

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            AssetToken.initialize.selector,
            "Asset Token",
            "AST",
            maxSupply,
            admin
        );

        // Deploy proxy with V1 implementation
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        console.log("Proxy deployed at:", address(proxy));

        // Cast proxy to AssetToken interface
        AssetToken token = AssetToken(payable(address(proxy)));

        // Verify deployment
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Max supply:", token.maxSupply());
        console.log("Admin address:", admin);
        console.log("Admin has DEFAULT_ADMIN_ROLE:", token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        console.log("Admin has MINTER_ROLE:", token.hasRole(token.MINTER_ROLE(), admin));

        vm.stopBroadcast();
    }
}

