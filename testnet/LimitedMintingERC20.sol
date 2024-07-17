// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// Open zeppelin upgradeable dependencies
import { ERC20PermitUpgradeable } from "@openzeppelin-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract LimitedMintingERC20 is UUPSUpgradeable, ERC20PermitUpgradeable, OwnableUpgradeable {
    uint256 internal maxAmountToMintPerAddress;
    mapping(address user => uint256 amount) public amountMintedPerAddress;

    error LimitedMintingERC20_ZeroAmount();
    error LimitedMintingERC20_AmountExceedsLimit();
    error LimitedMintingERC20_UserIsNotActive();

    function getAmountMintedPerAddress(address user) external view returns (uint256) {
        return amountMintedPerAddress[user];
    }

    function initialize(address owner, string memory name, string memory symbol) external initializer {
        maxAmountToMintPerAddress = 100_000e18;

        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);
        __Ownable_init(owner);
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != owner()) {
            _requireAmountNotZero(amount);
            _requireAmountLessThanMaxAmountMint(amount);
        }

        amountMintedPerAddress[msg.sender] += amount;

        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _requireAmountNotZero(amount);
        _burn(from, amount);
    }

    function updateMaxAmountToMintPerAddress(uint256 newAmount) external onlyOwner {
        maxAmountToMintPerAddress = newAmount;
    }

    function _requireAmountNotZero(uint256 amount) private pure {
        if (amount == 0) revert LimitedMintingERC20_ZeroAmount();
    }

    function _requireAmountLessThanMaxAmountMint(uint256 amount) private view {
        if (amountMintedPerAddress[msg.sender] + amount > maxAmountToMintPerAddress) {
            revert LimitedMintingERC20_AmountExceedsLimit();
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner { }
}
