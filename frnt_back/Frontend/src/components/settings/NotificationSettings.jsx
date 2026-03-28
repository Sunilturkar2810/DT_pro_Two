import React, { useState, useEffect } from 'react';
import { 
    Bell, Mail, MessageSquare, Clock, Globe, 
    ChevronRight, Save, Loader2, Check, Smartphone
} from 'lucide-react';
import api from '../../services/api';
import toast from 'react-hot-toast';

import NotificationTemplates from './NotificationTemplates';

const NotificationSettings = () => {
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [mainTab, setMainTab] = useState('Preferences');
    const [activeTab, setActiveTab] = useState('Admin');

    const defaultFrequency = {
        once: true, daily: false, weekly: false, monthly: false, yearly: false
    };

    const [settings, setSettings] = useState({
        whatsappNotifications: false,
        emailNotifications: false,
        timezone: 'Asia/Kolkata',
        dailyReminderTime: '09:00',
        whatsappReminders: false,
        emailReminders: false,
        dailyTaskReport: false,
        weeklyOffs: ['Sunday'],
        notificationChannels: {
            newTask: { admin: true, manager: true, member: true },
            newTaskInLoop: { admin: true, manager: true, member: true },
            taskEdit: { admin: true, manager: true, member: true },
            taskEditInLoop: { admin: true, manager: true, member: true },
            taskComment: { admin: true, manager: true, member: true },
            taskCommentInLoop: { admin: true, manager: true, member: true },
            taskInProgress: { admin: true, manager: true, member: true },
            taskInProgressInLoop: { admin: true, manager: true, member: true },
            taskComplete: { admin: true, manager: true, member: true },
            taskCompleteInLoop: { admin: true, manager: true, member: true },
            taskReOpen: { admin: true, manager: true, member: true },
            taskReOpenInLoop: { admin: true, manager: true, member: true },
            dailyPendingReminders: { admin: true, manager: true, member: true },
            reminderInLoop: { admin: true, manager: true, member: true }
        },
        notificationFrequency: {
            admin: {
                newTask: { ...defaultFrequency },
                newTaskInLoop: { ...defaultFrequency },
                taskEdit: { ...defaultFrequency },
                taskEditInLoop: { ...defaultFrequency },
                taskComment: { ...defaultFrequency },
                taskCommentInLoop: { ...defaultFrequency },
                taskInProgress: { ...defaultFrequency },
                taskInProgressInLoop: { ...defaultFrequency },
                taskComplete: { ...defaultFrequency },
                taskCompleteInLoop: { ...defaultFrequency },
                taskReOpen: { ...defaultFrequency },
                taskReOpenInLoop: { ...defaultFrequency },
                dailyPendingReminders: { ...defaultFrequency },
                reminderInLoop: { ...defaultFrequency }
            },
            manager: {
                newTask: { ...defaultFrequency },
                newTaskInLoop: { ...defaultFrequency },
                taskEdit: { ...defaultFrequency },
                taskEditInLoop: { ...defaultFrequency },
                taskComment: { ...defaultFrequency },
                taskCommentInLoop: { ...defaultFrequency },
                taskInProgress: { ...defaultFrequency },
                taskInProgressInLoop: { ...defaultFrequency },
                taskComplete: { ...defaultFrequency },
                taskCompleteInLoop: { ...defaultFrequency },
                taskReOpen: { ...defaultFrequency },
                taskReOpenInLoop: { ...defaultFrequency },
                dailyPendingReminders: { ...defaultFrequency },
                reminderInLoop: { ...defaultFrequency }
            },
            member: {
                newTask: { ...defaultFrequency },
                newTaskInLoop: { ...defaultFrequency },
                taskEdit: { ...defaultFrequency },
                taskEditInLoop: { ...defaultFrequency },
                taskComment: { ...defaultFrequency },
                taskCommentInLoop: { ...defaultFrequency },
                taskInProgress: { ...defaultFrequency },
                taskInProgressInLoop: { ...defaultFrequency },
                taskComplete: { ...defaultFrequency },
                taskCompleteInLoop: { ...defaultFrequency },
                taskReOpen: { ...defaultFrequency },
                taskReOpenInLoop: { ...defaultFrequency },
                dailyPendingReminders: { ...defaultFrequency },
                reminderInLoop: { ...defaultFrequency }
            }
        }
    });

    useEffect(() => {
        fetchSettings();
    }, []);

    const fetchSettings = async () => {
        try {
            setLoading(true);
            const response = await api.get('/notification-settings');
            if (response.data?.success) {
                const fetchedData = response.data.data;
                
                // Robustly handle legacy notificationFrequency (if it comes as a string)
                if (typeof fetchedData.notificationFrequency === 'string') {
                    delete fetchedData.notificationFrequency;
                }

                setSettings(prev => ({ 
                    ...prev, 
                    ...fetchedData,
                    notificationChannels: {
                        ...prev.notificationChannels,
                        ...(fetchedData.notificationChannels || {})
                    },
                    notificationFrequency: {
                        ...prev.notificationFrequency,
                        ...(fetchedData.notificationFrequency || {})
                    }
                }));
            }
        } catch (error) {
            console.error('Failed to fetch settings:', error);
            toast.error('Failed to load notification settings');
        } finally {
            setLoading(false);
        }
    };

    const handleSave = async () => {
        try {
            setSaving(true);
            const response = await api.post('/notification-settings', settings);
            if (response.data?.success) {
                toast.success('Settings saved successfully');
            }
        } catch (error) {
            console.error('Failed to save settings:', error);
            toast.error('Failed to save settings');
        } finally {
            setSaving(false);
        }
    };

    const toggleGlobal = (key) => {
        setSettings(prev => ({ ...prev, [key]: !prev[key] }));
    };

    const toggleChannel = (event, role) => {
        setSettings(prev => {
            const channels = prev.notificationChannels || {};
            const eventSettings = channels[event] || { admin: true, manager: true, member: true };
            return {
                ...prev,
                notificationChannels: {
                    ...channels,
                    [event]: {
                        ...eventSettings,
                        [role]: !eventSettings[role]
                    }
                }
            };
        });
    };

    const toggleFrequency = (event, freq) => {
        const role = activeTab.toLowerCase();
        setSettings(prev => {
            const frequencies = prev.notificationFrequency || {};
            const roleSettings = frequencies[role] || {};
            const eventSettings = roleSettings[event] || { ...defaultFrequency };
            return {
                ...prev,
                notificationFrequency: {
                    ...frequencies,
                    [role]: {
                        ...roleSettings,
                        [event]: {
                            ...eventSettings,
                            [freq]: !eventSettings[freq]
                        }
                    }
                }
            };
        });
    };

    const toggleWeeklyOff = (day) => {
        setSettings(prev => ({
            ...prev,
            weeklyOffs: prev.weeklyOffs.includes(day)
                ? prev.weeklyOffs.filter(d => d !== day)
                : [...prev.weeklyOffs, day]
        }));
    };

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center p-12 bg-white dark:bg-slate-900 rounded-3xl border border-slate-100 dark:border-slate-800">
                <Loader2 className="animate-spin text-emerald-500 mb-4" size={40} />
                <p className="text-slate-500 font-bold uppercase tracking-widest text-xs">Loading Preferences...</p>
            </div>
        );
    }

    const Switch = ({ enabled, onChange, icon: Icon, label, color = "emerald" }) => (
        <div className="flex items-center justify-between p-4 bg-slate-50/50 dark:bg-slate-800/30 rounded-2xl border border-slate-100 dark:border-slate-800 transition-all hover:bg-white dark:hover:bg-slate-800/50 group">
            <div className="flex items-center gap-3">
                {Icon && (
                    <div className={`p-2 rounded-xl bg-white dark:bg-slate-800 shadow-sm border border-slate-100 dark:border-slate-700 transition-colors ${enabled ? `text-${color}-500` : 'text-slate-400'}`}>
                        <Icon size={18} />
                    </div>
                )}
                <span className="text-sm font-bold text-slate-700 dark:text-slate-200">{label}</span>
            </div>
            <button
                onClick={onChange}
                className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${enabled ? 'bg-emerald-500' : 'bg-slate-200 dark:bg-slate-700'
                    }`}
            >
                <span
                    className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow-lg ring-0 transition duration-200 ease-in-out ${enabled ? 'translate-x-5' : 'translate-x-0'
                        }`}
                />
            </button>
        </div>
    );

    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    const eventLabels = {
        newTask: 'New Task',
        newTaskInLoop: 'New Task (In-Loop)',
        taskEdit: 'Task Edited',
        taskEditInLoop: 'Task Edited (In-Loop)',
        taskComment: 'Task Comment',
        taskCommentInLoop: 'Task Comment (In-Loop)',
        taskInProgress: 'Task In-Progress',
        taskInProgressInLoop: 'Task In-Progress (In-Loop)',
        taskComplete: 'Task Complete',
        taskCompleteInLoop: 'Task Complete (In-Loop)',
        taskReOpen: 'Task Re-Open',
        taskReOpenInLoop: 'Task Re-Open (In-Loop)',
        dailyPendingReminders: 'Daily Pending Task Reminders',
        reminderInLoop: 'Task Reminder (In-Loop)'
    };

    return (
        <div className="space-y-8 animate-in fade-in duration-500 pb-12">
            {/* Header / Main Tabs */}
            <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-100 dark:border-slate-800 shadow-sm overflow-hidden">
                <div className="p-6 flex items-center justify-between border-b border-slate-100 dark:border-slate-800">
                    <div>
                        <h2 className="text-xl font-black text-slate-800 dark:text-white tracking-tight">Notification Settings</h2>
                        <p className="text-xs text-slate-500 font-medium">Manage how you receive updates and reminders</p>
                    </div>
                    {mainTab === 'Preferences' && (
                        <button
                            onClick={handleSave}
                            disabled={saving}
                            className="flex items-center gap-2 px-6 py-2.5 bg-emerald-500 hover:bg-emerald-600 disabled:bg-slate-300 text-white rounded-xl font-bold text-sm shadow-xl shadow-emerald-500/20 transition-all active:scale-95"
                        >
                            {saving ? <Loader2 size={18} className="animate-spin" /> : <Save size={18} />}
                            {saving ? 'Saving...' : 'Save Changes'}
                        </button>
                    )}
                </div>
                
                <div className="flex px-4 bg-slate-50/50 dark:bg-slate-800/50">
                    <button
                        onClick={() => setMainTab('Preferences')}
                        className={`px-8 py-4 text-xs font-black uppercase tracking-widest transition-all relative ${
                            mainTab === 'Preferences' 
                            ? 'text-emerald-500' 
                            : 'text-slate-400 hover:text-slate-600 dark:hover:text-slate-300'
                        }`}
                    >
                        General Preferences
                        {mainTab === 'Preferences' && (
                            <div className="absolute bottom-0 left-8 right-8 h-1 bg-emerald-500 rounded-full" />
                        )}
                    </button>
                    <button
                        onClick={() => setMainTab('Templates')}
                        className={`px-8 py-4 text-xs font-black uppercase tracking-widest transition-all relative ${
                            mainTab === 'Templates' 
                            ? 'text-emerald-500' 
                            : 'text-slate-400 hover:text-slate-600 dark:hover:text-slate-300'
                        }`}
                    >
                        Notification Templates
                        {mainTab === 'Templates' && (
                            <div className="absolute bottom-0 left-8 right-8 h-1 bg-emerald-500 rounded-full" />
                        )}
                    </button>
                </div>
            </div>

            {mainTab === 'Templates' ? (
                <NotificationTemplates />
            ) : (
                <>

            {/* Global Toggles */}
            <div className="flex flex-wrap gap-4">

                <div className="flex-1 min-w-[200px]">
                    <Switch
                        enabled={settings.emailNotifications}
                        onChange={() => toggleGlobal('emailNotifications')}
                        icon={Mail}
                        label="Email Notifications"
                        color="red"
                    />
                </div>
                <div className="flex-1 min-w-[200px] relative">
                    <div className="flex items-center gap-3 p-4 bg-slate-50/50 dark:bg-slate-800/30 rounded-2xl border border-slate-100 dark:border-slate-800 h-full">
                        <div className="p-2 rounded-xl bg-white dark:bg-slate-800 shadow-sm border border-slate-100 dark:border-slate-700 text-slate-400">
                            <Clock size={18} />
                        </div>
                        <div className="flex flex-col flex-1">
                            <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider leading-none">Timezone</span>
                            <select
                                value={settings.timezone}
                                onChange={(e) => setSettings(prev => ({ ...prev, timezone: e.target.value }))}
                                className="bg-transparent border-none outline-none text-sm font-bold text-slate-700 dark:text-slate-200 p-0 mt-0.5 cursor-pointer"
                            >
                                <option value="Asia/Kolkata">Asia/Kolkata</option>
                                <option value="UTC">UTC</option>
                                <option value="America/New_York">New York</option>
                                <option value="Europe/London">London</option>
                            </select>
                        </div>
                    </div>
                </div>
            </div>

            {/* Reminder Settings */}
            <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 border border-slate-100 dark:border-slate-800 shadow-sm space-y-6">
                <div>
                    <h3 className="text-lg font-black text-slate-800 dark:text-white">Reminder Settings</h3>
                    <p className="text-xs text-slate-500 font-medium mt-1">Configure your recurring task reminders</p>
                </div>

                <div className="flex flex-wrap items-center gap-8">
                    <div className="flex items-center gap-4">
                        <div className="p-3 rounded-2xl bg-emerald-500 text-white shadow-lg shadow-emerald-500/20">
                            <Clock size={24} />
                        </div>
                        <div>
                            <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest leading-none">Daily Reminder Time</p>
                            <input 
                                type="time"
                                value={settings.dailyReminderTime}
                                onChange={(e) => setSettings(prev => ({ ...prev, dailyReminderTime: e.target.value }))}
                                className="bg-slate-50 dark:bg-slate-800 border-none outline-none text-xl font-black text-slate-800 dark:text-white mt-1 p-0 cursor-pointer"
                            />
                        </div>
                    </div>

                    <div className="flex flex-1 gap-4 min-w-[400px]">

                        <div className="flex-1">
                            <Switch
                                enabled={settings.emailReminders}
                                onChange={() => toggleGlobal('emailReminders')}
                                icon={Mail}
                                label="Email Reminders"
                                color="red"
                            />
                        </div>
                        <div className="flex-1">
                            <Switch
                                enabled={settings.dailyTaskReport}
                                onChange={() => toggleGlobal('dailyTaskReport')}
                                icon={Globe}
                                label="Daily Task Report"
                                color="sky"
                            />
                        </div>
                    </div>
                </div>
            </div>

            {/* Weekly Offs */}
            <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 border border-slate-100 dark:border-slate-800 shadow-sm space-y-6">
                <div>
                    <h3 className="text-lg font-black text-slate-800 dark:text-white">Weekly Offs</h3>
                    <p className="text-xs text-slate-500 font-medium mt-1">Select your non-working days</p>
                </div>

                <div className="flex items-center justify-between max-w-2xl px-4">
                    {fullDays.map((day, idx) => (
                        <div key={day} className="flex flex-col items-center gap-3">
                            <button
                                onClick={() => toggleWeeklyOff(day)}
                                className={`w-10 h-10 rounded-xl flex items-center justify-center border-2 transition-all ${
                                    settings.weeklyOffs.includes(day)
                                    ? 'bg-emerald-500 border-emerald-500 text-white shadow-lg shadow-emerald-500/20 scale-110'
                                    : 'border-slate-200 dark:border-slate-700 text-slate-400 hover:border-emerald-300'
                                }`}
                            >
                                <Check size={18} className={settings.weeklyOffs.includes(day) ? 'scale-100' : 'scale-0'} />
                            </button>
                            <span className="text-[10px] font-black text-slate-500 uppercase tracking-tighter">{days[idx]}</span>
                        </div>
                    ))}
                </div>
            </div>

            {/* Notification Channels Table */}
            <div className="bg-white dark:bg-slate-900 rounded-3xl overflow-hidden border border-slate-100 dark:border-slate-800 shadow-sm">
                <div className="p-8 border-b border-slate-100 dark:border-slate-800">
                    <h3 className="text-lg font-black text-slate-800 dark:text-white">Notification Channels</h3>
                    <p className="text-xs text-slate-500 font-medium mt-1">Select the platforms where you want to receive updates</p>
                </div>

                <div className="overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="bg-slate-50/50 dark:bg-slate-800/50">
                                <th className="px-8 py-4 text-[10px] font-black uppercase tracking-widest text-slate-400">Events</th>
                                <th className="px-8 py-4 text-[10px] font-black uppercase tracking-widest text-slate-400 text-center">Admin</th>
                                <th className="px-8 py-4 text-[10px] font-black uppercase tracking-widest text-slate-400 text-center">Manager</th>
                                <th className="px-8 py-4 text-[10px] font-black uppercase tracking-widest text-slate-400 text-center">Member</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-50 dark:divide-slate-800">
                            {Object.entries(eventLabels).map(([event, label]) => (
                                <tr key={event} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/20 transition-colors">
                                    <td className="px-8 py-4">
                                        <span className="text-sm font-bold text-slate-700 dark:text-slate-200">{label}</span>
                                    </td>
                                    {['admin', 'manager', 'member'].map(role => (
                                        <td key={role} className="px-8 py-4 text-center">
                                            <button
                                                onClick={() => toggleChannel(event, role)}
                                                className={`mx-auto w-6 h-6 rounded-lg border-2 flex items-center justify-center transition-all ${
                                                    settings.notificationChannels[event]?.[role]
                                                    ? 'bg-emerald-500 border-emerald-500 text-white shadow-md'
                                                    : 'border-slate-200 dark:border-slate-700 text-transparent'
                                                }`}
                                            >
                                                <Check size={14} strokeWidth={3} className={settings.notificationChannels[event]?.[role] ? 'scale-100' : 'scale-0'} />
                                            </button>
                                        </td>
                                    ))}
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Notification Frequency Table */}
            <div className="bg-white dark:bg-slate-900 rounded-3xl overflow-hidden border border-slate-100 dark:border-slate-800 shadow-sm transition-all duration-300">
                <div className="p-8 pb-0">
                    <h3 className="text-xl font-black text-slate-800 dark:text-white">Notification Frequency</h3>
                    <p className="text-xs text-slate-500 font-medium mt-1">Choose how often you'd like to receive notifications for each event.</p>
                </div>

                {/* Tabs */}
                <div className="mt-8 border-b border-slate-100 dark:border-slate-800 flex">
                    {['Admin', 'Manager', 'Member'].map((role) => (
                        <button
                            key={role}
                            onClick={() => setActiveTab(role)}
                            className={`flex-1 py-4 text-sm font-black transition-all relative ${
                                activeTab === role 
                                ? 'text-slate-800 dark:text-white' 
                                : 'text-slate-400 hover:text-slate-600 dark:hover:text-slate-300'
                            }`}
                        >
                            {role}
                            {activeTab === role && (
                                <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-12 h-1 bg-emerald-500 rounded-full animate-in fade-in zoom-in duration-300" />
                            )}
                        </button>
                    ))}
                </div>

                <div className="p-1 px-4 sm:px-6 md:px-8 pb-8 mt-6 overflow-x-auto custom-scrollbar">
                    <table className="w-full text-left border-separate border-spacing-y-0 min-w-[700px]">
                        <thead>
                            <tr className="bg-[#13d399] text-white">
                                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest rounded-tl-2xl">Events</th>
                                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-center">Once</th>
                                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-center">Daily</th>
                                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-center">Weekly</th>
                                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-center">Monthly</th>
                                <th className="px-6 py-4 text-[11px] font-black uppercase tracking-widest text-center rounded-tr-2xl">Yearly</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                            {Object.entries(eventLabels).map(([event, label]) => (
                                <tr key={event} className="group hover:bg-slate-50/50 dark:hover:bg-slate-800/20 transition-colors">
                                    <td className="px-6 py-5 border-l border-slate-100 dark:border-slate-800">
                                        <span className="text-sm font-black text-slate-700 dark:text-slate-200 group-hover:text-emerald-600 transition-colors">{label}</span>
                                    </td>
                                    {['once', 'daily', 'weekly', 'monthly', 'yearly'].map(freq => (
                                        <td key={freq} className="px-6 py-5 text-center border-r last:border-r border-slate-100 dark:border-slate-800">
                                            <button
                                                onClick={() => toggleFrequency(event, freq)}
                                                className={`mx-auto w-6 h-6 rounded-lg border-2 flex items-center justify-center transition-all ${
                                                    settings.notificationFrequency[activeTab.toLowerCase()]?.[event]?.[freq]
                                                    ? 'bg-[#13d399] border-[#13d399] text-white shadow-lg shadow-emerald-500/20 scale-110'
                                                    : 'border-slate-200 dark:border-slate-700 text-transparent hover:border-emerald-300'
                                                }`}
                                            >
                                                <Check size={14} strokeWidth={4} className={settings.notificationFrequency[activeTab.toLowerCase()]?.[event]?.[freq] ? 'scale-100' : 'scale-0'} />
                                            </button>
                                        </td>
                                    ))}
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
            </>
            )}
        </div>
    );
};

export default NotificationSettings;
