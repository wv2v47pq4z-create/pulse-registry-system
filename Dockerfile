# ── Build stage ──────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first (leverages Docker layer cache)
COPY package*.json ./
RUN npm ci --ignore-scripts

# Copy project sources
COPY . .

# Compile contracts
RUN npm run compile

# ── Test / CI stage ───────────────────────────────────────────────────────────
FROM builder AS test

RUN npm test

# ── Runtime / tooling stage ───────────────────────────────────────────────────
FROM node:20-alpine AS runtime

WORKDIR /app

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/contracts ./contracts
COPY --from=builder /app/artifacts ./artifacts
COPY --from=builder /app/hardhat.config.js ./hardhat.config.js

# Expose the default Hardhat Network JSON-RPC port
EXPOSE 8545

CMD ["npm", "run", "node"]
