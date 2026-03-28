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

    const [activeTab, setActiveTab] = useState('Teams');
    const [expandedTeams, setExpandedTeams] = useState(new Set());
    const [allUsers, setAllUsers] = useState([]);
    const [members, setMembers] = useState([]);
    const [isLoading, setIsLoading] = useState(true);

    const isAdmin = ['ADMIN', 'SUPERADMIN'].includes(user?.role?.toUpperCase());
    const currentUserId = user?.userId || user?.id || user?._id;
    const showActionsColumn = isAdmin || members.some(m => m.reportingManagerId === currentUserId);

    useEffect(() => {
        fetchMembers();
    }, [activeTab]);

    const fetchMembers = async () => {
        try {
            setIsLoading(true);
            if (activeTab === 'Teams') {
                const data = await teamService.getMyTeamMembers();
                setMembers(data);
            } else if (activeTab === 'Users' && isAdmin) {
                const data = await teamService.getUsers();
                setAllUsers(data);
            }
        } catch (error) {
            console.error('Failed to fetch data:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const toggleTeamExpansion = (teamName) => {
        const newExpanded = new Set(expandedTeams);
        if (newExpanded.has(teamName)) {
            newExpanded.delete(teamName);
        } else {
            newExpanded.add(teamName);
        }
        setExpandedTeams(newExpanded);
    };

    const filteredMembers = members.filter(member => {
        const matchesSearch = `${member.firstName} ${member.lastName}`.toLowerCase().includes(searchTerm.toLowerCase()) ||
            member.workEmail?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            member.teamName?.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesRole = roleFilter === 'All' || member.role === roleFilter;
        const matchesManager = managerFilter === 'All' || member.reportingManagerId === managerFilter;
        let matchesAccess = true;
        if (accessFilter === 'Task App') matchesAccess = member.taskAccess !== false;
        if (accessFilter === 'Leave App') matchesAccess = member.leaveAccess !== false;

        return matchesSearch && matchesRole && matchesManager && matchesAccess;
    });

    // Extract unique values for filters
    const uniqueRoles = ['All', ...new Set(members.map(m => m.role).filter(Boolean))];
    const uniqueManagers = ['All', ...new Set(members.map(m => m.reportingManagerId).filter(Boolean))];
    const accessOptions = ['All', 'Task App', 'Leave App'];

    const handleRemoveMember = async (teamId, userId) => {
        if (!window.confirm('Are you sure you want to remove this member from the team?')) return;
        try {
            await teamService.removeMember(teamId, userId);
            fetchMembers();
        } catch (error) {
            console.error('Failed to remove member:', error);
            alert('Failed to remove member');
        }
    };

    const teamsGrouped = filteredMembers.reduce((acc, m) => {
        const teamName = m.teamName || 'Unassigned';
        if (!acc[teamName]) acc[teamName] = [];
        acc[teamName].push(m);
        return acc;
    }, {});

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
                        {uniqueManagers.filter(m => m !== 'All').map(managerId => {
                            const mgr = members.find(m => m.userId === managerId);
                            return <option key={managerId} value={managerId}>{mgr ? `${mgr.firstName} ${mgr.lastName}` : 'Unknown'}</option>;
                        })}
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

            {/* Tabs Navigation */}
            <div className="flex items-center gap-8 border-b border-slate-100 dark:border-slate-800 px-2 pb-0">
                <button
                    onClick={() => setActiveTab('Teams')}
                    className={`pb-4 text-sm font-black uppercase tracking-widest transition-all relative ${activeTab === 'Teams' ? 'text-emerald-500' : 'text-slate-400 hover:text-slate-600'}`}
                >
                    Teams
                    {activeTab === 'Teams' && <div className="absolute bottom-0 left-0 right-0 h-1 bg-emerald-500 rounded-t-full shadow-[0_-4px_10px_rgba(16,185,129,0.3)]"></div>}
                </button>
                {isAdmin && (
                    <button
                        onClick={() => setActiveTab('Users')}
                        className={`pb-4 text-sm font-black uppercase tracking-widest transition-all relative ${activeTab === 'Users' ? 'text-emerald-500' : 'text-slate-400 hover:text-slate-600'}`}
                    >
                        Users
                        {activeTab === 'Users' && <div className="absolute bottom-0 left-0 right-0 h-1 bg-emerald-500 rounded-t-full shadow-[0_-4px_10px_rgba(16,185,129,0.3)]"></div>}
                    </button>
                )}
            </div>

            {/* Teams Content */}
            {activeTab === 'Teams' && (
                <div className="space-y-4">
                    {isLoading ? (
                         <div className="px-6 py-12 text-center text-emerald-500 bg-white dark:bg-slate-900 rounded-2xl border border-slate-100 dark:border-slate-800">
                             <div className="flex items-center justify-center gap-2">
                                 <Loader2 className="animate-spin" size={24} />
                                 <span className="font-bold uppercase tracking-wider text-xs">Loading Teams...</span>
                             </div>
                         </div>
                    ) : Object.keys(teamsGrouped).length === 0 ? (
                        <div className="px-6 py-12 text-center text-slate-500 font-medium bg-white dark:bg-slate-900 rounded-2xl border border-slate-100 dark:border-slate-800">
                            No teams found.
                        </div>
                    ) : (
                        Object.entries(teamsGrouped).map(([teamName, teamMembers]) => (
                            <div key={teamName} className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
                                <button 
                                    onClick={() => toggleTeamExpansion(teamName)}
                                    className="w-full px-6 py-4 flex items-center justify-between hover:bg-slate-50/50 dark:hover:bg-slate-800/50 transition-all"
                                >
                                    <div className="flex items-center gap-4">
                                        <div className="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-500/10 flex items-center justify-center text-emerald-500">
                                            <ShieldCheck size={20} />
                                        </div>
                                        <div className="text-left">
                                            <h3 className="text-sm font-black text-slate-800 dark:text-slate-100 uppercase tracking-widest">{teamName}</h3>
                                            <p className="text-[10px] font-bold text-slate-400 uppercase">{teamMembers.length} Members</p>
                                        </div>
                                    </div>
                                    <ChevronDown size={20} className={`text-slate-300 transition-transform duration-300 ${expandedTeams.has(teamName) ? 'rotate-180' : ''}`} />
                                </button>
                                
                                {expandedTeams.has(teamName) && (
                                    <div className="border-t border-slate-50 dark:border-slate-800 overflow-x-auto">
                                        <table className="w-full text-left border-collapse">
                                            <thead>
                                                <tr className="bg-slate-50/50 dark:bg-slate-800/30 text-slate-400">
                                                    <th className="px-6 py-3 font-black text-[10px] uppercase tracking-widest">User</th>
                                                    <th className="px-6 py-3 font-black text-[10px] uppercase tracking-widest">Mobile</th>
                                                    <th className="px-6 py-3 font-black text-[10px] uppercase tracking-widest">Reports To</th>
                                                    <th className="px-6 py-3 font-black text-[10px] uppercase tracking-widest">Role</th>
                                                    {showActionsColumn && <th className="px-6 py-3 font-black text-[10px] uppercase tracking-widest text-center">Actions</th>}
                                                </tr>
                                            </thead>
                                            <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                                                {teamMembers.map((member) => (
                                                    <tr key={member.userId} className="hover:bg-slate-50/30 dark:hover:bg-slate-800/20 transition-colors group">
                                                        <td className="px-6 py-4">
                                                            <div className="flex items-center gap-3">
                                                                <div className={`w-8 h-8 rounded-full ${getAvatarBg(member.role)} text-white flex items-center justify-center font-bold text-xs shadow-sm ring-2 ring-white dark:ring-slate-900 shrink-0`}>
                                                                    {getInitials(member.firstName, member.lastName)}
                                                                </div>
                                                                <div className="min-w-0">
                                                                    <div className="font-bold text-slate-800 dark:text-slate-100 text-sm truncate leading-tight">
                                                                        {member.firstName} {member.lastName}
                                                                        {member.isCore && <ShieldCheck size={12} className="inline ml-1 text-emerald-500" />}
                                                                    </div>
                                                                    <div className="text-[10px] text-slate-400 font-medium truncate">{member.workEmail}</div>
                                                                </div>
                                                            </div>
                                                        </td>
                                                        <td className="px-6 py-4 text-xs text-slate-600 dark:text-slate-400 font-medium">
                                                            {member.mobileNumber || 'N/A'}
                                                        </td>
                                                        <td className="px-6 py-4 text-xs text-slate-600 dark:text-slate-400 font-medium">
                                                            {(() => {
                                                                if (member.reportingManagerId) {
                                                                    const mgr = members.find(m => m.userId === member.reportingManagerId);
                                                                    if (mgr) return mgr.firstName + ' ' + mgr.lastName;
                                                                }
                                                                return 'NA';
                                                            })()}
                                                        </td>
                                                        <td className="px-6 py-4">
                                                            <span className={`px-2 py-0.5 rounded-lg text-[10px] font-black tracking-widest uppercase ${getRoleStyles(member.role)}`}>
                                                                {member.role}
                                                            </span>
                                                        </td>
                                                        {showActionsColumn && (
                                                            <td className="px-6 py-4 text-center relative group/actions">
                                                                <button className="p-2 text-slate-300 hover:text-emerald-500 transition-all rounded-lg">
                                                                    <MoreVertical size={16} />
                                                                </button>
                                                                
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
                                                                        onClick={() => handleRemoveMember(member.teamId, member.userId)}
                                                                        className="w-full px-4 py-2.5 text-sm text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 flex items-center justify-between group/item font-bold"
                                                                    >
                                                                        Remove from Team <span className="opacity-0 group-hover/item:opacity-100 text-xs">🚪</span>
                                                                    </button>
                                                                </div>
                                                            </td>
                                                        )}
                                                    </tr>
                                                ))}
                                            </tbody>
                                        </table>
                                    </div>
                                )}
                            </div>
                        ))
                    )}
                </div>
            )}

            {/* Users Content (Admin Only) */}
            {activeTab === 'Users' && isAdmin && (
                <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm relative overflow-hidden">
                    <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse">
                            <thead>
                                <tr className="bg-[#00d094] text-white">
                                    <th className="px-6 py-4 font-bold text-sm">User</th>
                                    <th className="px-6 py-4 font-bold text-sm">Mobile</th>
                                    <th className="px-6 py-4 font-bold text-sm">Role</th>
                                    <th className="px-6 py-4 font-bold text-sm">Department</th>
                                    <th className="px-6 py-4 font-bold text-sm">Status</th>
                                    {showActionsColumn && <th className="px-6 py-4 font-bold text-sm w-20 text-center">Actions</th>}
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                                {isLoading ? (
                                    <tr>
                                        <td colSpan={showActionsColumn ? 6 : 5} className="px-6 py-12 text-center text-emerald-500">
                                            <div className="flex items-center justify-center gap-2">
                                                <Loader2 className="animate-spin" size={24} />
                                                <span className="font-bold uppercase tracking-wider text-xs">Loading Users...</span>
                                            </div>
                                        </td>
                                    </tr>
                                ) : allUsers.length === 0 ? (
                                    <tr>
                                        <td colSpan={showActionsColumn ? 6 : 5} className="px-6 py-12 text-center text-slate-500 font-medium">
                                            No users found.
                                        </td>
                                    </tr>
                                ) : (
                                    allUsers.map((u) => (
                                        <tr key={u.userId} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/30 transition-colors group">
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-3">
                                                    <div className={`w-10 h-10 rounded-full ${getAvatarBg(u.role)} text-white flex items-center justify-center font-bold text-sm shadow-sm ring-2 ring-white dark:ring-slate-900`}>
                                                        {getInitials(u.firstName, u.lastName)}
                                                    </div>
                                                    <div>
                                                        <div className="font-bold text-slate-800 dark:text-slate-100 flex items-center gap-1.5 leading-tight">
                                                            {u.firstName} {u.lastName}
                                                        </div>
                                                        <div className="text-xs text-slate-400 font-medium">{u.workEmail}</div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400 font-medium">
                                                {u.mobileNumber || 'N/A'}
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className={`px-3 py-1 rounded-lg text-xs font-bold leading-none ${getRoleStyles(u.role)}`}>
                                                    {u.role}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400 font-medium">
                                                {u.department || 'N/A'}
                                            </td>
                                            <td className="px-6 py-4 text-sm font-medium">
                                                <span className={`px-2 py-1 rounded-full text-[10px] font-black uppercase tracking-widest ${u.status === 'active' ? 'bg-emerald-50 text-emerald-600 border border-emerald-100' : 'bg-red-50 text-red-600 border border-red-100'}`}>
                                                    {u.status}
                                                </span>
                                            </td>
                                            {showActionsColumn && (
                                                <td className="px-6 py-4 text-center relative group/actions">
                                                    <button 
                                                        onClick={() => { setSelectedMember(u); setShowUpdateMemberDrawer(true); }}
                                                        className="p-2 text-slate-400 hover:text-emerald-500 transition-all rounded-lg"
                                                    >
                                                        <MoreVertical size={18} />
                                                    </button>
                                                    
                                                    {/* Dropdown Menu for Users */}
                                                    <div className="hidden group-hover/actions:block absolute right-full top-0 mr-2 w-52 bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-800 rounded-xl shadow-2xl z-20 py-1 text-left">
                                                        <button 
                                                            onClick={() => { setSelectedMember(u); setShowUpdateMemberDrawer(true); }}
                                                            className="w-full px-4 py-2.5 text-sm text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-700 flex items-center justify-between group/item font-medium"
                                                        >
                                                            Edit <span className="opacity-0 group-hover/item:opacity-100 text-xs">✏️</span>
                                                        </button>
                                                        <button 
                                                            onClick={() => { setSelectedMember(u); setShowUpdateCredsModal(true); }}
                                                            className="w-full px-4 py-2.5 text-sm text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-700 flex items-center justify-between group/item font-medium"
                                                        >
                                                            Update Credentials <span className="opacity-0 group-hover/item:opacity-100 text-xs">🔑</span>
                                                        </button>
                                                        <div className="border-t border-slate-100 dark:border-slate-700 my-1"></div>
                                                        <button 
                                                            onClick={() => { setSelectedMember(u); setShowDeleteTasksModal(true); }}
                                                            className="w-full px-4 py-2.5 text-sm text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 flex items-center justify-between group/item font-bold"
                                                        >
                                                            Delete All Tasks <span className="opacity-0 group-hover/item:opacity-100 text-xs">🗑️</span>
                                                        </button>
                                                        <button 
                                                            onClick={() => { setSelectedMember(u); setShowDeleteUserModal(true); }}
                                                            className="w-full px-4 py-2.5 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-600/10 flex items-center justify-between group/item font-black italic uppercase tracking-tighter"
                                                        >
                                                            Delete User <span className="opacity-0 group-hover/item:opacity-100 text-xs">❌</span>
                                                        </button>
                                                    </div>
                                                </td>
                                            )}
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}

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
