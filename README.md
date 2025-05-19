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

### Anvil

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
