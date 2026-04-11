import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { 
    Search, Plus, ClipboardList, RotateCcw, FileUp,
    LayoutGrid, CheckCircle2, Lightbulb, Link2, History as HistoryIcon,
    Filter, ArrowDownAz, List, Layout, Calendar as CalendarIcon,
    Users, Clock, AlertCircle, ChevronDown, Pencil
} from 'lucide-react';
import delegationService from '../services/delegationService';
import teamService from '../services/teamService';
import { exportToExcel, formatTasksForExport } from '../utils/exportUtils';
import TaskTable from '../components/delegation/TaskTable';
import TaskCreationForm from '../components/delegation/TaskCreationForm';
import TaskKanbanView from '../components/delegation/TaskKanbanView';
import TaskCalendarView from '../components/delegation/TaskCalendarView';
import TaskDetailsDrawer from '../components/delegation/TaskDetailsDrawer';
import GroupDetailsModal from '../components/delegation/GroupDetailsModal';
import CreateGroupModal from '../components/groups/CreateGroupModal';

const AvatarGroup = ({ users, max = 3 }) => {
    const displayUsers = users.slice(0, max);
    const extraCount = users.length > max ? users.length - max : 0;

    return (
        <div className="flex -space-x-1.5 overflow-hidden">
            {displayUsers.map((user, i) => (
                <div 
                    key={user.userId || i} 
                    className="flex h-7 w-7 rounded-full ring-2 ring-white dark:ring-slate-900 bg-gradient-to-br from-emerald-400 to-sky-400 items-center justify-center shadow-sm"
                    title={`${user.firstName} ${user.lastName}`}
                >
                    <span className="text-[9px] font-bold text-white uppercase tracking-tighter">
                        {user.firstName ? user.firstName[0] : ''}{user.lastName ? user.lastName[0] : ''}
                    </span>
                </div>
            ))}
            {extraCount > 0 && (
                <div className="flex h-7 w-7 rounded-full ring-2 ring-white dark:ring-slate-900 bg-slate-100 dark:bg-slate-800 items-center justify-center border border-slate-200 dark:border-slate-700">
                    <span className="text-[9px] font-bold text-slate-500">+{extraCount}</span>
                </div>
            )}
        </div>
    );
};

const DetailedStatCard = ({ label, count, percentage, color, borderSide }) => (
    <div className={`flex items-center gap-3 bg-white dark:bg-slate-900 p-2.5 rounded-xl shadow-sm border border-slate-100 dark:border-slate-800 border-b-4 ${borderSide} flex-1 min-w-[150px]`}>
        <div className="relative w-10 h-10 flex-shrink-0">
            <svg className="w-full h-full rotate-[-90deg]">
                <circle cx="20" cy="20" r="17" fill="transparent" stroke="currentColor" strokeWidth="3" className="text-slate-100 dark:text-slate-800/50" />
                <circle cx="20" cy="20" r="17" fill="transparent" stroke="currentColor" strokeWidth="3" strokeDasharray={107} strokeDashoffset={107 - (107 * percentage / 100)} strokeLinecap="round" className={color} />
            </svg>
            <span className="absolute inset-0 flex items-center justify-center text-[10px] font-black text-slate-500">{percentage}%</span>
        </div>
        <div className="flex flex-col">
            <span className="text-[10px] font-black text-slate-400 uppercase leading-none mb-1">{label}</span>
            <span className="text-xl font-black text-slate-800 dark:text-white leading-none">{count}</span>
        </div>
    </div>
);

const ComingSoon = ({ title, icon: Icon }) => (
    <div className="flex flex-col items-center justify-center py-32 animate-in fade-in duration-700 bg-slate-50/30 dark:bg-slate-900/10 rounded-3xl border border-dashed border-slate-200 dark:border-slate-800">
        <div className="w-24 h-24 bg-emerald-50 dark:bg-emerald-500/10 rounded-full flex items-center justify-center mb-6 shadow-sm border border-emerald-100 dark:border-emerald-500/20">
            <Icon size={40} className="text-[#00d194] animate-bounce" />
        </div>
        <h2 className="text-3xl font-black text-slate-800 dark:text-white mb-2">{title}</h2>
        <div className="flex items-center gap-2 px-4 py-1.5 bg-slate-900 text-white rounded-full text-[10px] font-black uppercase tracking-widest shadow-lg">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            Coming Soon
        </div>
    </div>
);

const GroupTasks = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const [tasks, setTasks] = useState([]);
    const [loading, setLoading] = useState(true);
    const [groupName, setGroupName] = useState('Group 1');
    const [groupDesc, setGroupDesc] = useState('group desc');
    const [groupImage, setGroupImage] = useState(null);
    const [search, setSearch] = useState('');
    const [dateRange, setDateRange] = useState('This Month');
    const [customStartDate, setCustomStartDate] = useState('');
    const [customEndDate, setCustomEndDate] = useState('');
    const [assignedTo, setAssignedTo] = useState('All');
    const [assignedBy, setAssignedBy] = useState('All');
    const [frequency, setFrequency] = useState('All');
    const [priority, setPriority] = useState('All');
    const [category, setCategory] = useState('All');
    const [tag, setTag] = useState('All');
    const [sortBy, setSortBy] = useState('Target Date');
    const [viewMode, setViewMode] = useState('List'); // 'List', 'Kanban', 'Calendar'
    const [showTaskDrawer, setShowTaskDrawer] = useState(false);
    const [showGroupDetailsModal, setShowGroupDetailsModal] = useState(false);
    const [activeTab, setActiveTab] = useState('Dashboard');
    const [taskFilter, setTaskFilter] = useState('All'); // 'All' or 'My'
    const [statusFilter, setStatusFilter] = useState('All'); // 'All', 'Overdue', 'Pending', etc.
    const [showFilters, setShowFilters] = useState(false);
    const [showDetails, setShowDetails] = useState(false);
    const [selectedTaskId, setSelectedTaskId] = useState(null);
    const [showCreateGroup, setShowCreateGroup] = useState(false);

    const [groupUsers, setGroupUsers] = useState([]);
    const [categories, setCategories] = useState([]);
    const [allTags, setAllTags] = useState([]);

    const storedUser = JSON.parse(localStorage.getItem('user'));
    const currentUserId = storedUser?.user?.userId || storedUser?.userId;

    useEffect(() => {
        if (id) {
            fetchGroupData();
        }
    }, [id]);

    const fetchGroupData = async () => {
        if (!id) return;
        try {
            setLoading(true);
            const groupRes = await delegationService.getGroups();
            const currentGroup = groupRes.data?.find(g => g.groupId === id);
            if (currentGroup) {
                setGroupName(currentGroup.name);
                setGroupDesc(currentGroup.description || 'group desc');
                setGroupImage(currentGroup.imageUrl);
            }
            const response = await delegationService.getDelegations({ groupId: id });
            const tasksData = response.data || [];
            setTasks(tasksData);

            const membersRes = await delegationService.getGroupMembers(id);
            setGroupUsers(membersRes.data || []);

            const catRes = await delegationService.getCategories();
            setCategories(catRes || []);

            // Extract unique tags from tasks
            const tagsFromTasks = new Set();
            tasksData.forEach(task => {
                try {
                    const tags = JSON.parse(task.tags || '[]');
                    tags.forEach(t => tagsFromTasks.add(t));
                } catch(e) {}
            });
            setAllTags(Array.from(tagsFromTasks));
        } catch (err) {
            console.error('Failed to fetch group data:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleExport = () => {
        if (filteredTasks.length === 0) {
            toast.error('No tasks to export');
            return;
        }
        
        // Use groupUsers or fetch all users if groupUsers is empty
        const exportUsers = groupUsers.length > 0 ? groupUsers : [];
        const exportData = formatTasksForExport(filteredTasks, exportUsers);
        exportToExcel(exportData, `${groupName.replace(/\s+/g, '_')}_Tasks_${new Date().toISOString().split('T')[0]}`, `${groupName} Tasks`);
        toast.success('Tasks exported successfully');
    };

    if (!id) {
        return (
            <div className="flex flex-col items-center justify-center h-[calc(100vh-8rem)] text-center px-4">
                <div className="max-w-md flex flex-col items-center">
                    <div className="w-32 h-32 bg-slate-50 dark:bg-slate-900 rounded-full flex items-center justify-center mb-6">
                        <Users size={64} className="text-slate-200" />
                    </div>
                    <h2 className="text-3xl font-black text-slate-800 dark:text-white mb-2">Group Task</h2>
                    <p className="text-slate-500 font-bold mb-6">Assign and coordinate tasks within the group</p>
                    <button 
                        onClick={() => setShowCreateGroup(true)}
                        className="flex items-center gap-2 px-6 py-3 bg-[#00d094] hover:bg-[#00ba84] text-white font-black rounded-xl transition-all shadow-lg hover:shadow-[#00d094]/30 active:scale-95"
                    >
                        <Plus size={20} strokeWidth={3} />
                        Create Group
                    </button>
                    
                    <CreateGroupModal 
                        isOpen={showCreateGroup} 
                        onClose={() => setShowCreateGroup(false)} 
                        onSuccess={fetchGroupData} 
                    />
                </div>
            </div>
        );
    }

    const filteredTasks = tasks.filter(t => {
        // Search filter
        const matchesSearch = !search || t.taskTitle.toLowerCase().includes(search.toLowerCase()) || (t.description || '').toLowerCase().includes(search.toLowerCase());
        if (!matchesSearch) return false;

        // All/My filter
        if (taskFilter === 'My' && t.doerId !== currentUserId) return false;
        
        // Assigned To filter
        if (assignedTo !== 'All' && t.doerId !== assignedTo) return false;

        // Assigned By filter
        if (assignedBy !== 'All' && t.assignerId !== assignedBy) return false;

        // Frequency filter
        if (frequency !== 'All' && t.repeatFrequency !== frequency) return false;

        // Priority filter
        if (priority !== 'All' && t.priority !== priority) return false;

        // Category filter
        if (category !== 'All' && t.category !== category) return false;

        // Tag filter
        if (tag !== 'All') {
            try {
                const tagsArr = JSON.parse(t.tags || '[]');
                if (!tagsArr.includes(tag)) return false;
            } catch(e) { return false; }
        }

        // Status filter
        if (statusFilter !== 'All' && t.status !== statusFilter) return false;

        // Date Range filter
        return getDateRangeFilter(t.dueDate || t.createdAt, dateRange, customStartDate, customEndDate);
    });

    const now = new Date();
    const taskStats = {
        total: filteredTasks.length,
        overdue: filteredTasks.filter(t => t.status === 'Overdue' || (t.status !== 'Completed' && t.dueDate && new Date(t.dueDate) < now)).length,
        pending: filteredTasks.filter(t => ['Pending', 'Hold', 'Need Revision'].includes(t.status)).length,
        inProgress: filteredTasks.filter(t => t.status === 'In Progress').length,
        completed: filteredTasks.filter(t => t.status === 'Completed').length,
        inTime: filteredTasks.filter(t => t.status === 'Completed' && t.dueDate && new Date(t.updatedAt || t.createdAt) <= new Date(t.dueDate)).length,
        delayed: filteredTasks.filter(t => t.status === 'Completed' && t.dueDate && new Date(t.updatedAt || t.createdAt) > new Date(t.dueDate)).length
    };

    const getPercentage = (count) => {
        if (taskStats.total === 0) return 0;
        return Math.round((count / taskStats.total) * 100);
    };

    // If groupUsers is empty, derive from tasks to avoid "No Member Found"
    let displayUsers = groupUsers;
    if (displayUsers.length === 0 && tasks.length > 0) {
        const uniqueDoers = Array.from(new Set(tasks.map(t => t.doerId)));
        displayUsers = uniqueDoers.map(id => {
            const task = tasks.find(t => t.doerId === id);
            return {
                userId: id,
                firstName: task.doerFirstName || 'Member',
                lastName: task.doerLastName || id.substring(0, 4),
                displayName: task.doerName || 'Member'
            };
        });
    }

    const memberStats = Array.isArray(displayUsers) ? displayUsers.map(user => {
        const userTasks = filteredTasks.filter(t => t.doerId === user.userId);
        const total = userTasks.length;
        const overdue = userTasks.filter(t => t.status === 'Overdue').length;
        const pending = userTasks.filter(t => t.status === 'Pending').length;
        const inProgress = userTasks.filter(t => t.status === 'In Progress').length;
        const completed = userTasks.filter(t => t.status === 'Completed').length;
        
        const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0;
        const notCompleted = overdue + pending + inProgress;
        
        return {
            ...user,
            total,
            overdue,
            pending,
            inProgress,
            completed,
            inTime: 0,
            delayed: 0,
            completionRate,
            notCompleted
        };
    }) : [];

    return (
        <div className="p-6 flex flex-col gap-4 bg-white dark:bg-[#12161b] min-h-screen">
            {/* Top Toolbar */}
            <div className="flex items-center justify-between mb-2">
                <div 
                    className="flex items-center gap-4 cursor-pointer hover:bg-slate-50/50 dark:hover:bg-slate-900/40 p-2 rounded-2xl transition-all group"
                    onClick={() => setShowGroupDetailsModal(true)}
                >
                    <div className="w-12 h-12 bg-white dark:bg-slate-900 border border-slate-100 dark:border-slate-800 rounded-full flex items-center justify-center shadow-sm group-hover:border-[#00d194]/30 group-hover:shadow-[#00d194]/10 transition-all overflow-hidden">
                        {groupImage ? (
                            <img src={groupImage} alt={groupName} className="w-full h-full object-cover" />
                        ) : (
                            <Users className="text-slate-400 group-hover:text-[#00d194] transition-colors" size={24} />
                        )}
                    </div>
                    <div className="flex flex-col">
                        <div className="flex items-center gap-2">
                            <h1 className="text-lg font-black text-slate-800 dark:text-white leading-none mb-1 group-hover:text-[#00d194] transition-colors">{groupName}</h1>
                            <Pencil size={12} className="text-slate-300 opacity-0 group-hover:opacity-100 transition-all" />
                        </div>
                        <span className="text-xs text-slate-400 font-bold">{groupDesc}</span>
                    </div>
                </div>

                <div className="flex items-center gap-4">
                    <div className="relative w-64">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                        <input 
                            type="text"
                            placeholder="Search"
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                            className="w-full pl-10 pr-4 py-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-sm outline-none focus:ring-2 focus:ring-emerald-500/20 shadow-sm"
                        />
                    </div>
                    <div className="flex items-center bg-slate-50 dark:bg-slate-900/50 p-1 px-2.5 rounded-full border border-slate-100 dark:border-slate-800 shadow-inner">
                        <span className="text-[9px] font-bold text-slate-500 uppercase tracking-widest mr-2">Team</span>
                        <AvatarGroup users={displayUsers} />
                    </div>
                </div>
            </div>

            {/* Actions Bar - Tab Dependent */}
            <div className="flex flex-wrap items-end gap-3 pb-2 min-h-[60px]">
                <button 
                    onClick={() => setShowTaskDrawer(true)}
                    className="flex items-center gap-1.5 px-4 h-11 bg-[#00d194] text-white font-black rounded-lg hover:bg-[#00ba84] transition-all active:scale-95 shadow-sm"
                >
                    <Plus size={18} strokeWidth={3} />
                    Assign Task
                </button>

                {/* Shared Date Range Filter */}
                <div className="flex flex-col gap-1">
                    <span className="text-[10px] font-black text-slate-400 uppercase ml-1">Date Range</span>
                    <div className="relative min-w-[140px]">
                        <select 
                            value={dateRange}
                            onChange={(e) => setDateRange(e.target.value)}
                            className="w-full h-11 bg-white dark:bg-slate-900 border border-[#00d194] rounded-lg px-3 py-2 text-sm font-bold text-slate-700 dark:text-slate-200 outline-none appearance-none cursor-pointer pr-8 shadow-sm"
                        >
                            <option value="Today">Today</option>
                            <option value="Yesterday">Yesterday</option>
                            <option value="This Week">This Week</option>
                            <option value="Last Week">Last Week</option>
                            <option value="This Month">This Month</option>
                            <option value="Last Month">Last Month</option>
                            <option value="Next Week">Next Week</option>
                            <option value="Next Month">Next Month</option>
                            <option value="This Year">This Year</option>
                            <option value="All Time">All Time</option>
                            <option value="Custom">Custom</option>
                        </select>
                        <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                    </div>
                </div>

                {dateRange === 'Custom' && (
                    <>
                        <div className="flex flex-col gap-1">
                            <span className="text-[10px] font-black text-slate-400 uppercase ml-1 block">Start Date</span>
                            <div className="relative border border-[#00d194] rounded-lg h-11 flex items-center px-2 gap-1.5 bg-white dark:bg-slate-900 min-w-[125px]">
                                <CalendarIcon size={14} className="text-[#00d194]" />
                                <div className="flex flex-col">
                                    <span className="text-[8px] font-bold text-slate-400 leading-none">Start</span>
                                    <input 
                                        type="date" 
                                        value={customStartDate}
                                        onChange={(e) => setCustomStartDate(e.target.value)}
                                        className="bg-transparent border-none outline-none text-[11px] font-bold text-slate-700 dark:text-slate-200 w-full"
                                    />
                                </div>
                            </div>
                        </div>
                        <div className="flex flex-col gap-1">
                            <span className="text-[10px] font-black text-slate-400 uppercase ml-1 block">End Date</span>
                            <div className="relative border border-[#00d194] rounded-lg h-11 flex items-center px-2 gap-1.5 bg-white dark:bg-slate-900 min-w-[125px]">
                                <CalendarIcon size={14} className="text-[#00d194]" />
                                <div className="flex flex-col">
                                    <span className="text-[8px] font-bold text-slate-400 leading-none">End</span>
                                    <input 
                                        type="date" 
                                        value={customEndDate}
                                        onChange={(e) => setCustomEndDate(e.target.value)}
                                        className="bg-transparent border-none outline-none text-[11px] font-bold text-slate-700 dark:text-slate-200 w-full"
                                    />
                                </div>
                            </div>
                        </div>
                    </>
                )}

                {activeTab === 'Dashboard' ? (
                    <>
                        <div className="flex flex-col gap-1">
                            <span className="text-[10px] font-black text-slate-400 uppercase ml-1">Assigned To</span>
                            <div className="relative min-w-[140px]">
                                <select 
                                    value={assignedTo}
                                    onChange={(e) => setAssignedTo(e.target.value)}
                                    className="w-full h-11 bg-slate-100 dark:bg-slate-800/50 border border-transparent rounded-lg px-3 py-2 text-sm font-bold text-slate-700 dark:text-slate-200 outline-none appearance-none cursor-pointer pr-8 font-black"
                                >
                                    <option value="All">Assigned To</option>
                                    {Array.isArray(displayUsers) && displayUsers.map(u => (
                                        <option key={u.userId} value={u.userId}>{u.firstName} {u.lastName}</option>
                                    ))}
                                </select>
                                <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                            </div>
                        </div>
                        <div className="flex flex-col gap-1">
                            <span className="text-[10px] font-black text-slate-400 uppercase ml-1">Frequency</span>
                            <div className="relative min-w-[120px]">
                                <select 
                                    value={frequency}
                                    onChange={(e) => setFrequency(e.target.value)}
                                    className="w-full h-11 bg-slate-100 dark:bg-slate-800/50 border border-transparent rounded-lg px-3 py-2 text-sm font-bold text-slate-700 dark:text-slate-200 outline-none appearance-none cursor-pointer pr-8 font-black"
                                >
                                    <option value="All">Frequency</option>
                                    <option value="Once">Once</option>
                                    <option value="Daily">Daily</option>
                                    <option value="Weekly">Weekly</option>
                                    <option value="Monthly">Monthly</option>
                                </select>
                                <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                            </div>
                        </div>
                    </>
                ) : activeTab === 'Tasks' && (
                    <>
                        {/* Task specific filters grouped under a button */}
                        <div className="relative">
                            <button 
                                onClick={() => setShowFilters(!showFilters)}
                                className={`flex items-center gap-2 px-6 h-11 rounded-lg font-black text-sm transition-all border ${showFilters ? 'bg-emerald-500 text-white border-emerald-500' : 'bg-[#00d194] text-white border-transparent'}`}
                            >
                                <Filter size={18} />
                                Filter
                            </button>
                            
                            {showFilters && (
                                <div className="absolute top-14 left-0 z-50 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-2xl p-4 flex flex-col gap-4 min-w-[250px] animate-in slide-in-from-top-2 duration-200">
                                    <div className="flex flex-col gap-1">
                                        <label className="text-[10px] font-black text-slate-400 uppercase">Assigned To</label>
                                        <select value={assignedTo} onChange={(e) => setAssignedTo(e.target.value)} className="bg-slate-50 dark:bg-slate-800 p-2 rounded-lg text-xs font-bold font-black outline-none border border-slate-100 dark:border-slate-700">
                                            <option value="All">All Assignees</option>
                                            {displayUsers.map(u => <option key={u.userId} value={u.userId}>{u.firstName} {u.lastName}</option>)}
                                        </select>
                                    </div>
                                    <div className="flex flex-col gap-1">
                                        <label className="text-[10px] font-black text-slate-400 uppercase">Assigned From</label>
                                        <select value={assignedBy} onChange={(e) => setAssignedBy(e.target.value)} className="bg-slate-50 dark:bg-slate-800 p-2 rounded-lg text-xs font-bold font-black outline-none border border-slate-100 dark:border-slate-700">
                                            <option value="All">All Assigners</option>
                                            {displayUsers.map(u => <option key={u.userId} value={u.userId}>{u.firstName} {u.lastName}</option>)}
                                        </select>
                                    </div>
                                    <div className="flex flex-col gap-1">
                                        <label className="text-[10px] font-black text-slate-400 uppercase">Priority</label>
                                        <select value={priority} onChange={(e) => setPriority(e.target.value)} className="bg-slate-50 dark:bg-slate-800 p-2 rounded-lg text-xs font-bold font-black outline-none border border-slate-100 dark:border-slate-700">
                                            <option value="All">All Priority</option>
                                            <option value="High">High</option>
                                            <option value="Medium">Medium</option>
                                            <option value="Low">Low</option>
                                        </select>
                                    </div>
                                    <div className="flex flex-col gap-1">
                                        <label className="text-[10px] font-black text-slate-400 uppercase">Category</label>
                                        <select value={category} onChange={(e) => setCategory(e.target.value)} className="bg-slate-50 dark:bg-slate-800 p-2 rounded-lg text-xs font-bold font-black outline-none border border-slate-100 dark:border-slate-700">
                                            <option value="All">All Categories</option>
                                            {categories.map(cat => <option key={cat.id} value={cat.name}>{cat.name}</option>)}
                                        </select>
                                    </div>
                                    <div className="flex flex-col gap-1">
                                        <label className="text-[10px] font-black text-slate-400 uppercase">Tag</label>
                                        <select value={tag} onChange={(e) => setTag(e.target.value)} className="bg-slate-50 dark:bg-slate-800 p-2 rounded-lg text-xs font-bold font-black outline-none border border-slate-100 dark:border-slate-700">
                                            <option value="All">All Tags</option>
                                            {allTags.map(t => <option key={t} value={t}>{t}</option>)}
                                        </select>
                                    </div>
                                </div>
                            )}
                        </div>

                        <div className="flex flex-col gap-1">
                            <span className="text-[10px] font-black text-slate-400 uppercase ml-1">Sort By</span>
                            <div className="relative min-w-[140px]">
                                <select 
                                    value={sortBy}
                                    onChange={(e) => setSortBy(e.target.value)}
                                    className="w-full h-11 bg-slate-100 dark:bg-slate-800/50 border border-transparent rounded-lg px-3 py-2 text-sm font-bold text-slate-700 dark:text-slate-200 outline-none appearance-none cursor-pointer pr-8 font-black font-black"
                                >
                                    <option value="Target Date">Target Date</option>
                                    <option value="Assign Date">Assign Date</option>
                                    <option value="Priority">Priority</option>
                                </select>
                                <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                            </div>
                        </div>

                        <div className="flex items-center gap-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg p-1 shadow-sm h-11 self-end">
                            {[
                                { mode: 'List', icon: List },
                                { mode: 'Kanban', icon: Layout },
                                { mode: 'Calendar', icon: CalendarIcon }
                            ].map(item => (
                                <button 
                                    key={item.mode}
                                    onClick={() => setViewMode(item.mode)}
                                    className={`px-3 py-1.5 rounded-md flex items-center gap-2 text-[12px] font-black transition-all ${viewMode === item.mode ? 'bg-[#00d194] text-white shadow-md' : 'text-slate-400 hover:text-slate-600'}`}
                                >
                                    <item.icon size={14} />
                                </button>
                            ))}
                        </div>
                    </>
                )}

                <button 
                    onClick={handleExport}
                    className="flex items-center gap-2 px-4 h-11 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-200 font-bold rounded-lg hover:bg-slate-50 transition-all shadow-sm self-end"
                >
                    <FileUp size={18} />
                    Export
                </button>

                <button 
                    onClick={fetchGroupData}
                    className="h-11 w-11 flex items-center justify-center bg-[#00d194] text-white rounded-lg hover:bg-[#00ba84] transition-all shadow-sm self-end"
                >
                    <RotateCcw size={18} strokeWidth={3} />
                </button>
            </div>

            {/* Navigation Tabs */}
            <div className="flex items-center justify-center gap-12 border-t border-slate-100 dark:border-slate-800 mt-2">
                {[
                    { label: 'Dashboard', icon: LayoutGrid },
                    { label: 'Tasks', icon: CheckCircle2 },
                    { label: 'Ideaboard', icon: Lightbulb },
                    { label: 'Links', icon: Link2 },
                    { label: 'Timeline', icon: HistoryIcon }
                ].map((item) => (
                    <button 
                        key={item.label}
                        onClick={() => setActiveTab(item.label)}
                        className={`flex items-center gap-2 py-3.5 text-[13px] font-black transition-all relative ${activeTab === item.label ? 'text-emerald-500' : 'text-slate-500 hover:text-slate-700'}`}
                    >
                        <item.icon size={18} strokeWidth={activeTab === item.label ? 3 : 2} />
                        {item.label}
                        {activeTab === item.label && <div className="absolute bottom-0 left-0 right-0 h-1 bg-emerald-500 rounded-t-full shadow-[0_-2px_8px_rgba(16,185,129,0.3)]" />}
                    </button>
                ))}
            </div>

            {/* View Content based on Active Tab */}
            {activeTab === 'Dashboard' ? (
                <div className="flex flex-col gap-6 animate-in fade-in duration-500">
                    {/* Dashboard Cards Row - 6 Cards */}
                    <div className="flex items-center justify-between gap-3 w-full overflow-x-auto pb-2 custom-scrollbar">
                        <DetailedStatCard label="Overdue" count={taskStats.overdue} percentage={getPercentage(taskStats.overdue)} color="text-red-500" borderSide="border-b-red-500" />
                        <DetailedStatCard label="Pending" count={taskStats.pending} percentage={getPercentage(taskStats.pending)} color="text-red-400" borderSide="border-b-red-400" />
                        <DetailedStatCard label="In Progress" count={taskStats.inProgress} percentage={getPercentage(taskStats.inProgress)} color="text-orange-400" borderSide="border-b-orange-400" />
                        <DetailedStatCard label="Completed" count={taskStats.completed} percentage={getPercentage(taskStats.completed)} color="text-emerald-500" borderSide="border-b-emerald-500" />
                        <DetailedStatCard label="In Time" count={taskStats.inTime} percentage={getPercentage(taskStats.inTime)} color="text-emerald-400" borderSide="border-b-emerald-400" />
                        <DetailedStatCard label="Delayed" count={taskStats.delayed} percentage={getPercentage(taskStats.delayed)} color="text-red-600" borderSide="border-b-red-600" />
                    </div>

                    {/* Dashboard Table Header */}
                    <div className="bg-[#12161b] rounded-lg overflow-hidden border border-slate-800 shadow-xl">
                        <div className="flex divide-x divide-slate-800 border-b border-slate-800 bg-[#0f172a]">
                            <div className="w-[300px] shrink-0 py-4 px-6 text-center text-[11px] font-black text-white uppercase tracking-wider">Employee Name</div>
                            <div className="w-[120px] shrink-0 py-4 px-6 text-center text-[11px] font-black text-white uppercase tracking-wider">Total</div>
                            <div className="flex-[3] flex flex-col divide-y divide-slate-800">
                                <div className="py-2.5 text-center text-[10px] font-black text-white uppercase bg-slate-900/50 tracking-widest">Not Completed</div>
                                <div className="flex divide-x divide-slate-800 font-black">
                                    <div className="flex-1 py-3 flex items-center justify-center gap-2 text-[10px] text-slate-300">
                                        <span className="w-3 h-3 rounded-full bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.4)]" /> Overdue
                                    </div>
                                    <div className="flex-1 py-3 flex items-center justify-center gap-2 text-[10px] text-slate-300">
                                        <span className="w-3 h-3 rounded-full border-2 border-red-500" /> Pending
                                    </div>
                                    <div className="flex-1 py-3 flex items-center justify-center gap-2 text-[10px] text-slate-300">
                                        <span className="w-3 h-3 rounded-full border-l-4 border-orange-400 rotate-45" /> In-Progress
                                    </div>
                                </div>
                            </div>
                            <div className="flex-[2] flex flex-col divide-y divide-slate-800">
                                <div className="py-2.5 text-center text-[10px] font-black text-white uppercase bg-slate-900/50 tracking-widest">Completed</div>
                                <div className="flex divide-x divide-slate-800 font-black">
                                    <div className="flex-1 py-3 flex items-center justify-center gap-2 text-[10px] text-slate-300">
                                        <CheckCircle2 size={13} className="text-emerald-500 fill-emerald-500/10" /> In Time
                                    </div>
                                    <div className="flex-1 py-3 flex items-center justify-center gap-2 text-[10px] text-slate-300">
                                        <Clock size={13} className="text-red-500 fill-red-500/10" /> Delayed
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        {/* Table Body */}
                        <div className="bg-white dark:bg-[#12161b] divide-y divide-slate-800/20">
                            {memberStats.length > 0 ? (
                                memberStats.map((member, idx) => (
                                    <div key={member.userId} className={`flex divide-x divide-slate-100 dark:divide-slate-800/50 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors ${idx % 2 === 1 ? 'bg-slate-50/50 dark:bg-slate-800/10' : ''}`}>
                                        <div className="w-[300px] shrink-0 py-4 px-6 flex items-center gap-3">
                                            <div className="relative w-8 h-8 flex-shrink-0">
                                                <svg className="w-full h-full rotate-[-90deg]">
                                                    <circle cx="16" cy="16" r="14" fill="transparent" stroke="currentColor" strokeWidth="2.5" className="text-slate-100 dark:text-slate-800" />
                                                    <circle cx="16" cy="16" r="14" fill="transparent" stroke="currentColor" strokeWidth="2.5" strokeDasharray={88} strokeDashoffset={88 - (88 * member.completionRate / 100)} strokeLinecap="round" className="text-red-500" />
                                                </svg>
                                                <span className="absolute inset-0 flex items-center justify-center text-[8px] font-black text-slate-600 dark:text-slate-400">{member.completionRate}%</span>
                                            </div>
                                            <span className="text-[13px] font-bold text-slate-700 dark:text-slate-300">{member.firstName} {member.lastName}</span>
                                        </div>
                                        <div className="w-[120px] shrink-0 flex items-center justify-center text-[15px] font-black text-slate-800 dark:text-white">
                                            {member.total}
                                        </div>
                                        <div className="flex-[3] flex items-center justify-center gap-3 text-[13px] font-bold text-slate-800 dark:text-white">
                                            {member.notCompleted} <span className="text-[11px] font-black text-slate-400">({member.total > 0 ? Math.round((member.notCompleted / member.total) * 100) : 0}%)</span>
                                        </div>
                                        <div className="flex-[2] flex items-center justify-center gap-3 text-[13px] font-bold text-slate-800 dark:text-white">
                                            {member.completed} <span className="text-[11px] font-black text-slate-400">({member.total > 0 ? Math.round((member.completed / member.total) * 100) : 0}%)</span>
                                        </div>
                                    </div>
                                ))
                            ) : (
                                <div className="py-28 text-center bg-white dark:bg-[#12161b]">
                                    <h2 className="text-3xl font-black text-slate-800 dark:text-white mb-2">No Member Found</h2>
                                    <p className="text-slate-400 font-bold">There are no members in this group to show statistics</p>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            ) : activeTab === 'Tasks' ? (
                <div className="space-y-6 animate-in fade-in duration-500">
                    {/* View Switcher and All/My Tab */}
                    <div className="flex items-center justify-between pb-2">
                        <div className="flex items-center gap-4">
                            <div className="flex items-center h-10 bg-slate-100 dark:bg-slate-800/50 rounded-lg p-1">
                                <button 
                                    onClick={() => setTaskFilter('All')}
                                    className={`px-4 py-1.5 rounded-md text-[13px] font-black flex items-center gap-2 transition-all ${taskFilter === 'All' ? 'text-emerald-600 bg-white dark:bg-slate-700 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                                >
                                    All Task
                                </button>
                                <button 
                                    onClick={() => setTaskFilter('My')}
                                    className={`px-4 py-1.5 rounded-md text-[13px] font-black flex items-center gap-2 transition-all ${taskFilter === 'My' ? 'text-emerald-600 bg-white dark:bg-slate-700 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                                >
                                    My Task <span className={`px-1.5 min-w-[18px] h-[18px] rounded-md flex items-center justify-center text-[10px] ${taskFilter === 'My' ? 'bg-[#00d194] text-white' : 'bg-slate-200 dark:bg-slate-800 text-slate-500 font-bold'}`}>{tasks.filter(t => t.doerId === currentUserId).length}</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    {/* Status Tabs for Tasks */}
                    <div className="flex flex-nowrap md:flex-wrap overflow-x-auto scrollbar-hide items-center justify-start lg:justify-center gap-2 md:gap-4 bg-slate-50/50 dark:bg-slate-900/30 rounded-2xl border border-dashed border-slate-200 dark:border-slate-800 p-1.5">
                        {[
                            { label: 'All', count: tasks.length, color: 'text-slate-500', dot: 'bg-slate-400' },
                            { label: 'Overdue', count: taskStats.overdue, color: 'text-red-500', dot: 'bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.3)]' },
                            { label: 'Pending', count: tasks.filter(t => t.status === 'Pending').length, color: 'text-red-400', dot: 'border-2 border-red-500' },
                            { label: 'In Progress', count: taskStats.inProgress, color: 'text-orange-400', dot: 'bg-orange-400' },
                            { label: 'Hold', count: tasks.filter(t => t.status === 'Hold').length, color: 'text-amber-500', dot: 'bg-amber-500' },
                            { label: 'Need Revision', count: tasks.filter(t => t.status === 'Need Revision').length, color: 'text-blue-500', dot: 'bg-blue-500' },
                            { label: 'Completed', count: taskStats.completed, color: 'text-emerald-500', dot: 'bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.3)]' }
                        ].map(tab => (
                            <button
                                key={tab.label}
                                onClick={() => setStatusFilter(tab.label)}
                                className={`flex items-center gap-3 px-6 py-2.5 rounded-xl transition-all font-black text-[13px] flex-shrink-0 whitespace-nowrap ${
                                    statusFilter === tab.label 
                                    ? 'bg-white dark:bg-slate-800 shadow-sm border border-slate-100 dark:border-slate-700 ' + tab.color 
                                    : 'text-slate-400 hover:text-slate-600'
                                }`}
                            >
                                <span className={`w-3 h-3 rounded-full flex-shrink-0 ${tab.dot}`} />
                                {tab.label}
                                <span className={`px-2 py-0.5 rounded-md text-[10px] ${
                                    statusFilter === tab.label ? 'bg-slate-100 dark:bg-slate-700/50' : 'bg-slate-200/50 dark:bg-slate-800/50'
                                }`}>
                                    {tab.count}
                                </span>
                            </button>
                        ))}
                    </div>

                    {/* Content Area */}
                    <div className="flex-1">
                        {loading ? (
                            <div className="flex items-center justify-center py-32">
                                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-500"></div>
                            </div>
                        ) : filteredTasks.length === 0 ? (
                            <div className="flex flex-col items-center justify-center py-24 text-center gap-4 bg-slate-50/50 dark:bg-slate-900/20 rounded-2xl border border-dashed border-slate-200 dark:border-slate-800">
                                <div className="w-20 h-20 bg-white dark:bg-slate-800 rounded-full flex items-center justify-center shadow-sm">
                                    <ClipboardList size={40} className="text-slate-200" />
                                </div>
                                <h2 className="text-2xl font-black text-slate-800 dark:text-white">No Task Here</h2>
                                <p className="text-slate-400 font-bold max-w-xs">It seems there are no tasks matching your active filters in this group</p>
                            </div>
                        ) : (
                            viewMode === 'List' ? (
                                <TaskTable tasks={filteredTasks} type="assigned" />
                            ) : viewMode === 'Kanban' ? (
                                <TaskKanbanView tasks={filteredTasks} onTaskClick={(task) => { setSelectedTaskId(task.id); setShowDetails(true); }} />
                            ) : (
                                <TaskCalendarView tasks={filteredTasks} onTaskClick={(task) => { setSelectedTaskId(task.id); setShowDetails(true); }} />
                            )
                        )}
                    </div>
                </div>
            ) : (
                <ComingSoon title={activeTab} icon={
                    activeTab === 'Ideaboard' ? Lightbulb : 
                    activeTab === 'Links' ? Link2 : HistoryIcon
                } />
            )}

            <TaskCreationForm 
                isOpen={showTaskDrawer}
                onClose={() => setShowTaskDrawer(false)}
                onSuccess={fetchGroupData}
                groupId={id}
            />

            <TaskDetailsDrawer 
                isOpen={showDetails}
                taskId={selectedTaskId}
                onClose={() => setShowDetails(false)}
                onSuccess={fetchGroupData}
            />

            {showGroupDetailsModal && (
                <GroupDetailsModal
                    isOpen={showGroupDetailsModal}
                    onClose={() => setShowGroupDetailsModal(false)}
                    groupId={id}
                    onSuccess={fetchGroupData}
                />
            )}
            
            <CreateGroupModal 
                isOpen={showCreateGroup} 
                onClose={() => setShowCreateGroup(false)} 
                onSuccess={(newGroup) => {
                    fetchGroupData();
                    if (newGroup?.groupId) {
                        navigate(`/groups/${newGroup.groupId}`);
                    } else {
                        // refreshing group list usually happens in Sidebar, 
                        // but if we are in empty state we want to see the new group
                        window.location.reload(); 
                    }
                }} 
            />
        </div>
    );
};

const getDateRangeFilter = (taskDate, range, customStart, customEnd) => {
    if (!taskDate) return false;
    const d = new Date(taskDate);
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    
    switch (range) {
        case 'Today':
            return d >= today;
        case 'Yesterday': {
            const yesterday = new Date(today);
            yesterday.setDate(yesterday.getDate() - 1);
            return d >= yesterday && d < today;
        }
        case 'This Week': {
            const first = today.getDate() - today.getDay();
            const startOfWeek = new Date(today.setDate(first));
            return d >= startOfWeek;
        }
        case 'Last Week': {
            const first = today.getDate() - today.getDay() - 7;
            const startOfLastWeek = new Date(today.setDate(first));
            const endOfLastWeek = new Date(today.setDate(first + 6));
            return d >= startOfLastWeek && d <= endOfLastWeek;
        }
        case 'This Month': {
            const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
            return d >= startOfMonth;
        }
        case 'Last Month': {
            const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
            const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);
            return d >= startOfLastMonth && d <= endOfLastMonth;
        }
        case 'Next Week': {
            const first = today.getDate() - today.getDay() + 7;
            const startOfNextWeek = new Date(today.setDate(first));
            return d >= startOfNextWeek;
        }
        case 'Next Month': {
            const startOfNextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
            return d >= startOfNextMonth;
        }
        case 'This Year': {
            const startOfYear = new Date(now.getFullYear(), 0, 1);
            return d >= startOfYear;
        }
        case 'Custom': {
            if (!customStart || !customEnd) return true;
            return d >= new Date(customStart) && d <= new Date(customEnd);
        }
        case 'All Time':
        default:
            return true;
    }
};

export default GroupTasks;
