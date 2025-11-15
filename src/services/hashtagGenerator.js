/**
 * SR-OS AutoPost Hashtag Generator
 * Generates platform-specific hashtags based on topic and tone
 */

const { logger } = require('../utils/logger');

/**
 * Common trending hashtags by tone
 */
const toneHashtags = {
    hype: ['#viral', '#trending', '#fyp', '#foryou', '#insane', '#epic', '#amazing', '#wow', '#omg', '#unbelievable'],
    chill: ['#vibes', '#aesthetic', '#mood', '#chill', '#relaxing', '#peaceful', '#calm', '#cozy', '#softvibe', '#mindful'],
    educational: ['#learn', '#educational', '#tips', '#howto', '#tutorial', '#knowledge', '#facts', '#lifehacks', '#didyouknow', '#protips'],
    cinematic: ['#cinematic', '#visualart', '#filmmaking', '#artistic', '#storytelling', '#cinematography', '#creative', '#film', '#visual', '#artistry'],
    raw: ['#real', '#authentic', '#unfiltered', '#honest', '#truth', '#reallife', '#keepitreal', '#nofilter', '#raw', '#genuine'],
    default: ['#video', '#content', '#new', '#watch', '#check', '#see', '#daily', '#today', '#post', '#share']
};

/**
 * Platform-specific popular hashtags
 */
const platformHashtags = {
    tiktok: ['#tiktok', '#fyp', '#foryou', '#foryoupage', '#viral', '#trending', '#tiktokviral', '#explorepage'],
    instagram: ['#instagram', '#reels', '#reelsinstagram', '#instareels', '#instadaily', '#instagood', '#explore', '#explorepage', '#insta', '#ig'],
    youtube: ['#shorts', '#youtubeshorts', '#youtube', '#short', '#ytshorts', '#youtuber', '#subscribe']
};

/**
 * Extract keywords from topic for hashtag generation
 */
function extractKeywords(topic) {
    // Remove common words and extract meaningful keywords
    const commonWords = ['the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'be', 'been'];
    
    const words = topic.toLowerCase()
        .replace(/[^\w\s]/g, ' ')
        .split(/\s+/)
        .filter(word => word.length > 2 && !commonWords.includes(word));
    
    return words.slice(0, 3); // Return top 3 keywords
}

/**
 * Generate hashtags for TikTok
 * 6-12 hashtags with mix of trending, topic-specific, and tone-based
 */
function generateTikTokHashtags(topic, tone) {
    const hashtags = new Set();
    
    // Add platform hashtags (2-3)
    hashtags.add('#fyp');
    hashtags.add('#foryou');
    hashtags.add('#viral');
    
    // Add tone-specific hashtags (2-3)
    const toneHashes = toneHashtags[tone] || toneHashtags.default;
    for (let i = 0; i < 3 && i < toneHashes.length; i++) {
        hashtags.add(toneHashes[i]);
    }
    
    // Add topic-based hashtags (3-4)
    const keywords = extractKeywords(topic);
    keywords.forEach(keyword => {
        hashtags.add(`#${keyword}`);
    });
    
    // Add some general engagement hashtags
    hashtags.add('#trending');
    hashtags.add('#explore');
    
    // Ensure we have 6-12 hashtags
    const hashtagArray = Array.from(hashtags);
    return hashtagArray.slice(0, 12);
}

/**
 * Generate hashtags for Instagram
 * 8-15 hashtags with broader reach strategy
 */
function generateInstagramHashtags(topic, tone) {
    const hashtags = new Set();
    
    // Add platform hashtags (3-4)
    hashtags.add('#reels');
    hashtags.add('#reelsinstagram');
    hashtags.add('#explore');
    hashtags.add('#explorepage');
    
    // Add tone-specific hashtags (3-4)
    const toneHashes = toneHashtags[tone] || toneHashtags.default;
    for (let i = 0; i < 4 && i < toneHashes.length; i++) {
        hashtags.add(toneHashes[i]);
    }
    
    // Add topic-based hashtags (4-5)
    const keywords = extractKeywords(topic);
    keywords.forEach(keyword => {
        hashtags.add(`#${keyword}`);
        // Add variations
        hashtags.add(`#${keyword}gram`);
        hashtags.add(`#${keyword}daily`);
    });
    
    // Add engagement hashtags
    hashtags.add('#viral');
    hashtags.add('#trending');
    hashtags.add('#instagood');
    hashtags.add('#instadaily');
    
    // Ensure we have 8-15 hashtags
    const hashtagArray = Array.from(hashtags);
    return hashtagArray.slice(0, 15);
}

/**
 * Generate hashtags for YouTube Shorts
 * Fewer hashtags (4-7) - YouTube recommends minimal hashtags
 */
function generateYouTubeHashtags(topic, tone) {
    const hashtags = new Set();
    
    // Add platform hashtags (2)
    hashtags.add('#shorts');
    hashtags.add('#youtubeshorts');
    
    // Add tone-specific hashtags (1-2)
    const toneHashes = toneHashtags[tone] || toneHashtags.default;
    for (let i = 0; i < 2 && i < toneHashes.length; i++) {
        hashtags.add(toneHashes[i]);
    }
    
    // Add topic-based hashtags (2-3)
    const keywords = extractKeywords(topic);
    keywords.slice(0, 2).forEach(keyword => {
        hashtags.add(`#${keyword}`);
    });
    
    // Add one engagement hashtag
    hashtags.add('#viral');
    
    // Ensure we have 4-7 hashtags
    const hashtagArray = Array.from(hashtags);
    return hashtagArray.slice(0, 7);
}

/**
 * Generate hashtags for a given platform
 * @param {string} topic - The video topic
 * @param {string} tone - The desired tone
 * @param {string} platform - Target platform (tiktok, instagram, youtube)
 * @returns {Array<string>} Array of hashtags
 */
function generateHashtags(topic, tone, platform) {
    logger.info(`Generating hashtags for ${platform}`, { topic, tone });
    
    switch (platform.toLowerCase()) {
        case 'tiktok':
            return generateTikTokHashtags(topic, tone);
        case 'instagram':
            return generateInstagramHashtags(topic, tone);
        case 'youtube':
            return generateYouTubeHashtags(topic, tone);
        default:
            throw new Error(`Unsupported platform: ${platform}`);
    }
}

module.exports = {
    generateHashtags
};
