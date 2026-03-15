import { db } from '../db/index.js';
import { tickets, users } from '../db/schema.js';
import { eq, desc } from 'drizzle-orm';

// Create a new support ticket
export const raiseTicket = async (request, reply) => {
  try {
    const userId = request.user.id; // JWT uses 'id', not 'userId'
    const { title, description, category, subCategory, priority, screenshotUrls } = request.body;

    if (!title || !description || !category) {
      return reply.status(400).send({
        success: false,
        message: 'Title, description, and category are required'
      });
    }

    // Validate user exists
    const userRecord = await db
      .select()
      .from(users)
      .where(eq(users.userId, userId));

    if (!userRecord[0]) {
      return reply.status(401).send({
        success: false,
        message: 'User not found'
      });
    }

    const newTicket = await db.insert(tickets).values({
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      subCategory: (subCategory || 'Other').trim(),
      priority: priority || 'Medium',
      raisedBy: userId,
      screenshotUrls: screenshotUrls && Array.isArray(screenshotUrls) ? screenshotUrls : [],
    }).returning();

    return reply.status(201).send({
      success: true,
      message: 'Ticket raised successfully',
      ticket: newTicket[0]
    });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({
      success: false,
      message: error.message || 'Failed to raise ticket',
      error: process.env.NODE_ENV === 'development' ? error : undefined
    });
  }
};

// Get tickets raised by current user
export const getMyTickets = async (request, reply) => {
  try {
    const userId = request.user.id; // JWT uses 'id', not 'userId'

    const myTickets = await db
      .select()
      .from(tickets)
      .where(eq(tickets.raisedBy, userId))
      .orderBy(desc(tickets.createdAt));

    // Enrich with user info
    const enrichedTickets = await Promise.all(
      myTickets.map(async (ticket) => {
        const raiser = await db
          .select()
          .from(users)
          .where(eq(users.userId, ticket.raisedBy));
        
        return {
          ...ticket,
          raiserName: raiser[0] ? `${raiser[0].firstName} ${raiser[0].lastName}` : 'Unknown'
        };
      })
    );

    return reply.send({
      success: true,
      tickets: enrichedTickets
    });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({
      success: false,
      message: error.message || 'Failed to fetch tickets'
    });
  }
};

// Get all tickets (admin only)
export const getAllTickets = async (request, reply) => {
  try {
    const userId = request.user.id; // JWT uses 'id', not 'userId'

    // Check if user is admin
    const user = await db
      .select()
      .from(users)
      .where(eq(users.userId, userId));

    if (!user[0] || (user[0].role && user[0].role.toLowerCase() !== 'admin')) {
      return reply.status(403).send({
        success: false,
        message: 'Unauthorized: Admin access required'
      });
    }

    const allTickets = await db
      .select()
      .from(tickets)
      .orderBy(desc(tickets.createdAt));

    // Enrich with user info
    const enrichedTickets = await Promise.all(
      allTickets.map(async (ticket) => {
        const raiser = await db
          .select()
          .from(users)
          .where(eq(users.userId, ticket.raisedBy));
        
        const assignee = ticket.assignedTo
          ? (await db
              .select()
              .from(users)
              .where(eq(users.userId, ticket.assignedTo)))[0]
          : null;

        return {
          ...ticket,
          raiserName: raiser[0] ? `${raiser[0].firstName} ${raiser[0].lastName}` : 'Unknown',
          assigneeName: assignee ? `${assignee.firstName} ${assignee.lastName}` : null
        };
      })
    );

    return reply.send({
      success: true,
      tickets: enrichedTickets
    });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({
      success: false,
      message: error.message || 'Failed to fetch tickets'
    });
  }
};

// Update ticket status (admin only)
export const updateTicketStatus = async (request, reply) => {
  try {
    const userId = request.user.id; // JWT uses 'id', not 'userId'
    const { ticketId, status, assignedTo } = request.body;

    // Check if user is admin
    const user = await db
      .select()
      .from(users)
      .where(eq(users.userId, userId));

    if (!user[0] || (user[0].role && user[0].role.toLowerCase() !== 'admin')) {
      return reply.status(403).send({
        success: false,
        message: 'Unauthorized: Admin access required'
      });
    }

    if (!ticketId || !status) {
      return reply.status(400).send({
        success: false,
        message: 'Ticket ID and status are required'
      });
    }

    const updateData = { status };
    if (assignedTo) {
      updateData.assignedTo = assignedTo;
    }

    const updatedTicket = await db
      .update(tickets)
      .set(updateData)
      .where(eq(tickets.id, ticketId))
      .returning();

    return reply.send({
      success: true,
      message: 'Ticket updated successfully',
      ticket: updatedTicket[0]
    });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({
      success: false,
      message: error.message || 'Failed to update ticket'
    });
  }
};

// Delete ticket (admin only)
export const deleteTicket = async (request, reply) => {
  try {
    const userId = request.user.id; // JWT uses 'id', not 'userId'
    const { ticketId } = request.params;

    // Check if user is admin
    const user = await db
      .select()
      .from(users)
      .where(eq(users.userId, userId));

    if (!user[0] || (user[0].role && user[0].role.toLowerCase() !== 'admin')) {
      return reply.status(403).send({
        success: false,
        message: 'Unauthorized: Admin access required'
      });
    }

    if (!ticketId) {
      return reply.status(400).send({
        success: false,
        message: 'Ticket ID is required'
      });
    }

    const deletedTicket = await db
      .delete(tickets)
      .where(eq(tickets.id, ticketId))
      .returning();

    return reply.send({
      success: true,
      message: 'Ticket deleted successfully',
      ticket: deletedTicket[0]
    });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({
      success: false,
      message: error.message || 'Failed to delete ticket'
    });
  }
};
