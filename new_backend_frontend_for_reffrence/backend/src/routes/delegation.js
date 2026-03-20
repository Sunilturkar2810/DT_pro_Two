import {
    createDelegation,
    createDelegationTemplate,
    getDelegations,
    getDelegationById,
    updateDelegation,
    deleteDelegation,
    getDeletedDelegations,
    restoreDelegation,
    addRemark,
    uploadFile
} from '../controllers/delegation.controller.js';

export default async function delegationRoutes(fastify, options) {
    fastify.post('/', createDelegation);
    fastify.post('/templates', createDelegationTemplate);
    fastify.get('/', getDelegations);
    fastify.post('/upload', uploadFile);
    fastify.get('/deleted', getDeletedDelegations);          // admin: get soft-deleted tasks
    fastify.get('/:id', getDelegationById);
    fastify.patch('/:id', updateDelegation);
    fastify.delete('/:id', deleteDelegation);               // now soft-deletes
    fastify.patch('/:id/restore', restoreDelegation);       // admin: restore
    fastify.post('/:id/remarks', addRemark);
}
