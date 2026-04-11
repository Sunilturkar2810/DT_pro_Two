import { db } from '../db/index.js';
import { groups, groupMembers, users, delegations, checklistMaster } from '../db/schema.js';
import { eq, or } from 'drizzle-orm';
import { logActivity } from '../utils/activityLogger.js';

async function groupRoutes(app, options) {
  // Create group
  app.post('/create', {
    onRequest: [app.authenticate]
  }, async (request, reply) => {
    try {
      console.log('Received Group Create Request:', request.body);
      const { name, description, members, imageUrl } = request.body;

      // Use ID from JWT if not provided in body
      const creatorId = request.body.createdBy || request.user.id;

      if (!creatorId) {
        throw new Error('User ID is required (token missing or invalid)');
      }

      const [newGroup] = await db.insert(groups).values({
        name,
        description,
        imageUrl,
        createdBy: creatorId
      }).returning();

      console.log('Group Created:', newGroup);

      if (members && members.length > 0) {
        const memberEntries = members.map(userId => ({
          groupId: newGroup.groupId,
          userId,
          addedBy: creatorId
        }));
        console.log('Inserting members:', memberEntries);
        await db.insert(groupMembers).values(memberEntries);
      }

      // Log activity
      await logActivity({
        type: 'group_created',
        title: name,
        description: `New group "${name}" was created`,
        userId: creatorId,
        relatedId: newGroup.groupId,
        relatedType: 'group'
      });

      return { success: true, data: newGroup };
    } catch (error) {
      console.error('Error creating group:', error);
      request.log.error('Error creating group:', error);
      reply.status(500).send({ success: false, message: error.message });
    }
  });

  // Get all groups
  app.get('/list', {
    onRequest: [app.authenticate]
  }, async (request, reply) => {
    try {
      let allGroups = [];
      if (['ADMIN', 'SUPERADMIN', 'MANAGER'].includes(request.user?.role)) {
        allGroups = await db.select().from(groups);
      } else {
        // Regular users and Managers only see groups they are part of OR groups they created
        allGroups = await db.select({
          groupId: groups.groupId,
          name: groups.name,
          description: groups.description,
          imageUrl: groups.imageUrl,
          createdBy: groups.createdBy,
          createdAt: groups.createdAt,
          updatedAt: groups.updatedAt
        })
          .from(groups)
          .leftJoin(groupMembers, eq(groups.groupId, groupMembers.groupId))
          .where(
            or(
              eq(groupMembers.userId, request.user.id),
              eq(groups.createdBy, request.user.id)
            )
          );

        // Deduplicate just in case 
        const uniqueGroups = [];
        const seen = new Set();
        for (const g of allGroups) {
          if (!seen.has(g.groupId)) {
            seen.add(g.groupId);
            uniqueGroups.push(g);
          }
        }
        allGroups = uniqueGroups;
      }
      return { success: true, data: allGroups };
    } catch (error) {
      reply.status(500).send({ success: false, message: error.message });
    }
  });

  // Get group members with detailed info
  app.get('/:id/members', {
    onRequest: [app.authenticate]
  }, async (request, reply) => {
    try {
      const { id } = request.params;
      const membersData = await db.select({
        userId: users.userId,
        firstName: users.firstName,
        lastName: users.lastName,
        email: users.workEmail,
        workEmail: users.workEmail,
        designation: users.designation,
        department: users.department,
        profilePhotoUrl: users.profilePhotoUrl
      })
        .from(groupMembers)
        .innerJoin(users, eq(groupMembers.userId, users.userId))
        .where(eq(groupMembers.groupId, id));

      return { success: true, data: membersData };
    } catch (error) {
      reply.status(500).send({ success: false, message: error.message });
    }
  });
  // Get group by ID
  app.get('/:id', {
    onRequest: [app.authenticate]
  }, async (request, reply) => {
    try {
      const { id } = request.params;
      const [group] = await db.select().from(groups).where(eq(groups.groupId, id));
      if (!group) {
        return reply.status(404).send({ success: false, message: 'Group not found' });
      }
      return { success: true, data: group };
    } catch (error) {
      reply.status(500).send({ success: false, message: error.message });
    }
  });

  // Update group
  app.patch('/:id/update', {
    onRequest: [app.authenticate]
  }, async (request, reply) => {
    try {
      const { id } = request.params;
      const { name, description, members, imageUrl } = request.body;
      const userId = request.user.id;

      // Update basic info
      await db.update(groups)
        .set({ name, description, imageUrl, updatedAt: new Date() })
        .where(eq(groups.groupId, id));

      // Handle members (simple clear and re-add)
      if (members && Array.isArray(members)) {
        await db.delete(groupMembers).where(eq(groupMembers.groupId, id));
        if (members.length > 0) {
          const memberEntries = members.map(uid => ({
            groupId: id,
            userId: uid,
            addedBy: userId
          }));
          await db.insert(groupMembers).values(memberEntries);
        }
      }

      // Log activity
      await logActivity({
        type: 'group_updated',
        title: name || 'Group Updated',
        description: `Group details were updated`,
        userId: userId,
        relatedId: id,
        relatedType: 'group'
      });

      return { success: true, message: 'Group updated successfully' };
    } catch (error) {
      reply.status(500).send({ success: false, message: error.message });
    }
  });

  // Delete group
  app.delete('/:id', {
    onRequest: [app.authenticate]
  }, async (request, reply) => {
    try {
      const { id } = request.params;
      const userId = request.user.id;
      const userRole = request.user.role;

      // Check if group exists and who created it
      const [group] = await db.select().from(groups).where(eq(groups.groupId, id));
      
      if (!group) {
        return reply.status(404).send({ success: false, message: 'Group not found' });
      }

      // Permission check: Creator or Superadmin
      if (group.createdBy !== userId && userRole !== 'SUPERADMIN') {
        return reply.status(403).send({ success: false, message: 'Only the group creator or a superadmin can delete this group' });
      }

      // 1. Delete group members
      await db.delete(groupMembers).where(eq(groupMembers.groupId, id));

      // 2. Clear groupId from delegations (tasks) and checklistMaster
      // We don't delete the tasks, just remove the group association
      await db.update(delegations)
        .set({ groupId: null })
        .where(eq(delegations.groupId, id));

      await db.update(checklistMaster)
        .set({ groupId: null })
        .where(eq(checklistMaster.groupId, id));

      // 3. Delete the group
      await db.delete(groups).where(eq(groups.groupId, id));

      // Log activity
      await logActivity({
        type: 'group_deleted',
        title: group.name,
        description: `Group "${group.name}" was deleted by ${request.user.firstName}`,
        userId: userId,
        relatedId: id,
        relatedType: 'group'
      });

      return { success: true, message: 'Group deleted successfully' };
    } catch (error) {
      console.error('Error deleting group:', error);
      reply.status(500).send({ success: false, message: error.message });
    }
  });
}

export default groupRoutes;
