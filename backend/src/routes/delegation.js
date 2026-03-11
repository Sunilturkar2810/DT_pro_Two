import {
    createDelegation,
    createDelegationTemplate,
    getDelegations,
    getDelegationById,
    updateDelegation,
    deleteDelegation,
    addRemark,
    updateRemark,
    deleteRemark,
    uploadFile,
    toggleChecklistStatus
} from '../controllers/delegation.controller.js';

export default async function delegationRoutes(fastify, options) {
    fastify.post('/', createDelegation);
    fastify.post('/templates', createDelegationTemplate);
    fastify.get('/', getDelegations);
    fastify.post('/upload', uploadFile);
    fastify.get('/:id', getDelegationById);
    fastify.patch('/:id', updateDelegation);
    fastify.delete('/:id', deleteDelegation);
    fastify.post('/:id/remarks', addRemark);
    fastify.patch('/:id/remarks/:remarkId', updateRemark);
    fastify.delete('/:id/remarks/:remarkId', deleteRemark);
    fastify.patch('/:delegationId/checklist/:checklistId', toggleChecklistStatus);
}
