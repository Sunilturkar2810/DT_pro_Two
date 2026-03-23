import React, { useState, useEffect } from 'react';
import { X, UserPlus, Shield, User, Mail, Phone, Lock, Briefcase, Building2, ChevronDown, Check, Plus } from 'lucide-react';
import teamService from '../../services/teamService';
import authService from '../../services/auth.service';
import Button from '../ui/Button';
import Input from '../ui/Input';
import toast from 'react-hot-toast';
import PhoneInput from 'react-phone-input-2';
import 'react-phone-input-2/lib/style.css';

const CreateMemberDrawer = ({ isOpen, onClose, onSuccess }) => {
    const [formData, setFormData] = useState({
        firstName: '',
        lastName: '',
        workEmail: '',
        password: '',
        mobileNumber: '',
        role: 'TEAM MEMBER',
        designation: '',
        department: '',
        reportingManagerId: '',
        taskAccess: true,
        leaveAccess: true
    });
    
    const [roles, setRoles] = useState([]);
    const [users, setUsers] = useState([]);
    const [isCustomRole, setIsCustomRole] = useState(false);
    const [customRoleName, setCustomRoleName] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [showRoleDropdown, setShowRoleDropdown] = useState(false);

    useEffect(() => {
        if (isOpen) {
            fetchRoles();
            fetchUsers();
            // Reset form
            setFormData({
                firstName: '',
                lastName: '',
                workEmail: '',
                password: '',
                mobileNumber: '',
                role: 'TEAM MEMBER',
                designation: '',
                department: '',
                reportingManagerId: '',
                taskAccess: true,
                leaveAccess: true
            });
            setIsCustomRole(false);
            setCustomRoleName('');
        }
    }, [isOpen]);

    const fetchRoles = async () => {
        try {
            const data = await authService.getRoles();
            const currentUser = authService.getCurrentUser();
            const isManager = currentUser?.user?.role?.toUpperCase() === 'MANAGER' || currentUser?.role?.toUpperCase() === 'MANAGER';
            
            if (isManager) {
                // Filter out Admin/SuperAdmin for Managers
                setRoles(data.filter(r => !['ADMIN', 'SUPERADMIN'].includes(r.name.toUpperCase())));
            } else {
                setRoles(data);
            }
        } catch (error) {
            console.error('Failed to fetch roles:', error);
        }
    };

    const fetchUsers = async () => {
        try {
            const data = await teamService.getUsers();
            setUsers(data);
        } catch (error) {
            console.error('Failed to fetch users:', error);
        }
    };

    const handleRoleSelect = (roleName) => {
        if (roleName === 'Custom') {
            setIsCustomRole(true);
            setFormData(prev => ({ ...prev, role: '' }));
        } else {
            setIsCustomRole(false);
            setFormData(prev => ({ ...prev, role: roleName }));
        }
        setShowRoleDropdown(false);
    };

    const handleCreateCustomRole = async () => {
        if (!customRoleName.trim()) return;
        try {
            const newRole = await authService.createRole({ name: customRoleName });
            setRoles([...roles, newRole]);
            setFormData(prev => ({ ...prev, role: newRole.name }));
            setIsCustomRole(false);
            toast.success('Custom role created');
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to create role');
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        let finalRole = formData.role;
        if (isCustomRole && customRoleName) {
            // If they haven't "saved" the custom role yet, do it now
            try {
                const newRole = await authService.createRole({ name: customRoleName });
                finalRole = newRole.name;
            } catch (err) {
                 // Might already exist
                 finalRole = customRoleName;
            }
        }

        if (!finalRole) {
            return toast.error('Please select or enter a role');
        }

        setIsLoading(true);
        try {
            await authService.register({
                ...formData,
                role: finalRole,
                password: formData.password || 'Welcome@123' // Default password if empty
            });
            toast.success('Member added successfully');
            onSuccess();
            onClose();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to add member');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <>
            <div
                className={`fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 transition-opacity duration-300 ${isOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}
                onClick={onClose}
            />

            <div className={`fixed top-0 right-0 h-full w-full max-w-lg bg-white dark:bg-slate-900 shadow-2xl z-50 transform transition-transform duration-300 ease-out border-l border-gray-200 dark:border-slate-800 flex flex-col ${isOpen ? 'translate-x-0' : 'translate-x-full'}`}>
                {/* Header */}
                <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900/50">
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-emerald-500/10 text-emerald-500 flex items-center justify-center">
                            <UserPlus size={24} />
                        </div>
                        <div>
                            <h2 className="text-xl font-bold text-slate-800 dark:text-slate-100">Add New Team Member</h2>
                            <p className="text-xs text-slate-500 dark:text-slate-400 font-medium italic">Create a new user account</p>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-2 hover:bg-slate-200/50 dark:hover:bg-slate-800 rounded-full transition-colors text-slate-400 hover:text-slate-600 dark:hover:text-slate-200">
                        <X size={20} />
                    </button>
                </div>

                {/* Form Content */}
                <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6 scrollbar-thin">
                    <div className="grid grid-cols-2 gap-4">
                        <Input
                            label="First Name"
                            placeholder="Aashish"
                            value={formData.firstName}
                            onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                            required
                        />
                        <Input
                            label="Last Name"
                            placeholder="Yadav"
                            value={formData.lastName}
                            onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                            required
                        />
                    </div>

                    <Input
                        label="Work Email"
                        type="email"
                        placeholder="example@company.com"
                        value={formData.workEmail}
                        onChange={(e) => setFormData({ ...formData, workEmail: e.target.value })}
                        required
                    />

                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-1.5">
                            <label className="text-sm font-bold text-slate-700 dark:text-slate-300 ml-1">Mobile Number</label>
                            <div className="phone-input-container">
                                <PhoneInput
                                    country={'in'}
                                    value={formData.mobileNumber}
                                    onChange={phone => setFormData({ ...formData, mobileNumber: phone })}
                                    containerClass="!w-full"
                                    inputClass="!w-full !bg-white dark:!bg-slate-950 !border !border-gray-200 dark:!border-slate-800 !rounded-xl !px-4 !py-3 !text-sm !h-[46px] !pl-12 dark:!text-white font-medium"
                                    buttonClass="!bg-transparent !border !border-gray-200 dark:!border-slate-800 !rounded-l-xl"
                                    dropdownClass="dark:!bg-slate-800 dark:!text-white !border-slate-200 dark:!border-slate-700"
                                    placeholder="+91 XXXXX XXXXX"
                                />
                            </div>
                        </div>
                        <Input
                            label="Password"
                            type="password"
                            placeholder="••••••••"
                            value={formData.password}
                            onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                            helperText="Default: Welcome@123"
                        />
                    </div>

                    <div className="space-y-1.5 relative">
                        <label className="text-sm font-bold text-slate-700 dark:text-slate-300 ml-1">Role</label>
                        <div 
                            className="w-full bg-white dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-xl px-4 py-3 text-sm flex items-center justify-between cursor-pointer hover:border-emerald-500/50 transition-all"
                            onClick={() => setShowRoleDropdown(!showRoleDropdown)}
                        >
                            <span className="text-slate-700 dark:text-slate-200">{isCustomRole ? 'Custom Role' : (formData.role || 'Select Role')}</span>
                            <ChevronDown size={18} className={`text-slate-400 transition-transform ${showRoleDropdown ? 'rotate-180' : ''}`} />
                        </div>

                        {showRoleDropdown && (
                            <div className="absolute z-10 w-full mt-2 bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 rounded-xl shadow-2xl py-2 animate-in fade-in slide-in-from-top-2">
                                {roles.map(r => (
                                    <div 
                                        key={r.id} 
                                        className="px-4 py-2.5 hover:bg-slate-50 dark:hover:bg-slate-800 text-sm text-slate-700 dark:text-slate-300 cursor-pointer flex items-center justify-between group"
                                        onClick={() => handleRoleSelect(r.name)}
                                    >
                                        {r.name}
                                        {formData.role === r.name && <Check size={16} className="text-emerald-500" />}
                                    </div>
                                ))}
                                {(!authService.getCurrentUser()?.user?.role || (authService.getCurrentUser()?.user?.role?.toUpperCase() !== 'MANAGER' && authService.getCurrentUser()?.role?.toUpperCase() !== 'MANAGER')) && (
                                    <>
                                        <div className="border-t border-gray-100 dark:border-slate-800 my-1" />
                                        <div 
                                            className="px-4 py-2.5 hover:bg-slate-50 dark:hover:bg-slate-800 text-sm text-emerald-600 font-bold cursor-pointer flex items-center gap-2"
                                            onClick={() => handleRoleSelect('Custom')}
                                        >
                                            <Plus size={16} />
                                            Custom Role
                                        </div>
                                    </>
                                )}
                            </div>
                        )}
                    </div>

                    {isCustomRole && (
                        <div className="space-y-2 animate-in slide-in-from-top-2">
                            <label className="text-xs font-bold text-emerald-600 uppercase tracking-wider ml-1">Enter Custom Role Name</label>
                            <div className="flex gap-2">
                                <input
                                    type="text"
                                    className="flex-1 bg-white dark:bg-slate-950 border border-emerald-500/30 rounded-xl px-4 py-2 text-sm outline-none focus:ring-2 focus:ring-emerald-500/20"
                                    placeholder="e.g., Senior Designer"
                                    value={customRoleName}
                                    onChange={(e) => setCustomRoleName(e.target.value)}
                                />
                                <button 
                                    type="button"
                                    onClick={handleCreateCustomRole}
                                    className="bg-emerald-500 text-white px-4 rounded-xl text-xs font-bold"
                                >
                                    Add
                                </button>
                            </div>
                        </div>
                    )}

                    <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-700 dark:text-slate-300 ml-1">Reporting Manager</label>
                        <select
                            className="w-full bg-white dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all text-slate-700 dark:text-slate-200"
                            value={formData.reportingManagerId}
                            onChange={(e) => setFormData({ ...formData, reportingManagerId: e.target.value })}
                        >
                            <option value="">Select Reporting Manager</option>
                            {users.map(u => (
                                <option key={u.userId} value={u.userId}>{u.firstName} {u.lastName} ({u.role})</option>
                            ))}
                        </select>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <Input
                            label="Designation"
                            placeholder="e.g., Software Engineer"
                            value={formData.designation}
                            onChange={(e) => setFormData({ ...formData, designation: e.target.value })}
                        />
                        <Input
                            label="Department"
                            placeholder="e.g., IT"
                            value={formData.department}
                            onChange={(e) => setFormData({ ...formData, department: e.target.value })}
                        />
                    </div>

                    <div className="space-y-4 pt-4 border-t border-gray-100 dark:border-slate-800">
                        <div className="flex items-center justify-between">
                            <span className="text-sm font-bold text-slate-700 dark:text-slate-300">Task Access</span>
                            <button
                                type="button"
                                onClick={() => setFormData({ ...formData, taskAccess: !formData.taskAccess })}
                                className={`w-12 h-6 rounded-full transition-colors relative ${formData.taskAccess ? 'bg-emerald-500' : 'bg-slate-300'}`}
                            >
                                <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${formData.taskAccess ? 'left-7' : 'left-1'}`} />
                            </button>
                        </div>
                        <div className="flex items-center justify-between">
                            <span className="text-sm font-bold text-slate-700 dark:text-slate-300">Leave & Attendance Access</span>
                            <button
                                type="button"
                                onClick={() => setFormData({ ...formData, leaveAccess: !formData.leaveAccess })}
                                className={`w-12 h-6 rounded-full transition-colors relative ${formData.leaveAccess ? 'bg-emerald-500' : 'bg-slate-300'}`}
                            >
                                <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${formData.leaveAccess ? 'left-7' : 'left-1'}`} />
                            </button>
                        </div>
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
                        Add Team Member
                    </Button>
                </div>
            </div>
        </>
    );
};

export default CreateMemberDrawer;
