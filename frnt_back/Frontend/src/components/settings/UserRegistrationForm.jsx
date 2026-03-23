import React, { useState } from 'react';
import { UserPlus, Mail, Lock, Phone, Briefcase, Building2, UserCircle, Loader2, CheckCircle2 } from 'lucide-react';
import authService from '../../services/auth.service';
import { toast } from 'react-hot-toast';
import PhoneInput from 'react-phone-input-2';
import 'react-phone-input-2/lib/style.css';

const UserRegistrationForm = () => {
    const [formData, setFormData] = useState({
        firstName: '',
        lastName: '',
        workEmail: '',
        password: '',
        mobileNumber: '',
        role: 'TEAM MEMBER',
        designation: '',
        department: ''
    });

    const [isSubmitting, setIsSubmitting] = useState(false);
    const [roles, setRoles] = useState(['ADMIN', 'MANAGER', 'TEAM MEMBER']);

    React.useEffect(() => {
        const fetchRoles = async () => {
            try {
                const res = await authService.getRoles();
                const fetchedRoles = res.data || res;
                if (Array.isArray(fetchedRoles)) {
                    setRoles(fetchedRoles.map(r => r.name));
                }
            } catch (err) {
                console.error('Failed to fetch roles:', err);
            }
        };
        fetchRoles();
    }, []);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setIsSubmitting(true);
        try {
            await authService.register(formData);
            toast.success('User created successfully!');
            setFormData({
                firstName: '',
                lastName: '',
                workEmail: '',
                password: '',
                mobileNumber: '',
                role: 'TEAM MEMBER',
                designation: '',
                department: ''
            });
        } catch (error) {
            console.error('Registration error:', error);
            toast.error(error.response?.data?.message || 'Failed to create user');
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="bg-(--bg-secondary) rounded-2xl border border-(--border-color) shadow-sm overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-500">
            <div className="p-6 border-b border-(--border-color) bg-emerald-50/30 dark:bg-emerald-500/5">
                <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-emerald-500 flex items-center justify-center shadow-lg shadow-emerald-500/20">
                        <UserPlus className="text-white" size={20} />
                    </div>
                    <div>
                        <h3 className="text-lg font-bold text-slate-800 dark:text-slate-100">Create New User</h3>
                        <p className="text-sm text-slate-500 font-medium">Add a new associate to the system</p>
                    </div>
                </div>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {/* First Name */}
                    <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-700 dark:text-slate-300 flex items-center gap-2">
                            First Name
                        </label>
                        <div className="relative group">
                            <input
                                required
                                type="text"
                                name="firstName"
                                value={formData.firstName}
                                onChange={handleChange}
                                placeholder="Enter first name"
                                className="w-full bg-(--bg-primary) border border-(--border-color) rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all placeholder:text-slate-400 group-hover:border-emerald-500/30"
                            />
                        </div>
                    </div>

                    {/* Last Name */}
                    <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-700 dark:text-slate-300">
                            Last Name
                        </label>
                        <input
                            required
                            type="text"
                            name="lastName"
                            value={formData.lastName}
                            onChange={handleChange}
                            placeholder="Enter last name"
                            className="w-full bg-(--bg-primary) border border-(--border-color) rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all placeholder:text-slate-400"
                        />
                    </div>

                    {/* Work Email */}
                    <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-700 dark:text-slate-300 flex items-center gap-2">
                            <Mail size={14} className="text-emerald-500" />
                            Work Email
                        </label>
                        <input
                            required
                            type="email"
                            name="workEmail"
                            value={formData.workEmail}
                            onChange={handleChange}
                            placeholder="user@example.com"
                            className="w-full bg-(--bg-primary) border border-(--border-color) rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all placeholder:text-slate-400"
                        />
                    </div>

                    {/* Password */}
                    <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-700 dark:text-slate-300 flex items-center gap-2">
                            <Lock size={14} className="text-emerald-500" />
                            Initial Password
                        </label>
                        <input
                            required
                            type="password"
                            name="password"
                            value={formData.password}
                            onChange={handleChange}
                            placeholder="••••••••"
                            className="w-full bg-(--bg-primary) border border-(--border-color) rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all placeholder:text-slate-400"
                        />
                    </div>

                    {/* Mobile Number */}
                    <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-700 dark:text-slate-300 flex items-center gap-2">
                            <Phone size={14} className="text-emerald-500" />
                            Mobile Number
                        </label>
                        <div className="phone-input-container">
                            <PhoneInput
                                country={'in'}
                                value={formData.mobileNumber}
                                onChange={phone => setFormData(prev => ({ ...prev, mobileNumber: phone }))}
                                containerClass="!w-full"
                                inputClass="!w-full !bg-(--bg-primary) !border !border-(--border-color) !rounded-xl !py-2.5 !px-4 !pl-12 !text-sm focus:!ring-2 focus:!ring-emerald-500/20 !outline-none !transition-all !h-[42px] dark:!text-white"
                                buttonClass="!bg-transparent !border !border-(--border-color) !rounded-l-xl"
                                dropdownClass="dark:!bg-slate-800 dark:!text-white !border-slate-200 dark:!border-slate-700"
                                placeholder="+91 XXXXX XXXXX"
                            />
                        </div>
                    </div>

                    {/* Role */}
                    <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-700 dark:text-slate-300 flex items-center gap-2">
                            <UserCircle size={14} className="text-emerald-500" />
                            Role
                        </label>
                        <select
                            name="role"
                            value={formData.role}
                            onChange={handleChange}
                            className="w-full bg-(--bg-primary) border border-(--border-color) rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-emerald-500/20 outline-none appearance-none cursor-pointer"
                        >
                            {roles.map(role => (
                                <option key={role} value={role}>{role}</option>
                            ))}
                        </select>
                    </div>

                    {/* Designation */}
                    <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-700 dark:text-slate-300 flex items-center gap-2">
                            <Briefcase size={14} className="text-emerald-500" />
                            Designation
                        </label>
                        <input
                            required
                            type="text"
                            name="designation"
                            value={formData.designation}
                            onChange={handleChange}
                            placeholder="e.g. Sales Associate"
                            className="w-full bg-(--bg-primary) border border-(--border-color) rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all placeholder:text-slate-400"
                        />
                    </div>

                    {/* Department */}
                    <div className="space-y-1.5">
                        <label className="text-sm font-bold text-slate-700 dark:text-slate-300 flex items-center gap-2">
                            <Building2 size={14} className="text-emerald-500" />
                            Department
                        </label>
                        <input
                            required
                            type="text"
                            name="department"
                            value={formData.department}
                            onChange={handleChange}
                            placeholder="e.g. Operations"
                            className="w-full bg-(--bg-primary) border border-(--border-color) rounded-xl py-2.5 px-4 text-sm focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all placeholder:text-slate-400"
                        />
                    </div>
                </div>

                <div className="pt-4 flex justify-end">
                    <button
                        type="submit"
                        disabled={isSubmitting}
                        className="flex items-center gap-2 px-8 py-3 bg-emerald-500 hover:bg-emerald-600 text-white font-bold rounded-xl shadow-lg shadow-emerald-500/25 transition-all disabled:opacity-50 disabled:cursor-not-allowed group active:scale-95"
                    >
                        {isSubmitting ? (
                            <Loader2 className="animate-spin" size={18} />
                        ) : (
                            <CheckCircle2 size={18} className="group-hover:scale-110 transition-transform" />
                        )}
                        <span>{isSubmitting ? 'Creating User...' : 'Create User Account'}</span>
                    </button>
                </div>
            </form>
        </div>
    );
};

export default UserRegistrationForm;
