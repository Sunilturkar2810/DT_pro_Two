import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { X, Search, Upload, User, ChevronDown, ChevronUp } from 'lucide-react';
import teamService from '../../services/teamService';
import delegationService from '../../services/delegationService';

const CreateGroupModal = ({ isOpen, onClose, onSuccess }) => {
    const [name, setName] = useState('');
    const [description, setDescription] = useState('');
    const [isPublic, setIsPublic] = useState(false);
    const [searchMember, setSearchMember] = useState('');
    const [selectedMembers, setSelectedMembers] = useState([]);
    const [availableUsers, setAvailableUsers] = useState([]);
    const [showMemberList, setShowMemberList] = useState(true);
    const [loading, setLoading] = useState(false);
    const [image, setImage] = useState(null);
    const [imagePreview, setImagePreview] = useState(null);

    useEffect(() => {
        if (!image) {
            setImagePreview(null);
            return;
        }
        const reader = new FileReader();
        reader.onloadend = () => {
            setImagePreview(reader.result);
        };
        reader.readAsDataURL(image);
    }, [image]);

    useEffect(() => {
        if (isOpen) {
            fetchUsers();
        }
    }, [isOpen]);

    const fetchUsers = async () => {
        try {
            const res = await teamService.getUsers();
            // Auth controller returns the array directly
            setAvailableUsers(Array.isArray(res) ? res : (res?.data || []));
        } catch (err) {
            console.error('Failed to fetch users:', err);
        }
    };

    const handleCreate = async () => {
        if (!name.trim()) return;
        try {
            setLoading(true);
            const userJson = localStorage.getItem('user');
            const currentUser = userJson ? JSON.parse(userJson) : null;
            
            if (!currentUser) {
                console.error('No logged in user found');
                return;
            }

            let imageUrl = null;
            if (image) {
                const uploadRes = await delegationService.uploadFile(image, 'groups');
                if (uploadRes.success) {
                    imageUrl = uploadRes.url;
                }
            }

            const groupData = {
                name,
                description,
                imageUrl,
                members: selectedMembers.map(m => m.userId),
                createdBy: currentUser.userId || currentUser.id || currentUser._id
            };

            console.log('Sending Group Data:', groupData);
            const result = await delegationService.createGroup(groupData);
            onSuccess && onSuccess(result?.data || result);
            onClose();
        } catch (err) {
            console.error('Failed to create group:', err);
        } finally {
            setLoading(false);
        }
    };

    const toggleMember = (user) => {
        if (selectedMembers.find(m => m.userId === user.userId)) {
            setSelectedMembers(selectedMembers.filter(m => m.userId !== user.userId));
        } else {
            setSelectedMembers([...selectedMembers, user]);
        }
    };

    if (!isOpen) return null;

    return createPortal(
        <div className="fixed inset-0 z-[1000] flex items-center justify-center bg-black/60 backdrop-blur-md p-4 animate-in fade-in duration-300">
            <div className="bg-white dark:bg-slate-900 w-full max-w-md rounded-2xl shadow-2xl overflow-hidden animate-in zoom-in-95 duration-300 flex flex-col max-h-[85vh]">
                {/* Header */}
                <div className="px-5 py-3 flex items-center justify-between border-b border-slate-100 dark:border-slate-800">
                    <div>
                        <h2 className="text-sm font-bold text-slate-800 dark:text-white">Create Group</h2>
                        <p className="text-[9px] text-slate-400 font-bold uppercase tracking-wider">New workspace for team</p>
                    </div>
                    <button onClick={onClose} className="p-1.5 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors text-slate-300 hover:text-red-500">
                        <X size={16} />
                    </button>
                </div>

                {/* Content */}
                <div className="px-6 flex-1 overflow-y-auto pt-5 pb-5 space-y-5 scrollbar-thin">
                    {/* Image Preview & Upload Display */}
                    <div className="space-y-1.5">
                        <label className="text-[9px] font-black tracking-[0.15em] text-slate-400 uppercase ml-1">Group Image</label>
                        {imagePreview ? (
                            <div className="flex items-center gap-3 p-2.5 bg-emerald-50/30 dark:bg-emerald-500/5 rounded-xl border border-emerald-100 dark:border-emerald-500/20">
                                <div className="relative shrink-0">
                                    <img src={imagePreview} className="w-11 h-11 rounded-lg object-cover shadow-sm" alt="Preview" />
                                    <button 
                                        onClick={() => { setImage(null); setImagePreview(null); }}
                                        className="absolute -top-1.5 -right-1.5 w-4.5 h-4.5 bg-red-500 text-white rounded-full flex items-center justify-center shadow-lg hover:scale-110 transition-all"
                                    >
                                        <X size={9} strokeWidth={4} />
                                    </button>
                                </div>
                                <div className="flex-1 min-w-0">
                                    <h4 className="text-[11px] font-bold text-slate-800 dark:text-white truncate">{image?.name}</h4>
                                    <p className="text-[9px] text-emerald-600 font-black uppercase tracking-wider">Image Selected</p>
                                </div>
                            </div>
                        ) : (
                            <label className="flex flex-col items-center justify-center gap-1.5 p-4 bg-slate-50/50 dark:bg-white/5 rounded-xl border-2 border-dashed border-slate-100 dark:border-slate-800 hover:border-emerald-400 dark:hover:border-emerald-500 transition-all cursor-pointer group">
                                <input type="file" className="hidden" onChange={(e) => setImage(e.target.files[0])} accept="image/*" />
                                <div className="w-8 h-8 bg-white dark:bg-slate-800 text-slate-300 group-hover:text-emerald-500 rounded-lg flex items-center justify-center shadow-sm transition-all">
                                    <Upload size={16} />
                                </div>
                                <div className="text-center">
                                    <span className="text-[10px] font-bold text-slate-600 dark:text-slate-200">Click to upload</span>
                                    <p className="text-[8px] text-slate-400 mt-0.5 uppercase tracking-wide">PNG, JPG or WEBP</p>
                                </div>
                            </label>
                        )}
                    </div>

                    {/* Group Name */}
                    <div className="space-y-1">
                        <label className="text-[9px] font-black tracking-[0.15em] text-slate-400 uppercase ml-1">Group Name</label>
                        <div className="relative">
                            <input 
                                type="text"
                                placeholder="E.g. Marketing Team"
                                value={name}
                                onChange={(e) => setName(e.target.value.slice(0, 100))}
                                className="w-full px-3.5 py-1.5 bg-slate-50 dark:bg-slate-800 border-2 border-slate-100/50 dark:border-slate-700 rounded-xl outline-none focus:border-emerald-500 text-xs font-semibold transition-all"
                            />
                            <span className="absolute right-3.5 -bottom-4 text-[8px] font-black text-slate-300 uppercase">{name.length}/100</span>
                        </div>
                    </div>

                    {/* Group Description */}
                    <div className="space-y-1">
                        <label className="text-[9px] font-black tracking-[0.15em] text-slate-400 uppercase ml-1">Group Description</label>
                        <div className="relative">
                            <textarea 
                                placeholder="What is this group about?"
                                value={description}
                                onChange={(e) => setDescription(e.target.value.slice(0, 500))}
                                className="w-full px-3.5 py-1.5 bg-slate-50 dark:bg-slate-800 border-2 border-slate-100/50 dark:border-slate-700 rounded-xl outline-none focus:border-emerald-500 text-xs font-semibold min-h-[60px] resize-none transition-all"
                            />
                            <span className="absolute right-3.5 -bottom-4 text-[8px] font-black text-slate-300 uppercase">{description.length}/500</span>
                        </div>
                    </div>

                    {/* Members Selection */}
                    <div className="space-y-3">
                        <label className="text-[11px] font-bold tracking-widest text-slate-500 uppercase ml-1">Add Member [{selectedMembers.length}]</label>
                        
                        <div className="border border-slate-100 dark:border-slate-800 rounded-xl overflow-hidden">
                            <div className="p-2 border-b border-slate-100 dark:border-slate-800">
                                <div className="relative">
                                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={14} />
                                    <input 
                                        type="text"
                                        placeholder="Find Member"
                                        value={searchMember}
                                        onChange={(e) => setSearchMember(e.target.value)}
                                        className="w-full pl-9 pr-4 py-1.5 bg-slate-50 dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-xl outline-none focus:border-emerald-500 text-xs font-semibold"
                                    />
                                </div>
                            </div>

                            <div className="max-h-[180px] overflow-y-auto p-1.5 space-y-1 scrollbar-thin">
                                {availableUsers.filter(u => 
                                    u.firstName?.toLowerCase().includes(searchMember.toLowerCase()) || 
                                    u.lastName?.toLowerCase().includes(searchMember.toLowerCase()) ||
                                    u.designation?.toLowerCase().includes(searchMember.toLowerCase())
                                ).map(user => (
                                    <div 
                                        key={user.userId}
                                        onClick={() => toggleMember(user)}
                                        className={`flex items-center gap-3 p-2 rounded-xl cursor-pointer transition-all ${
                                            selectedMembers.find(m => m.userId === user.userId)
                                            ? 'bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600'
                                            : 'hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300'
                                        }`}
                                    >
                                        <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-[10px] shrink-0 ${
                                            selectedMembers.find(m => m.userId === user.userId) ? 'bg-emerald-500 text-white' : 'bg-slate-200 dark:bg-slate-700'
                                        }`}>
                                            {user.firstName?.charAt(0) || 'U'}
                                        </div>
                                        <div className="flex flex-col min-w-0">
                                            <span className="text-xs font-bold truncate">
                                                {user.firstName} {user.lastName}
                                            </span>
                                            <span className="text-[10px] text-slate-500 font-bold truncate uppercase tracking-widest opacity-70">
                                                {user.designation}
                                            </span>
                                        </div>
                                        <div className={`ml-auto w-4 h-4 rounded-md border-2 flex items-center justify-center shrink-0 ${
                                            selectedMembers.find(m => m.userId === user.userId) ? 'bg-emerald-500 border-emerald-500' : 'border-slate-200 dark:border-slate-700'
                                        }`}>
                                            {selectedMembers.find(m => m.userId === user.userId) && <X size={10} className="text-white rotate-45" />}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>

                {/* Footer */}
                <div className="px-5 py-3 border-t border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900/50">
                    <button 
                        onClick={handleCreate}
                        disabled={loading || !name.trim()}
                        className="w-full py-2 bg-gradient-to-r from-emerald-500 to-emerald-600 disabled:from-slate-300 disabled:to-slate-300 text-white font-bold text-[11px] rounded-lg shadow-lg shadow-emerald-500/10 transition-all active:scale-[0.98] uppercase tracking-[0.15em]"
                    >
                        {loading ? 'Processing...' : 'Create Group'}
                    </button>
                </div>
            </div>
        </div>,
        document.body
    );
};

export default CreateGroupModal;
