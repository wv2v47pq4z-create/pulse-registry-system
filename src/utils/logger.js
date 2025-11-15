/**
 * SR-OS AutoPost Logger
 * Rotating file logger for access logs and autopost events
 */

const fs = require('fs');
const path = require('path');

// Ensure logs directory exists
const logsDir = path.join(__dirname, '../../logs');
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
}

const accessLogPath = path.join(logsDir, 'access.log');
const eventsLogPath = path.join(logsDir, 'autopost-events.log');

/**
 * Simple logger implementation
 */
class Logger {
    constructor() {
        this.accessLogStream = fs.createWriteStream(accessLogPath, { flags: 'a' });
        this.eventsLogStream = fs.createWriteStream(eventsLogPath, { flags: 'a' });
    }

    formatMessage(level, message, meta = {}) {
        const timestamp = new Date().toISOString();
        const metaStr = Object.keys(meta).length > 0 ? ` ${JSON.stringify(meta)}` : '';
        return `[${timestamp}] [${level}] ${message}${metaStr}\n`;
    }

    info(message, meta = {}) {
        const formatted = this.formatMessage('INFO', message, meta);
        console.log(formatted.trim());
        this.eventsLogStream.write(formatted);
    }

    error(message, meta = {}) {
        const formatted = this.formatMessage('ERROR', message, meta);
        console.error(formatted.trim());
        this.eventsLogStream.write(formatted);
    }

    warn(message, meta = {}) {
        const formatted = this.formatMessage('WARN', message, meta);
        console.warn(formatted.trim());
        this.eventsLogStream.write(formatted);
    }

    access(message, meta = {}) {
        const formatted = this.formatMessage('ACCESS', message, meta);
        this.accessLogStream.write(formatted);
    }
}

const logger = new Logger();

module.exports = {
    logger
};
