import { raiseTicket, getMyTickets, getAllTickets, updateTicketStatus, deleteTicket } from '../controllers/ticketController.js';

export default async function ticketRoutes(fastify, options) {
  // Create a new ticket
  fastify.post('/', {
    onRequest: [fastify.authenticate]
  }, raiseTicket);

  // Get my tickets
  fastify.get('/', {
    onRequest: [fastify.authenticate]
  }, getMyTickets);

  // Get all tickets (admin)
  fastify.get('/admin/all', {
    onRequest: [fastify.authenticate]
  }, getAllTickets);

  // Update ticket status (admin)
  fastify.patch('/:ticketId', {
    onRequest: [fastify.authenticate]
  }, updateTicketStatus);

  // Delete ticket (admin)
  fastify.delete('/:ticketId', {
    onRequest: [fastify.authenticate]
  }, deleteTicket);
}
