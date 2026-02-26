# pulse-registry-system

Smart contracts for PulseRegistry and ZcashBridge – auto-registration and interoperability layer for Super Reality Studios blockchain ecosystem.

## Requirements

- [Docker](https://docs.docker.com/get-docker/) ≥ 24
- [Docker Compose](https://docs.docker.com/compose/install/) v2

> No local Node.js installation is required; all tooling runs inside Docker.

## Quick Start

### Compile contracts

```bash
docker compose run --rm compile
```

### Run tests

```bash
docker compose run --rm test
```

### Start a local Hardhat node (JSON-RPC on port 8545)

```bash
docker compose up node
```

## Building the image manually

```bash
# Build the runtime image
docker build --target runtime -t pulse-registry-system .

# Run the local node
docker run --rm -p 8545:8545 pulse-registry-system
```

## CI/CD

The repository ships a GitHub Actions workflow (`.github/workflows/docker.yml`) that:

1. **Builds** the `builder` stage and **runs the test suite** on every push and pull request.
2. **Publishes** the `runtime` image to Docker Hub on every merge to `main`/`master`.

To enable publishing, add the following repository secrets:

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | A Docker Hub [access token](https://hub.docker.com/settings/security) |

## Project structure

```
.
├── contracts/          # Solidity smart contracts
├── scripts/            # Deployment and utility scripts
├── test/               # Hardhat test suite
├── hardhat.config.js   # Hardhat configuration
├── Dockerfile          # Multi-stage Docker build
├── docker-compose.yml  # Local development services
└── .github/
    └── workflows/
        └── docker.yml  # CI/CD pipeline
```
