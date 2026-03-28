import { useState, useEffect } from 'react';
import authService from '../services/auth.service';
import roleService from '../services/roleService';

/**
 * Returns the permission object for the currently logged-in user's role.
 *
 * Usage:
 *   const { can, canOnOwn, userId, isAdmin, loading } = usePermissions();
 *
 *   can('taskTemplate', 'delete')            → true/false (role-level)
 *   canOnOwn('taskTemplate', 'delete', ownerId) → true if user owns item OR has role permission
 */
const usePermissions = () => {
    const [permissions, setPermissions] = useState(null);
    const [roleName, setRoleName]       = useState('');
    const [userId, setUserId]           = useState(null);
    const [loading, setLoading]         = useState(true);

    useEffect(() => {
        const load = async () => {
            try {
                const stored = authService.getCurrentUser();
                // Support both { user: { role, userId } } and { role, userId } shapes
                const role = stored?.user?.role || stored?.role || '';
                const uid  = stored?.user?.userId || stored?.user?.id || stored?.userId || stored?.id || null;
                setRoleName(role.toUpperCase());
                setUserId(uid);

                // SUPERADMIN / ADMIN have all permissions by default
                if (['SUPERADMIN', 'ADMIN'].includes(role.toUpperCase())) {
                    setPermissions('ADMIN');
                    setLoading(false);
                    return;
                }

                // Fetch the role list and find matching role's permissions
                const res = await roleService.getRoles();
                const roles = res.data || res;
                const matched = roles.find(r => r.name?.toUpperCase() === role.toUpperCase());
                setPermissions(matched?.permissions || null);
            } catch (err) {
                console.error('usePermissions: failed to load', err);
                setPermissions(null);
            } finally {
                setLoading(false);
            }
        };
        load();
    }, []);

    const isAdmin = roleName === 'ADMIN' || roleName === 'SUPERADMIN' || permissions === 'ADMIN';

    /**
     * can('taskTemplate', 'delete')
     * Returns:
     *   - true          for admin or when the boolean permission is true
     *   - false         when the permission is false / 'None' / undefined
     *   - string value  for select-type permissions ('All', 'Assigned', etc.)
     */
    const can = (category, action) => {
        if (isAdmin) return true;
        if (!permissions) return false;
        const val = permissions?.[category]?.[action];
        if (val === undefined || val === null) return false;
        if (typeof val === 'boolean') return val;
        // String-type: 'None' means no permission
        if (val === 'None') return false;
        return val; // e.g. 'All', 'Assigned', 'My Team + Assigned'
    };

    /**
     * canOnOwn('taskTemplate', 'edit', template.createdBy)
     * Returns true if:
     *  - The user has the role-level permission, OR
     *  - The item was created by this user (ownership exception)
     */
    const canOnOwn = (category, action, ownerId) => {
        if (can(category, action)) return true;
        // Ownership fallback: convert to string to avoid type mismatch
        if (userId && ownerId && String(userId) === String(ownerId)) return true;
        return false;
    };

    return { can, canOnOwn, isAdmin, roleName, userId, loading };
};

export default usePermissions;
