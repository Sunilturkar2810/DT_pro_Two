import React, { useState, useEffect } from 'react';
import { X, UserPlus, Trash2, Shield, User, Users, Plus } from 'lucide-react';
import teamService from '../../services/teamService';
import Button from '../ui/Button';
import Input from '../ui/Input';
import toast from 'react-hot-toast';

const CreateTeamDrawer = ({ isOpen, onClose, onSuccess }) => {
    const [teamName, setTeamName] = useState('');
    const [description, setDescription] = useState('');
    const [allUsers, setAllUsers] = useState([]);
    const [selectedMembers, setSelectedMembers] = useState([]);
    const [isLoading, setIsLoading] = useState(false);

    useEffect(() => {
        if (isOpen) {
            fetchUsers();
            // Reset form when opening
            setTeamName('');
            setDescription('');
            setSelectedMembers([]);
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

        const invalidMember = selectedMembers.find(m => !m.userId);
        if (invalidMember) {
            return toast.error('Please select a user for all members');
        }

        // Enforce manager selection for all except top-level
        const invalidReportsTo = selectedMembers.find(m => m.role !== 'ADMIN' && m.role !== 'MANAGER' && !m.reportsTo);
        if (invalidReportsTo) {
            return toast.error('Please select a Reporting Manager for all team members (except top-level/ADMIN/MANAGER).');
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

    return (
        <>
            {/* Backdrop */}
            <div
                className={`fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 transition-opacity duration-300 ${isOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}
                onClick={onClose}
            />

            {/* Side Drawer */}
            <div className={`fixed top-0 right-0 h-full w-full max-w-lg bg-white dark:bg-slate-900 shadow-2xl z-50 transform transition-transform duration-300 ease-out border-l border-gray-200 dark:border-slate-800 flex flex-col ${isOpen ? 'translate-x-0' : 'translate-x-full'}`}>
                {/* Header */}
                <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900/50">
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-emerald-500/10 text-emerald-500 flex items-center justify-center">
                            <UserPlus size={24} />
                        </div>
                        <div>
                            <h2 className="text-xl font-bold text-slate-800 dark:text-slate-100">Create New Team</h2>
                            <p className="text-xs text-slate-500 dark:text-slate-400 font-medium italic">Define your team structure</p>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-2 hover:bg-slate-200/50 dark:hover:bg-slate-800 rounded-full transition-colors text-slate-400 hover:text-slate-600 dark:hover:text-slate-200">
                        <X size={20} />
                    </button>
                </div>

                {/* Form Content */}
                <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-8 scrollbar-thin">
                    <div className="space-y-4">
                        <div className="bg-slate-50/50 dark:bg-slate-800/20 p-4 rounded-xl space-y-4">
                            <Input
                                label="Team Name"
                                placeholder="e.g., Marketing Squad, Backend Core"
                                value={teamName}
                                onChange={(e) => setTeamName(e.target.value)}
                                required
                            />
                            <div className="space-y-1.5">
                                <label className="text-sm font-bold text-slate-700 dark:text-slate-300 ml-1">Team Description</label>
                                <textarea
                                    className="w-full bg-white dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 outline-none transition-all min-h-[100px] text-slate-700 dark:text-slate-200"
                                    placeholder="What is the purpose of this team?"
                                    value={description}
                                    onChange={(e) => setDescription(e.target.value)}
                                />
                            </div>
                        </div>
                    </div>

                    <div className="space-y-6">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2 text-slate-800 dark:text-slate-100">
                                <Users size={18} className="text-emerald-500" />
                                <h3 className="font-bold">Team Members</h3>
                            </div>
                            <button
                                type="button"
                                onClick={addMember}
                                className="text-sm text-white bg-emerald-500 hover:bg-emerald-600 px-3 py-1.5 rounded-lg font-bold flex items-center gap-1 transition-all active:scale-95 shadow-lg shadow-emerald-500/20"
                            >
                                <Plus size={16} />
                                Add Member
                            </button>
                        </div>

                        {selectedMembers.length === 0 ? (
                            <div className="text-center py-12 border-2 border-dashed border-gray-100 dark:border-slate-800 rounded-2xl bg-slate-50/30 dark:bg-slate-900/30">
                                <div className="w-12 h-12 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center mx-auto mb-3 text-slate-400">
                                    <Users size={24} />
                                </div>
                                <p className="text-sm text-slate-500">No members added yet.</p>
                                <button
                                    type="button"
                                    onClick={addMember}
                                    className="text-emerald-500 text-xs font-bold mt-2 hover:underline"
                                >
                                    Click here to add your first member
                                </button>
                            </div>
                        ) : (
                            <div className="space-y-4">
                                {selectedMembers.map((member, index) => (
                                    <div key={index} className="p-4 bg-slate-50/50 dark:bg-slate-800/30 border border-gray-100 dark:border-slate-800 rounded-xl space-y-4 animate-in slide-in-from-right-4 duration-300">
                                        <div className="flex items-center justify-between border-b border-gray-100 dark:border-slate-800 pb-2">
                                            <span className="text-[10px] font-extrabold uppercase tracking-widest text-emerald-600 dark:text-emerald-400">Member #{index + 1}</span>
                                            <button
                                                type="button"
                                                onClick={() => removeMember(index)}
                                                className="text-red-400 hover:text-red-600 p-1 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-md transition-colors"
                                            >
                                                <Trash2 size={16} />
                                            </button>
                                        </div>

                                        <div className="space-y-4">
                                            <div className="space-y-1.5">
                                                <label className="text-[10px] font-bold uppercase tracking-wider text-slate-500 ml-1">Assign User</label>
                                                <select
                                                    className="w-full bg-white dark:bg-slate-900 border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-emerald-500/20 transition-all text-slate-700 dark:text-slate-200"
                                                    value={member.userId}
                                                    onChange={(e) => updateMember(index, 'userId', e.target.value)}
                                                >
                                                    <option value="">Select User</option>
                                                    {allUsers.map(u => (
                                                        <option key={u.userId} value={u.userId}>{u.firstName} {u.lastName} ({u.role})</option>
                                                    ))}
                                                </select>
                                            </div>

                                            <div className="grid grid-cols-2 gap-4">
                                                <div className="space-y-1.5">
                                                    <label className="text-[10px] font-bold uppercase tracking-wider text-slate-500 ml-1">Team Role</label>
                                                    <select
                                                        className="w-full bg-white dark:bg-slate-900 border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-emerald-500/20 transition-all text-slate-700 dark:text-slate-200"
                                                        value={member.role}
                                                        onChange={(e) => updateMember(index, 'role', e.target.value)}
                                                    >
                                                        <option value="TEAM MEMBER">TEAM MEMBER</option>
                                                        <option value="MANAGER">MANAGER</option>
                                                        <option value="ADMIN">ADMIN</option>
                                                    </select>
                                                </div>

                                                <div className="space-y-1.5">
                                                    <label className="text-[10px] font-bold uppercase tracking-wider text-slate-500 ml-1">Reports To</label>
                                                    <select
                                                        className="w-full bg-white dark:bg-slate-900 border border-gray-200 dark:border-slate-800 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-emerald-500/20 transition-all text-slate-700 dark:text-slate-200"
                                                        value={member.reportsTo}
                                                        onChange={(e) => updateMember(index, 'reportsTo', e.target.value)}
                                                    >
                                                        <option value="">Top Level</option>
                                                        {allUsers.filter(u => u.userId !== member.userId).map(u => (
                                                            <option key={u.userId} value={u.userId}>{u.firstName} {u.lastName}</option>
                                                        ))}
                                                    </select>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </form>

                {/* Footer */}
                <div className="px-6 py-6 border-t border-gray-100 dark:border-slate-800 flex items-center justify-end gap-3 bg-slate-50/50 dark:bg-slate-900/50">
                    <button
                        type="button"
                        onClick={onClose}
                        className="px-6 py-2.5 text-sm font-bold text-slate-600 dark:text-slate-400 hover:bg-slate-200/50 dark:hover:bg-slate-800 rounded-xl transition-colors"
                    >
                        Discard
                    </button>
                    <Button
                        onClick={handleSubmit}
                        isLoading={isLoading}
                        className="px-8 py-2.5 rounded-xl text-sm shadow-xl shadow-emerald-500/30"
                    >
                        Initialize Team
                    </Button>
                </div>
            </div>
        </>
    );
};

export default CreateTeamDrawer;
