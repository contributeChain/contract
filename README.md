## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## GroveACLOracle

**GroveACLOracle** is a smart contract that serves as an Access Control List (ACL) oracle for resources stored in [Grove](https://grove.storage/). It manages permissions for who can modify or delete resources stored in Grove's decentralized storage system.

### Purpose

Grove storage is a decentralized storage solution optimized for Lens Protocol and web3 social applications. The GroveACLOracle contract provides an on-chain mechanism for:

1. Registering Grove resources (content/metadata) with their owners
2. Managing permissions for who can edit or delete these resources
3. Providing a verification point for Grove's backend to check permissions
4. Enabling resource ownership transfers while maintaining an immutable record

### Architecture

```
┌───────────────────────────────────────────────────────────────────────┐
│                                                                       │
│                         Web3 Application                              │
│                                                                       │
└───────────┬───────────────────────────────────────────┬───────────────┘
            │                                           │
            │ Upload/Update                             │ Read
            │ Content                                   │ Content
            ▼                                           ▼
┌───────────────────────┐                     ┌───────────────────────┐
│                       │                     │                       │
│    Grove Storage      │◄────Verify ACL─────►│   GroveACLOracle      │
│    (IPFS/Arweave)     │                     │   (Smart Contract)    │
│                       │                     │                       │
└───────────────────────┘                     └───────────┬───────────┘
                                                          │
                                                          │ Manage
                                                          │ Permissions
                                                          ▼
┌────────────────────────────────────────────────────────────────────────┐
│                                                                        │
│  ┌───────────────┐    ┌───────────────┐    ┌──────────────────┐        │
│  │ Resource      │    │ Authorized    │    │ Permission       │        │
│  │ Owners        │    │ Users         │    │ Management       │        │
│  └───────────────┘    └───────────────┘    └──────────────────┘        │
│                                                                        │
│                          Blockchain                                    │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

#### Authorization Flow

1. User uploads content to Grove storage
2. Resource is registered in the GroveACLOracle with a unique resourceId
3. Owner manages permissions by granting/revoking access to specific addresses
4. When edit/delete requests are made to Grove:
   - Grove's backend queries GroveACLOracle.isAuthorized()
   - Contract verifies if the requester has appropriate permissions
   - Grove processes or rejects the request based on the contract response

### Key Features

- **Resource Registration**: Register Grove URIs with their owners
- **Permission Management**: Grant and revoke edit/delete permissions to specific users
- **Ownership Transfer**: Transfer ownership of resources to new addresses
- **Authorization Checks**: Verify if users are authorized to perform specific actions
- **Record Keeping**: Maintain on-chain records of resource URIs and ownership history

### Contract Functions

#### Resource Management

- `registerResource(string calldata groveURI, address resourceOwner)`: Register a new Grove resource
- `transferResourceOwnership(bytes32 resourceId, address newOwner)`: Transfer resource ownership
- `updateResourceURIRecord(bytes32 resourceId, string calldata newGroveURI)`: Update stored URI
- `deleteResourceRecord(bytes32 resourceId)`: Delete resource records from the contract

#### Permission Management

- `grantModificationPermission(bytes32 resourceId, address user)`: Grant edit/delete permission
- `revokeModificationPermission(bytes32 resourceId, address user)`: Revoke edit/delete permission
- `isAuthorized(bytes32 resourceId, address caller, bytes4 actionSelector)`: Check if user is authorized for an action

#### Accessor Functions

- `getResourceGroveURI(bytes32 resourceId)`: Get the Grove URI for a resource
- `ownerOfResource(bytes32)`: Get the owner address of a resource
- `authorizedUsersForModification(bytes32, address)`: Check if a user is authorized for a resource

### Events

- `ResourceRegistered`: Emitted when a new resource is registered
- `PermissionGranted`: Emitted when permission is granted to a user
- `PermissionRevoked`: Emitted when permission is revoked from a user
- `ResourceOwnershipTransferred`: Emitted when resource ownership is transferred
- `ResourceURIRecordUpdated`: Emitted when a resource URI is updated
- `ResourceRecordDeleted`: Emitted when a resource record is deleted

### Integration Example

```solidity
// 1. Register a resource after uploading to Grove
bytes32 resourceId = groveACLOracle.registerResource("lens://Qm...", userAddress);

// 2. Grant permission to collaborator
groveACLOracle.grantModificationPermission(resourceId, collaboratorAddress);

// 3. Check authorization (typically called by Grove backend)
bool canEdit = groveACLOracle.isAuthorized(
  resourceId, 
  requestingUser, 
  groveACLOracle.ACTION_EDIT()
);
```

### Security Considerations

- Only resource owners can manage permissions and transfer ownership
- The contract does not store the content itself, only permission records
- Action selectors (EDIT, DELETE) provide extensibility for future permission types
- Zero-address checks prevent common errors in permission management

## ContributorNFT

**ContributorNFT** is an ERC721 token contract designed to recognize and reward GitHub contributors with unique NFTs that reflect their contributions. Each NFT includes metadata about the contribution, repository, and a rarity grade based on the contribution's significance.

### Purpose

The ContributorNFT contract provides an on-chain mechanism to:

1. Recognize valuable contributions to GitHub repositories
2. Assign value to contributors through tokenized assets
3. Establish a verifiable record of contribution history
4. Create collectible NFTs with rarity tiers that reflect contribution significance

### Architecture

```
┌───────────────────────────────────────────────────────────────────────┐
│                                                                       │
│                            GitHub Project                             │
│                                                                       │
└──────────────────────────────┬────────────────────────────────────────┘
                               │
                               │ Contribution
                               │ Analysis
                               ▼
┌───────────────────────────────────────────────────────────────────────┐
│                                                                       │
│                       ContributorNFT Contract                         │
│                                                                       │
│  ┌───────────────────┐        ┌─────────────────────────────┐         │
│  │   Contribution    │        │         Token URI           │         │
│  │     Scoring       │───────►│      (IPFS/Grove URI)       │         │
│  └───────────────────┘        └─────────────────────────────┘         │
│           │                                                           │
│           │                                                           │
│           ▼                                                           │
│  ┌───────────────────┐        ┌─────────────────────────────┐         │
│  │      Rarity       │        │         Contributor         │         │
│  │   Determination   │────────┤           Reward            │         │
│  └───────────────────┘        └─────────────────────────────┘         │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

### Key Features

- **Contribution Tracking**: Associate NFTs with specific GitHub repositories
- **Rarity Tiers**: Five levels from Common to Legendary based on contribution score
- **Metadata Storage**: Store contribution details on-chain with NFT metadata
- **Repository Indexing**: Quickly retrieve all NFTs minted for a specific repository
- **Contribution Scoring**: Value contributions based on impact and complexity

### Contract Functions

#### Minting and Metadata

- `mintContribution(address to, string memory repositoryUrl, uint256 contributionScore, string memory tokenURI)`: Mint a new contribution NFT
- `getTokenMetadata(uint256 tokenId)`: Retrieve full metadata for a specific token
- `determineRarity(uint256 score)`: Calculate rarity tier based on contribution score
- `getRarityName(Rarity rarity)`: Convert rarity enum to human-readable string

#### Repository and Token Management

- `getRepositoryTokens(string memory repositoryUrl)`: Get all tokens associated with a repository
- `totalSupply()`: Get total number of minted NFTs

### Rarity System

ContributorNFT implements a 5-tier rarity system:

| Rarity Level | Contribution Score | Description |
|--------------|-------------------|-------------|
| Common       | 0-49              | Minor contributions like typo fixes |
| Uncommon     | 50-199            | Small improvements or documentation |
| Rare         | 200-499           | Feature implementations or bug fixes |
| Epic         | 500-999           | Major feature development |
| Legendary    | 1000+             | Critical contributions with project-wide impact |

### Events

- `ContributionNFTMinted`: Emitted when a new NFT is minted, including token ID, contributor, repository, rarity, and score

### Integration Example

```solidity
// 1. Mint an NFT for a valuable contribution
uint256 tokenId = contributorNFT.mintContribution(
    contributorAddress,
    "github.com/owner/repository",
    650,  // Epic rarity (score 500-999)
    "ipfs://QmYourTokenMetadataHash"
);

// 2. Retrieve all tokens for a repository
uint256[] memory tokens = contributorNFT.getRepositoryTokens("github.com/owner/repository");

// 3. Get metadata for a specific token
(
    string memory repoUrl,
    address contributor,
    string memory rarityName,
    uint256 score,
    uint256 timestamp
) = contributorNFT.getTokenMetadata(tokenId);
```

### Security Considerations

- The contract includes access control for admin functions
- Custom errors provide clear information about failed operations
- Non-existent token checks prevent unauthorized operations
- Repository URLs cannot be empty, ensuring proper indexing

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

## Deploying on Lens Chain

This project supports deployment on Lens Chain using Foundry ZKSync. Follow these steps to deploy the GroveACLOracle contract:

### Prerequisites

1. **Install Foundry ZKSync**:
   ```shell
   git clone git@github.com:matter-labs/foundry-zksync.git
   cd foundry-zksync
   ./install-foundry-zksync
   ```

2. **Configure foundry.toml**:
   Ensure your `foundry.toml` contains the ZKSync profile:
   ```toml
   [profile.zksync]
   src = 'src'
   libs = ['lib']
   solc-version = "0.8.24"
   fallback_oz = true
   is_system = false
   mode = "3"
   remappings = [
       "@openzeppelin/=lib/openzeppelin-contracts/"
   ]
   ```

3. **Set up deployment wallet**:
   ```shell
   FOUNDRY_PROFILE=zksync cast wallet import myKeystore --interactive
   ```
   You'll be prompted to enter your private key and a password.

4. **Get $GRASS tokens**:
   For Lens Chain Sepolia Testnet deployments, obtain $GRASS tokens from a faucet.

### Compiling

Compile the contracts for Lens Chain:

```shell
FOUNDRY_PROFILE=zksync forge build --zksync
```

### Deployment

Deploy the GroveACLOracle contract:

```shell
FOUNDRY_PROFILE=zksync forge create src/GroveACLOracle.sol:GroveACLOracle \
  --account myKeystore \
  --rpc-url https://rpc.testnet.lens.xyz \
  --chain 37111 \
  --zksync
```

Deploy the ContributorNFT contract:

```shell
FOUNDRY_PROFILE=zksync forge create src/ContributeNft.sol:ContributorNFT \
  --account myKeystore \
  --rpc-url https://rpc.testnet.lens.xyz \
  --chain 37111 \
  --zksync
```

### Troubleshooting

**Insufficient Funds Error**:
```
Error: server returned an error response: error code 3: insufficient funds for gas + value
```

This indicates your wallet needs more $GRASS tokens. Check your balance with:
```shell
cast balance YOUR_ADDRESS --rpc-url https://rpc.testnet.lens.xyz
```

**Keystore Issues**:
If you encounter keystore errors, verify it exists with:
```shell
cast wallet list
```

## Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
