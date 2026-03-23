import React, { useState, useEffect } from 'react';
import { X, UserPlus, Search, Check, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';
import teamService from '../../services/teamService';
import authService from '../../services/auth.service';

const AddExistingMemberModal = ({ isOpen, onClose, onSuccess }) => {
    const [users, setUsers] = useState([]);
    const [searchTerm, setSearchTerm] = useState('');
    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);
    const [selectedUserId, setSelectedUserId] = useState('');

    useEffect(() => {
        if (isOpen) {
            fetchUsersOptions();
            setSearchTerm('');
            setSelectedUserId('');
        }
    }, [isOpen]);

    const fetchUsersOptions = async () => {
        try {
            setLoading(true);
            const currentUser = authService.getCurrentUser();
            const currentUserId = currentUser?.user?.id || currentUser?.id;
            
            // Get all general users
            const allUsers = await teamService.getUsers();
            
            // Filter out the manager themselves, and users who already have this manager.
            const availableUsers = allUsers.filter(u => 
                u.userId !== currentUserId && 
                u.reportingManagerId !== currentUserId
            );
            
            setUsers(availableUsers);
        } catch (error) {
            console.error('Failed to fetch available users:', error);
            toast.error('Could not fetch user list.');
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!selectedUserId) {
            return toast.error('Please select a user to add.');
        }

        try {
            setSubmitting(true);
            const currentUser = authService.getCurrentUser();
            const currentUserId = currentUser?.user?.id || currentUser?.id;

            // We use the updateUser endpoint to just change their reportingManagerId
            await authService.updateUser(selectedUserId, {
                reportingManagerId: currentUserId
            });
            
            toast.success('Member successfully added to your team!');
            if (onSuccess) onSuccess();
            onClose();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to add member to team.');
        } finally {
            setSubmitting(false);
        }
    };

    const filteredUsers = users.filter(u => 
        (u.firstName + ' ' + u.lastName).toLowerCase().includes(searchTerm.toLowerCase()) || 
        u.workEmail?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div 
                className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity"
                onClick={onClose}
            />

            <div className="relative w-full max-w-md bg-white dark:bg-slate-900 rounded-2xl shadow-xl border border-slate-100 dark:border-slate-800 flex flex-col animate-in zoom-in-95 duration-200">
                <div className="flex items-center justify-between px-4 py-2.5 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900/50 rounded-t-2xl">
                    <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-lg bg-emerald-500/10 flex items-center justify-center text-emerald-500">
                            <UserPlus size={16} />
                        </div>
                        <div>
                            <h2 className="text-sm font-bold text-slate-800 dark:text-slate-100">Add Existing Member</h2>
                            <p className="text-[9px] text-slate-400 font-bold uppercase tracking-widest">Add employee to team</p>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-1.5 hover:bg-slate-200/50 dark:hover:bg-slate-800 rounded-full transition-colors text-slate-300 hover:text-red-500">
                        <X size={16} />
                    </button>
                </div>

                <div className="p-4">
                    <div className="space-y-3">
                        <div className="relative">
                            <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                            <input 
                                type="text"
                                placeholder="Search by name or email..."
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                                className="w-full pl-9 pr-4 py-2 bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-xl text-[11px] outline-none focus:ring-2 focus:ring-emerald-500/10 transition-all font-semibold text-slate-700 dark:text-slate-200"
                            />
                        </div>

                        <div className="max-h-[280px] overflow-y-auto border border-slate-100 dark:border-slate-800 rounded-xl bg-slate-50/50 dark:bg-slate-950/50 p-1.5 scrollbar-thin space-y-1">
                            {loading ? (
                                <div className="h-full flex flex-col items-center justify-center gap-2 text-emerald-500">
                                    <Loader2 className="animate-spin" size={24} />
                                    <span className="text-xs font-bold uppercase tracking-widest">Loading Users...</span>
                                </div>
                            ) : filteredUsers.length === 0 ? (
                                <div className="h-full flex items-center justify-center text-slate-400 text-sm font-medium italic">
                                    No available users found.
                                </div>
                            ) : (
                                filteredUsers.map(user => (
                                    <button
                                        key={user.userId}
                                        type="button"
                                        onClick={() => setSelectedUserId(user.userId)}
                                        className={`w-full text-left p-2.5 rounded-lg flex items-center justify-between transition-all group ${
                                            selectedUserId === user.userId 
                                            ? 'bg-emerald-500 text-white shadow-md' 
                                            : 'hover:bg-slate-200/50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-200'
                                        }`}
                                    >
                                        <div className="flex items-center gap-2.5 overflow-hidden">
                                            <div className={`w-7 h-7 rounded-full flex items-center justify-center text-[10px] font-bold shrink-0 ${
                                                selectedUserId === user.userId ? 'bg-white/20' : 'bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400'
                                            }`}>
                                                {user.firstName.charAt(0)}{user.lastName?.charAt(0) || ''}
                                            </div>
                                            <div className="truncate">
                                                <div className="text-xs font-bold truncate">{user.firstName} {user.lastName}</div>
                                                <div className={`text-[10px] truncate ${selectedUserId === user.userId ? 'text-emerald-50' : 'text-slate-500'}`}>
                                                    {user.workEmail} • {user.role}
                                                </div>
                                            </div>
                                        </div>
                                        {selectedUserId === user.userId && (
                                            <Check size={18} className="shrink-0" />
                                        )}
                                    </button>
                                ))
                            )}
                        </div>
                    </div>
                </div>

                <div className="px-4 pb-4 pt-1 flex gap-2.5">
                    <button
                        onClick={onClose}
                        className="flex-1 py-2 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-500 dark:text-slate-400 rounded-lg text-[10px] font-bold transition-colors uppercase tracking-widest"
                    >
                        Cancel
                    </button>
                    <button
                        onClick={handleSubmit}
                        disabled={submitting || !selectedUserId}
                        className="flex-[2] py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-lg text-[10px] font-bold transition-all shadow-lg shadow-emerald-500/10 disabled:opacity-50 flex items-center justify-center gap-2 uppercase tracking-widest"
                    >
                        {submitting && <Loader2 size={12} className="animate-spin" />}
                        {submitting ? 'Processing...' : 'Add Member'}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default AddExistingMemberModal;
