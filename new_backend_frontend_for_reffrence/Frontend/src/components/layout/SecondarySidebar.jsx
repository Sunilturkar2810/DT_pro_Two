import React, { useState, useEffect } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { 
    LayoutGrid, CheckSquare, ChevronRight, CheckCircle2, 
    ClipboardList, Trash2, Calendar, Settings, Folder, 
    Tag, Bell, Users, Search, Plus, Globe, ChevronLeft,
    Save, Activity, Shield
} from 'lucide-react';
import teamService from '../../services/teamService';
import delegationService from '../../services/delegationService';
import CreateGroupModal from '../groups/CreateGroupModal';

const SecondarySidebar = ({ activeModule, isCollapsed, onToggle }) => {
    const location = useLocation();
    const [groups, setGroups] = useState([]);
    const [teams, setTeams] = useState([]);
    const [loading, setLoading] = useState(false);
    const [showCreateGroup, setShowCreateGroup] = useState(false);

    useEffect(() => {
        if (activeModule === 'groups') {
            fetchGroups();
        } else if (activeModule === 'team') {
            fetchTeams();
        }
    }, [activeModule]);

    const fetchGroups = async () => {
        try {
            const res = await delegationService.getGroups();
            setGroups(res.data || []);
        } catch (err) {
            console.error('Error fetching groups:', err);
        }
    };
    
    // ... rest of the component
    
    // (Inside renderContent, for groups case)
    // <button onClick={() => setShowCreateGroup(true)} ...>
    // ...
    
    // (At the bottom of return)
    // <CreateGroupModal isOpen={showCreateGroup} onClose={() => setShowCreateGroup(false)} onSuccess={fetchGroups} />

    const fetchTeams = async () => {
        try {
            setLoading(true);
            const data = await teamService.getTeams();
            setTeams(data);
        } catch (error) {
            console.error('Error fetching teams:', error);
        } finally {
            setLoading(false);
        }
    };

    const renderContent = () => {
        switch (activeModule) {
            case 'tasks':
                return (
                    <div className="flex flex-col py-6 px-3 gap-1">
                        <h3 className="px-4 text-[11px] font-bold text-slate-400 uppercase tracking-wider mb-4">Task Management</h3>
                        {[
                            { label: 'Dashboard', path: '/dashboard', icon: LayoutGrid },
                            { label: 'My Tasks', path: '/my-tasks', icon: CheckSquare },
                            { label: 'Delegated Tasks', path: '/delegated-tasks', icon: ChevronRight },
                            { label: 'Subscribed Tasks', path: '/in-loop-tasks', icon: CheckCircle2 },
                        ].map((item, idx) => (
                            <NavLink
                                key={`group1-${idx}`}
                                to={item.path}
                                className={({ isActive }) => `flex items-center gap-3 px-4 py-3 rounded-xl text-[14px] font-medium transition-all ${
                                    isActive ? 'bg-emerald-50 text-emerald-600 shadow-sm' : 'text-slate-600 hover:bg-slate-50'
                                }`}
                            >
                                {({ isActive }) => (
                                    <>
                                        <item.icon size={18} strokeWidth={isActive ? 2.5 : 2} />
                                        {item.label}
                                    </>
                                )}
                            </NavLink>
                        ))}
                        
                        <div className="h-px bg-slate-200 dark:bg-slate-800/50 my-2 mx-4" />
                        
                        {[
                            { label: 'All Tasks', path: '/all-tasks', icon: ClipboardList },
                            { label: 'Deleted Tasks', path: '/deleted-tasks', icon: Trash2 },
                        ].map((item, idx) => (
                            <NavLink
                                key={`group2-${idx}`}
                                to={item.path}
                                className={({ isActive }) => `flex items-center gap-3 px-4 py-3 rounded-xl text-[14px] font-medium transition-all ${
                                    isActive ? 'bg-emerald-50 text-emerald-600 shadow-sm' : 'text-slate-600 hover:bg-slate-50'
                                }`}
                            >
                                {({ isActive }) => (
                                    <>
                                        <item.icon size={18} strokeWidth={isActive ? 2.5 : 2} />
                                        {item.label}
                                    </>
                                )}
                            </NavLink>
                        ))}

                        <div className="h-px bg-slate-200 dark:bg-slate-800/50 my-2 mx-4" />
                        
                        {[
                            { label: 'Task Templates', path: '/task-templates', icon: Save },
                            { label: 'Activities', path: '/activities', icon: Activity },
                            { label: 'Holidays', path: '/holidays', icon: Calendar },
                        ].map((item, idx) => (
                            <NavLink
                                key={`group3-${idx}`}
                                to={item.path}
                                className={({ isActive }) => `flex items-center gap-3 px-4 py-3 rounded-xl text-[14px] font-medium transition-all ${
                                    isActive ? 'bg-emerald-50 text-emerald-600 shadow-sm' : 'text-slate-600 hover:bg-slate-50'
                                }`}
                            >
                                {({ isActive }) => (
                                    <>
                                        <item.icon size={18} strokeWidth={isActive ? 2.5 : 2} />
                                        {item.label}
                                    </>
                                )}
                            </NavLink>
                        ))}
                    </div>
                );
            case 'groups':
                return (
                    <div className="flex flex-col py-4 px-3 gap-4">
                        <div className="flex items-center gap-2 px-1">
                            <div className="relative flex-1">
                                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={14} />
                                <input 
                                    type="text" 
                                    placeholder="Search Groups" 
                                    className="w-full pl-9 pr-3 py-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-[13px] outline-none focus:ring-2 focus:ring-emerald-500/20"
                                />
                            </div>
                            <button 
                                onClick={() => setShowCreateGroup(true)}
                                className="w-9 h-9 bg-[#00d094] text-white rounded-lg flex items-center justify-center hover:bg-[#00ba84] transition-colors shrink-0 shadow-sm"
                            >
                                <Plus size={18} strokeWidth={3} />
                            </button>
                        </div>

                        <div className="flex flex-col gap-1">
                            {groups.map(group => (
                                <NavLink
                                    key={group.groupId}
                                    to={`/groups/${group.groupId}`}
                                    className={({ isActive }) => `flex items-center gap-3 px-3 py-2.5 rounded-xl text-[14px] font-bold transition-all ${
                                        isActive ? 'bg-[#c5f2e0] text-slate-800 shadow-sm' : 'text-slate-600 hover:bg-slate-50'
                                    }`}
                                >
                                    <div className="w-8 h-8 rounded-full bg-white dark:bg-slate-800 flex items-center justify-center shadow-sm border border-slate-100 dark:border-slate-700 shrink-0">
                                        <Users size={16} className="text-slate-500" />
                                    </div>
                                    <span className="truncate">{group.name}</span>
                                </NavLink>
                            ))}
                        </div>
                    </div>
                );
            case 'team':
                return (
                    <div className="flex flex-col py-6 px-4 gap-6">
                        <div className="flex flex-col gap-1">
                            <h3 className="px-2 text-[11px] font-bold text-slate-400 uppercase tracking-wider mb-4">My Team</h3>
                            {teams.length > 0 ? teams.map(team => (
                                <NavLink
                                    key={team.teamId}
                                    to={`/my-team/${team.teamId}`}
                                    className={({ isActive }) => `flex items-center gap-3 px-4 py-3 rounded-xl text-[14px] font-medium transition-all ${
                                        isActive ? 'bg-emerald-50 text-emerald-600 shadow-sm' : 'text-slate-600 hover:bg-slate-50'
                                    }`}
                                >
                                    <div className={`w-2 h-2 rounded-full ${location.pathname.includes(team.teamId) ? 'bg-emerald-500' : 'bg-slate-300'}`} />
                                    {team.name}
                                </NavLink>
                            )) : (
                                <p className="px-2 text-sm text-slate-400 italic">No teams created yet</p>
                            )}
                        </div>
                    </div>
                );
            case 'settings': {
                const storedUser = JSON.parse(localStorage.getItem('user'));
                const userRole = storedUser?.user?.role || storedUser?.role;
                const isAdmin = userRole === 'ADMIN' || userRole === 'SUPERADMIN';
                
                const settingsLinks = [
                    { label: 'General', path: '/settings/general', icon: Settings },
                    { label: 'Roles & Permissions', path: '/settings/roles', icon: Users, restricted: true },
                    { label: 'Notifications', path: '/settings/notifications', icon: Bell },
                    { label: 'Security', path: '/settings/security', icon: Shield },
                    { label: 'Categories', path: '/settings/categories', icon: Folder },
                    { label: 'Tags', path: '/settings/tags', icon: Tag },
                    { label: 'Holidays', path: '/holidays', icon: Calendar },
                ];

                const filteredLinks = settingsLinks.filter(link => !link.restricted || isAdmin);

                return (
                    <div className="flex flex-col py-6 px-3 gap-1">
                        <h3 className="px-4 text-[11px] font-bold text-slate-400 uppercase tracking-wider mb-4">System Settings</h3>
                        {filteredLinks.map((item, idx) => (
                            <NavLink
                                key={idx}
                                to={item.path}
                                className={({ isActive }) => `flex items-center gap-3 px-4 py-3 rounded-xl text-[14px] font-medium transition-all ${
                                    isActive ? 'bg-emerald-50 text-emerald-600 shadow-sm' : 'text-slate-600 hover:bg-slate-50'
                                }`}
                            >
                                <item.icon size={18} />
                                {item.label}
                            </NavLink>
                        ))}
                    </div>
                );
            }
            default:
                return null;
        }
    };

    return (
        <aside 
            className={`relative bg-slate-50/80 dark:bg-[#1a1f26] border-r border-slate-200 dark:border-slate-800 h-full transition-all duration-300 ease-in-out group overflow-hidden ${
                isCollapsed ? 'w-0 border-none' : 'w-64 max-w-[calc(100vw-80px)]'
            }`}
        >
            <div className={`h-full overflow-y-auto overflow-x-hidden scrollbar-thin transition-opacity duration-200 ${
                isCollapsed ? 'opacity-0' : 'opacity-100'
            }`}>
                {renderContent()}
            </div>
            <CreateGroupModal 
                isOpen={showCreateGroup} 
                onClose={() => setShowCreateGroup(false)} 
                onSuccess={fetchGroups} 
            />
        </aside>
    );
};

export default SecondarySidebar;
