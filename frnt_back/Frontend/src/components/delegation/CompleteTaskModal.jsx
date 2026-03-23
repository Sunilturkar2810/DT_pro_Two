import React, { useState } from 'react';
import { X, CheckCircle2, Paperclip, Loader2, UploadCloud } from 'lucide-react';
import delegationService from '../../services/delegationService';

const CompleteTaskModal = ({ task, isOpen, onClose, onSuccess }) => {
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [selectedFile, setSelectedFile] = useState(null);
    const [error, setError] = useState(null);

    const handleFileSelect = (e) => {
        const file = e.target.files[0];
        if (file) {
            if (file.size > 10 * 1024 * 1024) {
                setError('File size exceeds 10MB limit');
                return;
            }
            setSelectedFile(file);
            setError(null);
        }
    };

    const handleComplete = async () => {
        try {
            setIsSubmitting(true);
            setError(null);

            let evidenceUrl = task.evidenceUrl || '';

            if (task.evidenceRequired && !selectedFile && !task.evidenceUrl) {
                throw new Error('Evidence is required to complete this task');
            }

            if (selectedFile) {
                const uploadRes = await delegationService.uploadFile(selectedFile, 'evidence');
                evidenceUrl = uploadRes.url;
            }

            await delegationService.updateDelegation(task.id, {
                status: 'Completed',
                evidenceUrl: evidenceUrl
            });

            onSuccess();
        } catch (err) {
            console.error('Failed to complete task:', err);
            setError(err.message || (err.response?.data?.message) || 'Failed to complete task');
        } finally {
            setIsSubmitting(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-[2px]">
            <div className="w-full max-w-sm bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-slate-100 dark:border-slate-800 overflow-hidden animate-in zoom-in-95 duration-200">
                <div className="px-4.5 py-3 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                        <div className="w-7 h-7 rounded-lg bg-emerald-500/10 text-emerald-500 flex items-center justify-center">
                            <CheckCircle2 size={16} />
                        </div>
                        <h2 className="text-sm font-black text-slate-800 dark:text-slate-100 uppercase tracking-tight">Complete Task</h2>
                    </div>
                    <button onClick={onClose} className="p-1.5 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full text-slate-300 hover:text-emerald-500 transition-colors">
                        <X size={16} />
                    </button>
                </div>

                <div className="p-4.5 space-y-4">
                    <div className="p-2.5 bg-slate-50 dark:bg-slate-950 rounded-xl border border-slate-100 dark:border-slate-800">
                        <p className="text-[9px] font-black text-slate-400 uppercase tracking-widest mb-1 opacity-70">Task Title</p>
                        <p className="text-[11px] font-bold text-slate-700 dark:text-slate-200 uppercase tracking-tight">{task.taskTitle}</p>
                    </div>

                    {task.evidenceRequired && (
                        <div className="space-y-2">
                            <label className="text-[10px] font-black text-slate-500 dark:text-slate-400 block px-1 uppercase tracking-widest">
                                Upload Evidence <span className="text-red-500">*</span>
                            </label>
                            <label className={`flex flex-col items-center justify-center w-full h-24 border border-dashed rounded-xl cursor-pointer transition-all ${selectedFile ? 'border-emerald-500 bg-emerald-500/5' : 'border-slate-200 dark:border-slate-800 hover:border-emerald-500 hover:bg-slate-50 dark:hover:bg-slate-800/30'}`}>
                                <div className="flex flex-col items-center justify-center p-4">
                                    {selectedFile ? (
                                        <>
                                            <Paperclip className="w-6 h-6 text-emerald-500 mb-1.5" />
                                            <p className="text-[10px] font-black text-emerald-600 truncate max-w-[200px] uppercase">{selectedFile.name}</p>
                                        </>
                                    ) : (
                                        <>
                                            <UploadCloud className="w-6 h-6 text-slate-300 dark:text-slate-700 mb-1.5" />
                                            <p className="text-[10px] font-black text-slate-400 text-center px-4 uppercase tracking-tighter">Click to upload evidence</p>
                                        </>
                                    )}
                                </div>
                                <input type="file" className="hidden" onChange={handleFileSelect} />
                            </label>
                            <p className="text-[9px] font-bold text-slate-400 dark:text-slate-600 italic px-1 uppercase tracking-tighter">Required: Verification photo or document.</p>
                        </div>
                    )}

                    {!task.evidenceRequired && !selectedFile && (
                        <div className="py-4 px-2 bg-emerald-500/5 rounded-xl border border-emerald-500/10 text-center">
                            <p className="text-[10px] font-black text-emerald-600 uppercase tracking-widest">
                                Ready to mark as completed?
                            </p>
                        </div>
                    )}

                    {error && (
                        <div className="p-2.5 bg-red-500/10 border border-red-500/20 text-red-500 rounded-xl text-[9px] font-black uppercase tracking-widest animate-shake">
                            {error}
                        </div>
                    )}
                </div>

                <div className="p-4 bg-slate-50 dark:bg-slate-950/50 border-t border-slate-100 dark:border-slate-800 flex gap-2.5">
                    <button 
                        onClick={onClose} 
                        className="flex-1 py-2 rounded-lg border border-slate-200 dark:border-slate-800 text-[10px] font-black text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-white dark:hover:bg-slate-800 transition-all uppercase tracking-widest"
                    >
                        CANCEL
                    </button>
                    <button 
                        onClick={handleComplete}
                        disabled={isSubmitting}
                        className="flex-1 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-lg text-[10px] font-black shadow-lg shadow-emerald-500/10 transition-all flex items-center justify-center gap-2 disabled:opacity-50 uppercase tracking-widest active:scale-[0.98]"
                    >
                        {isSubmitting ? <Loader2 className="animate-spin" size={14} /> : 'CONFIRM'}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default CompleteTaskModal;
