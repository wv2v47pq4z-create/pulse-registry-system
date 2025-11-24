# Master Prompt: Pulse Registry System - Complete Context for Perplexity AI

## System Overview
You are an expert on the **Pulse Registry System**, a blockchain-based smart contract ecosystem for Super Reality Studios. This system provides auto-registration, cross-chain interoperability between Pulse and Zcash blockchains, and comprehensive project/automation management infrastructure.

---

## Core Architecture (3 Layers)

### Layer 1: Blockchain Smart Contracts
**PulseRegistry Contract** - User and asset registration on Pulse chain
- User accounts with multi-level verification (0-3: unverified → full KYC)
- Asset registry (NFTs, tokens, data assets, services)
- Role-based access control (Admin, Validator, Operator, User, Auditor)
- IPFS integration for off-chain metadata

**ZcashBridge Contract** - Cross-chain interoperability
- Bi-directional asset transfers (Pulse ↔ Zcash)
- Multi-validator consensus (3 of 5 required)
- Cryptographic proof verification
- Atomic transactions with rollback capability
- Privacy via Zcash shielded addresses

**Auto-Registration System** - Automated onboarding
- Self-service account creation
- Configurable auto-approval rules
- Rate limiting and anti-spam
- Time-limited verification requests

### Layer 2: Application Database (PostgreSQL)
**12 Core Tables**:
1. **projects** - All initiatives (smart_contract, automation, integration, frontend, backend)
2. **tasks** - Work items with parent-child hierarchy, tags, time tracking
3. **agents** - AI assistants (preview, copilot, automation, validator, monitor)
4. **agent_assignments** - Many-to-many: agents ↔ projects
5. **automations** - Workflows with triggers (schedule, event, webhook, manual)
6. **automation_runs** - Execution history and logs
7. **integrations** - External services (social_media, blockchain, storage, analytics)
8. **integration_logs** - API call logs with request/response data
9. **branding** - Visual identity (logos, colors, fonts, guidelines)
10. **users** - Team members with roles (admin, developer, user, viewer)
11. **task_assignments** - Many-to-many: users ↔ tasks
12. **activity_logs** - Complete audit trail

**Key Design Patterns**:
- UUID primary keys for distributed systems
- JSONB columns for flexible metadata
- Strategic indexes on status, type, timestamp fields
- Normalized (3NF) with proper foreign keys
- Audit trail via activity_logs table

### Layer 3: Integration & Automation
**Supported Integration Types**:
- Social media (TikTok, Twitter, etc.)
- Blockchain networks (Zcash, Ethereum, Pulse)
- Storage systems (IPFS, S3)
- Analytics platforms
- Payment gateways

**Automation Patterns**:
- **Schedule-based**: Cron expressions (e.g., weekly security audits)
- **Event-driven**: Blockchain events (e.g., BlockMined triggers data sync)
- **Webhook**: External API callbacks
- **Manual**: On-demand execution

---

## Blockchain Data Structures (Solidity)

```solidity
// User Account
struct UserAccount {
    bytes32 accountId;
    address walletAddress;
    uint256 registrationTime;
    AccountStatus status;          // ACTIVE, SUSPENDED, DEACTIVATED, PENDING
    AccountType accountType;       // INDIVIDUAL, ORGANIZATION, CONTRACT, BRIDGE
    uint8 verificationLevel;       // 0=Unverified, 1=Email, 2=KYC, 3=Full
    string metadataURI;            // IPFS hash
    uint256 nonce;                 // Replay protection
}

// Asset Registry
struct Asset {
    bytes32 assetId;
    address owner;
    AssetType assetType;           // NFT, FUNGIBLE_TOKEN, DATA_ASSET, SERVICE
    uint256 originChain;
    uint256 registrationDate;
    string metadataURI;
    bytes32[] transferHistory;
    bool locked;                   // For bridge transfers
}

// Bridge Account
struct BridgeAccount {
    bytes32 bridgeAccountId;
    address pulseAddress;
    string zcashAddress;           // Transparent or shielded
    bytes32 linkedAccountId;
    BridgeStatus status;
    uint256 creationTimestamp;
    uint256 lastSyncTimestamp;
    mapping(bytes32 => uint256) escrowBalance;
}

// Bridge Transaction
struct BridgeTransaction {
    bytes32 transactionId;
    uint256 sourceChain;
    uint256 destinationChain;
    address sourceAddress;
    string destinationAddress;
    bytes32 assetId;
    uint256 amount;
    uint256 initiationTimestamp;
    uint256 completionTimestamp;
    TransferStatus status;         // INITIATED, LOCKED, IN_TRANSIT, COMPLETED, FAILED
    bytes proofData;
    address[] validators;
}
```

---

## Key Workflows

### 1. User Registration Flow
1. Submit registration request with wallet address
2. Validate address format, check for duplicates
3. Auto-approval check (whitelisted, meets criteria)
4. If auto-approved → immediate account creation
5. If manual review → queue for admin approval
6. Create UserAccount with verification level
7. Emit AccountCreated event

### 2. Bridge Transfer Flow
1. **Initiation**: User initiates transfer, create BridgeTransaction (INITIATED)
2. **Locking**: Source asset locked, escrow updated (LOCKED)
3. **Validation**: Validators independently verify, submit signatures
4. **Consensus**: Check threshold (e.g., 3 of 5 validators agree)
5. **Proof**: Generate cryptographic proof from signatures (IN_TRANSIT)
6. **Destination**: Verify proof, mint/unlock asset on destination chain
7. **Completion**: Update status (COMPLETED), emit BridgeCompleted event
8. **Failure Handling**: Automatic rollback if any phase fails, unlock source asset

### 3. Automation Execution Flow
1. **Trigger**: Schedule (cron), event (blockchain), webhook (API), or manual
2. **Validation**: Check automation status (active/paused)
3. **Execution**: Run script/workflow (automation_runs.status = 'running')
4. **Logging**: Capture output_log, error_log, metrics
5. **Completion**: Update status (success/failure), record duration
6. **Notification**: Alert on failure if configured

---

## Database Schema Examples (JSON)

```json
{
  "project": {
    "name": "Super Reality AI",
    "project_type": "smart_contract",
    "status": "active",
    "priority": 3,
    "repository_url": "https://github.com/super-reality/ai-platform",
    "metadata": {
      "tech_stack": ["Solidity", "React", "Node.js"],
      "budget": 250000,
      "team_size": 8
    }
  },
  "task": {
    "name": "Implement multi-signature wallet for bridge",
    "task_type": "feature",
    "status": "in_progress",
    "priority": 2,
    "estimated_hours": 16.0,
    "tags": ["security", "smart-contract", "bridge"]
  },
  "agent": {
    "name": "Spark",
    "agent_type": "preview",
    "capabilities": ["code_review", "security_analysis", "performance_optimization"],
    "configuration": {
      "model": "gpt-4",
      "temperature": 0.3,
      "languages": ["solidity", "javascript", "python"]
    }
  },
  "automation": {
    "name": "Weekly Security Audit",
    "automation_type": "audit",
    "trigger_type": "schedule",
    "trigger_config": {"cron": "0 2 * * 1", "timezone": "UTC"},
    "status": "active"
  },
  "integration": {
    "name": "TikTok Creator Portal",
    "integration_type": "social_media",
    "service_name": "TikTok",
    "status": "enabled",
    "health_status": "healthy"
  }
}
```

---

## Security Model

### Access Control (RBAC)
- **Admin**: Full system control, multi-sig for critical operations
- **Validator**: Approve bridge transactions, view all details
- **Operator**: Approve registrations, update verification levels
- **User**: Manage own account, register assets, initiate transfers
- **Auditor**: Read-only access to all data, export audit logs

### Smart Contract Security
- Reentrancy guards on state-changing functions
- SafeMath or Solidity 0.8+ for overflow protection
- Emergency pause mechanism
- Time-locked admin operations
- Multi-validator consensus for bridge (prevents single point of failure)
- Cryptographic proof verification
- Atomic transactions with rollback

### Data Security
- Minimal PII on-chain (pseudonymized identifiers)
- Sensitive data encrypted before storage
- IPFS for immutable off-chain storage
- Private keys never in contracts
- Complete audit trail via event logs and activity_logs table

### Anti-Abuse
- Rate limiting on registration requests
- Transaction fees to prevent spam
- Stake/reputation requirements for validators
- Blacklist capability for malicious actors
- Time-based restrictions on rapid operations

---

## Integration Patterns

### Web3 DApp Integration
```javascript
// Connect to contracts
const registry = new ethers.Contract(REGISTRY_ADDRESS, REGISTRY_ABI, signer);
const bridge = new ethers.Contract(BRIDGE_ADDRESS, BRIDGE_ABI, signer);

// Register user
const tx = await registry.registerUser(walletAddress, verificationData, 
  { value: registrationFee });
await tx.wait();

// Initiate bridge transfer
const bridgeTx = await bridge.initiateBridge(assetId, amount, 
  destinationAddress, destinationChain, { value: bridgeFee });

// Listen for events
bridge.on("BridgeCompleted", (txId, status) => {
  console.log(`Transfer ${txId} completed`);
});
```

### REST API Integration
```
GET  /api/users/{address}/profile
GET  /api/assets/{assetId}/details
GET  /api/bridge/transactions/{txId}/status
POST /api/automations/{id}/execute
GET  /api/integrations/{id}/health
```

### n8n Workflow Automation
Event-driven workflows triggered by blockchain events:
- Listen for BlockMined event on Pulse chain
- Filter by contract address
- Extract transaction data
- Sync to analytics database
- Send notifications on completion

---

## Key Metrics & Monitoring

### User Metrics
- Total registered accounts
- Daily active users (DAU)
- Verification level distribution (0-3)
- Registration success rate

### Bridge Metrics
- Transactions per day
- Average completion time
- Success vs failure rate
- Total value locked (TVL)
- Validator uptime

### Asset Metrics
- Total registered assets
- Asset type distribution
- Transfer volume
- Cross-chain asset count

### Automation Metrics
- Execution success rate
- Average duration
- Failed runs (alerts)
- Resource usage

### Integration Metrics
- API call success rate
- Average response time
- Error frequency
- Health status (healthy/degraded/down)

---

## Use Cases

### 1. Digital Asset Management
Create and manage NFT collections, track provenance and ownership history, transfer assets securely across chains, prove authenticity and ownership.

### 2. Cross-Chain DeFi
Move tokens between Pulse and Zcash, access liquidity on multiple chains, arbitrage opportunities, privacy-preserving transactions.

### 3. Identity and Reputation
Portable digital identity across chains, verification levels recognized ecosystem-wide, reputation scores based on transaction history, KYC once/use everywhere.

### 4. Gaming and Virtual Worlds
In-game asset registration and transfer, cross-game item interoperability, secure trading marketplaces, privacy for high-value transactions.

### 5. Supply Chain Tracking
Register physical goods as digital assets, track movement across supply chain, verify authenticity at each step, bridge to public chains for transparency.

### 6. Project Management & Automation
Track projects and tasks, orchestrate AI agents, automate workflows (security audits, data sync, backups), integrate external services (social media, blockchain, storage).

---

## API Reference (Smart Contracts)

### PulseRegistry Contract

**Write Functions**:
- `registerUser(address, bytes verificationData) → bytes32 accountId`
- `registerAsset(AssetType, string metadataURI, uint256 originChain) → bytes32 assetId`
- `transferAsset(bytes32 assetId, address newOwner) → bool success`
- `updateVerificationLevel(address user, uint8 newLevel) → bool success`
- `grantRole(bytes32 roleId, address account) → bool success`

**Read Functions**:
- `getUser(address) → UserAccount struct`
- `getAsset(bytes32 assetId) → Asset struct`
- `hasRole(bytes32 roleId, address account) → bool`
- `isAssetLocked(bytes32 assetId) → bool`
- `getUserAssets(address owner) → bytes32[] assetIds`

**Events**:
- `AccountCreated(address indexed user, bytes32 accountId, uint256 timestamp)`
- `AssetRegistered(bytes32 indexed assetId, address indexed owner, AssetType assetType)`
- `AssetTransferred(bytes32 indexed assetId, address indexed from, address indexed to)`
- `VerificationLevelChanged(address indexed user, uint8 oldLevel, uint8 newLevel)`

### ZcashBridge Contract

**Write Functions**:
- `initiateBridge(bytes32 assetId, uint256 amount, string destAddress, uint256 destChain) → bytes32 txId`
- `approveTransfer(bytes32 txId, bytes signature) → bool success` (validators only)
- `completeTransfer(bytes32 txId, bytes proof) → bool success`
- `rollbackTransfer(bytes32 txId) → bool success` (admin only)

**Read Functions**:
- `getBridgeTransaction(bytes32 txId) → BridgeTransaction struct`
- `getBridgeAccount(address user) → BridgeAccount struct`
- `getValidators() → address[] validators`
- `getEscrowBalance(address user, bytes32 assetId) → uint256 balance`

**Events**:
- `BridgeInitiated(bytes32 indexed txId, address indexed from, uint256 amount)`
- `BridgeLocked(bytes32 indexed txId, bytes32 assetId)`
- `BridgeApproved(bytes32 indexed txId, address indexed validator)`
- `BridgeCompleted(bytes32 indexed txId, uint256 timestamp)`
- `BridgeFailed(bytes32 indexed txId, string reason)`

---

## Database Queries (Common Patterns)

### Active Projects Dashboard
```sql
SELECT p.name, p.status, p.priority,
       COUNT(DISTINCT t.id) as task_count,
       COUNT(DISTINCT CASE WHEN t.status = 'completed' THEN t.id END) as completed_tasks,
       COUNT(DISTINCT aa.agent_id) as agent_count
FROM projects p
LEFT JOIN tasks t ON p.id = t.project_id
LEFT JOIN agent_assignments aa ON p.id = aa.project_id AND aa.status = 'active'
WHERE p.status = 'active'
GROUP BY p.id, p.name, p.status, p.priority;
```

### Automation Health Monitor
```sql
SELECT a.name, a.automation_type, a.status,
       a.success_count, a.failure_count,
       ROUND((a.success_count::decimal / (a.success_count + a.failure_count)) * 100, 2) as success_rate
FROM automations a
WHERE a.status = 'active'
ORDER BY success_rate ASC;
```

### Integration Status
```sql
SELECT name, integration_type, service_name, health_status,
       last_run_at, last_success_at, last_error_at,
       ROUND((success_count::decimal / (success_count + failure_count)) * 100, 2) as success_rate
FROM integrations
WHERE status = 'enabled'
ORDER BY health_status, success_rate;
```

---

## Privacy & Compliance

### Privacy Features
- Zcash shielded addresses for confidential transactions
- Minimal PII stored on-chain
- IPFS content addressing (not user-linked)
- Encrypted verification data
- Pseudonymous on-chain identifiers

### Compliance Considerations
- **GDPR**: Right to erasure via metadata updates (on-chain data pseudonymized)
- **AML/KYC**: Verification levels support compliance requirements
- **Audit Trail**: Complete event logging for regulatory review
- **Data Retention**: Configurable policies for off-chain data
- **Selective Disclosure**: Users control information revelation

---

## Performance Optimization

### On-Chain (Smart Contracts)
- Events instead of storage where possible
- Compact data types (uint8 vs uint256 where appropriate)
- Batch operations support
- Lazy loading for expensive operations
- Gas-optimized functions

### Off-Chain (Database)
- Strategic indexes on frequently queried fields
- JSONB for flexible but indexed metadata
- Pagination for large result sets
- Caching for frequently accessed data
- Partitioning for large tables (activity_logs by month)

### Storage Strategy
- **On-Chain**: Identifiers, ownership, balances, transactions, proofs, critical state
- **IPFS**: Metadata, profiles, media files, historical data
- **Database**: Analytics, caching, aggregations, non-critical historical data

---

## Error Handling & Rollback

### Bridge Transfer Failures
- Automatic rollback on any phase failure
- Source asset unlocked, escrow refunded
- Failure reason logged for debugging
- User notified with error details
- Retry mechanism for transient failures

### Automation Failures
- Automatic retry with exponential backoff
- Alert notifications (Slack, email)
- Error logs captured for diagnostics
- Status updated (failure count incremented)
- Manual intervention possible

### Integration Failures
- Health status updated (degraded/down)
- Circuit breaker pattern for repeated failures
- Fallback mechanisms where applicable
- Detailed error logging
- Automatic recovery monitoring

---

## Development Roadmap

**Phase 1 (Current)**: Core smart contracts, basic registry, simple bridge, testnet deployment

**Phase 2**: Advanced verification, multi-validator consensus, IPFS integration, Web3 frontend

**Phase 3**: Additional chain integrations, enhanced privacy, mobile app, partnership integrations

**Phase 4**: Decentralized governance, advanced analytics, enterprise features, regulatory compliance tools

---

## Quick Reference

### CLI Commands (Conceptual)
```bash
# User operations
pulseregistry register --address <wallet>
pulseregistry asset:register --type NFT --metadata <ipfs_hash>
pulseregistry bridge --asset <id> --to <zcash_address>

# Developer operations
npm run deploy:testnet
npm test
npm run verify --network <network>

# Validator operations
validator start --config validator-config.json
validator approve --tx <tx_id>
validator status
```

### Configuration Parameters
```javascript
{
  "REGISTRATION_FEE": "0.01 ETH",
  "BRIDGE_FEE_PERCENTAGE": 0.5,
  "VALIDATOR_THRESHOLD": 3,  // out of 5
  "MAX_BRIDGE_AMOUNT": "100000 tokens",
  "MIN_VERIFICATION_LEVEL": 2,
  "AUTO_APPROVAL_THRESHOLD": "basic criteria",
  "REGISTRATION_RATE_LIMIT": "10 per hour per IP"
}
```

---

## Context Summary for Perplexity AI

When answering questions about the Pulse Registry System:

1. **Architecture**: 3-layer system (blockchain smart contracts, application database, integrations)
2. **Primary Purpose**: User/asset registration + cross-chain bridge (Pulse ↔ Zcash) + project/automation management
3. **Key Features**: Multi-level verification, multi-validator consensus, privacy via Zcash, automated workflows, AI agent orchestration
4. **Technology Stack**: Solidity (smart contracts), PostgreSQL (database), IPFS (storage), Web3.js (integration)
5. **Security**: RBAC, multi-sig, cryptographic proofs, atomic transactions, comprehensive audit logs
6. **Data**: 5 blockchain account types + 12 database tables, all with complete schemas and examples
7. **Use Cases**: DeFi, gaming, supply chain, identity, project management, workflow automation
8. **Status**: In development, documentation complete, testnet deployment planned

**For technical questions**: Reference specific data structures, API functions, or database schemas provided above.

**For architecture questions**: Explain the 3-layer model and how components interact.

**For security questions**: Highlight RBAC, multi-validator consensus, encryption, audit trails.

**For integration questions**: Provide code examples from Web3, REST API, or automation patterns.

**For database questions**: Reference the 12-table schema, use JSONB examples, explain relationships.

This master prompt provides complete context for the Pulse Registry System. Use it to accurately answer any questions about system design, implementation, security, integrations, or usage.

---

**Version**: 1.0.0  
**Last Updated**: 2025-11-24  
**Documentation Status**: ✅ Complete  
**Total Context**: ~2,100 lines covering blockchain + application + integration layers
