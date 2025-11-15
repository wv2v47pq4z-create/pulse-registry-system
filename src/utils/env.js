/**
 * SR-OS AutoPost Environment Configuration
 * Loads environment variables with sensible defaults
 */

const path = require('path');
const fs = require('fs');

/**
 * Load environment configuration
 * @returns {Object} Configuration object
 */
function loadEnv() {
    // Try to load .env file if it exists
    const envPath = path.join(__dirname, '../../.env');
    if (fs.existsSync(envPath)) {
        require('dotenv').config({ path: envPath });
    }

    const config = {
        // Server configuration
        PORT: process.env.PORT || 8181,
        NODE_ENV: process.env.NODE_ENV || 'development',

        // AutoPost API configuration
        AUTOPOST_WEBHOOK_URL: process.env.AUTOPOST_WEBHOOK_URL || 'https://autopost.superreality.studio/webhook/auto-post',

        // Folder paths
        POSTED_FOLDER: process.env.POSTED_FOLDER || path.join(__dirname, '../../posted'),
        LOGS_FOLDER: process.env.LOGS_FOLDER || path.join(__dirname, '../../logs'),

        // Optional API keys
        OPENAI_API_KEY: process.env.OPENAI_API_KEY || '',
        ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY || '',
    };

    return config;
}

module.exports = {
    loadEnv
};
