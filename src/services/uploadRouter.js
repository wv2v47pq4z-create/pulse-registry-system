/**
 * SR-OS AutoPost Upload Router
 * Routes validated payloads to appropriate platform upload handlers
 */

const { logger } = require('../utils/logger');
const { loadEnv } = require('../utils/env');
const { generateCaption } = require('./captionGenerator');
const { generateHashtags } = require('./hashtagGenerator');

const config = loadEnv();

/**
 * Build platform-specific artifact for TikTok
 */
function buildTikTokArtifact(payload, caption, hashtags) {
    return {
        platform: 'tiktok',
        videoUrl: payload.videoUrl,
        caption: caption,
        hashtags: hashtags,
        hashtagString: hashtags.join(' '),
        fullCaption: `${caption}\n\n${hashtags.join(' ')}`,
        tone: payload.tone,
        batchId: payload.batchId
    };
}

/**
 * Build platform-specific artifact for Instagram
 */
function buildInstagramArtifact(payload, caption, hashtags) {
    return {
        platform: 'instagram',
        videoUrl: payload.videoUrl,
        caption: caption,
        hashtags: hashtags,
        hashtagString: hashtags.join(' '),
        fullCaption: `${caption}\n\n${hashtags.join(' ')}`,
        tone: payload.tone,
        batchId: payload.batchId
    };
}

/**
 * Build platform-specific artifact for YouTube
 */
function buildYouTubeArtifact(payload, captionData, hashtags) {
    return {
        platform: 'youtube',
        videoUrl: payload.videoUrl,
        title: captionData.title,
        description: captionData.description,
        hashtags: hashtags,
        hashtagString: hashtags.join(' '),
        fullDescription: `${captionData.description}\n\n${hashtags.join(' ')}`,
        tone: payload.tone,
        batchId: payload.batchId
    };
}

/**
 * Build HTTP request body for webhook
 */
function buildHttpRequest(artifact, platform) {
    const webhookUrl = config.AUTOPOST_WEBHOOK_URL;
    
    const requestBody = {
        platform: platform,
        videoUrl: artifact.videoUrl,
        content: platform === 'youtube' ? {
            title: artifact.title,
            description: artifact.fullDescription
        } : {
            caption: artifact.fullCaption
        },
        hashtags: artifact.hashtags,
        metadata: {
            tone: artifact.tone,
            batchId: artifact.batchId,
            generatedAt: new Date().toISOString()
        }
    };
    
    return {
        method: 'POST',
        url: webhookUrl,
        headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'SR-OS-AutoPost-Engine/2.0'
        },
        body: requestBody
    };
}

/**
 * Generate curl command for testing
 */
function generateCurlCommand(httpRequest) {
    const bodyJson = JSON.stringify(httpRequest.body, null, 2);
    
    return `curl -X ${httpRequest.method} '${httpRequest.url}' \\
  -H 'Content-Type: application/json' \\
  -H 'User-Agent: SR-OS-AutoPost-Engine/2.0' \\
  -d '${bodyJson.replace(/'/g, "'\\''")}'`;
}

/**
 * Route upload to appropriate platforms
 * @param {Object} payload - Validated AutoPost payload
 * @returns {Object} Upload routing response with artifacts and HTTP requests
 */
function routeUpload(payload) {
    logger.info('Routing upload', { payload });
    
    const artifacts = [];
    const httpRequests = [];
    const curlExamples = [];
    
    // Process each platform
    for (const platform of payload.platforms) {
        logger.info(`Building artifact for ${platform}`, { topic: payload.topic });
        
        try {
            // Generate caption and hashtags
            const caption = generateCaption(payload.topic, payload.tone, platform);
            const hashtags = generateHashtags(payload.topic, payload.tone, platform);
            
            // Build platform-specific artifact
            let artifact;
            switch (platform.toLowerCase()) {
                case 'tiktok':
                    artifact = buildTikTokArtifact(payload, caption, hashtags);
                    break;
                case 'instagram':
                    artifact = buildInstagramArtifact(payload, caption, hashtags);
                    break;
                case 'youtube':
                    artifact = buildYouTubeArtifact(payload, caption, hashtags);
                    break;
                default:
                    throw new Error(`Unsupported platform: ${platform}`);
            }
            
            artifacts.push(artifact);
            
            // Build HTTP request
            const httpRequest = buildHttpRequest(artifact, platform);
            httpRequests.push(httpRequest);
            
            // Generate curl command
            const curlCommand = generateCurlCommand(httpRequest);
            curlExamples.push({
                platform: platform,
                curl: curlCommand
            });
            
            logger.info(`Artifact built successfully for ${platform}`);
        } catch (error) {
            logger.error(`Error building artifact for ${platform}:`, error);
            throw error;
        }
    }
    
    // Build response
    const response = {
        status: 'success',
        topic: payload.topic,
        tone: payload.tone,
        platforms: payload.platforms,
        batchId: payload.batchId,
        artifacts: artifacts,
        httpRequests: httpRequests,
        curlExamples: curlExamples,
        summary: {
            totalPlatforms: payload.platforms.length,
            generatedAt: new Date().toISOString(),
            webhookUrl: config.AUTOPOST_WEBHOOK_URL
        }
    };
    
    logger.info('Upload routing complete', { 
        platforms: payload.platforms.length,
        topic: payload.topic 
    });
    
    return response;
}

module.exports = {
    routeUpload
};
