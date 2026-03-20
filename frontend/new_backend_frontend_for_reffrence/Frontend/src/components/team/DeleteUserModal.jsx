import React, { useState } from 'react';
import { X, AlertCircle, UserX, AlertTriangle, ShieldAlert, Trash2 } from 'lucide-react';
import authService from '../../services/auth.service';
import Button from '../ui/Button';
import toast from 'react-hot-toast';

const DeleteUserModal = ({ isOpen, onClose, member, onSuccess }) => {
    const [isLoading, setIsLoading] = useState(false);

    if (!isOpen) return null;

    const handleDelete = async () => {
        setIsLoading(true);
        try {
            await authService.deleteUser(member.userId);
            toast.success('User account deleted');
            onSuccess();
            onClose();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to delete user');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" onClick={onClose} />
            
            <div className="relative w-full max-w-sm bg-white dark:bg-slate-900 rounded-2xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200 border border-slate-100 dark:border-slate-800">
                <button 
                    onClick={onClose} 
                    className="absolute top-3.5 right-3.5 p-1.5 text-slate-300 hover:text-red-500 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 transition-all z-10"
                >
                    <X size={16} />
                </button>

                <div className="p-4.5 space-y-4 text-center">
                    <div className="flex flex-col items-center gap-2.5">
                        <div className="w-10 h-10 rounded-xl bg-red-500/10 text-red-500 flex items-center justify-center relative">
                            <Trash2 size={20} />
                            <div className="absolute -top-1 -right-1 bg-red-500 text-white rounded-full p-1 ring-2 ring-white dark:ring-slate-900 shadow-lg">
                                <ShieldAlert size={8} />
                            </div>
                        </div>
                        <div className="space-y-0.5">
                            <h2 className="text-sm font-black text-slate-800 dark:text-slate-100 uppercase tracking-tight">Delete User</h2>
                            <p className="text-[9px] text-red-500 font-black uppercase tracking-[0.15em] opacity-80">Irreversible Action</p>
                        </div>
                    </div>

                    <div className="bg-red-500/5 border border-red-500/10 p-3 rounded-xl relative overflow-hidden group">
                        <div className="absolute -right-4 -bottom-4 opacity-5 group-hover:scale-110 transition-transform">
                             <AlertCircle size={60} />
                        </div>
                        <p className="text-[11px] font-bold text-slate-600 dark:text-slate-400 leading-[1.6] relative z-10">
                            You are about to delete <span className="font-black text-red-500 px-1">{member?.firstName} {member?.lastName}</span>. All data associated with this user will be permanently erased.
                        </p>
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
                            onClick={handleDelete}
                            disabled={isLoading}
                            className="flex-[2] py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg text-[10px] font-black uppercase tracking-widest shadow-lg shadow-red-500/10 flex items-center justify-center gap-2 transition-all active:scale-[0.98]"
                        >
                            {isLoading ? (
                                <span className="w-3.5 h-3.5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                            ) : (
                                "CONFIRM DELETION"
                            )}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default DeleteUserModal;
