import React, { useState } from 'react';
import { 
    UserPlus, Trash2, Plus, CheckCircle2, 
    X, Loader2, Mail, Lock, Phone, 
    Briefcase, Building2, UserCircle, Save
} from 'lucide-react';
import authService from '../services/auth.service';
import { toast } from 'react-hot-toast';

const AddUserPage = () => {
    const [users, setUsers] = useState([
        { 
            id: Date.now(),
            firstName: '', 
            lastName: '', 
            workEmail: '', 
            password: '', 
            mobileNumber: '', 
            role: 'User', 
            designation: '', 
            department: '' 
        }
    ]);
    const [isSubmitting, setIsSubmitting] = useState(false);

    const roles = ['ADMIN', 'User'];

    const handleAddRow = () => {
        setUsers([
            ...users,
            { 
                id: Date.now(),
                firstName: '', 
                lastName: '', 
                workEmail: '', 
                password: '', 
                mobileNumber: '', 
                role: 'User', 
                designation: '', 
                department: '' 
            }
        ]);
    };

    const handleRemoveRow = (id) => {
        if (users.length === 1) {
            toast.error('At least one user is required');
            return;
        }
        setUsers(users.filter(user => user.id !== id));
    };

    const handleChange = (id, field, value) => {
        setUsers(users.map(user => 
            user.id === id ? { ...user, [field]: value } : user
        ));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        // Validation
        const invalidUser = users.find(u => !u.firstName || !u.workEmail || !u.password);
        if (invalidUser) {
            toast.error('Please fill in required fields for all users');
            return;
        }

        setIsSubmitting(true);

        try {
            const { results, message } = await authService.bulkRegister(users);
            
            const successCount = results.success.length;
            const failCount = results.failed.length;

            if (successCount > 0) {
                toast.success(`Successfully added ${successCount} users!`);
                if (failCount === 0) {
                    setUsers([{ 
                        id: Date.now(),
                        firstName: '', 
                        lastName: '', 
                        workEmail: '', 
                        password: '', 
                        mobileNumber: '', 
                        role: 'User', 
                        designation: '', 
                        department: '' 
                    }]);
                } else {
                    const failDetails = results.failed.map(f => `${f.email}: ${f.reason}`).join('\n');
                    toast.error(`Failed to add ${failCount} users:\n${failDetails}`, { duration: 5000 });
                    // Keep failed users in the list
                    const failedEmails = results.failed.map(f => f.email);
                    setUsers(users.filter(u => failedEmails.includes(u.workEmail)));
                }
            } else {
                toast.error('Failed to add users. Please check your data.');
            }
        } catch (err) {
            console.error('Bulk registration error:', err);
            toast.error(err.response?.data?.message || 'Server error during registration');
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="flex flex-col gap-8 p-6 lg:p-10 animate-in fade-in duration-700">
            {/* Page Header */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-3xl font-extrabold text-slate-900 dark:text-white flex items-center gap-3 tracking-tight">
                        <div className="p-2 bg-emerald-500/10 rounded-xl">
                            <UserPlus className="text-emerald-500" size={32} />
                        </div>
                        Add Multiple Users
                    </h1>
                    <p className="mt-2 text-slate-500 font-medium">Register multiple team members at once to your workspace</p>
                </div>
                
                <div className="flex items-center gap-3">
                    <button 
                        onClick={handleAddRow}
                        className="flex items-center gap-2 px-6 py-3 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl text-slate-700 dark:text-slate-200 font-bold hover:border-emerald-500/50 hover:bg-emerald-50/30 dark:hover:bg-emerald-500/5 transition-all active:scale-95 shadow-sm"
                    >
                        <Plus size={18} className="text-emerald-500" />
                        Add New Row
                    </button>
                    <button 
                        onClick={handleSubmit}
                        disabled={isSubmitting}
                        className="flex items-center gap-2 px-8 py-3 bg-emerald-500 hover:bg-emerald-600 text-white font-bold rounded-xl shadow-lg shadow-emerald-500/25 transition-all disabled:opacity-50 disabled:cursor-not-allowed active:scale-95"
                    >
                        {isSubmitting ? <Loader2 className="animate-spin" size={18} /> : <Save size={18} />}
                        Save All Users
                    </button>
                </div>
            </div>

            {/* User Forms List */}
            <div className="space-y-6">
                {users.map((user, index) => (
                    <div 
                        key={user.id} 
                        className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200 dark:border-slate-800 shadow-xl shadow-slate-200/50 dark:shadow-none overflow-hidden animate-in slide-in-from-bottom-4 duration-500"
                        style={{ animationDelay: `${index * 100}ms` }}
                    >
                        {/* Form Header */}
                        <div className="px-8 py-4 bg-slate-50/50 dark:bg-white/5 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <span className="flex items-center justify-center w-8 h-8 rounded-full bg-emerald-500 text-white text-xs font-black shadow-md shadow-emerald-500/20">
                                    {index + 1}
                                </span>
                                <h3 className="text-sm font-bold text-slate-800 dark:text-slate-200 tracking-wide uppercase">User Details</h3>
                            </div>
                            <button 
                                onClick={() => handleRemoveRow(user.id)}
                                className="p-2 text-slate-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-xl transition-all"
                            >
                                <Trash2 size={18} />
                            </button>
                        </div>

                        {/* Form Fields */}
                        <div className="p-8 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                            {/* First Name */}
                            <div className="space-y-2">
                                <label className="text-[11px] font-black text-slate-400 uppercase tracking-widest px-1">First Name</label>
                                <input 
                                    type="text" 
                                    value={user.firstName}
                                    onChange={(e) => handleChange(user.id, 'firstName', e.target.value)}
                                    placeholder="John"
                                    className="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 rounded-xl outline-none focus:border-emerald-500 focus:bg-white dark:focus:bg-slate-900 transition-all text-sm font-medium"
                                />
                            </div>

                            {/* Last Name */}
                            <div className="space-y-2">
                                <label className="text-[11px] font-black text-slate-400 uppercase tracking-widest px-1">Last Name</label>
                                <input 
                                    type="text" 
                                    value={user.lastName}
                                    onChange={(e) => handleChange(user.id, 'lastName', e.target.value)}
                                    placeholder="Doe"
                                    className="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 rounded-xl outline-none focus:border-emerald-500 focus:bg-white dark:focus:bg-slate-900 transition-all text-sm font-medium"
                                />
                            </div>

                            {/* Email */}
                            <div className="space-y-2 lg:col-span-2">
                                <label className="text-[11px] font-black text-slate-400 uppercase tracking-widest px-1">Work Email</label>
                                <div className="relative">
                                    <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                                    <input 
                                        type="email" 
                                        value={user.workEmail}
                                        onChange={(e) => handleChange(user.id, 'workEmail', e.target.value)}
                                        placeholder="john.doe@company.com"
                                        className="w-full pl-12 pr-4 py-3 bg-slate-50 dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 rounded-xl outline-none focus:border-emerald-500 focus:bg-white dark:focus:bg-slate-900 transition-all text-sm font-medium"
                                    />
                                </div>
                            </div>

                            {/* Password */}
                            <div className="space-y-2">
                                <label className="text-[11px] font-black text-slate-400 uppercase tracking-widest px-1">Initial Password</label>
                                <div className="relative">
                                    <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                                    <input 
                                        type="password" 
                                        value={user.password}
                                        onChange={(e) => handleChange(user.id, 'password', e.target.value)}
                                        placeholder="••••••••"
                                        className="w-full pl-12 pr-4 py-3 bg-slate-50 dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 rounded-xl outline-none focus:border-emerald-500 focus:bg-white dark:focus:bg-slate-900 transition-all text-sm font-medium"
                                    />
                                </div>
                            </div>

                            {/* Mobile */}
                            <div className="space-y-2">
                                <label className="text-[11px] font-black text-slate-400 uppercase tracking-widest px-1">Mobile No</label>
                                <div className="relative">
                                    <Phone className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                                    <input 
                                        type="tel" 
                                        value={user.mobileNumber}
                                        onChange={(e) => handleChange(user.id, 'mobileNumber', e.target.value)}
                                        placeholder="+91 XXXXX XXXXX"
                                        className="w-full pl-12 pr-4 py-3 bg-slate-50 dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 rounded-xl outline-none focus:border-emerald-500 focus:bg-white dark:focus:bg-slate-900 transition-all text-sm font-medium"
                                    />
                                </div>
                            </div>

                            {/* Role */}
                            <div className="space-y-2">
                                <label className="text-[11px] font-black text-slate-400 uppercase tracking-widest px-1">Role</label>
                                <div className="relative">
                                    <UserCircle className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                                    <select 
                                        value={user.role}
                                        onChange={(e) => handleChange(user.id, 'role', e.target.value)}
                                        className="w-full pl-12 pr-4 py-3 bg-slate-50 dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 rounded-xl outline-none focus:border-emerald-500 focus:bg-white dark:focus:bg-slate-900 transition-all text-sm font-medium appearance-none cursor-pointer"
                                    >
                                        {roles.map(r => <option key={r} value={r}>{r}</option>)}
                                    </select>
                                </div>
                            </div>

                            {/* Designation */}
                            <div className="space-y-2">
                                <label className="text-[11px] font-black text-slate-400 uppercase tracking-widest px-1">Designation</label>
                                <div className="relative">
                                    <Briefcase className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                                    <input 
                                        type="text" 
                                        value={user.designation}
                                        onChange={(e) => handleChange(user.id, 'designation', e.target.value)}
                                        placeholder="Project Manager"
                                        className="w-full pl-12 pr-4 py-3 bg-slate-50 dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 rounded-xl outline-none focus:border-emerald-500 focus:bg-white dark:focus:bg-slate-900 transition-all text-sm font-medium"
                                    />
                                </div>
                            </div>

                            {/* Department */}
                            <div className="space-y-2 lg:col-span-1">
                                <label className="text-[11px] font-black text-slate-400 uppercase tracking-widest px-1">Department</label>
                                <div className="relative">
                                    <Building2 className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                                    <input 
                                        type="text" 
                                        value={user.department}
                                        onChange={(e) => handleChange(user.id, 'department', e.target.value)}
                                        placeholder="Engineering"
                                        className="w-full pl-12 pr-4 py-3 bg-slate-50 dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 rounded-xl outline-none focus:border-emerald-500 focus:bg-white dark:focus:bg-slate-900 transition-all text-sm font-medium"
                                    />
                                </div>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {/* Bottom Actions */}
            {users.length > 3 && (
                <div className="flex justify-center pt-8">
                    <button 
                        onClick={handleSubmit}
                        disabled={isSubmitting}
                        className="flex items-center gap-3 px-12 py-4 bg-emerald-500 hover:bg-emerald-600 text-white font-black text-lg rounded-2xl shadow-2xl shadow-emerald-500/40 transition-all hover:-translate-y-1 active:scale-95 disabled:opacity-50"
                    >
                        {isSubmitting ? <Loader2 className="animate-spin" size={24} /> : <CheckCircle2 size={24} />}
                        Save All Users Now
                    </button>
                </div>
            )}
        </div>
    );
};

export default AddUserPage;
