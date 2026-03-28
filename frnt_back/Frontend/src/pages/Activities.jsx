import React, { useState, useEffect } from 'react';
import { 
    Search, RotateCcw, ChevronDown, CheckCircle2, 
    MoreHorizontal, Clock, User, ExternalLink, 
    MessageSquare, AlertCircle, PlayCircle, PlusCircle,
    Layers, ArrowRight
} from 'lucide-react';
import activityService from '../services/activityService';
import teamService from '../services/teamService';
import { toast } from 'react-hot-toast';
import TaskDetailsDrawer from '../components/delegation/TaskDetailsDrawer';

const Activities = () => {
    const [activities, setActivities] = useState([]);
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [dateRange, setDateRange] = useState('This Month');
    const [updatedBy, setUpdatedBy] = useState('Updated By');
    const [selectedTaskId, setSelectedTaskId] = useState(null);
    const [showDetails, setShowDetails] = useState(false);

    useEffect(() => {
        fetchUsers();
        fetchActivities();
    }, []);

    useEffect(() => {
        fetchActivities();
    }, [dateRange, updatedBy]);

    const fetchUsers = async () => {
        try {
            const data = await teamService.getUsers();
            setUsers(Array.isArray(data) ? data : (data.data || []));
        } catch (err) {
            console.error('Failed to fetch users:', err);
        }
    };

    const fetchActivities = async () => {
        try {
            setLoading(true);
            const filters = {
                userId: updatedBy !== 'Updated By' ? updatedBy : undefined,
                search: search || undefined
            };

            // Calculate dates for predefined ranges
            const now = new Date();
            if (dateRange === 'Today') {
                filters.startDate = new Date(now.setHours(0,0,0,0)).toISOString();
            } else if (dateRange === 'This Week') {
                const start = new Date(now.setDate(now.getDate() - now.getDay()));
                filters.startDate = start.toISOString();
            } else if (dateRange === 'This Month') {
                filters.startDate = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
            }

            const res = await activityService.getActivities(filters);
            setActivities(res.data || []);
        } catch (err) {
            console.error('Failed to fetch activities:', err);
            toast.error('Failed to load activities');
        } finally {
            setLoading(false);
        }
    };

    const handleRefresh = () => {
        fetchActivities();
    };

    const getInitials = (user) => {
        if (!user) return '?';
        return `${user.firstName?.[0] || ''}${user.lastName?.[0] || ''}`.toUpperCase();
    };

    const formatTime = (date) => {
        return new Date(date).toLocaleString('en-US', { 
            month: 'short', 
            day: 'numeric', 
            year: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            hour12: true
        });
    };

    const getActivityIcon = (type) => {
        switch (type) {
            case 'task_created': return <PlusCircle size={20} className="text-red-500" />;
            case 'subtask_created': return <PlusCircle size={20} className="text-emerald-500" />;
            case 'status_change': return <CheckCircle2 size={20} className="text-red-500" />;
            case 'remark': return <MessageSquare size={20} className="text-blue-500" />;
            default: return <Clock size={20} className="text-slate-400" />;
        }
    };

    // Aggregate activity counts by user for the summary cards
    const userStats = activities.reduce((acc, act) => {
        if (act.user) {
            const uid = act.user.userId || act.user.id;
            if (!acc[uid]) acc[uid] = { user: act.user, count: 0 };
            acc[uid].count++;
        }
        return acc;
    }, {});

    const sortedStats = Object.values(userStats).sort((a, b) => b.count - a.count);

    const filteredActivities = activities.filter(a => {
        if (!search) return true;
        const s = search.toLowerCase();
        return (
            a.title.toLowerCase().includes(s) || 
            a.description.toLowerCase().includes(s) ||
            `${a.user?.firstName} ${a.user?.lastName}`.toLowerCase().includes(s)
        );
    });

    return (
        <div className="p-6 bg-[#e6f9f1] min-h-screen">
            {/* Header / Filters Section */}
            <div className="max-w-7xl mx-auto space-y-6">
                
                {/* Filters Bar */}
                <div className="flex flex-wrap items-center justify-end gap-3 px-4">
                    <div className="flex flex-col gap-1">
                        <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">Date Range</span>
                        <div className="relative">
                            <select 
                                value={dateRange} 
                                onChange={(e) => setDateRange(e.target.value)}
                                className="h-10 pl-3 pr-8 bg-white border border-emerald-500/30 rounded-lg text-xs font-bold text-slate-700 outline-none appearance-none cursor-pointer shadow-sm min-w-[120px]"
                            >
                                <option>This Month</option>
                                <option>Today</option>
                                <option>This Week</option>
                                <option>All Time</option>
                            </select>
                            <ChevronDown size={14} className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                        </div>
                    </div>

                    <div className="flex flex-col gap-1">
                        <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">Updated By</span>
                        <div className="relative">
                            <select 
                                value={updatedBy} 
                                onChange={(e) => setUpdatedBy(e.target.value)}
                                className="h-10 pl-3 pr-8 bg-white border border-emerald-500/30 rounded-lg text-xs font-bold text-slate-700 outline-none appearance-none cursor-pointer shadow-sm min-w-[120px]"
                            >
                                <option>Updated By</option>
                                {users.map(u => (
                                    <option key={u.userId || u.id} value={u.userId || u.id}>
                                        {u.firstName} {u.lastName}
                                    </option>
                                ))}
                            </select>
                            <ChevronDown size={14} className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                        </div>
                    </div>

                    <div className="flex flex-col gap-1 flex-1 max-w-xs">
                        <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest invisible">Search</span>
                        <div className="relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                            <input 
                                type="text"
                                placeholder="Search"
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                                className="w-full h-10 pl-10 pr-4 bg-white border border-slate-200 rounded-lg text-xs font-bold outline-none focus:ring-2 focus:ring-emerald-500/20"
                            />
                        </div>
                    </div>

                    <button 
                        onClick={handleRefresh}
                        className="h-10 w-10 mt-5 bg-[#00d094] text-white rounded-lg flex items-center justify-center hover:bg-[#00ba84] transition-all active:scale-95 shadow-sm self-end"
                    >
                        <RotateCcw size={18} strokeWidth={3} />
                    </button>
                </div>

                {/* User Summary Cards */}
                <div className="flex flex-wrap justify-center gap-4 py-2">
                    {sortedStats.slice(0, 5).map((stat, i) => (
                        <div key={i} className="bg-white rounded-xl shadow-sm border border-emerald-100 p-4 flex items-center gap-4 min-w-[180px] relative">
                            <div className="relative">
                                <div className={`w-12 h-12 rounded-full flex items-center justify-center text-sm font-black ${
                                    i % 2 === 0 ? 'bg-cyan-400 text-white' : 'bg-red-500 text-white'
                                }`}>
                                    {getInitials(stat.user)}
                                </div>
                                <div className="absolute -top-1 -right-1 bg-white rounded-md shadow-sm p-0.5 border border-slate-100">
                                    <PlusCircle size={10} className="text-slate-800" strokeWidth={3} />
                                </div>
                            </div>
                            <div className="flex flex-col">
                                <span className="text-xl font-black text-slate-800 leading-none">{stat.count}</span>
                                <span className="text-xs font-bold text-slate-500 mt-1">{stat.user.firstName}</span>
                            </div>
                        </div>
                    ))}
                </div>

                {/* Activity Feed */}
                <div className="space-y-3 pb-20">
                    {loading ? (
                        <div className="bg-white/50 rounded-2xl p-20 flex flex-col items-center justify-center gap-4">
                            <div className="w-10 h-10 border-4 border-[#00d094] border-t-transparent rounded-full animate-spin" />
                            <p className="text-sm font-bold text-slate-400 uppercase tracking-widest">Loading Activities...</p>
                        </div>
                    ) : filteredActivities.length === 0 ? (
                        <div className="bg-white/50 rounded-2xl p-20 flex flex-col items-center justify-center text-center">
                            <AlertCircle size={40} className="text-slate-300 mb-4" />
                            <h3 className="text-lg font-black text-slate-700">No Activities Found</h3>
                            <p className="text-sm text-slate-400 mt-1">Try adjusting your filters or date range</p>
                        </div>
                    ) : (
                        filteredActivities.map((act) => (
                            <div 
                                key={act.id}
                                onClick={() => { setSelectedTaskId(act.relatedId); setShowDetails(true); }}
                                className="bg-white rounded-xl shadow-sm border border-white p-4 flex items-center gap-4 group hover:shadow-md transition-all cursor-pointer"
                            >
                                <div className="p-2 border border-slate-100 rounded-full bg-slate-50">
                                    {getActivityIcon(act.type)}
                                </div>

                                <div className="flex-1 min-w-0">
                                    <div className="flex items-center gap-2">
                                        <span className="text-sm font-bold text-slate-500">Title:</span>
                                        <span className="text-sm font-black text-slate-800 truncate">{act.title}</span>
                                    </div>
                                    <div className="flex items-center gap-2 mt-0.5">
                                        <span className="text-xs font-bold text-slate-400 leading-relaxed truncate">
                                            {act.description}
                                        </span>
                                    </div>
                                </div>

                                {/* Placeholder IDs like T-6 -> T-11 */}
                                <div className="hidden sm:flex items-center gap-2 px-3">
                                    <div className="px-2 py-0.5 bg-slate-200 text-slate-600 rounded-lg text-[10px] font-bold">T-{Math.floor(Math.random() * 20)}</div>
                                    <ArrowRight size={14} className="text-slate-400" />
                                    <div className="px-2 py-0.5 bg-slate-200 text-slate-600 rounded-lg text-[10px] font-bold">T-{Math.floor(Math.random() * 50)}</div>
                                </div>

                                <div className="flex items-center gap-3 shrink-0">
                                    <div className="flex items-center gap-2 bg-slate-50 px-2 py-1 rounded-lg">
                                        <div className={`w-8 h-8 rounded-full flex items-center justify-center text-[10px] font-black text-white ${
                                            getInitials(act.user) === 'SS' ? 'bg-cyan-400' : 'bg-red-500'
                                        }`}>
                                            {getInitials(act.user)}
                                        </div>
                                        <div className="hidden md:flex flex-col">
                                            <span className="text-[11px] font-black text-slate-700 leading-none">
                                                {act.user?.firstName} {act.user?.lastName}
                                            </span>
                                            <span className="text-[9px] font-bold text-slate-400 mt-1 uppercase">
                                                {act.user?.designation || 'Staff'}
                                            </span>
                                        </div>
                                    </div>

                                    <div className="text-right hidden sm:block">
                                        <span className="text-xs font-bold text-slate-500 block">{formatTime(act.createdAt)}</span>
                                    </div>

                                    <button className="p-2 text-[#00d094] hover:bg-emerald-50 rounded-lg transition-all">
                                        <ExternalLink size={18} />
                                    </button>
                                </div>
                            </div>
                        ))
                    )}
                </div>
            </div>

            <TaskDetailsDrawer 
                isOpen={showDetails}
                taskId={selectedTaskId}
                onClose={() => setShowDetails(false)}
                onSuccess={fetchActivities}
            />
        </div>
    );
};

export default Activities;
