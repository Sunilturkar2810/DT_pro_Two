import { useState, useEffect } from 'react';
import { Search, ChevronDown, MoreVertical, ShieldCheck, Plus, Loader2, UserPlus, Upload } from 'lucide-react';
import CreateTeamDrawer from '../components/team/CreateTeamDrawer';
import CreateMemberDrawer from '../components/team/CreateMemberDrawer';
import UpdateMemberDrawer from '../components/team/UpdateMemberDrawer';
import UpdateCredentialsModal from '../components/team/UpdateCredentialsModal';
import DeleteTasksModal from '../components/team/DeleteTasksModal';
import DeleteUserModal from '../components/team/DeleteUserModal';
import teamService from '../services/teamService';
import TaskCreationForm from '../components/delegation/TaskCreationForm';
import TaskTemplateForm from '../components/delegation/TaskTemplateForm';
import { useNavigate } from 'react-router-dom';

const MyTeam = () => {
    const [searchTerm, setSearchTerm] = useState('');
    const [roleFilter, setRoleFilter] = useState('All');
    const [managerFilter, setManagerFilter] = useState('All');
    const [accessFilter, setAccessFilter] = useState('All');
    const [showCreateModal, setShowCreateModal] = useState(false);
    const [showCreateMemberDrawer, setShowCreateMemberDrawer] = useState(false);
    const [showUpdateMemberDrawer, setShowUpdateMemberDrawer] = useState(false);
    const [showUpdateCredsModal, setShowUpdateCredsModal] = useState(false);
    const [showDeleteTasksModal, setShowDeleteTasksModal] = useState(false);
    const [showDeleteUserModal, setShowDeleteUserModal] = useState(false);
    const [selectedMember, setSelectedMember] = useState(null);
    const [showTaskForm, setShowTaskForm] = useState(false);
    const [showTaskTemplateForm, setShowTaskTemplateForm] = useState(false);
    const navigate = useNavigate();
    const [user, setUser] = useState(() => {
        const storedUser = localStorage.getItem('user');
        if (storedUser) {
            const parsed = JSON.parse(storedUser);
            return parsed.user || parsed;
        }
        return null;
    });

    const [members, setMembers] = useState([]);
    const [isLoading, setIsLoading] = useState(true);

    const isAdmin = ['ADMIN', 'SUPERADMIN'].includes(user?.role);
    const currentUserId = user?.userId || user?.id || user?._id;
    const showActionsColumn = isAdmin || members.some(m => m.reportingManagerId === currentUserId);

    useEffect(() => {
        fetchMembers();
    }, []);

    const fetchMembers = async () => {
        try {
            setIsLoading(true);
            const data = await teamService.getMyTeamMembers();
            setMembers(data);
        } catch (error) {
            console.error('Failed to fetch members:', error);
        } finally {
            setIsLoading(false);
        }
    };

    // Extract unique values for filters
    const uniqueRoles = ['All', ...new Set(members.map(m => m.role).filter(Boolean))];
    const uniqueManagers = ['All', ...new Set(members.map(m => m.manager).filter(Boolean))];
    const accessOptions = ['All', 'Task App', 'Leave App'];

    const filteredMembers = members.filter(member => {
        // Role-based filtering logic
        const matchesSearch = `${member.firstName} ${member.lastName}`.toLowerCase().includes(searchTerm.toLowerCase()) ||
            member.workEmail?.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesRole = roleFilter === 'All' || member.role === roleFilter;
        const matchesManager = managerFilter === 'All' || member.manager === managerFilter;
        let matchesAccess = true;
        if (accessFilter === 'Task App') matchesAccess = member.taskAccess !== false;
        if (accessFilter === 'Leave App') matchesAccess = member.leaveAccess !== false;

        // Show all members in the user's team (for all roles)
        return matchesSearch && matchesRole && matchesManager && matchesAccess;
    });

    const isPrivileged = user?.role?.toUpperCase() === 'SUPERADMIN' || user?.role?.toUpperCase() === 'ADMIN';
    const isManager = user?.role?.toUpperCase() === 'MANAGER';

    const getInitials = (firstName, lastName) => {
        return `${firstName?.charAt(0) || ''}${lastName?.charAt(0) || ''}`.toUpperCase();
    };

    const getAvatarBg = (role) => {
        switch (role?.toUpperCase()) {
            case 'ADMIN':
            case 'SUPERADMIN':
                return 'bg-pink-500';
            case 'MANAGER':
                return 'bg-sky-400';
            default:
                return 'bg-orange-400';
        }
    };

    const getRoleStyles = (role) => {
        switch (role) {
            case 'ADMIN':
            case 'SUPERADMIN':
                return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400';
            case 'MANAGER':
                return 'bg-sky-100 text-sky-700 dark:bg-sky-500/10 dark:text-sky-400';
            default:
                return 'bg-orange-100 text-orange-700 dark:bg-orange-500/10 dark:text-orange-400';
        }
    };

    return (
        <div className="bg-white dark:bg-[#12161b] min-h-screen p-6 lg:p-8 space-y-6 text-slate-900 dark:text-white">
            {/* Header / Filters Bar */}
            <div className="flex flex-wrap items-center gap-3">
                {isPrivileged && (
                    <>
                        <button
                            onClick={() => setShowCreateModal(true)}
                            className="flex items-center gap-2 px-5 py-2.5 bg-[#00d094] hover:bg-[#00ba84] text-white rounded-lg font-bold text-sm transition-all active:scale-95 shadow-sm"
                        >
                            <Plus size={18} /> Create New Team
                        </button>
                        <button
                            onClick={() => setShowCreateMemberDrawer(true)}
                            className="flex items-center gap-2 px-5 py-2.5 bg-[#00d094] hover:bg-[#00ba84] text-white rounded-lg font-bold text-sm transition-all active:scale-95 shadow-sm"
                        >
                            <UserPlus size={18} /> Add Member
                        </button>
                        <button
                            onClick={() => navigate('/add-user')}
                            className="flex items-center gap-2 px-5 py-2.5 bg-[#00d094] hover:bg-[#00ba84] text-white rounded-lg font-bold text-sm transition-all active:scale-95 shadow-sm"
                        >
                            <Upload size={18} /> Upload User
                        </button>
                    </>
                )}
                {isManager && (
                    <button
                        onClick={() => setShowCreateMemberDrawer(true)}
                        className="flex items-center gap-2 px-5 py-2.5 bg-[#00d094] hover:bg-[#00ba84] text-white rounded-lg font-bold text-sm transition-all active:scale-95 shadow-sm"
                    >
                        <UserPlus size={18} /> Add Member
                    </button>
                )}

                <div className="relative min-w-[120px]">
                    <select
                        value={roleFilter}
                        onChange={(e) => setRoleFilter(e.target.value)}
                        className="w-full h-11 bg-white dark:bg-slate-900 border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm text-slate-700 dark:text-slate-300 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500/50 appearance-none transition-all cursor-pointer font-medium min-w-30"
                    >
                        {uniqueRoles.map(role => (
                            <option key={role} value={role}>{role}</option>
                        ))}
                    </select>
                    <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                </div>

                <div className="relative min-w-[180px]">
                    <select
                        value={managerFilter}
                        onChange={(e) => setManagerFilter(e.target.value)}
                        className="w-full h-11 bg-white dark:bg-slate-900 border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm text-slate-700 dark:text-slate-300 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500/50 appearance-none transition-all cursor-pointer font-medium min-w-45"
                    >
                        <option value="All">Reporting Manager (All)</option>
                        {uniqueManagers.filter(m => m !== 'All').map(manager => (
                            <option key={manager} value={manager}>{manager}</option>
                        ))}
                    </select>
                    <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                </div>

                <div className="relative min-w-[200px] flex-1 max-w-sm">
                    <input
                        type="text"
                        placeholder="Search Team Member"
                        className="w-full h-11 bg-white dark:bg-slate-900 border border-gray-200 dark:border-slate-800 rounded-lg py-2 px-10 text-sm focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500/50 text-slate-700 dark:text-slate-200 transition-all font-medium min-w-50"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                    <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                </div>

                <div className="relative min-w-[160px]">
                    <select
                        value={accessFilter}
                        onChange={(e) => setAccessFilter(e.target.value)}
                        className="w-full h-11 bg-white dark:bg-slate-900 border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm text-slate-700 dark:text-slate-300 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500/50 appearance-none transition-all cursor-pointer font-medium min-w-40"
                    >
                        <option value="All">Access Type (All)</option>
                        <option value="Task App">Task App</option>
                        <option value="Leave App">Leave App</option>
                    </select>
                    <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                </div>
            </div>

            {/* Status Badges */}
            <div className="flex flex-wrap items-center justify-center gap-3">
                <div className="bg-[#b4f5e1] text-[#2c7a63] dark:bg-emerald-500/20 dark:text-emerald-400 px-5 py-1.5 rounded-full text-sm font-bold border border-[#a0decb] dark:border-emerald-500/30">
                    {members.length} Members
                </div>
                <div className="bg-[#cfeaff] text-[#2b6fb5] dark:bg-sky-500/20 dark:text-sky-400 px-5 py-1.5 rounded-full text-sm font-bold border border-[#b6daff] dark:border-sky-500/30">
                    {members.filter(m => m.taskAccess !== false).length}/{members.length} Task App
                </div>
                <div className="bg-[#cfeaff] text-[#2b6fb5] dark:bg-sky-500/20 dark:text-sky-400 px-5 py-1.5 rounded-full text-sm font-bold border border-[#b6daff] dark:border-sky-500/30">
                    {members.filter(m => m.leaveAccess !== false).length}/{members.length} Leave & Attendance App
                </div>
            </div>

            {/* Table Container */}
            <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm relative">
                <table className="w-full text-left border-collapse">
                    <thead>
                        <tr className="bg-[#00d094] text-white">
                            <th className="px-6 py-4 font-bold text-sm w-20 rounded-tl-2xl">Select</th>
                            <th className="px-6 py-4 font-bold text-sm">User</th>
                            <th className="px-6 py-4 font-bold text-sm">Mobile</th>
                            <th className="px-6 py-4 font-bold text-sm">Reports To</th>
                            <th className="px-6 py-4 font-bold text-sm">Team Name</th>
                            <th className="px-6 py-4 font-bold text-sm">Role</th>
                            {showActionsColumn && <th className="px-6 py-4 font-bold text-sm w-20 text-center rounded-tr-2xl">Actions</th>}
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                        {isLoading ? (
                            <tr>
                                <td colSpan={showActionsColumn ? 6 : 5} className="px-6 py-12 text-center text-emerald-500">
                                    <div className="flex items-center justify-center gap-2">
                                        <Loader2 className="animate-spin" size={24} />
                                        <span className="font-bold uppercase tracking-wider text-xs">Loading Team...</span>
                                    </div>
                                </td>
                            </tr>
                        ) : filteredMembers.length === 0 ? (
                            <tr>
                                <td colSpan={showActionsColumn ? 6 : 5} className="px-6 py-12 text-center text-slate-500 font-medium">
                                    No team members match your filters.
                                </td>
                            </tr>
                        ) : (
                            filteredMembers.map((member) => (
                                <tr key={member.userId} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/30 transition-colors group">
                                    <td className="px-6 py-4">
                                        <div className="flex items-center justify-center">
                                            <input type="checkbox" className="w-5 h-5 rounded border-slate-300 text-[#00d094] focus:ring-[#00d094] cursor-pointer" />
                                        </div>
                                    </td>
                                    <td className="px-6 py-4">
                                        <div className="flex items-center gap-3">
                                            <div className={`w-10 h-10 rounded-full ${getAvatarBg(member.role)} text-white flex items-center justify-center font-bold text-sm shadow-sm ring-2 ring-white dark:ring-slate-900`}>
                                                {getInitials(member.firstName, member.lastName)}
                                            </div>
                                            <div>
                                                <div className="font-bold text-slate-800 dark:text-slate-100 flex items-center gap-1.5 leading-tight">
                                                    {member.firstName} {member.lastName}
                                                    {member.isCore && <ShieldCheck size={14} className="text-[#00d094] fill-[#00d094]/10" />}
                                                </div>
                                                <div className="text-xs text-slate-400 font-medium">{member.workEmail}</div>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400 font-medium">
                                        {member.mobileNumber || 'N/A'}
                                    </td>
                                    <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400 font-medium">
                                        {(() => {
                                            if (member.reportingManagerId) {
                                                const mgr = members.find(m => m.userId === member.reportingManagerId);
                                                if (mgr) return mgr.firstName + ' ' + mgr.lastName;
                                            }
                                            return 'NA';
                                        })()}
                                    </td>
                                    <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400 font-medium">
                                        {member.teamName || 'N/A'}
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`px-3 py-1 rounded-lg text-xs font-bold leading-none ${getRoleStyles(member.role)}`}>
                                            {member.role}
                                        </span>
                                    </td>
                                    {showActionsColumn && (
                                        <td className="px-6 py-4 text-center relative group/actions">
                                            {(isAdmin || member.reportingManagerId === currentUserId) ? (
                                                <>
                                                    <button className="p-2 text-slate-400 hover:text-[#00d094] hover:bg-[#00d094]/10 rounded-lg transition-all focus:outline-none">
                                                        <MoreVertical size={18} />
                                                    </button>
                                                    
                                                    {/* Dropdown Menu */}
                                                    <div className="hidden group-hover/actions:block absolute right-full top-0 mr-2 w-52 bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-800 rounded-xl shadow-2xl z-20 py-1 text-left">
                                                        <button 
                                                            onClick={() => { setSelectedMember(member); setShowUpdateMemberDrawer(true); }}
                                                            className="w-full px-4 py-2.5 text-sm text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-700 flex items-center justify-between group/item font-medium"
                                                        >
                                                            Edit <span className="opacity-0 group-hover/item:opacity-100 text-xs">✏️</span>
                                                        </button>
                                                        <button 
                                                            onClick={() => { setSelectedMember(member); setShowUpdateCredsModal(true); }}
                                                            className="w-full px-4 py-2.5 text-sm text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-700 flex items-center justify-between group/item font-medium"
                                                        >
                                                            Update Credentials <span className="opacity-0 group-hover/item:opacity-100 text-xs">🔑</span>
                                                        </button>
                                                        <div className="border-t border-slate-100 dark:border-slate-700 my-1"></div>
                                                        <button 
                                                            onClick={() => { setSelectedMember(member); setShowDeleteTasksModal(true); }}
                                                            className="w-full px-4 py-2.5 text-sm text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 flex items-center justify-between group/item font-bold"
                                                        >
                                                            Delete All Tasks <span className="opacity-0 group-hover/item:opacity-100 text-xs">🗑️</span>
                                                        </button>
                                                        <button 
                                                            onClick={() => { setSelectedMember(member); setShowDeleteUserModal(true); }}
                                                            className="w-full px-4 py-2.5 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-600/10 flex items-center justify-between group/item font-black italic uppercase tracking-tighter"
                                                        >
                                                            Delete User <span className="opacity-0 group-hover/item:opacity-100 text-xs">❌</span>
                                                        </button>
                                                    </div>
                                                </>
                                            ) : (
                                                <span className="text-slate-300 text-xs font-bold">-</span>
                                            )}
                                        </td>
                                    )}
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* Existing Drawers/Forms */}
            <CreateTeamDrawer isOpen={showCreateModal} onClose={() => setShowCreateModal(false)} onSuccess={fetchMembers} />
            <CreateMemberDrawer isOpen={showCreateMemberDrawer} onClose={() => setShowCreateMemberDrawer(false)} onSuccess={fetchMembers} />
            
            {/* New Update/Delete Modals */}
            <UpdateMemberDrawer 
                isOpen={showUpdateMemberDrawer} 
                onClose={() => setShowUpdateMemberDrawer(false)} 
                member={selectedMember} 
                onSuccess={fetchMembers} 
            />
            <UpdateCredentialsModal 
                isOpen={showUpdateCredsModal} 
                onClose={() => setShowUpdateCredsModal(false)} 
                member={selectedMember} 
                onSuccess={fetchMembers} 
            />
            <DeleteTasksModal 
                isOpen={showDeleteTasksModal} 
                onClose={() => setShowDeleteTasksModal(false)} 
                member={selectedMember} 
                onSuccess={fetchMembers} 
            />
            <DeleteUserModal 
                isOpen={showDeleteUserModal} 
                onClose={() => setShowDeleteUserModal(false)} 
                member={selectedMember} 
                onSuccess={fetchMembers} 
            />

            <TaskCreationForm isOpen={showTaskForm} onClose={() => setShowTaskForm(false)} onSuccess={() => console.log('Task assigned')} />
            <TaskTemplateForm isOpen={showTaskTemplateForm} onClose={() => setShowTaskTemplateForm(false)} onSuccess={() => console.log('Template created')} />
        </div>
    );
};

export default MyTeam;
