/**
 * SR-OS AutoPost Routes
 * Handles AutoPost requests for different platforms
 */

const express = require('express');
const { logger } = require('../utils/logger');
const { validateAutoPostPayload } = require('../services/validation');
const { routeUpload } = require('../services/uploadRouter');

const router = express.Router();

/**
 * Process AutoPost request for any platform
 * @param {Object} req - Express request
 * @param {Object} res - Express response
 * @param {string} defaultPlatform - Default platform if not specified
 */
async function processAutoPostRequest(req, res, defaultPlatform) {
    try {
        logger.info(`Received ${defaultPlatform} AutoPost request`, { 
            body: req.body,
            timestamp: new Date().toISOString()
        });

        // Ensure the request payload includes the correct platform
        const requestPayload = {
            ...req.body,
            platforms: req.body.platforms || [defaultPlatform]
        };

        // Validate payload
        const validatedPayload = validateAutoPostPayload(requestPayload);
        
        logger.info('Payload validated', { 
            topic: validatedPayload.topic,
            tone: validatedPayload.tone,
            platforms: validatedPayload.platforms
        });
        
        // Route upload and generate artifacts
        const uploadResponse = routeUpload(validatedPayload);
        
        logger.info('AutoPost processing complete', {
            topic: validatedPayload.topic,
            platforms: validatedPayload.platforms.length
        });
        
        // Return machine-usable JSON response
        res.json(uploadResponse);
        
    } catch (error) {
        logger.error(`${defaultPlatform} AutoPost error:`, {
            message: error.message,
            stack: error.stack
        });
        
        res.status(400).json({
            status: 'error',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
}

/**
 * TikTok AutoPost endpoint
 * POST /sr-autopost/tiktok
 */
router.post('/tiktok', async (req, res) => {
    await processAutoPostRequest(req, res, 'tiktok');
});

/**
 * Instagram AutoPost endpoint
 * POST /sr-autopost/instagram
 */
router.post('/instagram', async (req, res) => {
    await processAutoPostRequest(req, res, 'instagram');
});

/**
 * YouTube AutoPost endpoint
 * POST /sr-autopost/youtube
 */
router.post('/youtube', async (req, res) => {
    await processAutoPostRequest(req, res, 'youtube');
});

/**
 * Generic AutoPost endpoint (supports multiple platforms)
 * POST /sr-autopost
 */
router.post('/', async (req, res) => {
    try {
        logger.info('Received generic AutoPost request', { 
            body: req.body,
            timestamp: new Date().toISOString()
        });

        // Validate payload
        const validatedPayload = validateAutoPostPayload(req.body);
        
        logger.info('Payload validated', { 
            topic: validatedPayload.topic,
            tone: validatedPayload.tone,
            platforms: validatedPayload.platforms
        });
        
        // Route upload and generate artifacts for all platforms
        const uploadResponse = routeUpload(validatedPayload);
        
        logger.info('AutoPost processing complete', {
            topic: validatedPayload.topic,
            platforms: validatedPayload.platforms.length
        });
        
        // Return machine-usable JSON response
        res.json(uploadResponse);
        
    } catch (error) {
        logger.error('Generic AutoPost error:', {
            message: error.message,
            stack: error.stack
        });
        
        res.status(400).json({
            status: 'error',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

module.exports = router;
