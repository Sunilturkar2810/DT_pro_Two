import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const WHATSAPP_TOKEN = process.env.WHATSAPP_ACCESS_TOKEN;
const PHONE_NUMBER_ID = process.env.WHATSAPP_PHONE_NUMBER_ID;
const API_VERSION = 'v17.0';

/**
 * Send a WhatsApp message using Meta Cloud API
 * @param {string} to - Recipient phone number (with country code, e.g., "919876543210")
 * @param {string} message - Message text
 * @param {object} template - Optional template configuration { name, languageCode, components }
 */
export const sendWhatsAppMessage = async (to, message, template = null) => {
    try {
        const url = `https://graph.facebook.com/${API_VERSION}/${PHONE_NUMBER_ID}/messages`;
        
        const data = {
            messaging_product: 'whatsapp',
            to: to,
        };

        if (template) {
            data.type = 'template';
            data.template = {
                name: template.name,
                language: { code: template.languageCode || 'en_US' },
                components: template.components || []
            };
        } else {
            data.type = 'text';
            data.text = { body: message };
        }

        const response = await axios.post(url, data, {
            headers: {
                'Authorization': `Bearer ${WHATSAPP_TOKEN}`,
                'Content-Type': 'application/json',
            },
        });

        console.log('WhatsApp message sent:', response.data);
        return response.data;
    } catch (error) {
        console.error('Error sending WhatsApp message:', error.response?.data || error.message);
        throw error;
    }
};
