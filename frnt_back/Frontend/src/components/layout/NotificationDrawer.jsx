import React, { useEffect, useState } from 'react';
import { X, Bell, CheckCircle2, Trash2, Clock, Inbox, AlertCircle, Info, RefreshCw } from 'lucide-react';
import notificationService from '../../services/notificationService';

const NotificationDrawer = ({ isOpen, onClose }) => {
    const [notifications, setNotifications] = useState([]);
    const [loading, setLoading] = useState(false);
    const [unreadCount, setUnreadCount] = useState(0);

    const fetchNotifications = async () => {
        try {
            setLoading(true);
            const response = await notificationService.getNotifications();
            if (response.success) {
                setNotifications(response.data);
                setUnreadCount(response.data.filter(n => !n.isRead).length);
            }
        } catch (error) {
            console.error('Failed to fetch notifications:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (isOpen) {
            fetchNotifications();
        }
    }, [isOpen]);

    const handleMarkAsRead = async (id) => {
        try {
            await notificationService.markAsRead(id);
            setNotifications(notifications.map(n => n.id === id ? { ...n, isRead: true } : n));
            setUnreadCount(prev => Math.max(0, prev - 1));
        } catch (error) {
            console.error('Failed to mark as read:', error);
        }
    };

    const handleMarkAllAsRead = async () => {
        try {
            await notificationService.markAllAsRead();
            setNotifications(notifications.map(n => ({ ...n, isRead: true })));
            setUnreadCount(0);
        } catch (error) {
            console.error('Failed to mark all as read:', error);
        }
    };

    const handleDelete = async (id) => {
        try {
            await notificationService.deleteNotification(id);
            const deleted = notifications.find(n => n.id === id);
            setNotifications(notifications.filter(n => n.id !== id));
            if (deleted && !deleted.isRead) {
                setUnreadCount(prev => Math.max(0, prev - 1));
            }
        } catch (error) {
            console.error('Failed to delete notification:', error);
        }
    };

    const handleClearAll = async () => {
        try {
            await notificationService.clearAll();
            setNotifications([]);
            setUnreadCount(0);
        } catch (error) {
            console.error('Failed to clear all notifications:', error);
        }
    };

    const getIcon = (type) => {
        switch (type) {
            case 'delegation': return <Inbox className="text-blue-500" size={18} />;
            case 'remark': return <Info className="text-emerald-500" size={18} />;
            case 'revision': return <Clock className="text-amber-500" size={18} />;
            case 'status_change': return <CheckCircle2 className="text-purple-500" size={18} />;
            default: return <AlertCircle className="text-slate-500" size={18} />;
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[100] overflow-hidden">
            <div className="absolute inset-0 bg-black/40 backdrop-blur-sm transition-opacity" onClick={onClose} />

            <div className="absolute inset-y-0 right-0 max-w-full flex">
                <div className="w-screen max-w-md bg-[var(--bg-primary)] shadow-2xl animate-in slide-in-from-right duration-300 flex flex-col">
                    {/* Header */}
                    <div className="px-6 py-4 border-b border-[var(--border-color)] flex items-center justify-between bg-[var(--bg-secondary)]">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-emerald-500/10 rounded-xl flex items-center justify-center text-emerald-500">
                                <Bell size={20} />
                            </div>
                            <div>
                                <h2 className="text-lg font-black text-[var(--text-primary)] uppercase tracking-tight">Notifications</h2>
                                <p className="text-xs font-bold text-[var(--text-secondary)]">You have {unreadCount} unread messages</p>
                            </div>
                        </div>
                        <button onClick={onClose} className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors text-[var(--text-secondary)]">
                            <X size={20} />
                        </button>
                    </div>

                    {/* Toolbar */}
                    {notifications.length > 0 && (
                        <div className="px-6 py-3 bg-[var(--bg-secondary)] border-b border-[var(--border-color)] flex items-center justify-between">
                            <button
                                onClick={handleMarkAllAsRead}
                                className="text-xs font-black text-emerald-500 hover:text-emerald-600 uppercase tracking-widest flex items-center gap-2"
                            >
                                <CheckCircle2 size={14} />
                                Mark All Read
                            </button>
                            <button
                                onClick={handleClearAll}
                                className="text-xs font-black text-red-500 hover:text-red-600 uppercase tracking-widest flex items-center gap-2"
                            >
                                <Trash2 size={14} />
                                Clear All
                            </button>
                        </div>
                    )}

                    {/* Content */}
                    <div className="flex-1 overflow-y-auto p-0 scrollbar-thin scrollbar-thumb-[var(--border-color)]">
                        {loading && notifications.length === 0 ? (
                            <div className="h-full flex flex-col items-center justify-center gap-4">
                                <RefreshCw className="animate-spin text-emerald-500" size={32} />
                                <p className="text-xs font-black text-[var(--text-secondary)] uppercase tracking-widest">Loading...</p>
                            </div>
                        ) : notifications.length > 0 ? (
                            <div className="divide-y divide-[var(--border-color)]">
                                {notifications.map((notification) => (
                                    <div
                                        key={notification.id}
                                        className={`p-6 transition-all hover:bg-slate-50 dark:hover:bg-slate-800/50 group relative ${!notification.isRead ? 'bg-emerald-500/5 dark:bg-emerald-500/5' : ''}`}
                                    >
                                        <div className="flex gap-4">
                                            <div className="mt-1">{getIcon(notification.type)}</div>
                                            <div className="flex-1 min-w-0">
                                                <div className="flex items-start justify-between gap-4">
                                                    <h4 className={`text-sm font-black tracking-tight ${!notification.isRead ? 'text-[var(--text-primary)]' : 'text-[var(--text-secondary)]'}`}>
                                                        {notification.title}
                                                    </h4>
                                                    <span className="text-[10px] font-bold text-slate-400 whitespace-nowrap">
                                                        {new Date(notification.createdAt).toLocaleDateString()}
                                                    </span>
                                                </div>
                                                <p className="text-xs font-bold text-[var(--text-secondary)] mt-1 line-clamp-2">
                                                    {notification.message}
                                                </p>

                                                <div className="flex items-center gap-4 mt-4 opacity-0 group-hover:opacity-100 transition-opacity">
                                                    {!notification.isRead && (
                                                        <button
                                                            onClick={() => handleMarkAsRead(notification.id)}
                                                            className="text-[10px] font-black text-emerald-500 hover:text-emerald-600 uppercase tracking-widest"
                                                        >
                                                            Mark Read
                                                        </button>
                                                    )}
                                                    <button
                                                        onClick={() => handleDelete(notification.id)}
                                                        className="text-[10px] font-black text-red-500 hover:text-red-600 uppercase tracking-widest"
                                                    >
                                                        Remove
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                        {!notification.isRead && (
                                            <div className="absolute left-0 top-0 bottom-0 w-1 bg-emerald-500" />
                                        )}
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <div className="h-full flex flex-col items-center justify-center p-12 text-center gap-4">
                                <div className="w-20 h-20 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center text-slate-400">
                                    <Inbox size={40} />
                                </div>
                                <div>
                                    <h3 className="text-sm font-black text-[var(--text-primary)] uppercase tracking-widest">No Notifications</h3>
                                    <p className="text-xs font-bold text-[var(--text-secondary)] mt-2">When you have updates, they'll show up here.</p>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default NotificationDrawer;
