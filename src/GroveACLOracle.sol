// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title GroveACLOracle
 * @author Lens Alchemy Team
 * @notice This contract serves as an Access Control List (ACL) oracle for resources
 * stored in Grove (https://grove.storage/). It allows owners to register their Grove
 * resources and manage permissions for who can modify or delete them. Grove's
 * backend can then query the `isAuthorized` function of this contract to determine
 * if a user (identified by their address and a signed message) is permitted to
 * perform an action on a specific resource.
 *
 * The contract uses a `resourceId` (bytes32) to uniquely identify Grove resources.
 * This ID is typically derived from the Grove URI (e.g., keccak256 of the lens:// URI).
 * Actions are represented by `bytes4` selectors.
 */
contract GroveACLOracle {
    // Custom Errors
    error GroveACLOracle__NotContractOwner();
    error GroveACLOracle__NotResourceOwner();
    error GroveACLOracle__GroveURICannotBeEmpty();
    error GroveACLOracle__ResourceOwnerCannotBeZeroAddress();
    error GroveACLOracle__ResourceAlreadyRegistered();
    error GroveACLOracle__UserCannotBeZeroAddress();
    error GroveACLOracle__NewOwnerCannotBeZeroAddress();
    error GroveACLOracle__NewContractOwnerCannotBeZeroAddress();
    error GroveACLOracle__NoEtherAccepted();

    using ECDSA for bytes32;
    using Strings for uint256;

    address public contractOwner;

    mapping(bytes32 => address) public ownerOfResource;
    mapping(bytes32 => mapping(address => bool)) public authorizedUsersForModification;
    mapping(bytes32 => string) internal resourceGroveURIs; // For record-keeping

    // Standard action selectors Grove might use
    bytes4 public constant ACTION_EDIT = bytes4(keccak256(bytes("EDIT")));
    bytes4 public constant ACTION_DELETE = bytes4(keccak256(bytes("DELETE")));

    /**
     * @dev Emitted when a new Grove resource is registered with the oracle.
     * @param resourceId The unique identifier for the resource.
     * @param owner The address of the owner of this resource.
     * @param groveURI The Grove URI of the resource (e.g., "lens://...").
     */
    event ResourceRegistered(bytes32 indexed resourceId, address indexed owner, string groveURI);

    /**
     * @dev Emitted when modification permission is granted to a user for a resource.
     * @param resourceId The unique identifier for the resource.
     * @param user The address of the user granted permission.
     */
    event PermissionGranted(bytes32 indexed resourceId, address indexed user);

    /**
     * @dev Emitted when modification permission is revoked from a user for a resource.
     * @param resourceId The unique identifier for the resource.
     * @param user The address of the user whose permission is revoked.
     */
    event PermissionRevoked(bytes32 indexed resourceId, address indexed user);

    /**
     * @dev Emitted when the ownership of a resource is transferred.
     * @param resourceId The unique identifier for the resource.
     * @param oldOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event ResourceOwnershipTransferred(bytes32 indexed resourceId, address indexed oldOwner, address indexed newOwner);

    /**
     * @dev Emitted when the Grove URI record for a resource is updated.
     * @param resourceId The unique identifier for the resource.
     * @param newGroveURI The new Grove URI.
     */
    event ResourceURIRecordUpdated(bytes32 indexed resourceId, string newGroveURI);
    
    /**
     * @dev Emitted when a resource's record is deleted from the oracle.
     * @param resourceId The unique identifier for the resource.
     */
    event ResourceRecordDeleted(bytes32 indexed resourceId);

    modifier onlyContractOwner() {
        if (msg.sender != contractOwner) revert GroveACLOracle__NotContractOwner();
        _;
    }

    modifier onlyResourceOwner(bytes32 resourceId) {
        if (msg.sender != ownerOfResource[resourceId]) revert GroveACLOracle__NotResourceOwner();
        _;
    }

    /**
     * @dev Sets the contract deployer as the initial owner.
     */
    constructor() {
        contractOwner = msg.sender;
    }

    /**
     * @notice Registers a new Grove resource with this oracle.
     * @dev Typically called by an application backend or by the user after uploading to Grove.
     * The `resourceOwner` is the address that will have control over this resource's permissions.
     * @param groveURI The full Grove URI of the resource (e.g., "lens://Qm...").
     * @param resourceOwner The address designated as the owner of this resource.
     * @return resourceId The generated unique identifier for the resource.
     */
    function registerResource(string calldata groveURI, address resourceOwner) external returns (bytes32 resourceId) {
        if (bytes(groveURI).length == 0) revert GroveACLOracle__GroveURICannotBeEmpty();
        if (resourceOwner == address(0)) revert GroveACLOracle__ResourceOwnerCannotBeZeroAddress();

        resourceId = keccak256(abi.encodePacked(groveURI));
        
        if (ownerOfResource[resourceId] != address(0)) revert GroveACLOracle__ResourceAlreadyRegistered();

        ownerOfResource[resourceId] = resourceOwner;
        resourceGroveURIs[resourceId] = groveURI;

        emit ResourceRegistered(resourceId, resourceOwner, groveURI);
        return resourceId;
    }

    /**
     * @notice Grants general modification (edit/delete) permission for a resource to a user.
     * @dev Only the current owner of the resource can call this function.
     * @param resourceId The identifier of the resource.
     * @param user The address of the user to grant permission to.
     */
    function grantModificationPermission(bytes32 resourceId, address user) external onlyResourceOwner(resourceId) {
        if (user == address(0)) revert GroveACLOracle__UserCannotBeZeroAddress();
        authorizedUsersForModification[resourceId][user] = true;
        emit PermissionGranted(resourceId, user);
    }

    /**
     * @notice Revokes general modification (edit/delete) permission for a resource from a user.
     * @dev Only the current owner of the resource can call this function.
     * @param resourceId The identifier of the resource.
     * @param user The address of the user to revoke permission from.
     */
    function revokeModificationPermission(bytes32 resourceId, address user) external onlyResourceOwner(resourceId) {
        if (user == address(0)) revert GroveACLOracle__UserCannotBeZeroAddress();
        authorizedUsersForModification[resourceId][user] = false;
        emit PermissionRevoked(resourceId, user);
    }

    /**
     * @notice Transfers ownership of a registered resource to a new owner.
     * @dev Only the current owner of the resource can call this function.
     * The new owner will have full control over the resource's permissions.
     * Any previously granted permissions to other users remain intact unless explicitly revoked.
     * @param resourceId The identifier of the resource.
     * @param newOwner The address of the new owner.
     */
    function transferResourceOwnership(bytes32 resourceId, address newOwner) external onlyResourceOwner(resourceId) {
        if (newOwner == address(0)) revert GroveACLOracle__NewOwnerCannotBeZeroAddress();
        address oldOwner = ownerOfResource[resourceId];
        ownerOfResource[resourceId] = newOwner;
        emit ResourceOwnershipTransferred(resourceId, oldOwner, newOwner);
    }
    
    /**
     * @notice Updates the stored Grove URI for a resource.
     * @dev This is for record-keeping within the oracle. It does NOT change the resourceId.
     * Only the resource owner can call this.
     * @param resourceId The identifier of the resource.
     * @param newGroveURI The new Grove URI string.
     */
    function updateResourceURIRecord(bytes32 resourceId, string calldata newGroveURI) external onlyResourceOwner(resourceId) {
        if (bytes(newGroveURI).length == 0) revert GroveACLOracle__GroveURICannotBeEmpty();
        resourceGroveURIs[resourceId] = newGroveURI;
        emit ResourceURIRecordUpdated(resourceId, newGroveURI);
    }

    /**
     * @notice Deletes the record of a resource from this oracle.
     * @dev This should be called after the resource is confirmed to be deleted from Grove.
     * It removes ownership and permission data associated with the `resourceId`.
     * Only the current owner of the resource can call this function.
     * @param resourceId The identifier of the resource to delete.
     */
    function deleteResourceRecord(bytes32 resourceId) external onlyResourceOwner(resourceId) {
        address oldOwner = ownerOfResource[resourceId];
        // Consider if authorizedUsersForModification for this resourceId should be cleared explicitly
        // For gas efficiency, often it's left, as future lookups for this resourceId won't happen.
        // However, for complete cleanup:
        // delete authorizedUsersForModification[resourceId]; // This would require a loop if it's a nested mapping of users.
        // Simpler to just delete the owner and URI record.
        delete ownerOfResource[resourceId];
        delete resourceGroveURIs[resourceId];
        // Note: authorizedUsersForModification[resourceId][anyUser] will default to false.
        // If a more complex user management was in authorizedUsersForModification (e.g., an array of users),
        // it would need explicit deletion.

        emit ResourceRecordDeleted(resourceId);
    }

    /**
     * @notice Checks if a caller is authorized to perform an action on a resource.
     * @dev This is the primary function Grove's ACL validator mechanism will call.
     * Authorization is granted if the caller is the resource owner OR
     * if the caller has been explicitly granted modification permission.
     * This function can be extended for more granular, action-specific checks.
     * @param resourceId The identifier of the Grove resource.
     * @param caller The address attempting the action (verified by Grove via user's signature).
     * @param actionSelector A bytes4 value representing the action (e.g., ACTION_EDIT, ACTION_DELETE).
     *                       Currently, ACTION_EDIT and ACTION_DELETE grant same level of access.
     * @return bool True if the caller is authorized, false otherwise.
     */
    function isAuthorized(bytes32 resourceId, address caller, bytes4 actionSelector) external view returns (bool) {
        if (ownerOfResource[resourceId] == address(0)) {
            return false; // Resource not registered
        }
        if (caller == ownerOfResource[resourceId]) {
            return true; // Owner is always authorized
        }
        if (authorizedUsersForModification[resourceId][caller]) {
             // For now, ACTION_EDIT and ACTION_DELETE are covered by general modification permission.
             // This can be made more granular if needed:
             // if (actionSelector == ACTION_EDIT || actionSelector == ACTION_DELETE) return true;
            return true; 
        }
        // Add more complex/granular logic based on actionSelector if needed in the future
        return false;
    }

    /**
     * @notice Retrieves the Grove URI for a given resourceId.
     * @dev Useful for frontends or services to look up the original URI.
     * @param resourceId The identifier of the resource.
     * @return string The Grove URI associated with the resourceId.
     */
    function getResourceGroveURI(bytes32 resourceId) external view returns (string memory) {
        return resourceGroveURIs[resourceId];
    }

    /**
     * @notice Allows the contract owner to change the contract owner address.
     * @param newContractOwner The address of the new contract owner.
     */
    function transferContractOwnership(address newContractOwner) external onlyContractOwner {
        if (newContractOwner == address(0)) revert GroveACLOracle__NewContractOwnerCannotBeZeroAddress();
        contractOwner = newContractOwner;
    }

    // Fallback function to receive Ether.
    receive() external payable {
        revert GroveACLOracle__NoEtherAccepted();
    }

    // Fallback function for arbitrary calls.
    fallback() external payable {
        revert GroveACLOracle__NoEtherAccepted();
    }
} 