import React, { useState, useEffect } from 'react';
import { X, UserPlus, Shield, User, Mail, Phone, Briefcase, Building2, ChevronDown, Check, Plus, ArrowLeft, Save } from 'lucide-react';
import teamService from '../../services/teamService';
import authService from '../../services/auth.service';
import Button from '../ui/Button';
import Input from '../ui/Input';
import toast from 'react-hot-toast';
import PhoneInput from 'react-phone-input-2';
import 'react-phone-input-2/lib/style.css';

const UpdateMemberDrawer = ({ isOpen, onClose, member, onSuccess }) => {
    const [formData, setFormData] = useState({
        firstName: '',
        lastName: '',
        mobileNumber: '',
        role: '',
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
        if (isOpen && member) {
            setFormData({
                firstName: member.firstName || '',
                lastName: member.lastName || '',
                mobileNumber: member.mobileNumber || '',
                role: member.role || '',
                designation: member.designation || '',
                department: member.department || '',
                reportingManagerId: member.reportingManagerId || '',
                taskAccess: member.taskAccess !== false,
                leaveAccess: member.leaveAccess !== false
            });
            fetchRoles();
            fetchUsers();
            setIsCustomRole(false);
            setCustomRoleName('');
        }
    }, [isOpen, member]);

    const fetchRoles = async () => {
        try {
            const data = await authService.getRoles();
            setRoles(data);
        } catch (error) {
            console.error('Failed to fetch roles:', error);
        }
    };

    const fetchUsers = async () => {
        try {
            const data = await teamService.getUsers();
            // Filter out the current member from reporting manager options
            setUsers(data.filter(u => u.userId !== member.userId));
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
            try {
                const newRole = await authService.createRole({ name: customRoleName });
                finalRole = newRole.name;
            } catch (err) {
                 finalRole = customRoleName;
            }
        }

        if (!finalRole) {
            return toast.error('Please select or enter a role');
        }

        setIsLoading(true);
        try {
            await authService.updateUser(member.userId, {
                ...formData,
                role: finalRole,
            });
            toast.success('Member updated successfully');
            onSuccess();
            onClose();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to update member');
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
                        <button onClick={onClose} className="p-2 hover:bg-slate-200/50 dark:hover:bg-slate-800 rounded-lg transition-colors text-slate-400">
                            <ArrowLeft size={20} />
                        </button>
                        <div>
                            <h2 className="text-xl font-bold text-slate-800 dark:text-slate-100">Update Team Member</h2>
                            <p className="text-xs text-slate-500 dark:text-slate-400 font-medium italic">Modify member details</p>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-2 hover:bg-slate-200/50 dark:hover:bg-slate-800 rounded-full transition-colors text-slate-400">
                        <X size={20} />
                    </button>
                </div>

                {/* Form Content */}
                <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6 scrollbar-thin">
                    <div className="grid grid-cols-2 gap-4">
                        <Input
                            label="First Name"
                            placeholder="firstName"
                            value={formData.firstName}
                            onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                            required
                        />
                        <Input
                            label="Last Name"
                            placeholder="lastName"
                            value={formData.lastName}
                            onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                            required
                        />
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-1.5 grayscale opacity-70 cursor-not-allowed">
                             <label className="text-sm font-bold text-slate-700 dark:text-slate-300 ml-1">Work Email</label>
                             <div className="w-full bg-slate-50 dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-xl px-4 py-3 text-sm text-slate-500">
                                 {member?.workEmail}
                             </div>
                             <p className="text-[10px] text-slate-400 font-medium italic ml-1">Email cannot be changed here</p>
                         </div>
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
                    </div>

                    <div className="space-y-1.5 relative">
                        <label className="text-sm font-bold text-slate-700 dark:text-slate-300 ml-1">Role</label>
                        <div 
                            className="w-full bg-white dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-xl px-4 py-3 text-sm flex items-center justify-between cursor-pointer hover:border-emerald-500/50 transition-all font-medium"
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
                                <div className="border-t border-gray-100 dark:border-slate-800 my-1" />
                                <div 
                                    className="px-4 py-2.5 hover:bg-slate-50 dark:hover:bg-slate-800 text-sm text-emerald-600 font-bold cursor-pointer flex items-center gap-2"
                                    onClick={() => handleRoleSelect('Custom')}
                                >
                                    <Plus size={16} />
                                    Custom Role
                                </div>
                            </div>
                        )}
                    </div>

                    <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-700 dark:text-slate-300 ml-1">Reporting Manager</label>
                        <select
                            className="w-full bg-white dark:bg-slate-950 border border-gray-200 dark:border-slate-800 rounded-xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-all text-slate-700 dark:text-slate-200 font-medium"
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
                <div className="px-6 py-6 border-t border-gray-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900/50">
                    <Button
                        onClick={handleSubmit}
                        isLoading={isLoading}
                        className="w-full py-3.5 rounded-xl text-sm font-bold shadow-xl shadow-emerald-500/20 flex items-center justify-center gap-2"
                    >
                        <Save size={18} />
                        Save Changes
                    </Button>
                </div>
            </div>
        </>
    );
};

export default UpdateMemberDrawer;
