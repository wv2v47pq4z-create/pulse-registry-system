/**
 * SR-OS AutoPost Engine - Main Server
 * Express server with health check and AutoPost routes
 */

const express = require('express');
const { logger } = require('./utils/logger');
const { loadEnv } = require('./utils/env');
const autopostRoutes = require('./routes/autopost');

// Load environment configuration
const config = loadEnv();

const app = express();

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path}`, {
        ip: req.ip,
        userAgent: req.get('user-agent')
    });
    next();
});

// Health check endpoint
app.get('/status', (req, res) => {
    res.json({
        status: 'online',
        service: 'SR-OS AutoPost Engine',
        version: '2.0.0',
        timestamp: new Date().toISOString()
    });
});

// Mount AutoPost routes
app.use('/sr-autopost', autopostRoutes);

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        path: req.path
    });
});

// Error handler
app.use((err, req, res, next) => {
    logger.error('Server error:', err);
    res.status(500).json({
        error: 'Internal Server Error',
        message: err.message
    });
});

// Start server
const PORT = config.PORT;
app.listen(PORT, () => {
    logger.info(`SR-OS AutoPost Engine listening on port ${PORT}`);
    logger.info(`Health check: http://localhost:${PORT}/status`);
    logger.info(`AutoPost endpoint: http://localhost:${PORT}/sr-autopost/tiktok`);
});

module.exports = app;
