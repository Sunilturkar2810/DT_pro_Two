import React, { useState } from 'react';
import { X, Mail, Lock, AlertCircle } from 'lucide-react';
import authService from '../../services/auth.service';
import Button from '../ui/Button';
import Input from '../ui/Input';
import toast from 'react-hot-toast';

const UpdateCredentialsModal = ({ isOpen, onClose, member, onSuccess }) => {
    const [mode, setMode] = useState(null); // 'email', 'password', 'both'
    const [formData, setFormData] = useState({
        oldPassword: '',
        newPassword: '',
        confirmPassword: '',
        newEmail: ''
    });
    const [isLoading, setIsLoading] = useState(false);

    if (!isOpen) return null;

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        if (!formData.oldPassword) {
            return toast.error('Old password is required to verify identity');
        }

        if ((mode === 'password' || mode === 'both') && formData.newPassword !== formData.confirmPassword) {
            return toast.error('New passwords do not match');
        }

        setIsLoading(true);
        try {
            await authService.updateCredentials(member.userId, {
                oldPassword: formData.oldPassword,
                newPassword: (mode === 'password' || mode === 'both') ? formData.newPassword : null,
                newEmail: (mode === 'email' || mode === 'both') ? formData.newEmail : null
            });
            toast.success('Credentials updated successfully');
            onSuccess();
            onClose();
            setMode(null);
            setFormData({ oldPassword: '', newPassword: '', confirmPassword: '', newEmail: '' });
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to update credentials');
        } finally {
            setIsLoading(false);
        }
    };

    const renderSelection = () => (
        <div className="p-4 space-y-4">
            <div className="text-center space-y-0.5">
                <h2 className="text-sm font-black text-slate-800 dark:text-slate-100 uppercase tracking-[0.1em]">Update Credentials</h2>
                <p className="text-[9px] text-slate-400 font-black uppercase tracking-[0.15em]">Security Settings</p>
            </div>
            
            <div className="grid grid-cols-3 gap-2.5">
                <button 
                    onClick={() => { setMode('email'); setFormData({...formData, newEmail: member.workEmail}); }}
                    className="flex flex-col items-center justify-center p-3 border border-slate-100 dark:border-slate-800 rounded-2xl hover:border-emerald-500 hover:bg-emerald-500/5 transition-all group scale-[0.98] hover:scale-100"
                >
                    <div className="w-8 h-8 rounded-xl bg-slate-50 dark:bg-slate-900/50 flex items-center justify-center text-slate-400 group-hover:text-emerald-500 mb-2 transition-colors">
                        <Mail size={16} />
                    </div>
                    <span className="text-[9px] font-black text-slate-400 dark:text-slate-500 group-hover:text-slate-800 dark:group-hover:text-slate-200 uppercase tracking-widest">Email</span>
                </button>
                
                <button 
                    onClick={() => setMode('password')}
                    className="flex flex-col items-center justify-center p-3 border border-slate-100 dark:border-slate-800 rounded-2xl hover:border-emerald-500 hover:bg-emerald-500/5 transition-all group scale-[0.98] hover:scale-100"
                >
                    <div className="w-8 h-8 rounded-xl bg-slate-50 dark:bg-slate-900/50 flex items-center justify-center text-slate-400 group-hover:text-emerald-500 mb-2 transition-colors">
                        <Lock size={16} />
                    </div>
                    <span className="text-[9px] font-black text-slate-400 dark:text-slate-500 group-hover:text-slate-800 dark:group-hover:text-slate-200 uppercase tracking-widest">Password</span>
                </button>
 
                <button 
                    onClick={() => { setMode('both'); setFormData({...formData, newEmail: member.workEmail}); }}
                    className="flex flex-col items-center justify-center p-3 border border-slate-100 dark:border-slate-800 rounded-2xl hover:border-emerald-500 hover:bg-emerald-500/5 transition-all group scale-[0.98] hover:scale-100"
                >
                    <div className="w-8 h-8 rounded-xl bg-slate-50 dark:bg-slate-900/50 flex items-center justify-center text-slate-400 group-hover:text-emerald-500 mb-2 transition-colors relative">
                        <Mail size={10} className="absolute top-1.5 left-1.5" />
                        <Lock size={10} className="absolute bottom-1.5 right-1.5" />
                    </div>
                    <span className="text-[9px] font-black text-slate-400 dark:text-slate-500 group-hover:text-slate-800 dark:group-hover:text-slate-200 uppercase tracking-widest">Both</span>
                </button>
            </div>
        </div>
    );

    const renderForm = () => (
        <form onSubmit={handleSubmit} className="p-4 space-y-4 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between mb-1">
                <button type="button" onClick={() => setMode(null)} className="text-[9px] font-black text-emerald-500 uppercase tracking-widest hover:underline">← Back</button>
                <div className="text-right">
                    <h3 className="text-sm font-black text-slate-800 dark:text-slate-100 uppercase tracking-tight">
                        {mode === 'email' ? 'Update Email' : mode === 'password' ? 'Reset Password' : 'Update Credentials'}
                    </h3>
                </div>
            </div>
 
            <div className="bg-slate-50 dark:bg-slate-950 p-2.5 rounded-xl border border-slate-100 dark:border-slate-800 flex gap-2.5 items-center">
                <AlertCircle className="text-emerald-500 shrink-0" size={12} />
                <p className="text-[9px] text-slate-400 font-bold uppercase tracking-widest italic">Identity verification required.</p>
            </div>
 
            <div className="space-y-3">
                <Input 
                    label="Current Password"
                    type="password"
                    placeholder="Verify identity"
                    value={formData.oldPassword}
                    onChange={(e) => setFormData({...formData, oldPassword: e.target.value})}
                    required
                />
 
                {(mode === 'email' || mode === 'both') && (
                    <Input 
                        label="New Work Email"
                        type="email"
                        placeholder="new.email@company.com"
                        value={formData.newEmail}
                        onChange={(e) => setFormData({...formData, newEmail: e.target.value})}
                        required
                    />
                )}
 
                {(mode === 'password' || mode === 'both') && (
                    <div className="grid grid-cols-2 gap-2.5">
                        <Input 
                            label="New Pass"
                            type="password"
                            placeholder="Min 8 chars"
                            value={formData.newPassword}
                            onChange={(e) => setFormData({...formData, newPassword: e.target.value})}
                            required
                        />
                        <Input 
                            label="Confirm"
                            type="password"
                            placeholder="Repeat"
                            value={formData.confirmPassword}
                            onChange={(e) => setFormData({...formData, confirmPassword: e.target.value})}
                            required
                        />
                    </div>
                )}
            </div>
 
            <div className="flex gap-2.5 pt-1">
                <button 
                    type="button" 
                    onClick={onClose}
                    className="flex-1 py-2 text-[10px] font-bold text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 bg-slate-100 dark:bg-slate-800 rounded-lg transition-colors uppercase tracking-widest"
                >
                    Cancel
                </button>
                <button 
                    onClick={handleSubmit}
                    disabled={isLoading}
                    className="flex-[2] py-2 rounded-lg bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-[10px] shadow-lg shadow-emerald-500/10 transition-all active:scale-[0.98] uppercase tracking-widest"
                >
                    {isLoading ? 'Verifying...' : 'Confirm'}
                </button>
            </div>
        </form>
    );

    return (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" onClick={onClose} />
            <div className="relative w-full max-w-sm bg-white dark:bg-slate-900 rounded-2xl shadow-2xl overflow-hidden border border-slate-100 dark:border-slate-800 animate-in fade-in zoom-in-95 duration-200">
                <button 
                    onClick={onClose} 
                    className="absolute top-3.5 right-3.5 p-1.5 text-slate-300 hover:text-red-500 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 transition-all z-10"
                >
                    <X size={16} />
                </button>
                
                {mode ? renderForm() : renderSelection()}
            </div>
        </div>
    );
};

export default UpdateCredentialsModal;
