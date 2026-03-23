import React, { useState } from 'react';
import { X, AlertTriangle, Trash2, Mail, Info } from 'lucide-react';
import authService from '../../services/auth.service';
import Button from '../ui/Button';
import Input from '../ui/Input';
import toast from 'react-hot-toast';

const DeleteTasksModal = ({ isOpen, onClose, member, onSuccess }) => {
    const [confirmEmail, setConfirmEmail] = useState('');
    const [isLoading, setIsLoading] = useState(false);

    if (!isOpen) return null;

    const handleDelete = async (e) => {
        e.preventDefault();
        
        if (confirmEmail !== member.workEmail) {
            return toast.error('Confirmation email does not match');
        }

        setIsLoading(true);
        try {
            await authService.deleteAllTasks(member.userId, confirmEmail);
            toast.success('All tasks deleted permanently');
            onSuccess();
            onClose();
            setConfirmEmail('');
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to delete tasks');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 transition-all duration-300">
            <div className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" onClick={onClose} />
            
            <div className="relative w-full max-w-sm bg-white dark:bg-slate-900 rounded-2xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200 border border-red-500/10">
                <div className="bg-red-500/5 px-4.5 py-3 flex items-center justify-between border-b border-red-500/10">
                    <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-lg bg-red-500 text-white flex items-center justify-center shadow-lg shadow-red-500/20">
                            <AlertTriangle size={16} />
                        </div>
                        <div>
                            <h2 className="text-sm font-black text-slate-800 dark:text-slate-100 uppercase tracking-tight">Erase Tasks</h2>
                            <p className="text-[9px] text-red-500 font-black uppercase tracking-widest opacity-80">Permanent Deletion</p>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-1.5 hover:bg-red-500/10 rounded-full transition-colors text-slate-300 hover:text-red-500">
                        <X size={16} />
                    </button>
                </div>

                <div className="p-4.5 space-y-4">
                    <div className="space-y-3">
                        <p className="text-[11px] text-slate-500 dark:text-slate-400 font-bold leading-relaxed px-1">
                            Confirm permanent erasure of all tasks for <span className="font-black text-slate-800 dark:text-slate-200">{member?.workEmail}</span>.
                        </p>
                        <div className="bg-slate-50 dark:bg-slate-950 p-3 rounded-xl border border-slate-100 dark:border-slate-800 space-y-1.5">
                             <div className="flex items-center gap-2 text-red-500 font-black text-[9px] uppercase tracking-wider">
                                 <Info size={10} />
                                 Caution: Irreversible Action
                             </div>
                            <p className="text-[9px] text-slate-400 dark:text-slate-500 font-bold leading-relaxed uppercase tracking-tight">All assigned and received tasks will be wiped from the system permanently.</p>
                        </div>
                    </div>

                    <form onSubmit={handleDelete} className="space-y-4">
                        <div className="space-y-2">
                            <label className="text-[9px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest block px-1">
                                Verification Required
                            </label>
                            <div className="relative group">
                                <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-red-500 transition-colors">
                                    <Mail size={14} />
                                </div>
                                <input 
                                    type="text"
                                    className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-100 dark:border-slate-800 rounded-xl pl-10 pr-4 py-2 text-[10px] font-black focus:border-red-500/30 focus:ring-4 focus:ring-red-500/5 outline-none transition-all placeholder:text-slate-300 dark:placeholder:text-slate-700 text-red-500 tracking-wide"
                                    placeholder={member?.workEmail}
                                    value={confirmEmail}
                                    onChange={(e) => setConfirmEmail(e.target.value)}
                                    required
                                />
                            </div>
                        </div>

                        <div className="flex gap-2.5 pt-1">
                            <button 
                                type="button" 
                                onClick={onClose}
                                className="flex-1 py-2 text-[10px] font-black text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 bg-slate-50 dark:bg-slate-800 rounded-lg transition-all"
                            >
                                CANCEL
                            </button>
                            <button 
                                type="submit"
                                disabled={confirmEmail !== member.workEmail || isLoading}
                                className={`flex-[2] py-2 rounded-lg text-[10px] font-black uppercase tracking-widest shadow-lg flex items-center justify-center gap-2 transition-all active:scale-[0.98] ${confirmEmail === member.workEmail ? 'bg-red-500 text-white shadow-red-500/10 hover:bg-red-600' : 'bg-slate-100 dark:bg-slate-800 text-slate-300 dark:text-slate-700 cursor-not-allowed'}`}
                            >
                                {isLoading ? (
                                    <span className="w-3.5 h-3.5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                ) : (
                                    <>
                                        <Trash2 size={14} />
                                        PERMANENTLY ERASE
                                    </>
                                )}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default DeleteTasksModal;
