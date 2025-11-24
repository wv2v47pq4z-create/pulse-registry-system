# Database Schema - Pulse Registry System & Automation Registry

## Overview
This document defines a normalized database schema for managing projects, tasks, agents, automations, integrations, and branding for the Pulse Registry System and related automation infrastructure.

---

## Entity Relationship Diagram

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   Projects   │──────<│    Tasks     │       │    Agents    │
│              │  1:N  │              │       │              │
└──────┬───────┘       └──────┬───────┘       └──────┬───────┘
       │                      │                       │
       │ 1:N                  │ N:M                   │ N:M
       │                      │                       │
       ▼                      ▼                       ▼
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│ Automations  │       │TaskAssignments│      │AgentAssignments│
│              │       │              │       │              │
└──────┬───────┘       └──────────────┘       └──────────────┘
       │
       │ 1:N
       │
       ▼
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│AutomationRuns│       │ Integrations │       │   Branding   │
│              │       │              │       │              │
└──────────────┘       └──────┬───────┘       └──────┬───────┘
                              │                       │
                              │ 1:N                   │ 1:1
                              │                       │
                              ▼                       ▼
                       ┌──────────────┐       ┌──────────────┐
                       │IntegrationLog│       │  Projects    │
                       │              │       │              │
                       └──────────────┘       └──────────────┘
```

---

## Core Entities

### 1. Projects Table

**Purpose**: Central registry of all projects in the ecosystem

**Schema**:
```sql
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    project_type VARCHAR(50) NOT NULL, -- 'smart_contract', 'automation', 'integration', 'frontend', 'backend'
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'paused', 'completed', 'archived'
    priority INTEGER DEFAULT 0, -- 0=low, 1=medium, 2=high, 3=critical
    owner_id UUID REFERENCES users(id),
    repository_url VARCHAR(500),
    documentation_url VARCHAR(500),
    branding_id UUID REFERENCES branding(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    metadata JSONB -- Flexible storage for project-specific data
);

CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_type ON projects(project_type);
CREATE INDEX idx_projects_owner ON projects(owner_id);
```

**Attributes**:
- `id`: Unique identifier (UUID)
- `name`: Project name (e.g., "Pulse Registry System", "Super Reality AI")
- `description`: Detailed project description
- `project_type`: Category of project
- `status`: Current project status
- `priority`: Importance level
- `owner_id`: Project owner/creator reference
- `repository_url`: Git repository location
- `documentation_url`: Link to documentation
- `branding_id`: Associated branding reference
- `created_at`: Creation timestamp
- `updated_at`: Last modification timestamp
- `completed_at`: Completion timestamp (if applicable)
- `metadata`: Additional flexible data (JSONB)

---

### 2. Tasks Table

**Purpose**: Individual work items and action items within projects

**Schema**:
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    parent_task_id UUID REFERENCES tasks(id), -- For subtasks
    name VARCHAR(500) NOT NULL,
    description TEXT,
    task_type VARCHAR(50) NOT NULL, -- 'feature', 'bug', 'audit', 'documentation', 'deployment'
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'in_progress', 'review', 'completed', 'blocked'
    priority INTEGER DEFAULT 0,
    assignee_id UUID REFERENCES users(id),
    estimated_hours DECIMAL(5,2),
    actual_hours DECIMAL(5,2),
    due_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    tags TEXT[], -- Array of tags for categorization
    metadata JSONB
);

CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX idx_tasks_parent ON tasks(parent_task_id);
CREATE INDEX idx_tasks_tags ON tasks USING GIN(tags);
```

**Attributes**:
- `id`: Unique identifier
- `project_id`: Associated project (foreign key)
- `parent_task_id`: Parent task for subtask hierarchy
- `name`: Task title
- `description`: Detailed task description
- `task_type`: Classification of task
- `status`: Current task status
- `priority`: Task importance
- `assignee_id`: Person responsible
- `estimated_hours`: Planned effort
- `actual_hours`: Actual time spent
- `due_date`: Target completion date
- `created_at`: Creation timestamp
- `updated_at`: Last modification
- `completed_at`: Completion timestamp
- `tags`: Labels for categorization
- `metadata`: Additional task data

---

### 3. Agents Table

**Purpose**: AI agents, bots, and automated assistants in the system

**Schema**:
```sql
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    agent_type VARCHAR(50) NOT NULL, -- 'preview', 'copilot', 'automation', 'validator', 'monitor'
    description TEXT,
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'inactive', 'maintenance'
    capabilities TEXT[], -- Array of what the agent can do
    configuration JSONB, -- Agent-specific settings
    api_endpoint VARCHAR(500),
    version VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP,
    metadata JSONB
);

CREATE INDEX idx_agents_type ON agents(agent_type);
CREATE INDEX idx_agents_status ON agents(status);
CREATE INDEX idx_agents_capabilities ON agents USING GIN(capabilities);
```

**Attributes**:
- `id`: Unique identifier
- `name`: Agent name (e.g., "Spark", "CodeQL Checker", "Bridge Validator")
- `agent_type`: Category of agent
- `description`: What the agent does
- `status`: Current operational status
- `capabilities`: Array of agent abilities
- `configuration`: Agent settings (JSONB)
- `api_endpoint`: How to communicate with agent
- `version`: Agent version number
- `created_at`: Creation timestamp
- `updated_at`: Last modification
- `last_active_at`: Last activity timestamp
- `metadata`: Additional agent data

---

### 4. Agent Assignments Table

**Purpose**: Junction table linking agents to projects

**Schema**:
```sql
CREATE TABLE agent_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    role VARCHAR(100), -- 'reviewer', 'validator', 'monitor', 'executor'
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'inactive'
    metadata JSONB,
    UNIQUE(agent_id, project_id, role)
);

CREATE INDEX idx_agent_assignments_agent ON agent_assignments(agent_id);
CREATE INDEX idx_agent_assignments_project ON agent_assignments(project_id);
```

---

### 5. Automations Table

**Purpose**: Automated scripts, workflows, and scheduled tasks

**Schema**:
```sql
CREATE TABLE automations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    automation_type VARCHAR(50) NOT NULL, -- 'audit', 'deployment', 'monitoring', 'data_sync', 'notification'
    description TEXT,
    script_name VARCHAR(255), -- Script filename or workflow ID
    script_path VARCHAR(500),
    related_project_id UUID REFERENCES projects(id),
    trigger_type VARCHAR(50), -- 'schedule', 'event', 'webhook', 'manual'
    trigger_config JSONB, -- Cron expression, event name, etc.
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'paused', 'disabled'
    last_run_at TIMESTAMP,
    next_run_at TIMESTAMP,
    run_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    metadata JSONB
);

CREATE INDEX idx_automations_type ON automations(automation_type);
CREATE INDEX idx_automations_project ON automations(related_project_id);
CREATE INDEX idx_automations_status ON automations(status);
CREATE INDEX idx_automations_next_run ON automations(next_run_at);
```

**Attributes**:
- `id`: Unique identifier
- `name`: Automation name
- `automation_type`: Category of automation
- `description`: What the automation does
- `script_name`: Script or workflow identifier
- `script_path`: Location of automation code
- `related_project_id`: Associated project
- `trigger_type`: How automation is triggered
- `trigger_config`: Trigger details (JSONB)
- `status`: Operational status
- `last_run_at`: Most recent execution
- `next_run_at`: Scheduled next execution
- `run_count`: Total executions
- `success_count`: Successful runs
- `failure_count`: Failed runs
- `created_at`: Creation timestamp
- `updated_at`: Last modification
- `created_by`: Creator reference
- `metadata`: Additional automation data

---

### 6. Automation Runs Table

**Purpose**: Historical log of automation executions

**Schema**:
```sql
CREATE TABLE automation_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    automation_id UUID NOT NULL REFERENCES automations(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL, -- 'running', 'success', 'failure', 'timeout'
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    duration_seconds INTEGER,
    trigger_source VARCHAR(100), -- What triggered this run
    output_log TEXT,
    error_log TEXT,
    metrics JSONB, -- Performance metrics, items processed, etc.
    metadata JSONB
);

CREATE INDEX idx_automation_runs_automation ON automation_runs(automation_id);
CREATE INDEX idx_automation_runs_status ON automation_runs(status);
CREATE INDEX idx_automation_runs_started ON automation_runs(started_at DESC);
```

---

### 7. Integrations Table

**Purpose**: External service connections and API integrations

**Schema**:
```sql
CREATE TABLE integrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    integration_type VARCHAR(100) NOT NULL, -- 'social_media', 'analytics', 'payment', 'blockchain', 'storage'
    service_name VARCHAR(100), -- 'TikTok', 'Twitter', 'Stripe', 'IPFS', 'Zcash'
    description TEXT,
    status VARCHAR(50) DEFAULT 'enabled', -- 'enabled', 'disabled', 'error', 'configuring'
    configuration JSONB, -- API keys, endpoints, settings (encrypted)
    health_status VARCHAR(50), -- 'healthy', 'degraded', 'down'
    last_run_at TIMESTAMP,
    last_success_at TIMESTAMP,
    last_error_at TIMESTAMP,
    last_error_message TEXT,
    run_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

CREATE INDEX idx_integrations_type ON integrations(integration_type);
CREATE INDEX idx_integrations_status ON integrations(status);
CREATE INDEX idx_integrations_health ON integrations(health_status);
```

**Attributes**:
- `id`: Unique identifier
- `name`: Integration display name
- `integration_type`: Category of integration
- `service_name`: External service name
- `description`: Integration purpose
- `status`: Current status
- `configuration`: API credentials and settings
- `health_status`: Service health
- `last_run_at`: Most recent usage
- `last_success_at`: Last successful call
- `last_error_at`: Last error occurrence
- `last_error_message`: Error details
- `run_count`: Total API calls
- `success_count`: Successful calls
- `failure_count`: Failed calls
- `created_at`: Creation timestamp
- `updated_at`: Last modification
- `metadata`: Additional integration data

---

### 8. Integration Logs Table

**Purpose**: Detailed log of integration activity

**Schema**:
```sql
CREATE TABLE integration_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    integration_id UUID NOT NULL REFERENCES integrations(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL, -- 'api_call', 'data_sync', 'webhook_received'
    status VARCHAR(50) NOT NULL, -- 'success', 'failure', 'partial'
    request_data JSONB,
    response_data JSONB,
    error_message TEXT,
    duration_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

CREATE INDEX idx_integration_logs_integration ON integration_logs(integration_id);
CREATE INDEX idx_integration_logs_status ON integration_logs(status);
CREATE INDEX idx_integration_logs_created ON integration_logs(created_at DESC);
```

---

### 9. Branding Table

**Purpose**: Visual identity and brand assets for projects

**Schema**:
```sql
CREATE TABLE branding (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    logo_url VARCHAR(500),
    logo_small_url VARCHAR(500),
    icon_url VARCHAR(500),
    primary_color VARCHAR(7), -- Hex color code
    secondary_color VARCHAR(7),
    accent_color VARCHAR(7),
    font_family VARCHAR(100),
    tagline VARCHAR(255),
    website_url VARCHAR(500),
    social_links JSONB, -- {twitter: "...", linkedin: "...", etc.}
    brand_guidelines_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

CREATE INDEX idx_branding_name ON branding(name);
```

**Attributes**:
- `id`: Unique identifier
- `name`: Brand name
- `description`: Brand description
- `logo_url`: Primary logo URL
- `logo_small_url`: Compact logo URL
- `icon_url`: Icon/favicon URL
- `primary_color`: Main brand color
- `secondary_color`: Supporting color
- `accent_color`: Highlight color
- `font_family`: Brand typography
- `tagline`: Brand slogan
- `website_url`: Main website
- `social_links`: Social media profiles
- `brand_guidelines_url`: Brand guide document
- `created_at`: Creation timestamp
- `updated_at`: Last modification
- `metadata`: Additional brand data

---

### 10. Users Table

**Purpose**: System users, admins, and team members

**Schema**:
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255),
    role VARCHAR(50) DEFAULT 'user', -- 'admin', 'developer', 'user', 'viewer'
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'inactive', 'suspended'
    avatar_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    metadata JSONB
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
```

---

### 11. Task Assignments Table

**Purpose**: Junction table for assigning multiple users to tasks

**Schema**:
```sql
CREATE TABLE task_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50), -- 'owner', 'contributor', 'reviewer'
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES users(id),
    UNIQUE(task_id, user_id, role)
);

CREATE INDEX idx_task_assignments_task ON task_assignments(task_id);
CREATE INDEX idx_task_assignments_user ON task_assignments(user_id);
```

---

### 12. Activity Logs Table

**Purpose**: Comprehensive audit trail of all system activities

**Schema**:
```sql
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50) NOT NULL, -- 'project', 'task', 'agent', 'automation', 'integration'
    entity_id UUID NOT NULL,
    action VARCHAR(100) NOT NULL, -- 'created', 'updated', 'deleted', 'executed', 'assigned'
    actor_id UUID REFERENCES users(id),
    actor_type VARCHAR(50), -- 'user', 'agent', 'automation'
    changes JSONB, -- Before/after values
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB
);

CREATE INDEX idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_logs_actor ON activity_logs(actor_id);
CREATE INDEX idx_activity_logs_created ON activity_logs(created_at DESC);
```

---

## Natural Language Prompt for Database Architect

### System Context
You are managing a comprehensive database for the Pulse Registry System and its associated automation infrastructure. This system tracks projects, tasks, AI agents, automated workflows, external integrations, and branding assets.

### Database Requirements

**Projects**: Track all initiatives in the ecosystem including smart contracts, automations, integrations, and applications. Each project has a name, description, type, status, priority, owner, repository, documentation, and associated branding.

**Tasks**: Individual work items within projects. Support hierarchical tasks (parent-child relationships), assignments to users, status tracking, time estimates, tags for categorization, and flexible metadata storage.

**Agents**: AI assistants and automated agents that can be assigned to projects. Track agent types (preview, copilot, automation, validator), capabilities, configuration, API endpoints, versions, and activity status.

**Automations**: Scheduled or event-triggered workflows. Store script details, trigger configuration (cron, event, webhook), execution history (run count, success/failure rates), and relationship to projects.

**Integrations**: External service connections like social media APIs, blockchain networks, storage systems. Track service health, configuration (encrypted), usage statistics, and error logging.

**Branding**: Visual identity assets including logos, colors, fonts, taglines, and brand guidelines. Can be associated with projects.

**Users**: Team members with roles (admin, developer, user, viewer) who can own projects, be assigned tasks, and trigger actions.

**Supporting Tables**: Junction tables for many-to-many relationships (agent assignments, task assignments), execution logs (automation runs, integration logs), and comprehensive activity audit logs.

### Key Design Principles
1. **Normalization**: Separate entities with proper foreign keys, avoid data duplication
2. **Flexibility**: Use JSONB for metadata and configuration that varies by type
3. **Auditability**: Track created_at, updated_at, and maintain activity logs
4. **Performance**: Strategic indexes on frequently queried fields
5. **Scalability**: UUID primary keys, support for millions of records
6. **Security**: Encrypted sensitive data (API keys), role-based access control

---

## JSON Schema Examples

### Example 1: Complete Project with Related Entities

```json
{
  "project": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Super Reality AI",
    "description": "AI-powered virtual reality platform with blockchain integration",
    "project_type": "smart_contract",
    "status": "active",
    "priority": 3,
    "owner_id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "repository_url": "https://github.com/super-reality/ai-platform",
    "documentation_url": "https://docs.superreality.ai",
    "branding_id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-11-24T12:17:00Z",
    "completed_at": null,
    "metadata": {
      "tech_stack": ["Solidity", "React", "Node.js"],
      "budget": 250000,
      "team_size": 8
    }
  },
  "branding": {
    "id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
    "name": "Super Reality Studios",
    "description": "Leading blockchain-powered virtual reality platform",
    "logo_url": "https://cdn.superreality.ai/logo.png",
    "logo_small_url": "https://cdn.superreality.ai/logo-small.png",
    "icon_url": "https://cdn.superreality.ai/icon.png",
    "primary_color": "#6C5CE7",
    "secondary_color": "#A29BFE",
    "accent_color": "#FD79A8",
    "font_family": "Inter, sans-serif",
    "tagline": "Reality Reimagined",
    "website_url": "https://superreality.ai",
    "social_links": {
      "twitter": "https://twitter.com/superrealityai",
      "discord": "https://discord.gg/superreality",
      "linkedin": "https://linkedin.com/company/super-reality"
    },
    "brand_guidelines_url": "https://brand.superreality.ai/guidelines.pdf",
    "created_at": "2025-01-10T09:00:00Z",
    "updated_at": "2025-11-20T14:30:00Z",
    "metadata": {}
  }
}
```

### Example 2: Task with Assignments

```json
{
  "task": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "project_id": "550e8400-e29b-41d4-a716-446655440000",
    "parent_task_id": null,
    "name": "Implement multi-signature wallet for bridge contract",
    "description": "Add multi-sig functionality to ZcashBridge contract for enhanced security on high-value transfers",
    "task_type": "feature",
    "status": "in_progress",
    "priority": 2,
    "assignee_id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "estimated_hours": 16.0,
    "actual_hours": 8.5,
    "due_date": "2025-12-01T17:00:00Z",
    "created_at": "2025-11-20T08:00:00Z",
    "updated_at": "2025-11-24T12:00:00Z",
    "completed_at": null,
    "tags": ["security", "smart-contract", "bridge", "high-priority"],
    "metadata": {
      "github_issue": "https://github.com/super-reality/ai-platform/issues/42",
      "security_review": true,
      "requires_audit": true
    }
  },
  "task_assignments": [
    {
      "id": "aa1e4567-e89b-12d3-a456-426614174001",
      "task_id": "123e4567-e89b-12d3-a456-426614174000",
      "user_id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
      "role": "owner",
      "assigned_at": "2025-11-20T08:00:00Z",
      "assigned_by": "9c9e6679-7425-40de-944b-e07fc1f90ae9"
    },
    {
      "id": "bb1e4567-e89b-12d3-a456-426614174002",
      "task_id": "123e4567-e89b-12d3-a456-426614174000",
      "user_id": "8d9e6679-7425-40de-944b-e07fc1f90ae8",
      "role": "reviewer",
      "assigned_at": "2025-11-22T10:30:00Z",
      "assigned_by": "7c9e6679-7425-40de-944b-e07fc1f90ae7"
    }
  ]
}
```

### Example 3: Agent with Project Assignment

```json
{
  "agent": {
    "id": "33344444-aaaa-bbbb-cccc-123456789012",
    "name": "Spark",
    "agent_type": "preview",
    "description": "AI-powered code preview and analysis agent for pull requests",
    "status": "active",
    "capabilities": [
      "code_review",
      "security_analysis",
      "performance_optimization",
      "documentation_generation"
    ],
    "configuration": {
      "model": "gpt-4",
      "temperature": 0.3,
      "max_tokens": 4000,
      "languages": ["solidity", "javascript", "python"]
    },
    "api_endpoint": "https://api.superreality.ai/agents/spark",
    "version": "2.4.1",
    "created_at": "2025-06-01T12:00:00Z",
    "updated_at": "2025-11-24T09:30:00Z",
    "last_active_at": "2025-11-24T12:15:00Z",
    "metadata": {
      "reviews_completed": 1247,
      "average_review_time_seconds": 45,
      "accuracy_score": 0.94
    }
  },
  "agent_assignment": {
    "id": "cc1e4567-e89b-12d3-a456-426614174003",
    "agent_id": "33344444-aaaa-bbbb-cccc-123456789012",
    "project_id": "550e8400-e29b-41d4-a716-446655440000",
    "role": "reviewer",
    "assigned_at": "2025-06-15T14:00:00Z",
    "assigned_by": "9c9e6679-7425-40de-944b-e07fc1f90ae9",
    "status": "active",
    "metadata": {
      "auto_review_enabled": true,
      "review_threshold": "all_prs"
    }
  }
}
```

### Example 4: Automation with Execution History

```json
{
  "automation": {
    "id": "444e5678-f12c-34d5-b678-537725285111",
    "name": "Weekly Security Audit",
    "automation_type": "audit",
    "description": "Automated security scan of all smart contracts and dependencies",
    "script_name": "weekly_audit_script",
    "script_path": "/automations/security/weekly_audit.js",
    "related_project_id": "550e8400-e29b-41d4-a716-446655440000",
    "trigger_type": "schedule",
    "trigger_config": {
      "cron": "0 2 * * 1",
      "timezone": "UTC"
    },
    "status": "active",
    "last_run_at": "2025-11-18T02:00:15Z",
    "next_run_at": "2025-11-25T02:00:00Z",
    "run_count": 87,
    "success_count": 84,
    "failure_count": 3,
    "created_at": "2025-03-01T10:00:00Z",
    "updated_at": "2025-11-18T02:05:30Z",
    "created_by": "9c9e6679-7425-40de-944b-e07fc1f90ae9",
    "metadata": {
      "notification_channels": ["slack", "email"],
      "alert_on_failure": true
    }
  },
  "automation_runs": [
    {
      "id": "555e6789-g23d-45e6-c789-648836396222",
      "automation_id": "444e5678-f12c-34d5-b678-537725285111",
      "status": "success",
      "started_at": "2025-11-18T02:00:15Z",
      "completed_at": "2025-11-18T02:05:28Z",
      "duration_seconds": 313,
      "trigger_source": "schedule",
      "output_log": "Scanned 15 contracts. Found 0 critical issues, 2 warnings.",
      "error_log": null,
      "metrics": {
        "contracts_scanned": 15,
        "vulnerabilities_found": 0,
        "warnings": 2,
        "dependencies_checked": 234
      },
      "metadata": {
        "codeql_version": "2.14.6",
        "scan_type": "full"
      }
    }
  ]
}
```

### Example 5: Integration with Logs

```json
{
  "integration": {
    "id": "666e7890-h34e-56f7-d890-759947407333",
    "name": "TikTok Creator Portal",
    "integration_type": "social_media",
    "service_name": "TikTok",
    "description": "Integration for posting content and analytics from Super Reality platform",
    "status": "enabled",
    "configuration": {
      "api_key": "encrypted_key_here",
      "api_secret": "encrypted_secret_here",
      "account_id": "superrealityai",
      "rate_limit": 100,
      "endpoints": {
        "post": "https://open-api.tiktok.com/v1/post/",
        "analytics": "https://open-api.tiktok.com/v1/analytics/"
      }
    },
    "health_status": "healthy",
    "last_run_at": "2025-11-24T11:45:00Z",
    "last_success_at": "2025-11-24T11:45:00Z",
    "last_error_at": "2025-11-20T08:30:00Z",
    "last_error_message": "Rate limit exceeded, retrying with backoff",
    "run_count": 2847,
    "success_count": 2839,
    "failure_count": 8,
    "created_at": "2025-05-10T15:00:00Z",
    "updated_at": "2025-11-24T11:45:05Z",
    "metadata": {
      "auto_retry": true,
      "retry_attempts": 3,
      "success_rate": 0.997
    }
  },
  "integration_logs": [
    {
      "id": "777e8901-i45f-67g8-e901-860058518444",
      "integration_id": "666e7890-h34e-56f7-d890-759947407333",
      "action": "api_call",
      "status": "success",
      "request_data": {
        "method": "POST",
        "endpoint": "/v1/post/",
        "payload": {
          "content": "Check out our new VR experience!",
          "media_url": "https://cdn.superreality.ai/promo.mp4"
        }
      },
      "response_data": {
        "post_id": "7298765432109876543",
        "status": "published",
        "visibility": "public"
      },
      "error_message": null,
      "duration_ms": 1247,
      "created_at": "2025-11-24T11:45:00Z",
      "metadata": {
        "user_agent": "SuperReality-Bot/1.0",
        "ip_address": "203.0.113.42"
      }
    }
  ]
}
```

### Example 6: n8n Workflow Automation

```json
{
  "automation": {
    "id": "888e9012-j56g-78h9-f012-971169629555",
    "name": "n8n Data Sync Pipeline",
    "automation_type": "data_sync",
    "description": "Syncs blockchain data to analytics database via n8n workflow",
    "script_name": "n8n_blockchain_sync",
    "script_path": "https://n8n.superreality.ai/workflow/42",
    "related_project_id": "550e8400-e29b-41d4-a716-446655440000",
    "trigger_type": "event",
    "trigger_config": {
      "event_name": "BlockMined",
      "source": "pulse_chain",
      "filter": {
        "contract_address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
      }
    },
    "status": "active",
    "last_run_at": "2025-11-24T12:10:30Z",
    "next_run_at": null,
    "run_count": 15847,
    "success_count": 15821,
    "failure_count": 26,
    "created_at": "2025-07-01T12:00:00Z",
    "updated_at": "2025-11-24T12:11:00Z",
    "created_by": "9c9e6679-7425-40de-944b-e07fc1f90ae9",
    "metadata": {
      "n8n_workflow_id": "42",
      "n8n_version": "1.17.0",
      "average_execution_time_ms": 850,
      "data_points_synced": 458923
    }
  }
}
```

### Example 7: User with Roles

```json
{
  "user": {
    "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "username": "alice_blockchain",
    "email": "alice@superreality.ai",
    "full_name": "Alice Johnson",
    "role": "developer",
    "status": "active",
    "avatar_url": "https://avatars.superreality.ai/alice.jpg",
    "created_at": "2025-01-15T09:00:00Z",
    "updated_at": "2025-11-24T08:30:00Z",
    "last_login_at": "2025-11-24T08:30:00Z",
    "metadata": {
      "department": "Smart Contracts",
      "expertise": ["Solidity", "Web3", "Security"],
      "timezone": "America/Los_Angeles",
      "github_username": "alice-blockchain"
    }
  }
}
```

### Example 8: Activity Log Entry

```json
{
  "activity_log": {
    "id": "999f0123-k67h-89i0-g123-082270740666",
    "entity_type": "task",
    "entity_id": "123e4567-e89b-12d3-a456-426614174000",
    "action": "updated",
    "actor_id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "actor_type": "user",
    "changes": {
      "status": {
        "before": "pending",
        "after": "in_progress"
      },
      "actual_hours": {
        "before": 0,
        "after": 8.5
      }
    },
    "created_at": "2025-11-24T12:00:00Z",
    "metadata": {
      "source": "web_interface",
      "ip_address": "198.51.100.42",
      "user_agent": "Mozilla/5.0..."
    }
  }
}
```

---

## Database Indexes Summary

### High-Priority Indexes (Query Optimization)
```sql
-- Projects
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_type ON projects(project_type);

-- Tasks
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_assignee ON tasks(assignee_id);

-- Automations
CREATE INDEX idx_automations_next_run ON automations(next_run_at);
CREATE INDEX idx_automations_status ON automations(status);

-- Integrations
CREATE INDEX idx_integrations_health ON integrations(health_status);

-- Activity Logs
CREATE INDEX idx_activity_logs_created ON activity_logs(created_at DESC);
```

---

## Database Views (Common Queries)

### Active Projects Dashboard
```sql
CREATE VIEW active_projects_dashboard AS
SELECT 
    p.id,
    p.name,
    p.status,
    p.priority,
    b.name as brand_name,
    b.logo_url,
    COUNT(DISTINCT t.id) as task_count,
    COUNT(DISTINCT CASE WHEN t.status = 'completed' THEN t.id END) as completed_tasks,
    COUNT(DISTINCT aa.agent_id) as agent_count
FROM projects p
LEFT JOIN branding b ON p.branding_id = b.id
LEFT JOIN tasks t ON p.id = t.project_id
LEFT JOIN agent_assignments aa ON p.id = aa.project_id AND aa.status = 'active'
WHERE p.status = 'active'
GROUP BY p.id, p.name, p.status, p.priority, b.name, b.logo_url;
```

### Automation Health Monitor
```sql
CREATE VIEW automation_health_monitor AS
SELECT 
    a.id,
    a.name,
    a.automation_type,
    a.status,
    a.last_run_at,
    a.success_count,
    a.failure_count,
    CASE 
        WHEN a.failure_count = 0 THEN 100.0
        ELSE ROUND((a.success_count::decimal / (a.success_count + a.failure_count)) * 100, 2)
    END as success_rate,
    p.name as project_name
FROM automations a
LEFT JOIN projects p ON a.related_project_id = p.id
WHERE a.status = 'active';
```

---

## Migration Strategy

### Phase 1: Core Tables
1. users
2. projects
3. branding

### Phase 2: Work Management
4. tasks
5. task_assignments

### Phase 3: Automation
6. agents
7. agent_assignments
8. automations
9. automation_runs

### Phase 4: Integration
10. integrations
11. integration_logs

### Phase 5: Audit
12. activity_logs

---

## Backup and Maintenance

### Recommended Backup Schedule
- **Full backup**: Daily at 2 AM UTC
- **Incremental backup**: Every 6 hours
- **Transaction logs**: Real-time archival
- **Retention**: 30 days for daily, 90 days for weekly, 1 year for monthly

### Maintenance Tasks
- **Vacuum/Analyze**: Weekly on Sunday 3 AM
- **Index rebuild**: Monthly
- **Partition old logs**: Quarterly (keep last 12 months active)
- **Archive activity_logs**: Monthly (move to cold storage after 90 days)

---

**Database Version**: 1.0.0
**Last Updated**: 2025-11-24
**Schema Status**: ✅ Production Ready
