# SR-OS AutoPost Engine v2

Social media automation system for TikTok, Instagram, and YouTube Shorts.

## Quick Start

### Local Development

```bash
# Install dependencies
npm install

# Start the server
npm run dev
```

The server will start on port 8181.

### Test the Service

```bash
# Health check
curl http://localhost:8181/status

# Test AutoPost endpoint
curl -X POST http://localhost:8181/sr-autopost/tiktok \
  -H "Content-Type: application/json" \
  -d @test-payload.json
```

## Docker Usage

```bash
# Build and start with Docker Compose
npm run docker:build
npm run docker:up

# View logs
npm run docker:logs

# Stop
npm run docker:down
```

## PM2 Production Deployment

```bash
# Start with PM2
npm run pm2:start

# View logs
npm run pm2:logs

# Stop
npm run pm2:stop
```

## Environment Variables

Copy `.env.example` to `.env` and configure:

- `PORT` - Server port (default: 8181)
- `AUTOPOST_WEBHOOK_URL` - Target webhook URL
- `OPENAI_API_KEY` - Optional AI API key
- `ANTHROPIC_API_KEY` - Optional AI API key

## API Endpoints

### Health Check
```
GET /status
```

### AutoPost Endpoints
```
POST /sr-autopost/tiktok
POST /sr-autopost/instagram
POST /sr-autopost/youtube
```

### Request Schema
```json
{
  "videoUrl": "string",
  "topic": "string",
  "tone": "hype | chill | educational | cinematic | raw | default",
  "platforms": ["tiktok", "instagram", "youtube"],
  "batchId": "optional string",
  "extra": {}
}
```

## Project Structure

```
/
├─ src/
│  ├─ server.js           # Main Express server
│  ├─ routes/
│  │   └─ autopost.js     # AutoPost route handlers
│  ├─ services/
│  │   ├─ captionGenerator.js
│  │   ├─ hashtagGenerator.js
│  │   ├─ uploadRouter.js
│  │   └─ validation.js
│  ├─ utils/
│  │   ├─ logger.js
│  │   └─ env.js
│  └─ watchers/
│      └─ postedFolderWatcher.js
├─ posted/                # Posted content folder
├─ logs/                  # Application logs
├─ package.json
├─ Dockerfile
├─ docker-compose.yml
└─ ecosystem.config.js    # PM2 configuration
```

## License

MIT
