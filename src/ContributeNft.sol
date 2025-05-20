// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ContributorNFT
 * @dev ERC721 token for GitHub contributors with rarity grading
 */
contract ContributorNFT is ERC721URIStorage, Ownable {
    using Strings for uint256;
    
    // Custom errors
    error EmptyRepositoryUrl();
    error TokenDoesNotExist(uint256 tokenId);
    error UnauthorizedAccess(address caller, address owner);
    
    // Using our own counter instead of OpenZeppelin's Counter to avoid import issues
    uint256 private _currentTokenId = 0;
    
    // Rarity levels (1-5, with 5 being the rarest)
    enum Rarity { Common, Uncommon, Rare, Epic, Legendary }
    
    // Repository to token mapping
    mapping(string => uint256[]) public repositoryTokens;
    
    // Token metadata
    struct TokenMetadata {
        string repositoryUrl;
        address contributor;
        Rarity rarity;
        uint256 contributionScore;
        uint256 mintedAt;
    }
    
    // Token ID to metadata
    mapping(uint256 => TokenMetadata) public tokenMetadata;
    
    // Events
    event ContributionNFTMinted(
        uint256 indexed tokenId,
        address indexed contributor,
        string repositoryUrl,
        uint8 rarity,
        uint256 contributionScore
    );
    
    constructor() ERC721("ContributorNFT", "CONTRIB") Ownable(msg.sender) {}
    
    /**
     * @dev Mint a new contribution NFT
     * @param to Address to receive the NFT
     * @param repositoryUrl GitHub repository URL
     * @param contributionScore Contribution score (higher = better contribution)
     * @param tokenURI URI for token metadata (stored in Grove/IPFS)
     * @return tokenId New token ID
     */
    function mintContribution(
        address to,
        string memory repositoryUrl,
        uint256 contributionScore,
        string memory tokenURI
    ) public returns (uint256) {
        if(bytes(repositoryUrl).length == 0) {
            revert EmptyRepositoryUrl();
        }
        
        _currentTokenId += 1;
        uint256 newTokenId = _currentTokenId;
        
        // Determine rarity based on contribution score
        Rarity rarity = determineRarity(contributionScore);
        
        // Mint the token
        _mint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        
        // Store metadata
        tokenMetadata[newTokenId] = TokenMetadata({
            repositoryUrl: repositoryUrl,
            contributor: to,
            rarity: rarity,
            contributionScore: contributionScore,
            mintedAt: block.timestamp
        });
        
        // Associate token with repository
        repositoryTokens[repositoryUrl].push(newTokenId);
        
        // Emit event
        emit ContributionNFTMinted(
            newTokenId,
            to,
            repositoryUrl,
            uint8(rarity),
            contributionScore
        );
        
        return newTokenId;
    }
    
    /**
     * @dev Determine rarity based on contribution score
     * @param score Contribution score
     * @return Rarity level
     */
    function determineRarity(uint256 score) public pure returns (Rarity) {
        if (score >= 1000) {
            return Rarity.Legendary;
        } else if (score >= 500) {
            return Rarity.Epic;
        } else if (score >= 200) {
            return Rarity.Rare;
        } else if (score >= 50) {
            return Rarity.Uncommon;
        } else {
            return Rarity.Common;
        }
    }
    
    /**
     * @dev Get rarity name as string
     * @param rarity Rarity enum value
     * @return String representation
     */
    function getRarityName(Rarity rarity) public pure returns (string memory) {
        if (rarity == Rarity.Legendary) {
            return "Legendary";
        } else if (rarity == Rarity.Epic) {
            return "Epic";
        } else if (rarity == Rarity.Rare) {
            return "Rare";
        } else if (rarity == Rarity.Uncommon) {
            return "Uncommon";
        } else {
            return "Common";
        }
    }
    
    /**
     * @dev Get token metadata
     * @param tokenId Token ID
     * @return repositoryUrl Repository URL
     * @return contributor Contributor address
     * @return rarityName Rarity name
     * @return contributionScore Contribution score
     * @return mintedAt Timestamp when token was minted
     */
    function getTokenMetadata(uint256 tokenId) public view returns (
        string memory repositoryUrl,
        address contributor,
        string memory rarityName,
        uint256 contributionScore,
        uint256 mintedAt
    ) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }
        
        TokenMetadata memory metadata = tokenMetadata[tokenId];
        
        return (
            metadata.repositoryUrl,
            metadata.contributor,
            getRarityName(metadata.rarity),
            metadata.contributionScore,
            metadata.mintedAt
        );
    }
    
    /**
     * @dev Get all tokens for a repository
     * @param repositoryUrl Repository URL
     * @return Array of token IDs
     */
    function getRepositoryTokens(string memory repositoryUrl) public view returns (uint256[] memory) {
        return repositoryTokens[repositoryUrl];
    }
    
    /**
     * @dev Get total number of minted tokens
     * @return Total supply
     */
    function totalSupply() public view returns (uint256) {
        return _currentTokenId;
    }
    
    /**
     * @dev Check if a token exists
     * @param tokenId Token ID
     * @return Whether token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}