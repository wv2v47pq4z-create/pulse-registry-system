/**
 * SR-OS AutoPost Caption Generator
 * Generates platform-specific captions based on topic and tone
 */

const { logger } = require('../utils/logger');

/**
 * Generate tone-specific prefixes and styles
 */
const toneStyles = {
    hype: {
        hooks: ['🔥', '⚡', '💥', 'EPIC', 'INSANE', 'UNREAL'],
        styles: ['ALL CAPS', 'energy', 'excitement']
    },
    chill: {
        hooks: ['✨', '🌙', '💫', 'Vibes', 'Mood', 'Peaceful'],
        styles: ['lowercase', 'relaxed', 'calm']
    },
    educational: {
        hooks: ['📚', '💡', '🎓', 'Learn', 'Discover', 'Tips'],
        styles: ['clear', 'informative', 'structured']
    },
    cinematic: {
        hooks: ['🎬', '🎥', '✨', 'Watch', 'Experience', 'Journey'],
        styles: ['artistic', 'dramatic', 'storytelling']
    },
    raw: {
        hooks: ['Real', 'Raw', 'Honest', 'Unfiltered', 'Truth'],
        styles: ['authentic', 'unpolished', 'direct']
    },
    default: {
        hooks: ['Check this out', 'New video', 'Watch this'],
        styles: ['standard', 'neutral', 'balanced']
    }
};

/**
 * Generate caption for TikTok
 * Short hook (3-6 words) + 2-3 lines of caption
 */
function generateTikTokCaption(topic, tone) {
    const style = toneStyles[tone] || toneStyles.default;
    const hook = style.hooks[Math.floor(Math.random() * style.hooks.length)];
    
    let caption = '';
    
    if (tone === 'hype') {
        caption = `${hook} ${topic.toUpperCase()}!\n\nYou won't believe what happened! This is absolutely insane!\n\nTag someone who needs to see this! 👇`;
    } else if (tone === 'chill') {
        caption = `${hook} ${topic.toLowerCase()}\n\njust some good vibes for your feed\n\nrelax and enjoy ✨`;
    } else if (tone === 'educational') {
        caption = `${hook} ${topic}\n\nQuick tips you need to know about this. Swipe for more insights!\n\nSave this for later 📌`;
    } else if (tone === 'cinematic') {
        caption = `${hook} ${topic}\n\nA visual journey through an unforgettable moment.\n\nExperience it yourself ✨`;
    } else if (tone === 'raw') {
        caption = `${hook}: ${topic}\n\nNo filter, no BS. Just the real deal.\n\nThis is what actually happened.`;
    } else {
        caption = `${hook} - ${topic}\n\nCheck out this amazing content!\n\nLet me know what you think in the comments! 💬`;
    }
    
    return caption;
}

/**
 * Generate caption for Instagram Reels
 * 1-2 sentences + engaging CTA
 */
function generateInstagramCaption(topic, tone) {
    const style = toneStyles[tone] || toneStyles.default;
    const hook = style.hooks[Math.floor(Math.random() * style.hooks.length)];
    
    let caption = '';
    
    if (tone === 'hype') {
        caption = `${hook} ${topic.toUpperCase()}! This is the most incredible thing you'll see today. Drop a 🔥 if you agree!`;
    } else if (tone === 'chill') {
        caption = `${hook} ${topic.toLowerCase()} ✨ Sometimes you just need to slow down and appreciate moments like these. Double tap if you feel it 💫`;
    } else if (tone === 'educational') {
        caption = `${hook} Everything you need to know about ${topic}. Save this post for later and share it with someone who needs this information! 📚`;
    } else if (tone === 'cinematic') {
        caption = `${hook} Presenting: ${topic}. Every frame tells a story. Swipe through and immerse yourself in this visual experience. 🎬`;
    } else if (tone === 'raw') {
        caption = `${hook} ${topic} - no edits, no scripts, just authentic content. This is what real life looks like. Tag someone who keeps it real 💯`;
    } else {
        caption = `Check out this amazing content about ${topic}! Let me know your thoughts in the comments below. 💬`;
    }
    
    return caption;
}

/**
 * Generate caption for YouTube Shorts
 * Short title (≤45 chars) + 1-3 line description
 */
function generateYouTubeCaption(topic, tone) {
    const style = toneStyles[tone] || toneStyles.default;
    
    // Generate short title (≤45 chars)
    let title = '';
    if (tone === 'hype') {
        title = `${topic.toUpperCase().substring(0, 35)}! 🔥`;
    } else if (tone === 'chill') {
        title = `${topic.substring(0, 40)} ✨`;
    } else if (tone === 'educational') {
        title = `How to: ${topic.substring(0, 35)}`;
    } else if (tone === 'cinematic') {
        title = `${topic.substring(0, 38)} 🎬`;
    } else if (tone === 'raw') {
        title = `Real ${topic.substring(0, 38)}`;
    } else {
        title = topic.substring(0, 45);
    }
    
    // Ensure title is within limit
    title = title.substring(0, 45);
    
    // Generate description (1-3 lines)
    let description = '';
    if (tone === 'hype') {
        description = `${topic} - This is INSANE!\n\nYou won't believe what happens! Watch until the end!\n\nLike and subscribe for more! 🔥`;
    } else if (tone === 'chill') {
        description = `${topic}\n\nJust some good vibes for your day.\n\nRelax and enjoy ✨`;
    } else if (tone === 'educational') {
        description = `Learn about ${topic}\n\nQuick tips and insights you need to know.\n\nSubscribe for more educational content! 📚`;
    } else if (tone === 'cinematic') {
        description = `${topic} - A Visual Experience\n\nImmerse yourself in this journey.\n\nWatch in full screen for best experience 🎥`;
    } else if (tone === 'raw') {
        description = `${topic} - Unfiltered\n\nNo scripts, no edits, just real content.\n\nSubscribe for authentic videos 💯`;
    } else {
        description = `${topic}\n\nEnjoy this content and let me know what you think!\n\nLike and subscribe! 👍`;
    }
    
    return {
        title,
        description
    };
}

/**
 * Generate caption for a given platform
 * @param {string} topic - The video topic
 * @param {string} tone - The desired tone
 * @param {string} platform - Target platform (tiktok, instagram, youtube)
 * @returns {Object|string} Generated caption (object for YouTube with title/description, string for others)
 */
function generateCaption(topic, tone, platform) {
    logger.info(`Generating caption for ${platform}`, { topic, tone });
    
    switch (platform.toLowerCase()) {
        case 'tiktok':
            return generateTikTokCaption(topic, tone);
        case 'instagram':
            return generateInstagramCaption(topic, tone);
        case 'youtube':
            return generateYouTubeCaption(topic, tone);
        default:
            throw new Error(`Unsupported platform: ${platform}`);
    }
}

module.exports = {
    generateCaption
};
