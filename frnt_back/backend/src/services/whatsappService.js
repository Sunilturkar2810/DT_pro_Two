import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const API_KEY = process.env.AISENSY_API_KEY;

/**
 * Trigger a WhatsApp Campaign via AiSensy/Veup API
 * @param {string} to - Recipient phone number (with country code, e.g., "919876543210")
 * @param {string} userName - Name of the user receiving the message
 * @param {string} campaignName - Name of the campaign created in the WABA dashboard
 * @param {Array<string>} templateParams - Array of parameters mapping to {{1}}, {{2}}, etc.
 */
export const sendWhatsAppCampaign = async (to, userName, campaignName, templateParams = []) => {
    try {
        // Veup is typically a whitelabel of AiSensy, using the standard AiSensy backend endpoint
        const url = 'https://backend.api-wa.co/campaign/veup/api/v2';
        
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
            apiKey: API_KEY,
            campaignName: campaignName,
            destination: to,
            userName: userName || 'User',
            templateParams: templateParams,
            source: process.env.AISENSY_SOURCE || 'kesharia_rld_app',
            media: {},
            buttons: [],
            carouselCards: [],
            location: {},
            attributes: {},
            paramsFallbackValue: {
                FirstName: "user"
            }
        };

        const response = await axios.post(url, data, {
            headers: {
                'Content-Type': 'application/json',
            },
        });

        console.log(`WhatsApp campaign '${campaignName}' triggered successfully to ${to}`);
        return response.data;
    } catch (error) {
        console.error('Error triggering WhatsApp campaign:', error.response?.data || error.message);
        return false;
    }
};
