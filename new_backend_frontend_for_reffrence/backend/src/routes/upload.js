import { uploadProfileImage } from '../controllers/uploadController.js';

export default async function uploadRoutes(fastify) {
    fastify.post('/profile-image', {
        preHandler: [fastify.authenticate],
        handler: uploadProfileImage
    });
}
