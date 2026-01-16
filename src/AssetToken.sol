// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title AssetToken
 * @dev UUPS-upgradeable ERC20 token with minting capabilities and supply cap
 * @notice This contract implements a tokenized financial asset with role-based access control
 */
contract AssetToken is Initializable, ERC20Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    /// @dev Custom error for when minting would exceed max supply
    error MaxSupplyExceeded();

    /// @dev Role identifier for minters
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev Maximum supply of tokens that can be minted
    uint256 public maxSupply;

    /// @dev Event emitted when tokens are minted
    event TokensMinted(address indexed to, uint256 amount);

    /// @dev Event emitted when admin performs an action
    event AdminAction(string action, address indexed admin);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract
     * @param name Token name
     * @param symbol Token symbol
     * @param _maxSupply Maximum supply of tokens
     * @param admin Address to receive DEFAULT_ADMIN_ROLE
     */
    function initialize(string memory name, string memory symbol, uint256 _maxSupply, address admin)
        public
        initializer
    {
        __ERC20_init(name, symbol);
        __AccessControl_init();

        maxSupply = _maxSupply;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);

        emit AdminAction("Contract initialized", admin);
    }

    /**
     * @dev Mints tokens to a specified address
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint
     * @notice Only addresses with MINTER_ROLE can call this function
     * @notice Reverts if minting would exceed maxSupply
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (totalSupply() + amount > maxSupply) {
            revert MaxSupplyExceeded();
        }
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Authorizes an upgrade to a new implementation
     * @param newImplementation Address of the new implementation contract
     * @notice Only addresses with DEFAULT_ADMIN_ROLE can authorize upgrades
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {
        emit AdminAction("Upgrade authorized", msg.sender);
    }
}
