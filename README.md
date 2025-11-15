# SR-OS AutoPost Engine

Production-ready social media automation system for TikTok, Instagram, and YouTube Shorts with automated caption and hashtag generation.

## Overview

The SR-OS AutoPost Engine is an Express.js-based service that automatically generates platform-optimized captions and hashtags for social media content. It provides a REST API for processing video upload requests and generating ready-to-post content artifacts.

## Features

- **Platform-Specific Content Generation**: Tailored captions and hashtags for TikTok, Instagram, and YouTube
- **Tone-Aware Content**: Supports multiple tones (hype, chill, educational, cinematic, raw, default)
- **Smart Hashtag Generation**: Platform-optimized hashtag counts and keyword extraction
- **Machine-Usable Output**: Returns structured JSON with artifacts, HTTP requests, and curl examples
- **Production-Ready**: Docker support, PM2 clustering, health checks, and logging

## Quick Start

### Prerequisites

- Node.js v16 or higher
- npm or yarn (for local development)
- Docker & Docker Compose (for containerized deployment)

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

# Test AutoPost endpoint with TikTok
curl -X POST http://localhost:8181/sr-autopost/tiktok \
  -H "Content-Type: application/json" \
  -d '{
    "videoUrl": "https://example.com/video.mp4",
    "topic": "Amazing Dance Moves"
  }'

# Test with custom payload
curl -X POST http://localhost:8181/sr-autopost/tiktok \
  -H "Content-Type: application/json" \
  -d @test-payload.json
```

## Docker Usage

### Build and Run with Docker Compose

```bash
# Build the image
npm run docker:build
# or
docker-compose build

# Start the service
npm run docker:up
# or
docker-compose up -d

# View logs
npm run docker:logs
# or
docker-compose logs -f

# Stop the service
npm run docker:down
# or
docker-compose down
```

### Manual Docker Commands

```bash
# Build the image
docker build -t sr-os-autopost-engine .

# Run the container
docker run -d \
  -p 8181:8181 \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/posted:/app/posted \
  --name autopost \
  sr-os-autopost-engine

# View logs
docker logs -f autopost

# Stop and remove
docker stop autopost && docker rm autopost
```

## PM2 Production Deployment

For production deployments with process management:

```bash
# Start with PM2
npm run pm2:start

# View logs
npm run pm2:logs

# Stop the service
npm run pm2:stop
```

PM2 will run the service in cluster mode with automatic restarts and load balancing.

## Environment Variables

Copy `.env.example` to `.env` and configure:

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `8181` |
| `NODE_ENV` | Environment (development/production) | `development` |
| `AUTOPOST_WEBHOOK_URL` | Target webhook URL | `https://autopost.superreality.studio/webhook/auto-post` |
| `POSTED_FOLDER` | Folder for posted content | `./posted` |
| `LOGS_FOLDER` | Folder for log files | `./logs` |
| `OPENAI_API_KEY` | Optional OpenAI API key | - |
| `ANTHROPIC_API_KEY` | Optional Anthropic API key | - |

## API Documentation

### Endpoints

#### Health Check
```
GET /status
```

Returns service status and version information.

#### AutoPost Endpoints

##### TikTok
```
POST /sr-autopost/tiktok
```

##### Instagram
```
POST /sr-autopost/instagram
```

##### YouTube
```
POST /sr-autopost/youtube
```

##### Multi-Platform
```
POST /sr-autopost
```

### Request Schema

All AutoPost endpoints accept the following JSON payload:

```json
{
  "videoUrl": "string (required)",
  "topic": "string (required)",
  "tone": "hype | chill | educational | cinematic | raw | default (optional, default: hype)",
  "platforms": ["tiktok", "instagram", "youtube"] (optional, default: ["tiktok"]),
  "batchId": "string (optional)",
  "extra": {} (optional)
}
```

### Response Schema

The service returns a machine-usable JSON response:

```json
{
  "status": "success",
  "topic": "Your Video Topic",
  "tone": "hype",
  "platforms": ["tiktok"],
  "batchId": null,
  "artifacts": [
    {
      "platform": "tiktok",
      "videoUrl": "https://example.com/video.mp4",
      "caption": "Generated caption...",
      "hashtags": ["#fyp", "#viral", ...],
      "hashtagString": "#fyp #viral ...",
      "fullCaption": "Caption with hashtags..."
    }
  ],
  "httpRequests": [
    {
      "method": "POST",
      "url": "https://autopost.superreality.studio/webhook/auto-post",
      "headers": {...},
      "body": {...}
    }
  ],
  "curlExamples": [
    {
      "platform": "tiktok",
      "curl": "curl -X POST ..."
    }
  ],
  "summary": {
    "totalPlatforms": 1,
    "generatedAt": "2025-11-15T...",
    "webhookUrl": "https://autopost.superreality.studio/webhook/auto-post"
  }
}
```

## Platform-Specific Rules

### TikTok
- Short hook (3-6 words)
- 2-3 lines of caption
- 6-12 hashtags
- Trending and engagement-focused

### Instagram Reels
- 1-2 sentences
- 8-15 hashtags
- Broader reach strategy
- Engagement prompts

### YouTube Shorts
- Title ≤45 characters
- 1-3 line description
- 4-7 hashtags (minimal per YouTube best practices)
- Optimized for Shorts format

## Tone Styles

- **hype**: ALL CAPS, high energy, excitement
- **chill**: lowercase, relaxed, peaceful vibes
- **educational**: Clear, informative, structured
- **cinematic**: Artistic, dramatic, storytelling
- **raw**: Authentic, unfiltered, direct
- **default**: Balanced, neutral, standard

## Project Structure

```
sr-os-autopost-engine/
├── src/
│   ├── server.js              # Main Express server
│   ├── routes/
│   │   └── autopost.js        # AutoPost route handlers
│   ├── services/
│   │   ├── validation.js      # Schema validation
│   │   ├── captionGenerator.js # Caption generation
│   │   ├── hashtagGenerator.js # Hashtag generation
│   │   └── uploadRouter.js    # Upload routing
│   ├── utils/
│   │   ├── logger.js          # Logging utility
│   │   └── env.js             # Environment config
│   └── watchers/
│       └── postedFolderWatcher.js # Folder monitoring
├── logs/                      # Application logs
│   ├── access.log
│   └── autopost-events.log
├── posted/                    # Posted content folder
├── package.json               # Node.js configuration
├── .env.example               # Environment template
├── Dockerfile                 # Docker configuration
├── docker-compose.yml         # Docker Compose setup
├── ecosystem.config.js        # PM2 configuration
└── test-payload.json          # Example test payload
```

## Example Payloads

### Basic TikTok Request
```json
{
  "videoUrl": "https://example.com/dance.mp4",
  "topic": "Amazing Dance Moves"
}
```

### Educational YouTube Short
```json
{
  "videoUrl": "https://example.com/tutorial.mp4",
  "topic": "Quick Photography Tips",
  "tone": "educational",
  "platforms": ["youtube"]
}
```

### Multi-Platform Hype Content
```json
{
  "videoUrl": "https://example.com/epic.mp4",
  "topic": "Epic Gaming Comeback Victory",
  "tone": "hype",
  "platforms": ["tiktok", "instagram", "youtube"],
  "batchId": "batch-2024-001"
}
```

## Logging

The service logs to two files:
- `logs/access.log` - HTTP access logs
- `logs/autopost-events.log` - Application events and errors

Logs include timestamps, log levels, and structured metadata.

## Health Checks

The `/status` endpoint provides:
- Service status
- Version information
- Timestamp

Docker Compose includes automatic health checks using this endpoint.

## Security

- Runs as non-root user in Docker
- Input validation on all requests
- Configurable via environment variables
- No secrets in code or logs

## Development

### Install Dependencies
```bash
npm install
```

### Run Development Server
```bash
npm run dev
```

### Available Scripts
- `npm start` - Start the server
- `npm run dev` - Start in development mode
- `npm run pm2:start` - Start with PM2
- `npm run pm2:stop` - Stop PM2 service
- `npm run pm2:logs` - View PM2 logs
- `npm run docker:build` - Build Docker image
- `npm run docker:up` - Start Docker container
- `npm run docker:down` - Stop Docker container
- `npm run docker:logs` - View Docker logs

## Troubleshooting

### Port Already in Use
Change the `PORT` in `.env` or set it when running:
```bash
PORT=8182 npm start
```

### Dependencies Not Installing
Clear npm cache and reinstall:
```bash
rm -rf node_modules package-lock.json
npm install
```

### Docker Build Issues
Clean Docker cache:
```bash
docker-compose down -v
docker system prune -a
npm run docker:build
```

## License

MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions and support:
- Open an issue in this repository
- Check the example payloads in `test-payload.json`

## Acknowledgments

Developed by Super Reality Studios for the SR-OS ecosystem.
