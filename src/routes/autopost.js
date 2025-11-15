/**
 * SR-OS AutoPost Routes
 * Handles AutoPost requests for different platforms
 */

const express = require('express');
const { logger } = require('../utils/logger');
const { validateAutoPostPayload } = require('../services/validation');

const router = express.Router();

/**
 * TikTok AutoPost endpoint
 * POST /sr-autopost/tiktok
 */
router.post('/tiktok', async (req, res) => {
    try {
        logger.info('Received TikTok AutoPost request', { body: req.body });

        // Validate payload
        const validatedPayload = validateAutoPostPayload(req.body);
        
        // TODO: Phase 2 - Implement caption, hashtag generation and upload routing
        
        res.json({
            status: 'success',
            message: 'AutoPost request received and validated',
            payload: validatedPayload
        });
    } catch (error) {
        logger.error('TikTok AutoPost error:', error);
        res.status(400).json({
            status: 'error',
            message: error.message
        });
    }
});

/**
 * Instagram AutoPost endpoint
 * POST /sr-autopost/instagram
 */
router.post('/instagram', async (req, res) => {
    try {
        logger.info('Received Instagram AutoPost request', { body: req.body });

        const validatedPayload = validateAutoPostPayload(req.body);
        
        res.json({
            status: 'success',
            message: 'AutoPost request received and validated',
            payload: validatedPayload
        });
    } catch (error) {
        logger.error('Instagram AutoPost error:', error);
        res.status(400).json({
            status: 'error',
            message: error.message
        });
    }
});

/**
 * YouTube AutoPost endpoint
 * POST /sr-autopost/youtube
 */
router.post('/youtube', async (req, res) => {
    try {
        logger.info('Received YouTube AutoPost request', { body: req.body });

        const validatedPayload = validateAutoPostPayload(req.body);
        
        res.json({
            status: 'success',
            message: 'AutoPost request received and validated',
            payload: validatedPayload
        });
    } catch (error) {
        logger.error('YouTube AutoPost error:', error);
        res.status(400).json({
            status: 'error',
            message: error.message
        });
    }
});

module.exports = router;
