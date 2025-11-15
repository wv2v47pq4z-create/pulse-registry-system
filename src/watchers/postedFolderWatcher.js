/**
 * SR-OS AutoPost Posted Folder Watcher
 * Monitors the ./posted folder for new files and logs events
 */

const fs = require('fs');
const path = require('path');
const { logger } = require('../utils/logger');
const { loadEnv } = require('../utils/env');

const config = loadEnv();

/**
 * Start watching the posted folder
 */
function startWatcher() {
    const postedFolder = config.POSTED_FOLDER;

    // Ensure folder exists
    if (!fs.existsSync(postedFolder)) {
        fs.mkdirSync(postedFolder, { recursive: true });
        logger.info(`Created posted folder: ${postedFolder}`);
    }

    logger.info(`Starting watcher for folder: ${postedFolder}`);

    // Watch for file system changes
    fs.watch(postedFolder, (eventType, filename) => {
        if (filename) {
            logger.info(`Folder event detected: ${eventType} - ${filename}`);
            
            const filePath = path.join(postedFolder, filename);
            
            // Check if file exists and log details
            if (fs.existsSync(filePath)) {
                const stats = fs.statSync(filePath);
                logger.info(`File details:`, {
                    filename,
                    size: stats.size,
                    created: stats.birthtime,
                    modified: stats.mtime
                });
            }
        }
    });

    logger.info('Posted folder watcher started successfully');
}

module.exports = {
    startWatcher
};
