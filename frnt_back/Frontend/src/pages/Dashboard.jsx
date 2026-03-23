import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
    ChevronDown, Search, Table as TableIcon,
    BarChart3, Clock, AlertCircle, CheckCircle2, Timer,
    PlayCircle, Users as UsersIcon, RotateCcw, Loader2,
    Calendar, Folder, Tag, Share2, ClipboardList, Filter, X, Plus,
    ShieldAlert, Download
} from 'lucide-react';
import delegationService from '../services/delegationService';
import teamService from '../services/teamService';
import TaskCreationForm from '../components/delegation/TaskCreationForm';
import TaskCharts from '../components/delegation/TaskCharts';

// helper: export summary rows to CSV
const exportStatusCsv = (rows, firstColLabel) => {
    if (!rows || rows.length === 0) return;
    const headers = [firstColLabel, 'Total', 'Score', 'Overdue', 'Pending', 'In Progress', 'In Time', 'Delayed'];
    const cell = (v) => {
        if (v == null) return '';
        const s = String(v).replace(/"/g, '""');
        return `"${s}"`;
    };
    const lines = rows.map(r => [
        cell(r.label),
        cell(r.total),
        cell(((r.inTime / (r.total || 1)) * 100).toFixed(1) + '%'),
        cell(r.overdue),
        cell(r.pending),
        cell(r.inProgress),
        cell(r.inTime),
        cell(r.delayed),
    ].join(','));
    const csv = [headers.join(','), ...lines].join('\n');
    const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    const today = new Date().toLocaleDateString('en-CA');
    link.setAttribute('download', `dashboard_${firstColLabel.toLowerCase().replace(/\s+/g,'_')}_${today}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
};

// ─── Sub-components ───────────────────────────────────────────────────────────

const StatCard = ({ label, value, color, icon: Icon, borderColor }) => (
    <div className={`p-4 rounded-xl bg-white dark:bg-slate-900 shadow-sm flex flex-col gap-2 min-w-[150px] flex-1 border-l-4 ${borderColor} border-b-2 border-r-[1px] border-t-[1px] border-slate-100 dark:border-slate-800 transition-all hover:shadow-md`}>
        <div className="flex justify-between items-center">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-tight">{label}</span>
            <div className={`w-6 h-6 rounded-full flex items-center justify-center ${color}`}>
                <Icon size={14} className="text-white" />
            </div>
        </div>
        <span className="text-3xl font-extrabold text-slate-800 dark:text-white">{value}</span>
    </div>
);

const NavTab = ({ label, active, onClick, icon: Icon }) => (
    <button
        onClick={onClick}
        className={`flex items-center gap-2 px-4 py-3 text-sm font-bold transition-all relative ${active
            ? 'text-slate-800 dark:text-white'
            : 'text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'
            }`}>
        <Icon size={18} />
        {label}
        {active && <div className="absolute bottom-0 left-0 right-0 h-1 bg-emerald-500 rounded-t-full" />}
    </button>
);

const FilterButton = ({ label, active, onClick }) => (
    <button
        onClick={onClick}
        className={`px-6 py-2 rounded-full text-sm font-bold transition-all ${active
            ? 'bg-emerald-500 text-white shadow-lg shadow-emerald-500/30'
            : 'bg-slate-200 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-300 dark:hover:bg-slate-700'
            }`}>
        {label}
    </button>
);


// ─── Status Row Table ─────────────────────────────────────────────────────────

const StatusTable = ({ rows, firstColLabel, navigate, tabType }) => {
    if (rows.length === 0) {
        return (
            <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-800 p-10 text-center text-slate-400 font-medium">
                No data to display.
            </div>
        );
    }

    // Build the query string for /all-tasks based on tabType and row key
    const buildUrl = (row, status) => {
        const params = new URLSearchParams({ highlight: 'true' });
        if (status) params.set('status', status);
        if (tabType === 'Employees' || tabType === 'Delegated') params.set('doerId', row.rowKey);
        if (tabType === 'Groups') params.set('groupId', row.rowKey);
        if (tabType === 'Tags') params.set('tag', row.rowKey);
        if (tabType === 'Categories' || tabType === 'My Report') params.set('category', row.rowKey);
        return `/all-tasks?${params.toString()}`;
    };

    const NavCell = ({ children, row, status, className }) => (
        <td
            className={`px-6 py-4 cursor-pointer hover:opacity-75 transition-opacity ${className}`}
            onClick={() => navigate && navigate(buildUrl(row, status))}
            title={`View in All Tasks${status ? ` — ${status}` : ''}`}
        >
            {children}
        </td>
    );

    return (
        <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-sm overflow-hidden border border-slate-200 dark:border-slate-800 relative">
            {rows.length > 0 && (
                <button
                    onClick={() => exportStatusCsv(rows, firstColLabel)}
                    title="Download report"
                    className="absolute top-3 right-3 text-slate-500 hover:text-slate-800 dark:hover:text-white transition-colors z-10"
                >
                    <Download size={20} />
                </button>
            )}
            <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                    <thead className="bg-[#1a1c1e] text-white">
                        <tr>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider">{firstColLabel}</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider">Total</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider">
                                <div className="flex items-center gap-1">Score <AlertCircle size={12} className="opacity-70" /></div>
                            </th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider text-red-400">● Overdue</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider text-pink-400">○ Pending</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider text-orange-400">◔ In-Progress</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider text-teal-400">● In Time</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider text-rose-400">Delayed</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                        {rows.map((row, idx) => {
                            const score = ((row.inTime / (row.total || 1)) * 100).toFixed(1);
                            const pct = (n) => `${((n / (row.total || 1)) * 100).toFixed(0)}%`;
                            return (
                                <tr key={idx} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors group">
                                    {/* Row label — click = all tasks for this row */}
                                    <td className="px-6 py-4 cursor-pointer" onClick={() => navigate && navigate(buildUrl(row, null))}>
                                        <div className="flex items-center gap-3">
                                            <div className={`w-9 h-9 rounded-full border-2 flex items-center justify-center text-[10px] font-bold transition-all group-hover:scale-110 ${parseInt(score) > 70 ? 'border-emerald-500 text-emerald-500' : parseInt(score) > 40 ? 'border-orange-500 text-orange-500' : 'border-red-500 text-red-500'}`}>
                                                {score}%
                                            </div>
                                            <div>
                                                <span className="font-bold text-slate-800 dark:text-slate-200 whitespace-nowrap block group-hover:text-[#00d094] transition-colors">{row.label}</span>
                                                {row.sublabel && <span className="text-[10px] text-slate-400">{row.sublabel}</span>}
                                            </div>
                                        </div>
                                    </td>
                                    <NavCell row={row} status={null} className="font-bold text-slate-900 dark:text-white">{row.total}</NavCell>
                                    <NavCell row={row} status={null} className="font-bold text-emerald-600">{score}%</NavCell>
                                    <NavCell row={row} status="Overdue" className="font-bold text-red-500">{row.overdue} <span className="text-[10px] text-slate-400">({pct(row.overdue)})</span></NavCell>
                                    <NavCell row={row} status="Pending" className="font-bold text-pink-500">{row.pending} <span className="text-[10px] text-slate-400">({pct(row.pending)})</span></NavCell>
                                    <NavCell row={row} status="In Progress" className="font-bold text-orange-500">{row.inProgress} <span className="text-[10px] text-slate-400">({pct(row.inProgress)})</span></NavCell>
                                    <NavCell row={row} status="Completed" className="font-bold text-teal-500">{row.inTime} <span className="text-[10px] text-slate-400">({pct(row.inTime)})</span></NavCell>
                                    <NavCell row={row} status="Delayed" className="font-bold text-rose-500">{row.delayed} <span className="text-[10px] text-slate-400">({pct(row.delayed)})</span></NavCell>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

// ─── Helper: aggregate tasks into status rows ──────────────────────────────────

const buildRows = (tasks, getKey, getLabel, getSublabel) => {
    const map = {};
    tasks.forEach(task => {
        const key = getKey(task);
        if (!key) return;
        if (!map[key]) {
            map[key] = {
                rowKey: key, // preserve raw key (doerId, groupId, tag text, etc.) for navigation
                label: getLabel ? getLabel(task, key) : key,
                sublabel: getSublabel ? getSublabel(task, key) : undefined,
                total: 0, overdue: 0, pending: 0, inProgress: 0, inTime: 0, delayed: 0
            };
        }
        const row = map[key];
        row.total++;
        const s = task.status;
        if (s === 'Overdue') row.overdue++;
        else if (s === 'Pending') row.pending++;
        else if (s === 'In Progress') row.inProgress++;
        else if (s === 'Completed') row.inTime++;
        if (s !== 'Completed' && task.dueDate && new Date(task.dueDate) < new Date()) row.delayed++;
    });
    return Object.values(map).sort((a, b) => b.total - a.total);
};

const aggregateTaskStats = (tasks) => {
    const stats = { total: 0, overdue: 0, pending: 0, inProgress: 0, inTime: 0, delayed: 0 };
    tasks.forEach(task => {
        stats.total++;
        const s = task.status;
        if (s === 'Overdue') stats.overdue++;
        else if (s === 'Pending') stats.pending++;
        else if (s === 'In Progress') stats.inProgress++;
        else if (s === 'Completed') stats.inTime++;
        if (s !== 'Completed' && task.dueDate && new Date(task.dueDate) < new Date()) stats.delayed++;
    });
    return stats;
};

// ─── Tab Content Components ───────────────────────────────────────────────────

const EmployeesTab = ({ tasks, users, navigate }) => {
    const rows = (users || []).map(u => {
        const userTasks = tasks.filter(t => t.doerId === u.userId || t.doerId === u.id);
        const stats = aggregateTaskStats(userTasks);
        return {
            rowKey: u.userId || u.id,
            label: `${u.firstName || ''} ${u.lastName || ''}`.trim() || 'Unknown',
            sublabel: u.designation || u.department || '',
            ...stats
        };
    }).sort((a, b) => b.total - a.total);

    return <StatusTable rows={rows} firstColLabel="Employee Name" navigate={navigate} tabType="Employees" />;
};

const GroupsTab = ({ tasks, groups, navigate }) => {
    const rows = (groups || []).map(g => {
        const groupId = g.groupId || g.id;
        const groupTasks = tasks.filter(t => t.groupId === groupId);
        const stats = aggregateTaskStats(groupTasks);
        return {
            rowKey: groupId,
            label: g.name || 'Unknown Group',
            ...stats
        };
    }).sort((a, b) => b.total - a.total);

    return <StatusTable rows={rows} firstColLabel="Group" navigate={navigate} tabType="Groups" />;
};

const DelegatedTab = ({ tasks, currentUserId, users, navigate }) => {
    const delegated = tasks.filter(t => t.assignerId === currentUserId);

    const getUserName = (id) => {
        const u = users.find(u => u.userId === id || u.id === id);
        return u ? `${u.firstName || ''} ${u.lastName || ''}`.trim() : 'Unknown';
    };

    const rows = buildRows(
        delegated,
        t => t.doerId,
        (t) => getUserName(t.doerId)
    );

    return <StatusTable rows={rows} firstColLabel="Assigned To" navigate={navigate} tabType="Delegated" />;
};

const TagsTab = ({ tasks, navigate }) => {
    const tagMap = {};
    tasks.forEach(task => {
        const taskTags = task.tags ? (typeof task.tags === 'string' ? JSON.parse(task.tags) : task.tags) : [];
        if (!Array.isArray(taskTags) || taskTags.length === 0) {
            const key = '__notag__';
            if (!tagMap[key]) tagMap[key] = { rowKey: key, label: 'No Tag', color: null, total: 0, overdue: 0, pending: 0, inProgress: 0, inTime: 0, delayed: 0 };
            const row = tagMap[key];
            row.total++;
            const s = task.status;
            if (s === 'Overdue') row.overdue++;
            else if (s === 'Pending') row.pending++;
            else if (s === 'In Progress') row.inProgress++;
            else if (s === 'Completed') row.inTime++;
            if (s !== 'Completed' && task.dueDate && new Date(task.dueDate) < new Date()) row.delayed++;
            return;
        }
        taskTags.forEach(tag => {
            const key = tag.text || tag;
            if (!tagMap[key]) tagMap[key] = { rowKey: key, label: key, color: tag.color || null, total: 0, overdue: 0, pending: 0, inProgress: 0, inTime: 0, delayed: 0 };
            const row = tagMap[key];
            row.total++;
            const s = task.status;
            if (s === 'Overdue') row.overdue++;
            else if (s === 'Pending') row.pending++;
            else if (s === 'In Progress') row.inProgress++;
            else if (s === 'Completed') row.inTime++;
            if (s !== 'Completed' && task.dueDate && new Date(task.dueDate) < new Date()) row.delayed++;
        });
    });

    const rows = Object.values(tagMap).sort((a, b) => b.total - a.total);

    const buildUrl = (row, status) => {
        const params = new URLSearchParams({ highlight: 'true' });
        if (status) params.set('status', status);
        if (row.rowKey !== '__notag__') params.set('tag', row.rowKey);
        return `/all-tasks?${params.toString()}`;
    };

    const NavCell = ({ children, row, status, className }) => (
        <td className={`px-6 py-4 cursor-pointer hover:opacity-75 transition-opacity ${className}`}
            onClick={() => navigate && navigate(buildUrl(row, status))}
            title={`View in All Tasks${status ? ` — ${status}` : ''}`}>
            {children}
        </td>
    );

    if (rows.length === 0) {
        return <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-800 p-10 text-center text-slate-400 font-medium">No tags found.</div>;
    }

    return (
        <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-sm overflow-hidden border border-slate-200 dark:border-slate-800">
            <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                    <thead className="bg-[#1a1c1e] text-white">
                        <tr>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider">Tag</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider">Total</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider"><div className="flex items-center gap-1">Score <AlertCircle size={12} className="opacity-70" /></div></th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider text-red-400">● Overdue</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider text-pink-400">○ Pending</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider text-orange-400">◔ In-Progress</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider text-teal-400">● In Time</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider text-rose-400">Delayed</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                        {rows.map((row, idx) => {
                            const score = ((row.inTime / (row.total || 1)) * 100).toFixed(1);
                            const pct = (n) => `${((n / (row.total || 1)) * 100).toFixed(0)}%`;
                            return (
                                <tr key={idx} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors group">
                                    <td className="px-6 py-4 cursor-pointer" onClick={() => navigate && navigate(buildUrl(row, null))}>
                                        <div className="flex items-center gap-3">
                                            {row.color ? (
                                                <span className="flex items-center gap-2 px-3 py-1 rounded-full text-[11px] font-black uppercase tracking-widest border-2 group-hover:scale-105 transition-transform"
                                                    style={{ backgroundColor: `${row.color}15`, borderColor: `${row.color}30`, color: row.color }}>
                                                    <Tag size={10} strokeWidth={3} /> {row.label}
                                                </span>
                                            ) : (
                                                <span className="flex items-center gap-2 px-3 py-1 rounded-full text-[11px] font-black uppercase tracking-widest border-2 border-slate-200 text-slate-400 group-hover:scale-105 transition-transform">
                                                    <Tag size={10} strokeWidth={3} /> {row.label}
                                                </span>
                                            )}
                                        </div>
                                    </td>
                                    <NavCell row={row} status={null} className="font-bold text-slate-900 dark:text-white">{row.total}</NavCell>
                                    <NavCell row={row} status={null} className="font-bold text-emerald-600">{score}%</NavCell>
                                    <NavCell row={row} status="Overdue" className="font-bold text-red-500">{row.overdue} <span className="text-[10px] text-slate-400">({pct(row.overdue)})</span></NavCell>
                                    <NavCell row={row} status="Pending" className="font-bold text-pink-500">{row.pending} <span className="text-[10px] text-slate-400">({pct(row.pending)})</span></NavCell>
                                    <NavCell row={row} status="In Progress" className="font-bold text-orange-500">{row.inProgress} <span className="text-[10px] text-slate-400">({pct(row.inProgress)})</span></NavCell>
                                    <NavCell row={row} status="Completed" className="font-bold text-teal-500">{row.inTime} <span className="text-[10px] text-slate-400">({pct(row.inTime)})</span></NavCell>
                                    <NavCell row={row} status="Delayed" className="font-bold text-rose-500">{row.delayed} <span className="text-[10px] text-slate-400">({pct(row.delayed)})</span></NavCell>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

const MonthlyTab = ({ tasks, navigate }) => {
    const getMonthKey = (task) => { const d = new Date(task.createdAt); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`; };
    const getMonthLabel = (task) => { const d = new Date(task.createdAt); return `${d.toLocaleString('default', { month: 'long' })} ${d.getFullYear()}`; };
    const rows = buildRows(tasks, getMonthKey, getMonthLabel).sort((a, b) => b.rowKey.localeCompare(a.rowKey));
    return <StatusTable rows={rows} firstColLabel="Month" navigate={navigate} tabType="Monthly" />;
};

const DailyTab = ({ tasks, navigate }) => {
    const rows = buildRows(
        tasks,
        t => new Date(t.createdAt).toLocaleDateString('en-CA'),
        (t) => new Date(t.createdAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })
    ).sort((a, b) => b.rowKey.localeCompare(a.rowKey));
    return <StatusTable rows={rows} firstColLabel="Date" navigate={navigate} tabType="Daily" />;
};

const OverdueTab = ({ tasks }) => {
    const overdue = tasks.filter(t => t.status === 'Overdue' || (t.status !== 'Completed' && t.dueDate && new Date(t.dueDate) < new Date()));

    const renderTimeAgo = (dateString) => {
        if (!dateString) return 'N/A';
        const diff = Math.floor((new Date() - new Date(dateString)) / 1000);
        if (diff < 60) return `${diff}s ago`;
        if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
        if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
        const days = Math.floor(diff / 86400);
        if (days < 30) return `${days} days ago`;
        return `${Math.floor(days / 30)} months ago`;
    };

    const exportOverdue = () => {
        if (overdue.length === 0) return;
        const headers = ['Task','Due Date','Overdue Since','Status'];
        const cell = v => {
            if (v == null) return '';
            const s = String(v).replace(/"/g,'""');
            return `"${s}"`;
        };
        const lines = overdue.map(t => [
            cell(t.taskTitle),
            cell(t.dueDate ? new Date(t.dueDate).toLocaleDateString('en-GB',{day:'numeric',month:'short',year:'numeric'}) : ''),
            cell(renderTimeAgo(t.dueDate)),
            cell(t.status)
        ].join(','));
        const csv = [headers.join(','), ...lines].join('\n');
        const blob = new Blob(['\uFEFF' + csv], { type:'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        const today = new Date().toLocaleDateString('en-CA');
        link.setAttribute('download', `overdue_tasks_${today}.csv`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    };

    return (
        <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-sm overflow-hidden border border-slate-200 dark:border-slate-800 relative">
            {overdue.length > 0 && (
                <button
                    onClick={exportOverdue}
                    title="Download report"
                    className="absolute top-3 right-3 text-slate-500 hover:text-slate-800 dark:hover:text-white transition-colors z-10"
                >
                    <Download size={20} />
                </button>
            )}
            <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                    <thead className="bg-[#1a1c1e] text-white">
                        <tr>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider">Task</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider text-red-400">Due Date</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider text-red-400">Overdue Since</th>
                            <th className="px-6 py-4 text-[11px] font-bold uppercase tracking-wider">Status</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                        {overdue.length === 0 && (
                            <tr><td colSpan="4" className="px-6 py-10 text-center text-slate-400">No overdue tasks 🎉</td></tr>
                        )}
                        {overdue.map((t, i) => (
                            <tr key={i} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                                <td className="px-6 py-4 font-bold text-slate-800 dark:text-slate-200">{t.taskTitle}</td>
                                <td className="px-6 py-4 font-bold text-red-500">{t.dueDate ? new Date(t.dueDate).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }) : 'N/A'}</td>
                                <td className="px-6 py-4 font-bold text-slate-500">{renderTimeAgo(t.dueDate)}</td>
                                <td className="px-6 py-4"><span className="px-2 py-1 text-[10px] font-bold rounded-full bg-red-100 text-red-600 uppercase">{t.status}</span></td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

const MyReportTab = ({ tasks, currentUserId, navigate }) => {
    const mine = tasks.filter(t => t.doerId === currentUserId);
    const rows = buildRows(mine, t => t.category || 'Uncategorized', (t) => t.category || 'Uncategorized');
    return <StatusTable rows={rows} firstColLabel="Category" navigate={navigate} tabType="My Report" />;
};

const CategoriesTab = ({ tasks, navigate }) => {
    const rows = buildRows(tasks, t => t.category || 'Uncategorized', t => t.category || 'Uncategorized');
    return <StatusTable rows={rows} firstColLabel="Category" navigate={navigate} tabType="Categories" />;
};

// ─── Main Dashboard ───────────────────────────────────────────────────────────

const Dashboard = () => {
    const navigate = useNavigate();
    const storedUser = JSON.parse(localStorage.getItem('user'));
    const currentUserId = storedUser?.user?.id || storedUser?.id;
    const userRole = (storedUser?.user?.role || storedUser?.role || '').toUpperCase();
    const isAdmin = ['ADMIN', 'SUPERADMIN', 'MANAGER'].includes(userRole);

    const ALL_TABS = [
        { label: 'Employees', icon: UsersIcon, adminOnly: true },
        { label: 'Groups', icon: Folder },
        { label: 'My Report', icon: CheckCircle2 },
        { label: 'Delegated', icon: Share2 },
        { label: 'Daily', icon: Calendar },
        { label: 'Monthly', icon: Calendar },
        { label: 'Overdue', icon: Clock },
        { label: 'Tags', icon: Tag },
        { label: 'Categories', icon: Folder },
    ];

    const navTabs = ALL_TABS.filter(t => !t.adminOnly || isAdmin);

    const [activeTimeFilter, setActiveTimeFilter] = useState('All Time');
    const [viewMode, setViewMode] = useState('table');
    const [bottomTab, setBottomTab] = useState('Monthly');
    const [showDelegationDrawer, setShowDelegationDrawer] = useState(false);

    // Filter states
    const [search, setSearch] = useState('');
    const [category, setCategory] = useState('Category');
    const [assignedTo, setAssignedTo] = useState('Assigned To');
    const [tag, setTag] = useState('Tag');
    const [frequency, setFrequency] = useState('Frequency');
    const [dateRange, setDateRange] = useState({ start: '', end: '' });
    const [showCustomDate, setShowCustomDate] = useState(false);

    const [tasks, setTasks] = useState([]);
    const [users, setUsers] = useState([]);
    const [groups, setGroups] = useState([]);
    const [categories, setCategories] = useState([]);
    const [tags, setTags] = useState([]);
    const [loading, setLoading] = useState(true);

    const timeFilters = ['Today', 'Yesterday', 'This Week', 'Last Week', 'This Month', 'Last Month', 'This Year', 'All Time', 'Custom'];


    useEffect(() => {
        fetchUsers();
        fetchCategories();
        fetchGroups();
        fetchTags();
    }, []);

    useEffect(() => {
        if (activeTimeFilter !== 'Custom') {
            const range = getDateRange(activeTimeFilter);
            setDateRange(range);
            setShowCustomDate(false);
        } else {
            setShowCustomDate(true);
        }
    }, [activeTimeFilter]);

    useEffect(() => {
        fetchTasks();
    }, [search, category, assignedTo, tag, frequency, dateRange, groups]);

    const fetchUsers = async () => {
        try {
            const res = await teamService.getUsers();
            setUsers(Array.isArray(res) ? res : (res.data || []));
        } catch (err) {
            console.error('Failed to fetch users:', err);
        }
    };

    const fetchGroups = async () => {
        try {
            const res = await delegationService.getGroups();
            setGroups(Array.isArray(res) ? res : (res.data || []));
        } catch (err) {
            console.error('Failed to fetch groups:', err);
        }
    };

    const fetchCategories = async () => {
        try {
            const res = await delegationService.getCategories();
            setCategories(Array.isArray(res) ? res : (res.data || []));
        } catch (err) {
            console.error('Failed to fetch categories:', err);
        }
    };

    const fetchTags = async () => {
        try {
            const res = await delegationService.getTagsList();
            setTags(Array.isArray(res) ? res : (res.data || []));
        } catch (err) {
            console.error('Failed to fetch tags:', err);
        }
    };

    const fetchTasks = async () => {
        try {
            setLoading(true);
            const filters = {
                search,
                category: category !== 'Category' ? category : undefined,
                doerId: assignedTo !== 'Assigned To' ? assignedTo : undefined,
                tag: tag !== 'Tag' ? tag : undefined,
                frequency: frequency !== 'Frequency' ? frequency : undefined,
                startDate: dateRange.start,
                endDate: dateRange.end
            };
            const response = await delegationService.getDelegations(filters);
            let fetchedTasks = response.data || [];

            if (!isAdmin) { // Filter tasks based on role
                const userGroupIds = (groups || []).map(g => g.groupId || g.id);
                fetchedTasks = fetchedTasks.filter(t => {
                    if (t.assignerId === currentUserId) return true;
                    if (t.doerId === currentUserId) return true;
                    if (t.groupId && userGroupIds.includes(t.groupId)) return true;
                    try {
                        const loopIds = typeof t.inLoopIds === 'string' ? JSON.parse(t.inLoopIds) : (t.inLoopIds || []);
                        if (Array.isArray(loopIds) && loopIds.includes(currentUserId)) return true;
                    } catch (e) {}
                    return false;
                });
            }

            setTasks(fetchedTasks);
        } catch (err) {
            console.error('Failed to fetch tasks:', err);
        } finally {
            setLoading(false);
        }
    };

    const getDateRange = (filter) => {
        const now = new Date();
        let start = new Date();
        let end = new Date();
        end.setHours(23, 59, 59, 999);
        switch (filter) {
            case 'Today': start.setHours(0, 0, 0, 0); break;
            case 'Yesterday':
                start.setDate(now.getDate() - 1); start.setHours(0, 0, 0, 0);
                end.setDate(now.getDate() - 1); end.setHours(23, 59, 59, 999); break;
            case 'This Week': { const d = now.getDay(); start.setDate(now.getDate() - d + (d === 0 ? -6 : 1)); start.setHours(0, 0, 0, 0); break; }
            case 'Last Week': { const ln = new Date(); const ld = ln.getDay(); const ls = new Date(ln.setDate(ln.getDate() - ld - 6 + (ld === 0 ? -6 : 1))); ls.setHours(0, 0, 0, 0); start = ls; end = new Date(ls.getTime() + 6 * 86400000); end.setHours(23, 59, 59, 999); break; }
            case 'This Month': start = new Date(now.getFullYear(), now.getMonth(), 1); break;
            case 'Last Month': start = new Date(now.getFullYear(), now.getMonth() - 1, 1); end = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999); break;
            case 'This Year': start = new Date(now.getFullYear(), 0, 1); break;
            case 'All Time': return { start: '', end: '' };
            default: return { start: '', end: '' };
        }
        return { start: start.toISOString(), end: end.toISOString() };
    };

    const handleClearFilters = () => {
        setActiveTimeFilter('All Time');
        setSearch('');
        setCategory('Category');
        setAssignedTo('Assigned To');
        setTag('Tag');
        setFrequency('Frequency');
        setDateRange({ start: '', end: '' });
    };

    const stats = [
        { label: 'Overdue', value: tasks.filter(t => t.status === 'Overdue').length, icon: AlertCircle, color: 'bg-red-500', borderColor: 'border-red-500' },
        { label: 'Pending', value: tasks.filter(t => t.status === 'Pending').length, icon: Clock, color: 'bg-pink-500', borderColor: 'border-pink-500' },
        { label: 'In Progress', value: tasks.filter(t => t.status === 'In Progress').length, icon: PlayCircle, color: 'bg-orange-500', borderColor: 'border-orange-500' },
        { label: 'Completed', value: tasks.filter(t => t.status === 'Completed').length, icon: CheckCircle2, color: 'bg-emerald-500', borderColor: 'border-emerald-500' },
        { label: 'In Time', value: tasks.filter(t => t.status === 'Completed' && (!t.dueDate || new Date(t.dueDate) >= new Date(t.updatedAt))).length, icon: Timer, color: 'bg-teal-500', borderColor: 'border-teal-500' },
        { label: 'Delayed', value: tasks.filter(t => t.status !== 'Completed' && t.dueDate && new Date(t.dueDate) < new Date()).length, icon: Clock, color: 'bg-rose-500', borderColor: 'border-rose-500' }
    ];

    const renderTab = () => {
        switch (bottomTab) {
            case 'Employees': return isAdmin ? <EmployeesTab tasks={tasks} users={users} navigate={navigate} /> : null;
            case 'Groups': return <GroupsTab tasks={tasks} groups={groups} navigate={navigate} />;
            case 'Delegated': return <DelegatedTab tasks={tasks} currentUserId={currentUserId} users={users} navigate={navigate} />;
            case 'Tags': return <TagsTab tasks={tasks} navigate={navigate} />;
            case 'My Report': return <MyReportTab tasks={tasks} currentUserId={currentUserId} navigate={navigate} />;
            case 'Categories': return <CategoriesTab tasks={tasks} navigate={navigate} />;
            case 'Monthly': return <MonthlyTab tasks={tasks} navigate={navigate} />;
            case 'Daily': return <DailyTab tasks={tasks} navigate={navigate} />;
            case 'Overdue': return <OverdueTab tasks={tasks} />;
            default: return null;
        }
    };

    return (
        <div className="p-6 flex flex-col gap-8 bg-slate-50 dark:bg-slate-950 min-h-screen animate-in fade-in duration-500">
            {/* Time Filters */}
            <div className="flex flex-col gap-4">
                <div className="flex flex-wrap gap-2 items-center justify-center">
                    {timeFilters.map(f => (
                        <FilterButton key={f} label={f} active={activeTimeFilter === f} onClick={() => setActiveTimeFilter(f)} />
                    ))}
                </div>
                {showCustomDate && (
                    <div className="flex justify-center gap-4 animate-in slide-in-from-top-2 duration-300">
                        <div className="flex flex-col gap-1">
                            <label className="text-[10px] font-bold text-emerald-500 uppercase px-1">Start Date</label>
                            <input type="date" value={dateRange.start.split('T')[0]} onChange={e => setDateRange(p => ({ ...p, start: e.target.value ? new Date(e.target.value).toISOString() : '' }))} className="bg-white dark:bg-slate-900 border border-emerald-500/30 rounded-lg px-4 py-2 text-sm outline-none focus:ring-2 focus:ring-emerald-500/20" />
                        </div>
                        <div className="flex flex-col gap-1">
                            <label className="text-[10px] font-bold text-emerald-500 uppercase px-1">End Date</label>
                            <input type="date" value={dateRange.end.split('T')[0]} onChange={e => setDateRange(p => ({ ...p, end: e.target.value ? new Date(e.target.value).toISOString() : '' }))} className="bg-white dark:bg-slate-900 border border-emerald-500/30 rounded-lg px-4 py-2 text-sm outline-none focus:ring-2 focus:ring-emerald-500/20" />
                        </div>
                    </div>
                )}
            </div>

            {/* Top Area: Summary Cards (Table Mode) or Donut Charts (Charts Mode) */}
            {viewMode === 'table' ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
                    {stats.map((s, i) => <StatCard key={i} {...s} />)}
                </div>
            ) : (
                <div className="w-full">
                    <TaskCharts 
                        tasks={tasks} 
                        users={users} 
                        groups={groups} 
                        currentUserId={currentUserId} 
                        type="donuts" 
                    />
                </div>
            )}

            {/* Filters */}
            <div className="flex flex-wrap items-center gap-4 bg-slate-200/50 dark:bg-slate-900/50 p-2 rounded-2xl">
                <div className="grid grid-cols-2 md:grid-cols-5 gap-2 flex-1">
                    <div className="relative">
                        <select value={assignedTo} onChange={e => setAssignedTo(e.target.value)} className="w-full bg-white dark:bg-slate-800 border-none rounded-xl py-3 pl-4 pr-10 text-sm font-bold appearance-none outline-none focus:ring-2 focus:ring-emerald-500/20">
                            <option>Assigned To</option>
                            {users.map(u => <option key={u.userId || u.id} value={u.userId || u.id}>{u.firstName} {u.lastName}</option>)}
                        </select>
                        <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" size={16} />
                    </div>
                    <div className="relative">
                        <select value={category} onChange={e => setCategory(e.target.value)} className="w-full bg-white dark:bg-slate-800 border-none rounded-xl py-3 pl-4 pr-10 text-sm font-bold appearance-none outline-none focus:ring-2 focus:ring-emerald-500/20">
                            <option>Category</option>
                            {categories.map(c => <option key={c.id} value={c.name}>{c.name}</option>)}
                        </select>
                        <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" size={16} />
                    </div>
                    <div className="relative">
                        <select value={tag} onChange={e => setTag(e.target.value)} className="w-full bg-white dark:bg-slate-800 border-none rounded-xl py-3 pl-4 pr-10 text-sm font-bold appearance-none outline-none focus:ring-2 focus:ring-emerald-500/20">
                            <option>Tag</option>
                            {tags.map((t, idx) => <option key={t.id || idx} value={t.name}>{t.name}</option>)}
                        </select>
                        <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" size={16} />
                    </div>
                    <div className="relative">
                        <select value={frequency} onChange={e => setFrequency(e.target.value)} className="w-full bg-white dark:bg-slate-800 border-none rounded-xl py-3 pl-4 pr-10 text-sm font-bold appearance-none outline-none focus:ring-2 focus:ring-emerald-500/20">
                            <option>Frequency</option>
                            {["Daily", "Weekly", "monthly", "Yearly", "Periodically", "Custom", "Once"].map((f, idx) => <option key={idx} value={f}>{f}</option>)}
                        </select>
                        <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" size={16} />
                    </div>
                    <div className="relative flex-1 col-span-2 md:col-span-1">
                        <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400"><Search size={18} /></div>
                        <input type="text" placeholder="Search tasks..." value={search} onChange={e => setSearch(e.target.value)} className="w-full bg-white dark:bg-slate-800 border-none rounded-xl py-3 pl-12 pr-4 text-sm font-bold outline-none focus:ring-2 focus:ring-emerald-500/20" />
                    </div>
                </div>
                <button onClick={handleClearFilters} className="flex items-center gap-2 px-5 py-3 bg-slate-200 dark:bg-slate-800 rounded-xl text-sm font-bold text-slate-600 dark:text-slate-400 hover:bg-slate-300 dark:hover:bg-slate-700 transition-all">
                    <RotateCcw size={16} /> Clear
                </button>
            </div>

            {/* View Mode */}
            <div className="flex justify-center">
                <div className="bg-slate-200 dark:bg-slate-800 p-1 rounded-full flex gap-1">
                    <button onClick={() => setViewMode('table')} className={`flex items-center gap-2 px-8 py-2 rounded-full text-sm font-bold transition-all ${viewMode === 'table' ? 'bg-emerald-500 text-white shadow-lg' : 'text-slate-500'}`}>
                        <TableIcon size={18} /> Table
                    </button>
                    <button onClick={() => setViewMode('charts')} className={`flex items-center gap-2 px-8 py-2 rounded-full text-sm font-bold transition-all ${viewMode === 'charts' ? 'bg-emerald-500 text-white shadow-lg' : 'text-slate-500'}`}>
                        <BarChart3 size={18} /> Bar Chart
                    </button>
                </div>
            </div>


            {/* Nav Tabs - Only in Table Mode */}
            {viewMode === 'table' && (
                <div className="border-b border-slate-200 dark:border-slate-800 overflow-x-auto scrollbar-none">
                    <div className="flex min-w-max md:w-full md:justify-center px-4">
                        {navTabs.map(tab => (
                            <NavTab key={tab.label} {...tab} active={bottomTab === tab.label} onClick={() => setBottomTab(tab.label)} />
                        ))}
                    </div>
                </div>
            )}

            {/* Content */}
            <div className="min-h-[400px]">
                {loading ? (
                    <div className="flex flex-col items-center justify-center h-64 gap-4">
                        <Loader2 className="animate-spin text-emerald-500" size={40} />
                        <p className="text-sm font-bold text-slate-500 uppercase tracking-widest">Loading Report...</p>
                    </div>
                ) : viewMode === 'charts' ? (
                    <TaskCharts 
                        tasks={tasks} 
                        users={users} 
                        groups={groups} 
                        currentUserId={currentUserId} 
                    />
                ) : (
                    renderTab()
                )}
            </div>

            {/* FAB */}
            <button
                onClick={() => setShowDelegationDrawer(true)}
                className="fixed bottom-8 right-8 w-16 h-16 bg-emerald-500 text-white rounded-2xl shadow-2xl shadow-emerald-500/40 flex items-center justify-center hover:scale-110 active:scale-95 transition-all z-50 group"
            >
                <Plus size={32} className="group-hover:rotate-90 transition-transform duration-300" />
            </button>

            <TaskCreationForm
                isOpen={showDelegationDrawer}
                onClose={() => setShowDelegationDrawer(false)}
                onSuccess={fetchTasks}
            />
        </div>
    );
};

export default Dashboard;
