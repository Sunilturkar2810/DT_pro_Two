import { db } from '../db/index.js';
import { groups, groupMembers, users } from '../db/schema.js';
import { eq, sql } from 'drizzle-orm';

async function groupRoutes(app, options) {
  // Create group
  app.post('/', {
    onRequest: [app.authenticate]
  }, async (request, reply) => {
    try {
      console.log('Received Group Create Request:', request.body);
      const { name, description, imageUrl, members, memberIds } = request.body;
      const groupMembersList = members || memberIds || [];
      
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

      console.log('Group Created:', newGroup);

      if (groupMembersList && groupMembersList.length > 0) {
        const memberEntries = groupMembersList.map(userId => ({
          groupId: newGroup.groupId,
          userId,
          addedBy: creatorId
        }));
        console.log('Inserting members:', memberEntries);
        await db.insert(groupMembers).values(memberEntries);
      }

      return { 
        success: true, 
        data: { 
          ...newGroup, 
          id: newGroup.groupId, 
          memberCount: groupMembersList.length 
        } 
      };
    } catch (error) {
      console.error('Error creating group:', error);
      request.log.error('Error creating group:', error);
      reply.status(500).send({ success: false, message: error.message });
    }
  });

  // Get all groups
  app.get('/', {
    onRequest: [app.authenticate]
  }, async (request, reply) => {
    try {
      const allGroups = await db.select({
        id: groups.groupId,
        name: groups.name,
        description: groups.description,
        imageUrl: groups.imageUrl,
        createdBy: groups.createdBy,
        createdAt: groups.createdAt,
        updatedAt: groups.updatedAt,
        memberCount: sql`count(${groupMembers.userId})::int`
      })
      .from(groups)
      .leftJoin(groupMembers, eq(groups.groupId, groupMembers.groupId))
      .groupBy(groups.groupId);
      return { success: true, data: allGroups };
    } catch (error) {
      reply.status(500).send({ success: false, message: error.message });
    }
  });

  // Get single group
  app.get('/:id', {
    onRequest: [app.authenticate]
  }, async (request, reply) => {
    try {
      const { id } = request.params;
      const [group] = await db.select({
        id: groups.groupId,
        name: groups.name,
        description: groups.description,
        imageUrl: groups.imageUrl,
        createdBy: groups.createdBy,
        createdAt: groups.createdAt,
        updatedAt: groups.updatedAt,
        memberCount: sql`count(${groupMembers.userId})::int`
      })
      .from(groups)
      .leftJoin(groupMembers, eq(groups.groupId, groupMembers.groupId))
      .where(eq(groups.groupId, id))
      .groupBy(groups.groupId);
      
      if (!group) return reply.status(404).send({ success: false, message: 'Group not found' });

      // Fetch member details
      const membersData = await db.select({
        userId: users.userId,
        firstName: users.firstName,
        lastName: users.lastName,
        designation: users.designation,
        department: users.department,
        role: users.role,
        workEmail: users.workEmail,
        profilePhotoUrl: users.profilePhotoUrl
      })
      .from(groupMembers)
      .innerJoin(users, eq(groupMembers.userId, users.userId))
      .where(eq(groupMembers.groupId, id));

      group.members = membersData;
      
      return { success: true, data: group };
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

  // Mock tasks for a group
  app.get('/:id/tasks', {
    onRequest: [app.authenticate]
  }, async (request, reply) => {
    return { success: true, data: [] };
  });
}

export default groupRoutes;
