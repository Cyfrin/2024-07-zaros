// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Zaros dependencies
import { IPerpsEngine } from "@zaros/perpetuals/PerpsEngine.sol";

// Open Zeppelin dependencies
import { ERC721, ERC721Enumerable } from "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";

contract AccountNFT is ERC721Enumerable, Ownable {
    using SafeCast for uint256;

    constructor(string memory name, string memory symbol, address owner) ERC721(name, symbol) Ownable(owner) { }

    function mint(address to, uint256 tokenId) external onlyOwner {
        // intentionally not using _safeMint
        _mint(to, tokenId);
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address previousOwner = super._update(to, tokenId, auth);
        IPerpsEngine(owner()).notifyAccountTransfer(to, tokenId.toUint128());

        return previousOwner;
    }
}
