import React, { useState, useEffect, useMemo } from 'react';
import { 
    Search, Plus, RotateCcw, 
    Save, Tag, Clock, 
    Trash2, Edit, ChevronDown, CheckSquare,
    Calendar, ClipboardCheck, X, Flag, Repeat, Lock
} from 'lucide-react';
import TaskCreationForm from '../components/delegation/TaskCreationForm';
import taskTemplateService from '../services/taskTemplateService';
import delegationService from '../services/delegationService';
import teamService from '../services/teamService';
import { toast } from 'react-hot-toast';
import TaskTemplateForm from '../components/delegation/TaskTemplateForm';
import usePermissions from '../hooks/usePermissions';

const PRIORITY_OPTIONS = ['All', 'Low', 'Medium', 'High', 'Urgent'];
const FREQUENCY_OPTIONS = ['All', 'Once', 'Daily', 'Weekly', 'Monthly'];

const PRIORITY_STYLES = {
    Urgent: 'bg-red-50 text-red-500 border-red-200',
    High:   'bg-orange-50 text-orange-500 border-orange-200',
    Medium: 'bg-amber-50 text-amber-500 border-amber-200',
    Low:    'bg-emerald-50 text-emerald-600 border-emerald-200',
};

const TaskTemplates = () => {
    const { can, canOnOwn, loading: permLoading } = usePermissions();
    const [templates, setTemplates]               = useState([]);
    const [categories, setCategories]             = useState([]);
    const [users, setUsers]                       = useState([]);
    const [loading, setLoading]                   = useState(true);

    // Filters
    const [selectedCategory, setSelectedCategory] = useState('All');
    const [search, setSearch]                     = useState('');
    const [createdByFilter, setCreatedByFilter]   = useState('All');
    const [priorityFilter, setPriorityFilter]     = useState('All');
    const [frequencyFilter, setFrequencyFilter]   = useState('All');

    // Forms
    const [showForm, setShowForm]                 = useState(false);
    const [editingTemplate, setEditingTemplate]   = useState(null);
    const [showAssignForm, setShowAssignForm]     = useState(false);
    const [templateToAssign, setTemplateToAssign] = useState(null);

    useEffect(() => { fetchData(); }, []);

    const fetchData = async () => {
        try {
            setLoading(true);
            const [templatesRes, catRes, usersRes] = await Promise.all([
                taskTemplateService.getTemplates(),
                delegationService.getCategories(),
                teamService.getUsers()
            ]);
            setTemplates(templatesRes.data || []);
            setCategories(catRes.data || catRes || []);
            setUsers(Array.isArray(usersRes) ? usersRes : (usersRes.data || []));
        } catch (err) {
            console.error('Error fetching data:', err);
            toast.error('Failed to load templates');
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Are you sure you want to delete this template?')) return;
        try {
            await taskTemplateService.deleteTemplate(id);
            toast.success('Template deleted');
            fetchData();
        } catch (err) {
            toast.error('Failed to delete template');
        }
    };

    const handleEdit = (template) => {
        setEditingTemplate(template);
        setShowForm(true);
    };

    const handleAssign = (template) => {
        setTemplateToAssign(template);
        setShowAssignForm(true);
    };

    const resetFilters = () => {
        setSearch('');
        setSelectedCategory('All');
        setCreatedByFilter('All');
        setPriorityFilter('All');
        setFrequencyFilter('All');
    };

    const hasActiveFilters = search || selectedCategory !== 'All' || createdByFilter !== 'All' || priorityFilter !== 'All' || frequencyFilter !== 'All';

    const filteredTemplates = useMemo(() => templates.filter(t => {
        const q = search.toLowerCase();
        const matchesSearch =
            t.title.toLowerCase().includes(q) ||
            (t.description && t.description.toLowerCase().includes(q));
        const matchesCategory  = selectedCategory === 'All'   || t.category  === selectedCategory;
        const matchesUser      = createdByFilter  === 'All'   || t.createdBy === createdByFilter;
        const matchesPriority  = priorityFilter   === 'All'   || t.priority  === priorityFilter;
        const matchesFrequency = frequencyFilter  === 'All'   || (t.frequency || 'Once') === frequencyFilter;
        return matchesSearch && matchesCategory && matchesUser && matchesPriority && matchesFrequency;
    }), [templates, search, selectedCategory, createdByFilter, priorityFilter, frequencyFilter]);

    const categoriesWithCount = [
        { name: 'All', count: templates.length },
        ...categories.map(c => ({
            name: c.name,
            count: templates.filter(t => t.category === c.name).length
        }))
    ];

    // Active filter chips for display
    const activeChips = [
        search            && { label: `"${search}"`,                 key: 'search',    clear: () => setSearch('') },
        selectedCategory !== 'All' && { label: selectedCategory,     key: 'cat',       clear: () => setSelectedCategory('All') },
        priorityFilter   !== 'All' && { label: priorityFilter,       key: 'priority',  clear: () => setPriorityFilter('All') },
        frequencyFilter  !== 'All' && { label: frequencyFilter,      key: 'frequency', clear: () => setFrequencyFilter('All') },
        createdByFilter  !== 'All' && { 
            label: (() => { const u = users.find(u => (u.userId || u.id) === createdByFilter); return u ? `${u.firstName} ${u.lastName}` : 'User'; })(),
            key: 'user', 
            clear: () => setCreatedByFilter('All') 
        },
    ].filter(Boolean);

    // Only block access if the user has NO taskTemplate permission at all.
    // Having create/edit/delete but not view is still valid — they can manage their own.
    const hasAnyTemplatePermission = can('taskTemplate', 'view')
        || can('taskTemplate', 'create')
        || can('taskTemplate', 'edit')
        || can('taskTemplate', 'delete');

    if (!permLoading && !hasAnyTemplatePermission) {
        return (
            <div className="min-h-screen bg-[#f8fafc] flex items-center justify-center">
                <div className="text-center">
                    <div className="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                        <Lock size={28} className="text-slate-400" />
                    </div>
                    <h2 className="text-lg font-black text-slate-700">Access Restricted</h2>
                    <p className="text-sm text-slate-400 font-medium mt-1">You don't have permission to access Task Templates.</p>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-[#f8fafc] p-6 lg:p-8 animate-in fade-in duration-500">

            {/* ── Header ── */}
            <div className="flex items-center justify-between mb-8">
                <div>
                    <h1 className="text-2xl font-black text-slate-800 leading-none">Task Templates</h1>
                    <p className="text-xs font-bold text-slate-400 mt-1.5 uppercase tracking-wider">
                        Predefined task blueprints for your team
                    </p>
                </div>
                {can('taskTemplate', 'create') && (
                    <button
                        onClick={() => { setEditingTemplate(null); setShowForm(true); }}
                        className="flex items-center gap-2 px-5 py-2.5 bg-[#00d094] hover:bg-[#00ba84] text-white rounded-xl font-bold text-sm transition-all active:scale-95 shadow-sm"
                    >
                        <Plus size={18} strokeWidth={3} />
                        Add New
                    </button>
                )}
            </div>

            <div className="flex gap-8">

                {/* ── Category Sidebar ── */}
                <div className="w-56 shrink-0 flex flex-col gap-2">
                    <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1 px-1">Categories</p>
                    {categoriesWithCount.map((cat) => (
                        <button
                            key={cat.name}
                            onClick={() => setSelectedCategory(cat.name)}
                            className={`p-3.5 rounded-xl border text-left transition-all hover:scale-[1.02] ${
                                selectedCategory === cat.name
                                    ? 'bg-[#e0f7ef] border-[#00d094] shadow-sm'
                                    : 'bg-white border-slate-100 hover:border-slate-200'
                            }`}
                        >
                            <span className="block text-sm font-black text-slate-700 uppercase tracking-wide truncate">{cat.name}</span>
                            <span className="text-[11px] font-bold text-slate-400 mt-0.5 inline-block">{cat.count} Templates</span>
                        </button>
                    ))}
                </div>

                {/* ── Main Content ── */}
                <div className="flex-1 min-w-0 space-y-5">

                    {/* ── Filter Bar ── */}
                    <div className="bg-white p-4 rounded-2xl border border-slate-100 shadow-sm space-y-3">
                        <div className="flex flex-wrap items-center gap-3">

                            {/* Search */}
                            <div className="relative flex-1 min-w-[200px]">
                                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                                <input
                                    type="text"
                                    placeholder="Search templates..."
                                    value={search}
                                    onChange={(e) => setSearch(e.target.value)}
                                    className="w-full h-10 pl-9 pr-4 bg-slate-50 border border-slate-100 rounded-xl text-sm font-semibold text-slate-700 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#00d094]/25 focus:border-[#00d094]/40 transition"
                                />
                                {search && (
                                    <button onClick={() => setSearch('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-300 hover:text-slate-500 transition">
                                        <X size={14} strokeWidth={3} />
                                    </button>
                                )}
                            </div>

                            {/* Priority */}
                            <div className="relative">
                                <Flag size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                                <select
                                    value={priorityFilter}
                                    onChange={(e) => setPriorityFilter(e.target.value)}
                                    className="h-10 pl-9 pr-8 bg-slate-50 border border-slate-100 rounded-xl text-sm font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-[#00d094]/25 focus:border-[#00d094]/40 transition appearance-none cursor-pointer"
                                >
                                    {PRIORITY_OPTIONS.map(p => (
                                        <option key={p} value={p}>{p === 'All' ? 'Priority' : p}</option>
                                    ))}
                                </select>
                                <ChevronDown size={14} className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                            </div>

                            {/* Frequency */}
                            <div className="relative">
                                <Repeat size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                                <select
                                    value={frequencyFilter}
                                    onChange={(e) => setFrequencyFilter(e.target.value)}
                                    className="h-10 pl-9 pr-8 bg-slate-50 border border-slate-100 rounded-xl text-sm font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-[#00d094]/25 focus:border-[#00d094]/40 transition appearance-none cursor-pointer"
                                >
                                    {FREQUENCY_OPTIONS.map(f => (
                                        <option key={f} value={f}>{f === 'All' ? 'Frequency' : f}</option>
                                    ))}
                                </select>
                                <ChevronDown size={14} className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                            </div>

                            {/* Created By */}
                            <div className="relative">
                                <select
                                    value={createdByFilter}
                                    onChange={(e) => setCreatedByFilter(e.target.value)}
                                    className="h-10 px-4 pr-8 bg-slate-50 border border-slate-100 rounded-xl text-sm font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-[#00d094]/25 focus:border-[#00d094]/40 transition appearance-none cursor-pointer"
                                >
                                    <option value="All">Created By</option>
                                    {users.map(u => (
                                        <option key={u.userId || u.id} value={u.userId || u.id}>
                                            {u.firstName} {u.lastName}
                                        </option>
                                    ))}
                                </select>
                                <ChevronDown size={14} className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                            </div>

                            {/* Reset */}
                            {hasActiveFilters && (
                                <button
                                    onClick={resetFilters}
                                    className="h-10 px-4 flex items-center gap-2 bg-red-50 hover:bg-red-100 text-red-500 border border-red-100 rounded-xl transition font-bold text-sm"
                                >
                                    <RotateCcw size={14} />
                                    Reset
                                </button>
                            )}
                        </div>

                        {/* Active Filter Chips */}
                        {activeChips.length > 0 && (
                            <div className="flex flex-wrap items-center gap-2 pt-1">
                                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Active:</span>
                                {activeChips.map(chip => (
                                    <span
                                        key={chip.key}
                                        className="inline-flex items-center gap-1.5 px-3 py-1 bg-[#e0f7ef] text-[#00a877] border border-[#00d094]/30 rounded-full text-[11px] font-black uppercase tracking-wide"
                                    >
                                        {chip.label}
                                        <button onClick={chip.clear} className="hover:text-red-500 transition ml-0.5">
                                            <X size={11} strokeWidth={3} />
                                        </button>
                                    </span>
                                ))}
                                <span className="text-[11px] font-bold text-slate-400 ml-1">
                                    — {filteredTemplates.length} result{filteredTemplates.length !== 1 ? 's' : ''}
                                </span>
                            </div>
                        )}
                    </div>

                    {/* ── Template List ── */}
                    {loading ? (
                        <div className="flex flex-col items-center justify-center py-20 gap-4">
                            <div className="w-10 h-10 border-4 border-[#00d094] border-t-transparent rounded-full animate-spin" />
                            <p className="text-xs font-bold text-slate-500 uppercase tracking-widest">Loading Templates...</p>
                        </div>
                    ) : filteredTemplates.length === 0 ? (
                        <div className="bg-white border-2 border-dashed border-slate-100 rounded-3xl p-20 flex flex-col items-center justify-center text-center">
                            <div className="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mb-4">
                                <Save size={32} className="text-slate-300" />
                            </div>
                            <h3 className="text-lg font-black text-slate-700">No Templates Found</h3>
                            <p className="text-slate-400 text-sm font-medium mt-1">
                                {hasActiveFilters ? 'Try adjusting your filters' : 'Add your first template to get started'}
                            </p>
                            {hasActiveFilters && (
                                <button
                                    onClick={resetFilters}
                                    className="mt-5 px-5 py-2 rounded-xl bg-[#00d094] text-white font-bold text-sm hover:bg-[#00ba84] transition active:scale-95"
                                >
                                    Clear All Filters
                                </button>
                            )}
                        </div>
                    ) : (
                        <div className="grid gap-4">
                            {filteredTemplates.map((template) => (
                                <div
                                    key={template.id}
                                    className="bg-white rounded-2xl border border-slate-100 p-6 shadow-sm hover:shadow-md transition-all group"
                                >
                                    {/* Card Header */}
                                    <div className="flex justify-between items-start mb-3">
                                        <div className="flex-1 min-w-0 pr-4">
                                            <h3 className="text-lg font-black text-slate-800 transition-colors group-hover:text-[#00d094] truncate">
                                                {template.title}
                                            </h3>

                                            <div className="flex flex-wrap items-center gap-3 mt-2">
                                                {/* Creator avatar */}
                                                <div className="flex items-center gap-1.5">
                                                    <div className="w-6 h-6 rounded-full bg-emerald-500 flex items-center justify-center text-[10px] font-black text-white shrink-0">
                                                        {(template.creatorFirstName?.[0] || 'U')}{(template.creatorLastName?.[0] || '')}
                                                    </div>
                                                    <span className="text-xs font-bold text-slate-600">
                                                        {template.creatorFirstName} {template.creatorLastName}
                                                    </span>
                                                </div>

                                                {/* Date */}
                                                <div className="flex items-center gap-1 text-[11px] font-bold text-slate-400">
                                                    <Calendar size={12} />
                                                    {new Date(template.createdAt).toLocaleDateString('en-US', { day: 'numeric', month: 'short', year: 'numeric' })}
                                                </div>

                                                {/* Priority badge */}
                                                {template.priority && (
                                                    <span className={`px-2 py-0.5 rounded-lg text-[10px] font-black uppercase tracking-wider border ${PRIORITY_STYLES[template.priority] || PRIORITY_STYLES.Low}`}>
                                                        {template.priority}
                                                    </span>
                                                )}

                                                {/* Category badge */}
                                                {template.category && (
                                                    <span className="px-2 py-0.5 rounded-lg text-[10px] font-black uppercase tracking-wider bg-slate-50 text-slate-500 border border-slate-100">
                                                        {template.category}
                                                    </span>
                                                )}

                                                {/* Frequency badge */}
                                                {template.frequency && template.frequency !== 'Once' && (
                                                    <span className="flex items-center gap-1 px-2 py-0.5 rounded-lg text-[10px] font-black uppercase tracking-wider bg-indigo-50 text-indigo-500 border border-indigo-100">
                                                        <Repeat size={10} strokeWidth={3} />
                                                        {template.frequency}
                                                    </span>
                                                )}
                                            </div>
                                        </div>

                                        {/* Action buttons */}
                                        <div className="flex items-center gap-1.5 shrink-0">
                                            {canOnOwn('taskTemplate', 'create', template.createdBy) && (
                                                <button
                                                    onClick={() => handleAssign(template)}
                                                    className="p-2 text-[#00d094] hover:bg-emerald-50 rounded-xl transition-all"
                                                    title="Assign Task from Template"
                                                >
                                                    <div className="relative">
                                                        <CheckSquare size={20} strokeWidth={2.5} />
                                                        <Plus size={10} strokeWidth={4} className="absolute -bottom-0.5 -right-0.5 bg-white rounded-full" />
                                                    </div>
                                                </button>
                                            )}
                                            {canOnOwn('taskTemplate', 'edit', template.createdBy) && (
                                                <button
                                                    onClick={() => handleEdit(template)}
                                                    className="p-2 text-blue-500 hover:bg-blue-50 rounded-xl transition-all"
                                                    title="Edit Template"
                                                >
                                                    <Edit size={18} />
                                                </button>
                                            )}
                                            {canOnOwn('taskTemplate', 'delete', template.createdBy) && (
                                                <button
                                                    onClick={() => handleDelete(template.id)}
                                                    className="p-2 text-red-400 hover:bg-red-50 rounded-xl transition-all"
                                                    title="Delete Template"
                                                >
                                                    <Trash2 size={18} />
                                                </button>
                                            )}
                                        </div>
                                    </div>

                                    {/* Description */}
                                    {template.description && (
                                        <p className="text-sm text-slate-500 font-medium mb-4 leading-relaxed line-clamp-2">
                                            {template.description}
                                        </p>
                                    )}

                                    {/* Checklist preview */}
                                    {template.checklistItems && template.checklistItems.length > 0 && (
                                        <div className="border-t border-slate-50 pt-4">
                                            <div className="flex items-center gap-2 mb-3">
                                                <ClipboardCheck size={16} className="text-orange-400" />
                                                <span className="text-xs font-black text-slate-700 uppercase tracking-wider">
                                                    Checklist — {template.checklistItems.length} item{template.checklistItems.length !== 1 ? 's' : ''}
                                                </span>
                                            </div>
                                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-1.5">
                                                {template.checklistItems.slice(0, 6).map((item, i) => (
                                                    <div key={i} className="flex items-center gap-2 text-xs text-slate-500 font-medium">
                                                        <div className="w-1.5 h-1.5 rounded-full bg-[#00d094]/40 shrink-0" />
                                                        <span className="truncate">{typeof item === 'string' ? item : item.text}</span>
                                                    </div>
                                                ))}
                                                {template.checklistItems.length > 6 && (
                                                    <div className="text-[11px] font-bold text-slate-400 mt-1">
                                                        +{template.checklistItems.length - 6} more items
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    )}
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>

            <TaskTemplateForm
                isOpen={showForm}
                onClose={() => setShowForm(false)}
                onSuccess={fetchData}
                template={editingTemplate}
            />

            <TaskCreationForm
                isOpen={showAssignForm}
                onClose={() => { setShowAssignForm(false); setTemplateToAssign(null); }}
                onSuccess={() => { toast.success('Task assigned from template!'); setShowAssignForm(false); }}
                initialData={templateToAssign}
            />
        </div>
    );
};

export default TaskTemplates;
