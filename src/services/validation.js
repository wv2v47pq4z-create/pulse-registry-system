/**
 * SR-OS AutoPost Validation Service
 * Validates AutoPost JSON payloads against schema
 */

const { logger } = require('../utils/logger');

/**
 * Validate AutoPost payload
 * @param {Object} payload - The AutoPost request payload
 * @returns {Object} Validated payload with defaults applied
 * @throws {Error} If validation fails
 */
function validateAutoPostPayload(payload) {
    if (!payload || typeof payload !== 'object') {
        throw new Error('Payload must be a valid object');
    }

    // Required field: videoUrl
    if (!payload.videoUrl || typeof payload.videoUrl !== 'string') {
        throw new Error('videoUrl is required and must be a string');
    }

    // Required field: topic
    if (!payload.topic || typeof payload.topic !== 'string') {
        throw new Error('topic is required and must be a string');
    }

    // Validate tone if provided
    const validTones = ['hype', 'chill', 'educational', 'cinematic', 'raw', 'default'];
    const tone = payload.tone || 'hype';
    if (!validTones.includes(tone)) {
        throw new Error(`tone must be one of: ${validTones.join(', ')}`);
    }

    // Validate platforms if provided
    const validPlatforms = ['tiktok', 'instagram', 'youtube'];
    const platforms = payload.platforms || ['tiktok'];
    
    if (!Array.isArray(platforms)) {
        throw new Error('platforms must be an array');
    }

    for (const platform of platforms) {
        if (!validPlatforms.includes(platform)) {
            throw new Error(`Invalid platform: ${platform}. Must be one of: ${validPlatforms.join(', ')}`);
        }
    }

    // Build validated payload with defaults
    const validated = {
        videoUrl: payload.videoUrl,
        topic: payload.topic,
        tone: tone,
        platforms: platforms,
        batchId: payload.batchId || null,
        extra: payload.extra || {}
    };

    logger.info('Payload validated successfully', { validated });

    return validated;
}

module.exports = {
    validateAutoPostPayload
};
