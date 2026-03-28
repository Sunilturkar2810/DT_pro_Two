import React, { useState, useEffect } from 'react';
import { 
    Mail, Save, Loader2, Info, Plus, Trash2, MessageSquare,
    Check, AlertCircle, Copy, Code, ChevronDown
} from 'lucide-react';
import toast from 'react-hot-toast';
import notificationTemplateService from '../../services/notificationTemplateService';

const NotificationTemplates = () => {
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [activeEvent, setActiveEvent] = useState('newTask');
    const [activeChannel, setActiveChannel] = useState('email');
    const [template, setTemplate] = useState({ subject: '', body: '', isActive: true });

    const events = {
        newTask: 'New Task (Assignee)',
        taskEdit: 'Task Edited (Assignee)',
        taskComment: 'Task Comment (Assignee)',
        taskInProgress: 'Task In-Progress (Assignee)',
        taskComplete: 'Task Complete (Assignee)',
        taskReOpen: 'Task Re-Open (Assignee)',
        dailyPendingReminders: 'Daily Pending Reminders',
        reminder: 'Custom Reminder (Assignee)',
        newTaskInLoop: '🔁 New Task (In-Loop)',
        taskEditInLoop: '🔁 Task Edited (In-Loop)',
        taskCommentInLoop: '🔁 Task Comment (In-Loop)',
        taskInProgressInLoop: '🔁 Task In-Progress (In-Loop)',
        taskCompleteInLoop: '🔁 Task Complete (In-Loop)',
        taskReOpenInLoop: '🔁 Task Re-Open (In-Loop)',
        reminderInLoop: '🔁 Task Reminder (In-Loop)'
    };

    const variables = [
        { key: '{taskId}', label: 'Task ID', description: 'The unique ID string for the task' },
        { key: '{taskTitle}', label: 'Task Title', description: 'The title of the task' },
        { key: '{taskDescription}', label: 'Description', description: 'Task description' },
        { key: '{priority}', label: 'Priority', description: 'Task priority level' },
        { key: '{category}', label: 'Category', description: 'Task category' },
        { key: '{dueDate}', label: 'Due Date', description: 'Formatted due date' },
        { key: '{assignerName}', label: 'Assigner', description: 'Name of the person who assigned the task' },
        { key: '{doerName}', label: 'Assignee', description: 'Name of the person the task is assigned to' },
        { key: '{updatedBy}', label: 'Updated By', description: 'Name of the person who edited the task' },
        { key: '{status}', label: 'Status', description: 'Current task status' },
        { key: '{remark}', label: 'Remark', description: 'Recent comment or remark' },
        { key: '{commenterName}', label: 'Commenter', description: 'Name of the person who added the remark' },
        { key: '{taskList}', label: 'Task List', description: 'Summary list of pending tasks (for Daily Report)' },
        { key: '{frequency}', label: 'Frequency', description: 'Recurrence frequency (Daily, Weekly, One-Time etc.)' },
        { key: '{startDate}', label: 'Start Date', description: 'Task or repeat start date' },
        { key: '{endDate}', label: 'End Date', description: 'Task or repeat end date' },
        { key: '{voiceNoteUrl}', label: 'Voice Note (Audio Note)', description: 'Link to the recorded audio' },
        { key: '{referenceDocs}', label: 'Attachments (Files/Links)', description: 'Links to files and documents' },
        { key: '{evidenceUrl}', label: 'Evidence File (Completion)', description: 'Link to the evidence document' }
    ];

    useEffect(() => {
        fetchTemplate();
    }, [activeEvent, activeChannel]);

    const fetchTemplate = async () => {
        try {
            setLoading(true);
            const response = await notificationTemplateService.getTemplate(activeEvent, activeChannel);
            if (response.success && response.data) {
                setTemplate(response.data);
            } else {
                setTemplate({ subject: '', body: '', isActive: true });
            }
        } catch (error) {
            console.error('Failed to fetch template:', error);
            toast.error('Failed to load template');
        } finally {
            setLoading(false);
        }
    };

    const handleSave = async () => {
        try {
            setSaving(true);
            const response = await notificationTemplateService.saveTemplate({
                eventName: activeEvent,
                channel: activeChannel,
                ...template
            });
            if (response.success) {
                toast.success('Template saved successfully');
                setTemplate(response.data);
            }
        } catch (error) {
            console.error('Failed to save template:', error);
            toast.error('Failed to save template');
        } finally {
            setSaving(false);
        }
    };

    const insertVariable = (key) => {
        const textarea = document.getElementById('template-body');
        if (!textarea) return;

        const start = textarea.selectionStart;
        const end = textarea.selectionEnd;
        const text = template.body || '';
        const newText = text.substring(0, start) + key + text.substring(end);
        
        setTemplate(prev => ({ ...prev, body: newText }));
        
        // Focus back on textarea after state update
        setTimeout(() => {
            textarea.focus();
            textarea.setSelectionRange(start + key.length, start + key.length);
        }, 0);
    };

    const insertVariableToSubject = (key) => {
        setTemplate(prev => ({ ...prev, subject: (prev.subject || '') + key }));
    };

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="flex flex-col md:flex-row gap-6">
                {/* Sidebar - Event Selection */}
                <div className="w-full md:w-64 space-y-2">
                    <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest px-4 mb-4">Event Types</h3>
                    {Object.entries(events).map(([key, label]) => (
                        <button
                            key={key}
                            onClick={() => setActiveEvent(key)}
                            className={`w-full flex items-center justify-between p-4 rounded-2xl text-left transition-all ${
                                activeEvent === key 
                                ? 'bg-emerald-500 text-white shadow-lg shadow-emerald-500/20 font-bold scale-105 z-10' 
                                : 'bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 border border-slate-100 dark:border-slate-800'
                            }`}
                        >
                            <span className="text-sm">{label}</span>
                            {activeEvent === key && <Check size={16} />}
                        </button>
                    ))}
                </div>

                {/* Main Content - Template Editor */}
                <div className="flex-1 space-y-6">
                    {/* Channel Selector - Only Email now */}
                    <div className="flex p-1 bg-slate-100 dark:bg-slate-800 rounded-2xl w-fit">
                        <button
                            onClick={() => setActiveChannel('email')}
                            className={`flex items-center gap-2 px-6 py-2.5 rounded-xl text-sm font-bold transition-all ${
                                activeChannel === 'email' 
                                ? 'bg-white dark:bg-slate-700 text-emerald-500 shadow-sm' 
                                : 'text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'
                            }`}
                        >
                            <Mail size={18} />
                            Email
                        </button>
                        <button
                            onClick={() => setActiveChannel('whatsapp')}
                            className={`flex items-center gap-2 px-6 py-2.5 rounded-xl text-sm font-bold transition-all ${
                                activeChannel === 'whatsapp' 
                                ? 'bg-white dark:bg-slate-700 text-emerald-500 shadow-sm' 
                                : 'text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'
                            }`}
                        >
                            <MessageSquare size={18} />
                            WhatsApp
                        </button>
                    </div>

                    {loading ? (
                        <div className="flex flex-col items-center justify-center p-24 bg-white dark:bg-slate-900 rounded-3xl border border-slate-100 dark:border-slate-800">
                            <Loader2 className="animate-spin text-emerald-500 mb-4" size={40} />
                            <p className="text-slate-500 font-bold uppercase tracking-widest text-xs">Loading Template...</p>
                        </div>
                    ) : (
                        <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 border border-slate-100 dark:border-slate-800 shadow-sm space-y-6">
                            <div className="flex items-center justify-between">
                                <div>
                                    <h3 className="text-lg font-black text-slate-800 dark:text-white uppercase tracking-tight">
                                        {events[activeEvent]} {activeChannel === 'email' ? 'Email' : 'WhatsApp'} Template
                                    </h3>
                                    <p className="text-xs text-slate-500 font-medium">Design how this notification will look</p>
                                </div>
                                <div className="flex items-center gap-4">
                                    <label className="flex items-center gap-2 cursor-pointer group">
                                        <span className="text-xs font-bold text-slate-500 group-hover:text-slate-700 transition-colors uppercase tracking-widest">Active</span>
                                        <div className="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none bg-slate-200 dark:bg-slate-700 has-[:checked]:bg-emerald-500">
                                            <input 
                                                type="checkbox" 
                                                className="sr-only" 
                                                checked={template.isActive}
                                                onChange={(e) => setTemplate(prev => ({ ...prev, isActive: e.target.checked }))}
                                            />
                                            <span className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow-lg ring-0 transition duration-200 ease-in-out ${template.isActive ? 'translate-x-5' : 'translate-x-0'}`} />
                                        </div>
                                    </label>
                                    <button
                                        onClick={handleSave}
                                        disabled={saving}
                                        className="flex items-center gap-2 px-6 py-2.5 bg-emerald-500 hover:bg-emerald-600 disabled:bg-slate-300 text-white rounded-xl font-bold text-sm shadow-xl shadow-emerald-500/20 transition-all active:scale-95"
                                    >
                                        {saving ? <Loader2 size={18} className="animate-spin" /> : <Save size={18} />}
                                        {saving ? 'Saving...' : 'Save Template'}
                                    </button>
                                </div>
                            </div>

                            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                                <div className="lg:col-span-2 space-y-6">
                                    {activeChannel === 'email' && (
                                        <div className="space-y-2">
                                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Email Subject</label>
                                            <div className="relative group">
                                                <input
                                                    type="text"
                                                    value={template.subject}
                                                    onChange={(e) => setTemplate(prev => ({ ...prev, subject: e.target.value }))}
                                                    placeholder="Enter email subject..."
                                                    className="w-full bg-slate-50 dark:bg-slate-800/50 border border-slate-100 dark:border-slate-800 rounded-2xl px-5 py-4 text-sm font-bold text-slate-700 dark:text-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-slate-400"
                                                />
                                            </div>
                                        </div>
                                    )}

                                    {activeChannel === 'whatsapp' && (
                                        <div className="space-y-2">
                                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Campaign Name (AISENSY_CAMPAIGN_KEYS)</label>
                                            <div className="relative group">
                                                <input
                                                    type="text"
                                                    value={template.subject}
                                                    onChange={(e) => setTemplate(prev => ({ ...prev, subject: e.target.value }))}
                                                    placeholder="Enter precise AiSensy campaign name (e.g. RLD_task_update)"
                                                    className="w-full bg-slate-50 dark:bg-slate-800/50 border border-slate-100 dark:border-slate-800 rounded-2xl px-5 py-4 text-sm font-bold text-slate-700 dark:text-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-slate-400"
                                                />
                                            </div>
                                        </div>
                                    )}

                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">
                                            {activeChannel === 'email' ? 'Email Body (HTML supported)' : 'Template Parameters (One per line)'}
                                        </label>
                                        <textarea
                                            id="template-body"
                                            value={template.body}
                                            onChange={(e) => setTemplate(prev => ({ ...prev, body: e.target.value }))}
                                            placeholder={activeChannel === 'email' ? "Enter your email content here..." : "Enter variables like {taskTitle} line by line...\nLine 1 maps to {{1}}\nLine 2 maps to {{2}}"}
                                            className={`w-full h-80 bg-slate-50 dark:bg-slate-800/50 border border-slate-100 dark:border-slate-800 rounded-3xl px-6 py-5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-emerald-500/20 transition-all placeholder:text-slate-400 resize-none font-mono ${activeChannel === 'whatsapp' ? 'text-emerald-700 dark:text-emerald-400 leading-loose text-base font-bold' : 'text-slate-700 dark:text-slate-200'}`}
                                        />
                                    </div>
                                </div>

                                {/* Variable Picker */}
                                <div className="space-y-4">
                                    <div className="flex items-center gap-2 p-4 bg-emerald-50 dark:bg-emerald-500/10 rounded-2xl border border-emerald-100 dark:border-emerald-500/20">
                                        <Info className="text-emerald-500" size={20} />
                                        <p className="text-[10px] font-bold text-emerald-700 dark:text-emerald-400 leading-tight">
                                            {activeChannel === 'whatsapp' 
                                                ? 'Click a variable to insert it into your template params. Each line = one {{param}} slot.' 
                                                : 'Click on a variable to insert it into your email body at the current cursor position.'}
                                        </p>
                                    </div>

                                    <div className="bg-slate-50 dark:bg-slate-800/30 rounded-3xl p-6 border border-slate-100 dark:border-slate-800 max-h-[500px] overflow-y-auto custom-scrollbar">
                                        <h4 className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-4">Available Variables (Total: {variables.length})</h4>
                                        <div className="space-y-2">
                                            {variables.map((v) => (
                                                <button
                                                    key={v.key}
                                                    onClick={() => insertVariable(v.key)}
                                                    className="w-full flex flex-col p-3 bg-white dark:bg-slate-800 rounded-xl border border-slate-100 dark:border-slate-700 text-left hover:border-emerald-500 hover:shadow-md transition-all group"
                                                >
                                                    <span className="text-xs font-black text-emerald-600 dark:text-emerald-400 group-hover:scale-105 transition-transform">{v.key}</span>
                                                    <span className="text-[10px] text-slate-500 font-medium mt-0.5">{v.label}</span>
                                                </button>
                                            ))}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default NotificationTemplates;
