// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IResonancePairView
 * @notice Minimal interface for resonance contracts in this network.
 * Any contract that can be part of a cluster must implement this.
 */
interface IResonancePairView {
    function getResonance()
        external
        view
        returns (
            uint32 score,
            uint32 confidence,
            uint64 updatedAt,
            bytes32 contextHash,
            uint256 updates
        );
}

/**
 * @title ResonanceCluster
 * @notice A "resonance-of-resonances" contract representing a group of
 *         2 or more resonance contracts interacting together.
 *
 * - Members: an array of resonance contract addresses.
 * - Cluster state: aggregate score + confidence + metadata.
 * - Created and owned by ResonanceClusterFactory.
 */
contract ResonanceCluster {
    // Factory that created this cluster
    address public immutable factory;

    // Member resonance contracts (pair-level or others)
    address[] public members;

    struct ClusterState {
        uint32 score;        // aggregated cluster score (0–1000)
        uint32 confidence;   // aggregated cluster confidence (0–1000)
        uint64 updatedAt;    // unix timestamp
        bytes32 contextHash; // optional metadata / off-chain reference
        uint256 updates;     // how many times this cluster has been updated
    }

    ClusterState private _state;

    event ClusterUpdated(
        uint32 score,
        uint32 confidence,
        uint64 updatedAt,
        bytes32 contextHash,
        uint256 updates
    );

    modifier onlyFactory() {
        require(msg.sender == factory, "CLUSTER: not factory");
        _;
    }

    constructor(address factory_, address[] memory members_) {
        require(factory_ != address(0), "CLUSTER: factory zero");
        require(members_.length >= 2, "CLUSTER: need >= 2 members");

        factory = factory_;
        members = members_;
    }

    // ------------------------------------------------------------
    // Core: update cluster resonance (called by factory or governance)
    // ------------------------------------------------------------

    /**
     * @notice Set cluster resonance explicitly (e.g. via off-chain eval or governance).
     */
    function setClusterResonance(
        uint32 score,
        uint32 confidence,
        bytes32 contextHash
    ) external onlyFactory {
        require(score <= 1000, "CLUSTER: score > 1.000");
        require(confidence <= 1000, "CLUSTER: confidence > 1.000");

        _state.score = score;
        _state.confidence = confidence;
        _state.updatedAt = uint64(block.timestamp);
        _state.contextHash = contextHash;
        _state.updates += 1;

        emit ClusterUpdated(
            _state.score,
            _state.confidence,
            _state.updatedAt,
            _state.contextHash,
            _state.updates
        );
    }

    /**
     * @notice Compute a fresh aggregate score/confidence
     *         from all member resonance contracts (simple average).
     *
     * This does NOT change state; it's a pure read across the network.
     */
    function computeAggregateFromMembers()
        external
        view
        returns (
            uint32 avgScore,
            uint32 avgConfidence,
            uint256 count
        )
    {
        uint256 len = members.length;
        require(len >= 2, "CLUSTER: invalid member count");

        uint256 sumScore = 0;
        uint256 sumConfidence = 0;

        for (uint256 i = 0; i < len; i++) {
            (
                uint32 s,
                uint32 c,
                ,
                ,
                
            ) = IResonancePairView(members[i]).getResonance();

            sumScore += s;
            sumConfidence += c;
        }

        count = len;
        avgScore = uint32(sumScore / count);
        avgConfidence = uint32(sumConfidence / count);
    }

    // ------------------------------------------------------------
    // Views
    // ------------------------------------------------------------

    function getClusterState()
        external
        view
        returns (
            uint32 score,
            uint32 confidence,
            uint64 updatedAt,
            bytes32 contextHash,
            uint256 updates
        )
    {
        ClusterState memory s = _state;
        return (s.score, s.confidence, s.updatedAt, s.contextHash, s.updates);
    }

    function getMembers() external view returns (address[] memory) {
        return members;
    }

    function memberCount() external view returns (uint256) {
        return members.length;
    }
}

/**
 * @title ResonanceClusterFactory
 * @notice When two or more resonance contracts "interact", this factory creates
 *         (or reuses) a ResonanceCluster contract representing that group.
 *
 * - Groups are unordered: same set of members = same cluster address.
 * - Cluster key = keccak256(sorted member addresses).
 */
contract ResonanceClusterFactory {
    address public owner;

    // clusterKey => cluster contract address
    mapping(bytes32 => address) public clusterByKey;
    address[] public allClusters;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ClusterCreated(address indexed cluster, bytes32 indexed clusterKey);

    modifier onlyOwner() {
        require(msg.sender == owner, "FACTORY: not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // ------------------------------------------------------------
    // Admin
    // ------------------------------------------------------------

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "FACTORY: newOwner zero");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // ------------------------------------------------------------
    // Core: "when two or more resonance contracts interact"
    // ------------------------------------------------------------

    /**
     * @notice Get or create a cluster for a group of resonance contracts.
     *
     * Interpretation of "interact":
     * - You call this when a set of resonance contracts participate in
     *   some shared operation / domain.
     *
     * Behavior:
     * - Requires at least 2 member addresses.
     * - Sorts addresses and computes an unordered clusterKey.
     * - If cluster exists, returns it.
     * - If not, deploys a new ResonanceCluster and returns it.
     */
    function getOrCreateCluster(address[] memory members)
        external
        returns (address cluster)
    {
        uint256 len = members.length;
        require(len >= 2, "FACTORY: need >= 2 members");

        // Basic validation
        for (uint256 i = 0; i < len; i++) {
            require(members[i] != address(0), "FACTORY: member zero");
        }

        // Normalize the list (sort addresses) so the group is unordered.
        address[] memory sorted = _sorted(members);
        bytes32 key = _clusterKey(sorted);

        cluster = clusterByKey[key];
        if (cluster == address(0)) {
            // First time this exact group interacts → create a new cluster
            cluster = address(new ResonanceCluster(address(this), sorted));
            clusterByKey[key] = cluster;
            allClusters.push(cluster);

            emit ClusterCreated(cluster, key);
        }

        return cluster;
    }

    // ------------------------------------------------------------
    // Helpers: sorting + key
    // ------------------------------------------------------------

    /**
     * @dev Simple in-memory insertion sort for small arrays.
     *      This is fine because group sizes are expected to be small.
     */
    function _sorted(address[] memory arr) internal pure returns (address[] memory) {
        uint256 len = arr.length;
        for (uint256 i = 1; i < len; i++) {
            address key = arr[i];
            uint256 j = i;
            while (j > 0 && arr[j - 1] > key) {
                arr[j] = arr[j - 1];
                j--;
            }
            arr[j] = key;
        }
        return arr;
    }

    function _clusterKey(address[] memory sortedMembers) internal pure returns (bytes32) {
        // hash of the concatenation of the sorted addresses
        return keccak256(abi.encodePacked(sortedMembers));
    }

    // ------------------------------------------------------------
    // Views
    // ------------------------------------------------------------

    function totalClusters() external view returns (uint256) {
        return allClusters.length;
    }
}
