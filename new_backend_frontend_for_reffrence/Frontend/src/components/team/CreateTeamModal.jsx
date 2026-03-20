import React, { useState, useEffect } from 'react';
import { X, UserPlus, Trash2, Shield, User, Users } from 'lucide-react';
import teamService from '../../services/teamService';
import Button from '../ui/Button';
import Input from '../ui/Input';
import toast from 'react-hot-toast';

const CreateTeamModal = ({ isOpen, onClose, onSuccess }) => {
    const [teamName, setTeamName] = useState('');
    const [description, setDescription] = useState('');
    const [allUsers, setAllUsers] = useState([]);
    const [selectedMembers, setSelectedMembers] = useState([]);
    const [isLoading, setIsLoading] = useState(false);

    useEffect(() => {
        if (isOpen) {
            fetchUsers();
        }
    }, [isOpen]);

    const fetchUsers = async () => {
        try {
            const users = await teamService.getUsers();
            setAllUsers(users);
        } catch (error) {
            toast.error('Failed to fetch users');
        }
    };

    const addMember = () => {
        setSelectedMembers([
            ...selectedMembers,
            { userId: '', role: 'TEAM MEMBER', reportsTo: '' }
        ]);
    };

    const removeMember = (index) => {
        setSelectedMembers(selectedMembers.filter((_, i) => i !== index));
    };

    const updateMember = (index, field, value) => {
        const newMembers = [...selectedMembers];
        newMembers[index][field] = value;
        setSelectedMembers(newMembers);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!teamName.trim()) {
            return toast.error('Team name is required');
        }

        // Validate members
        const invalidMember = selectedMembers.find(m => !m.userId);
        if (invalidMember) {
            return toast.error('Please select a user for all members');
        }

        setIsLoading(true);
        try {
            await teamService.createTeam({
                name: teamName,
                description,
                members: selectedMembers
            });
            toast.success('Team created successfully');
            onSuccess();
            onClose();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to create team');
        } finally {
            setIsLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200">
            <div className="bg-white dark:bg-slate-900 w-full max-w-2xl rounded-2xl shadow-2xl border border-gray-200 dark:border-slate-800 flex flex-col max-h-[90vh] overflow-hidden animate-in zoom-in-95 duration-200">
                {/* Header */}
                <div className="flex items-center justify-between px-4 py-2.5 border-b border-gray-100 dark:border-slate-800">
                    <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-lg bg-emerald-500/10 text-emerald-500 flex items-center justify-center">
                            <UserPlus size={16} />
                        </div>
                        <div>
                            <h2 className="text-sm font-bold text-slate-800 dark:text-slate-100">Create New Team</h2>
                            <p className="text-[9px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-widest">Define your team structure</p>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-1.5 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors text-slate-300 hover:text-red-500">
                        <X size={16} />
                    </button>
                </div>

                {/* Form */}
                <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-5 space-y-5 scrollbar-thin">
                    <div className="space-y-3">
                        <div className="space-y-1">
                            <label className="text-[9px] font-black tracking-[0.15em] text-slate-400 uppercase ml-1">Team Name</label>
                            <input
                                placeholder="e.g., Marketing Squad, Backend Core"
                                value={teamName}
                                onChange={(e) => setTeamName(e.target.value)}
                                required
                                className="w-full bg-slate-50/50 dark:bg-slate-950 border-2 border-slate-100 dark:border-slate-800 rounded-xl px-3.5 py-1.5 text-xs font-semibold focus:ring-2 focus:ring-emerald-500/10 focus:border-emerald-500 outline-none transition-all text-slate-700 dark:text-slate-200"
                            />
                        </div>
                        <div className="space-y-1">
                            <label className="text-[9px] font-black tracking-[0.15em] text-slate-400 uppercase ml-1">Team Description</label>
                            <textarea
                                className="w-full bg-slate-50/50 dark:bg-slate-950 border-2 border-slate-100 dark:border-slate-800 rounded-xl px-3.5 py-1.5 text-xs font-semibold focus:ring-2 focus:ring-emerald-500/10 focus:border-emerald-500 outline-none transition-all min-h-[60px] text-slate-700 dark:text-slate-200 resize-none"
                                placeholder="What is the purpose of this team?"
                                value={description}
                                onChange={(e) => setDescription(e.target.value)}
                            />
                        </div>
                    </div>

                    <div className="space-y-3">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2 text-slate-800 dark:text-slate-100">
                                <Users size={14} className="text-emerald-500" />
                                <h3 className="text-[9px] font-black uppercase tracking-[0.15em] text-slate-400">Team Members</h3>
                            </div>
                            <button
                                type="button"
                                onClick={addMember}
                                className="text-[10px] text-emerald-500 hover:text-emerald-600 font-bold flex items-center gap-1 transition-colors uppercase tracking-widest"
                            >
                                <Plus size={10} />
                                Add Member
                            </button>
                        </div>

                        {selectedMembers.length === 0 ? (
                            <div className="text-center py-6 border-2 border-dashed border-gray-100 dark:border-slate-800 rounded-2xl bg-slate-50/50">
                                <p className="text-xs text-slate-500 font-medium">No members added yet. Click "Add Member" to start.</p>
                            </div>
                        ) : (
                            <div className="space-y-3">
                                {selectedMembers.map((member, index) => (
                                    <div key={index} className="p-4 bg-slate-50 dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-xl flex flex-wrap gap-4 items-end relative group">
                                        <div className="flex-1 min-w-[200px] space-y-1.5">
                                            <label className="text-[10px] font-bold uppercase tracking-widest text-slate-500 ml-1">User</label>
                                            <select
                                                className="w-full bg-white dark:bg-slate-900 border-2 border-slate-100 dark:border-slate-800 rounded-xl px-3 py-1.5 text-xs font-semibold outline-none focus:ring-2 focus:ring-emerald-500/20 transition-all text-slate-700 dark:text-slate-200"
                                                value={member.userId}
                                                onChange={(e) => updateMember(index, 'userId', e.target.value)}
                                            >
                                                <option value="">Select User</option>
                                                {allUsers.map(u => (
                                                    <option key={u.userId} value={u.userId}>{u.firstName} {u.lastName}</option>
                                                ))}
                                            </select>
                                        </div>

                                        <div className="w-[120px] space-y-1.5">
                                            <label className="text-[10px] font-bold uppercase tracking-widest text-slate-500 ml-1">Role</label>
                                            <select
                                                className="w-full bg-white dark:bg-slate-900 border-2 border-slate-100 dark:border-slate-800 rounded-xl px-3 py-1.5 text-xs font-semibold outline-none focus:ring-2 focus:ring-emerald-500/20 transition-all text-slate-700 dark:text-slate-200"
                                                value={member.role}
                                                onChange={(e) => updateMember(index, 'role', e.target.value)}
                                            >
                                                <option value="TEAM MEMBER">MEMBER</option>
                                                <option value="MANAGER">MANAGER</option>
                                                <option value="ADMIN">ADMIN</option>
                                            </select>
                                        </div>

                                        <div className="flex-1 min-w-[180px] space-y-1.5">
                                            <label className="text-[10px] font-bold uppercase tracking-widest text-slate-500 ml-1">Reports To</label>
                                            <select
                                                className="w-full bg-white dark:bg-slate-900 border-2 border-slate-100 dark:border-slate-800 rounded-xl px-3 py-1.5 text-xs font-semibold outline-none focus:ring-2 focus:ring-emerald-500/20 transition-all text-slate-700 dark:text-slate-200"
                                                value={member.reportsTo}
                                                onChange={(e) => updateMember(index, 'reportsTo', e.target.value)}
                                            >
                                                <option value="">No One (Top Level)</option>
                                                {allUsers.filter(u => u.userId !== member.userId).map(u => (
                                                    <option key={u.userId} value={u.userId}>{u.firstName} {u.lastName}</option>
                                                ))}
                                            </select>
                                        </div>

                                        <button
                                            type="button"
                                            onClick={() => removeMember(index)}
                                            className="p-1.5 text-slate-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-all absolute -top-2 -right-2 bg-white dark:bg-slate-900 border border-slate-100 dark:border-slate-800 shadow-sm opacity-0 group-hover:opacity-100"
                                        >
                                            <X size={12} />
                                        </button>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </form>

                {/* Footer */}
                <div className="px-4 py-2.5 border-t border-gray-100 dark:border-slate-800 flex items-center justify-end gap-2.5 bg-slate-50/50 dark:bg-slate-900/50">
                    <button
                        type="button"
                        onClick={onClose}
                        className="px-4 py-1.5 text-[10px] font-bold text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100/50 dark:hover:bg-slate-800 rounded-lg transition-colors uppercase tracking-widest"
                    >
                        Cancel
                    </button>
                    <button
                        onClick={handleSubmit}
                        disabled={isLoading}
                        className="px-6 py-2 rounded-lg bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-[10px] shadow-lg shadow-emerald-500/10 transition-all active:scale-[0.98] uppercase tracking-widest"
                    >
                        {isLoading ? 'Creating...' : 'Create Team'}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default CreateTeamModal;
