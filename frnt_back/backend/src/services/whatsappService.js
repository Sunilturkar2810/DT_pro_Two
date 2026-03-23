import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const AISENSY_API_KEY = process.env.AISENSY_API_KEY;
const CAMPAIGN_NAME = process.env.AISENSY_CAMPAIGN_NAME;
const USER_NAME = process.env.AISENSY_USER_NAME;
const SOURCE = process.env.AISENSY_SOURCE || 'kesharia_rld';

/**
 * Send a WhatsApp message using AiSensy API
 * @param {string} to - Recipient phone number
 * @param {string} content - The final content from our Notification Templates
 * @param {object} options - Optional overrides for campaignName, etc.
 */
export const sendWhatsAppMessage = async (to, content, options = {}) => {
    try {
        const url = 'https://backend.aisensy.com/campaign/t1/api/v2';
        
        // AiSensy expects specific number format (e.g. 919876543210)
        const cleanTo = to.replace(/\D/g, '');

        // Sanitize content: AiSensy parameters cannot have newlines, tabs or 4+ spaces
        const sanitizedContent = content
            .replace(/[\r\n\t]/g, ' ') // Replace newlines/tabs with space
            .replace(/\s{4,}/g, ' ')  // Replace 4+ consecutive spaces with single space
            .trim();

        // We map our "content" (from templates) to the first parameter of the AiSensy campaign
        // The user's campaign "RLD3" might have a variable like "$FirstName" or similar.
        // If "content" is designed in our app, we can pass it as a param.
        const data = {
            apiKey: AISENSY_API_KEY,
            campaignName: options.campaignName || CAMPAIGN_NAME,
            destination: cleanTo,
            userName: USER_NAME,
            templateParams: [
                sanitizedContent // This maps to the first variable in the AiSensy template
            ],
            source: SOURCE,
            media: {},
            buttons: [],
            carouselCards: [],
            location: {},
            attributes: {},
            paramsFallbackValue: {}
        };

        const response = await axios.post(url, data, {
            headers: {
                'Content-Type': 'application/json',
            },
        });

        console.log('AiSensy WhatsApp message sent:', response.data);
        return response.data;
    } catch (error) {
        console.error('Error sending AiSensy WhatsApp message:', error.response?.data || error.message);
        throw error;
    }
};
