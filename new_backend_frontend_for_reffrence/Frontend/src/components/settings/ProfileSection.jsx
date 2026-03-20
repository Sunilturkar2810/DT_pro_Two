import React, { useState, useEffect, useRef } from 'react';
import { 
    User, Mail, Phone, Briefcase, Building2, Calendar, MapPin, 
    Shield, Clock, Loader2, AlertCircle, Save, Edit3, Camera,
    Search, Bell, MoreVertical, CheckCircle2, XCircle, UserCircle,
    Image as ImageIcon, Monitor
} from 'lucide-react';
import authService from '../../services/auth.service';
import api from '../../services/api';
import toast from 'react-hot-toast';

const ProfileSection = () => {
    const [profile, setProfile] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [isSaving, setIsSaving] = useState(false);
    const [isUploading, setIsUploading] = useState(false);
    const [formData, setFormData] = useState({});
    const [showUploadMenu, setShowUploadMenu] = useState(false);
    
    const fileInputRef = useRef(null);
    const cameraInputRef = useRef(null);

    useEffect(() => {
        const fetchProfile = async () => {
            try {
                const data = await authService.getMe();
                setProfile(data);
                setFormData(data);
            } catch (err) {
                console.error('Error fetching profile:', err);
                setError('Failed to load profile information');
            } finally {
                setLoading(false);
            }
        };

        fetchProfile();
    }, []);

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSave = async () => {
        try {
            setIsSaving(true);
            await authService.updateUser(profile.userId, formData);
            setProfile(formData);
            toast.success('Profile updated successfully');
        } catch (err) {
            console.error('Error updating profile:', err);
            toast.error('Failed to update profile');
        } finally {
            setIsSaving(false);
        }
    };

    const handleFileUpload = async (e) => {
        const file = e.target.files[0];
        if (!file) return;

        // Check file size (10MB)
        if (file.size > 10 * 1024 * 1024) {
            toast.error('File is too large (max 10MB)');
            return;
        }

        const formDataUpload = new FormData();
        formDataUpload.append('file', file);

        try {
            setIsUploading(true);
            setShowUploadMenu(false);
            const response = await authService.uploadProfileImage(formDataUpload);

            const newUrl = response.url;
            setProfile(prev => ({ ...prev, profilePhotoUrl: newUrl }));
            setFormData(prev => ({ ...prev, profilePhotoUrl: newUrl }));
            toast.success('Profile photo updated');
        } catch (err) {
            console.error('Upload error:', err);
            toast.error(err.response?.data?.message || 'Failed to upload image');
        } finally {
            setIsUploading(false);
        }
    };

    const triggerBrowse = () => {
        fileInputRef.current?.click();
    };

    const triggerCamera = () => {
        cameraInputRef.current?.click();
    };

    if (loading) {
        return (
            <div className="h-96 flex flex-col items-center justify-center bg-white dark:bg-slate-800/40 rounded-3xl border border-slate-100 dark:border-slate-800 border-dashed">
                <Loader2 className="animate-spin text-emerald-500 mb-4" size={40} />
                <p className="text-slate-500 font-medium">Fetching your profile details...</p>
            </div>
        );
    }

    if (error) {
        return (
            <div className="h-96 flex flex-col items-center justify-center bg-red-50/50 dark:bg-red-500/5 rounded-3xl border border-red-100 dark:border-red-900/30">
                <div className="p-4 bg-red-100 dark:bg-red-900/30 rounded-full mb-4">
                    <AlertCircle className="text-red-500" size={32} />
                </div>
                <p className="font-bold text-red-600 dark:text-red-400">{error}</p>
                <button
                    onClick={() => window.location.reload()}
                    className="mt-4 px-6 py-2 bg-red-500 text-white rounded-xl font-bold transition-transform active:scale-95"
                >
                    Try Again
                </button>
            </div>
        );
    }

    return (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 animate-in fade-in slide-in-from-bottom-4 duration-1000">
            {/* Hidden Inputs */}
            <input 
                type="file" 
                ref={fileInputRef} 
                className="hidden" 
                accept="image/*" 
                onChange={handleFileUpload} 
            />
            <input 
                type="file" 
                ref={cameraInputRef} 
                className="hidden" 
                accept="image/*" 
                capture="camera" 
                onChange={handleFileUpload} 
            />

            {/* Left Card: Main Profile */}
            <div className="lg:col-span-5 h-full">
                <div className="bg-white dark:bg-slate-800/50 rounded-[40px] shadow-2xl shadow-slate-200/50 dark:shadow-none border border-slate-100 dark:border-slate-700/50 overflow-hidden flex flex-col h-full">
                    {/* Header Image Area */}
                    <div className="relative h-64 w-full bg-slate-100 dark:bg-slate-900 group">
                        {isUploading && (
                            <div className="absolute inset-0 z-10 bg-black/40 backdrop-blur-sm flex items-center justify-center">
                                <div className="flex flex-col items-center">
                                    <Loader2 className="animate-spin text-white mb-2" size={32} />
                                    <span className="text-white text-xs font-bold uppercase tracking-widest">Uploading...</span>
                                </div>
                            </div>
                        )}
                        {profile.profilePhotoUrl ? (
                            <img 
                                src={profile.profilePhotoUrl} 
                                alt="Profile" 
                                className="w-full h-full object-cover grayscale transition-all duration-700 group-hover:grayscale-0"
                            />
                        ) : (
                            <div className="w-full h-full flex items-center justify-center text-slate-300">
                                <User size={80} strokeWidth={1} />
                            </div>
                        )}
                        
                        {/* Camera Action Button */}
                        <div className="absolute bottom-4 right-4 z-20">
                            <button 
                                onClick={() => setShowUploadMenu(!showUploadMenu)}
                                className="p-3 bg-white/90 dark:bg-slate-800/90 backdrop-blur-md rounded-2xl shadow-xl hover:scale-110 transition-all text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:border-orange-400"
                            >
                                <Camera size={20} />
                            </button>

                            {/* Selection Menu Overlay */}
                            {showUploadMenu && (
                                <>
                                    <div className="fixed inset-0 z-30" onClick={() => setShowUploadMenu(false)} />
                                    <div className="absolute bottom-16 right-0 w-48 bg-white dark:bg-slate-800 rounded-3xl shadow-2xl border border-slate-100 dark:border-slate-700 overflow-hidden z-40 animate-in zoom-in-95 duration-200 origin-bottom-right">
                                        <div className="p-2 space-y-1">
                                            <button 
                                                onClick={triggerCamera}
                                                className="w-full h-12 flex items-center gap-3 px-4 hover:bg-slate-50 dark:hover:bg-slate-700/50 text-slate-600 dark:text-slate-300 transition-colors rounded-2xl group"
                                            >
                                                <div className="w-8 h-8 rounded-xl bg-orange-50 dark:bg-orange-500/10 flex items-center justify-center group-hover:bg-orange-500 group-hover:text-white transition-all">
                                                    <Camera size={16} />
                                                </div>
                                                <span className="text-xs font-black uppercase tracking-wider">Take Photo</span>
                                            </button>
                                            <button 
                                                onClick={triggerBrowse}
                                                className="w-full h-12 flex items-center gap-3 px-4 hover:bg-slate-50 dark:hover:bg-slate-700/50 text-slate-600 dark:text-slate-300 transition-colors rounded-2xl group"
                                            >
                                                <div className="w-8 h-8 rounded-xl bg-emerald-50 dark:bg-emerald-500/10 flex items-center justify-center group-hover:bg-emerald-500 group-hover:text-white transition-all">
                                                    <ImageIcon size={16} />
                                                </div>
                                                <span className="text-xs font-black uppercase tracking-wider">Browse Files</span>
                                            </button>
                                        </div>
                                    </div>
                                </>
                            )}
                        </div>
                    </div>

                    <div className="p-10 flex-1 flex flex-col">
                        <div className="flex justify-between items-start mb-8">
                            <div>
                                <h2 className="text-3xl font-black text-slate-900 dark:text-white tracking-tight">My profile</h2>
                                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.2em] mt-1.5 flex items-center gap-2">
                                    Last Update: {new Date(profile.updatedAt).toLocaleDateString()}
                                </p>
                            </div>
                            <div className="text-right">
                                <p className="text-[10px] font-bold text-slate-400">STATUS</p>
                                <div className={`flex items-center gap-1.5 font-black text-xs mt-1 ${profile.status === 'active' ? 'text-emerald-500' : 'text-slate-400'}`}>
                                    <div className={`w-2 h-2 rounded-full ${profile.status === 'active' ? 'bg-emerald-500 animate-pulse' : 'bg-slate-400'}`} />
                                    {profile.status?.toUpperCase() || 'ACTIVE'}
                                </div>
                            </div>
                        </div>

                        <div className="space-y-6 flex-1">
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="text-[10px] font-black text-slate-400 uppercase tracking-wider mb-2 block">First Name</label>
                                    <input 
                                        type="text"
                                        name="firstName"
                                        value={formData.firstName || ''}
                                        onChange={handleInputChange}
                                        className="w-full bg-slate-50 dark:bg-slate-900/50 border-b-2 border-slate-200 dark:border-slate-700 focus:border-orange-400 dark:focus:border-orange-500 px-0 py-2.5 text-sm font-bold text-slate-800 dark:text-slate-100 transition-all outline-none"
                                    />
                                </div>
                                <div>
                                    <label className="text-[10px] font-black text-slate-400 uppercase tracking-wider mb-2 block">Last Name</label>
                                    <input 
                                        type="text"
                                        name="lastName"
                                        value={formData.lastName || ''}
                                        onChange={handleInputChange}
                                        className="w-full bg-slate-50 dark:bg-slate-900/50 border-b-2 border-slate-200 dark:border-slate-700 focus:border-orange-400 dark:focus:border-orange-500 px-0 py-2.5 text-sm font-bold text-slate-800 dark:text-slate-100 transition-all outline-none"
                                    />
                                </div>
                            </div>

                            <div>
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-wider mb-2 block">Work Email</label>
                                <div className="flex items-center gap-3 group">
                                    <input 
                                        type="email"
                                        name="workEmail"
                                        value={formData.workEmail || ''}
                                        onChange={handleInputChange}
                                        className="flex-1 bg-slate-50 dark:bg-slate-900/50 border-b-2 border-slate-200 dark:border-slate-700 focus:border-orange-400 dark:focus:border-orange-500 px-0 py-2.5 text-sm font-bold text-slate-800 dark:text-slate-100 transition-all outline-none"
                                    />
                                    <Mail size={18} className="text-slate-300 group-focus-within:text-orange-400 transition-colors" />
                                </div>
                            </div>

                            <div>
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-wider mb-2 block">Mobile Number</label>
                                <div className="flex items-center gap-3 group">
                                    <input 
                                        type="text"
                                        name="mobileNumber"
                                        value={formData.mobileNumber || ''}
                                        onChange={handleInputChange}
                                        className="flex-1 bg-slate-50 dark:bg-slate-900/50 border-b-2 border-slate-200 dark:border-slate-700 focus:border-orange-400 dark:focus:border-orange-500 px-0 py-2.5 text-sm font-bold text-slate-800 dark:text-slate-100 transition-all outline-none"
                                    />
                                    <Phone size={18} className="text-slate-300 group-focus-within:text-orange-400 transition-colors" />
                                </div>
                            </div>

                            <div className="flex items-center justify-between pt-4">
                                <div className="flex flex-col">
                                    <span className="text-sm font-bold text-orange-400">Task Access activation</span>
                                    <span className="text-[10px] font-medium text-slate-400">Allow user to manage and see assigned tasks</span>
                                </div>
                                <div className={`w-12 h-6 rounded-full p-1 cursor-pointer transition-all duration-300 flex items-center ${formData.taskAccess ? 'bg-emerald-500' : 'bg-slate-300 dark:bg-slate-700'}`} onClick={() => setFormData(p => ({...p, taskAccess: !p.taskAccess}))}>
                                    <div className={`w-4 h-4 rounded-full bg-white shadow-sm transition-transform duration-300 ${formData.taskAccess ? 'translate-x-6' : 'translate-x-0'}`} />
                                </div>
                            </div>
                        </div>

                        <div className="pt-10">
                            <button 
                                onClick={handleSave}
                                disabled={isSaving || isUploading}
                                className="w-full bg-gradient-to-r from-orange-400 to-pink-500 hover:from-orange-500 hover:to-pink-600 text-white font-black py-4 rounded-2xl shadow-xl shadow-orange-500/30 hover:shadow-orange-500/40 transition-all active:scale-[0.98] disabled:opacity-50 flex items-center justify-center gap-3 uppercase tracking-widest text-xs"
                            >
                                {isSaving ? <Loader2 className="animate-spin" size={20} /> : <Save size={20} />}
                                {isSaving ? 'Processing...' : 'Save Profile'}
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            {/* Right Cards */}
            <div className="lg:col-span-7 flex flex-col gap-8">
                {/* Professional Info Card */}
                <div className="bg-white dark:bg-slate-800/50 rounded-[40px] shadow-xl border border-slate-100 dark:border-slate-700/50 overflow-hidden">
                    <div className="px-10 py-8 border-b border-slate-100 dark:border-slate-700/50 flex items-center justify-between">
                        <h3 className="text-xl font-black text-slate-900 dark:text-white flex items-center gap-3 tracking-tight">
                            <Briefcase className="text-emerald-500" size={24} />
                            Career & Role
                        </h3>
                        <div className="p-2 bg-slate-50 dark:bg-slate-900 rounded-xl">
                            <Search size={18} className="text-slate-400" />
                        </div>
                    </div>
                    <div className="p-10 grid grid-cols-1 md:grid-cols-2 gap-8">
                        <div>
                            <p className="text-[10px] font-black text-slate-400 uppercase tracking-wider mb-2">Designation</p>
                            <p className="text-base font-bold text-slate-800 dark:text-slate-100">{profile.designation}</p>
                        </div>
                        <div>
                            <p className="text-[10px] font-black text-slate-400 uppercase tracking-wider mb-2">Department</p>
                            <p className="text-base font-bold text-slate-800 dark:text-slate-100">{profile.department}</p>
                        </div>
                        <div>
                            <p className="text-[10px] font-black text-slate-400 uppercase tracking-wider mb-2">Official Role</p>
                            <span className="inline-flex items-center px-3 py-1 bg-blue-50 dark:bg-blue-500/10 text-blue-500 rounded-full text-xs font-black uppercase tracking-tighter">
                                {profile.role}
                            </span>
                        </div>
                        <div>
                            <p className="text-[10px] font-black text-slate-400 uppercase tracking-wider mb-2">Reporting To</p>
                            <p className="text-base font-bold text-slate-800 dark:text-slate-100 flex items-center gap-2">
                                <UserCircle size={18} className="text-slate-400" />
                                {profile.manager || 'No Manager Assigned'}
                            </p>
                        </div>
                        <div className="md:col-span-2 pt-4 flex gap-4">
                            <div className="flex-1 bg-slate-50 dark:bg-slate-900/80 p-5 rounded-3xl border border-slate-100 dark:border-slate-700/50">
                                <p className="text-[10px] font-black text-slate-400 uppercase tracking-wider mb-2">Joining Date</p>
                                <p className="text-lg font-black text-slate-800 dark:text-white flex items-center gap-2">
                                    <Clock size={20} className="text-emerald-500" />
                                    {new Date(profile.joiningDate).toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' })}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Personal & Privacy Card */}
                <div className="bg-white dark:bg-slate-800/50 rounded-[40px] shadow-xl border border-slate-100 dark:border-slate-700/50 overflow-hidden">
                    <div className="px-10 py-8 border-b border-slate-100 dark:border-slate-700/50 flex items-center justify-between font-bold">
                        <h3 className="text-xl font-black text-slate-900 dark:text-white flex items-center gap-3 tracking-tight">
                            <Clock className="text-pink-500" size={24} />
                            Personal Info
                        </h3>
                        <button className="px-4 py-2 bg-slate-100 dark:bg-slate-900 rounded-xl text-xs font-black text-slate-600 dark:text-slate-400 uppercase tracking-widest hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors">
                            Filter by
                        </button>
                    </div>
                    <div className="p-10 space-y-8">
                        <div className="flex items-center justify-between group">
                            <div className="flex items-center gap-4">
                                <div className="w-3 h-3 rounded-full bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.5)]" />
                                <div>
                                    <p className="text-sm font-bold text-slate-700 dark:text-slate-200">Personal Email</p>
                                    <p className="text-xs text-slate-400">{profile.personalEmail || 'Not Provided'}</p>
                                </div>
                            </div>
                            <span className="px-4 py-2 bg-emerald-400 text-white rounded-2xl text-[10px] font-black uppercase tracking-wider shadow-lg shadow-emerald-400/20">Verified</span>
                        </div>

                        <div className="flex items-center justify-between group">
                            <div className="flex items-center gap-4">
                                <div className="w-3 h-3 rounded-full bg-pink-500 shadow-[0_0_10px_rgba(236,72,153,0.5)]" />
                                <div>
                                    <p className="text-sm font-bold text-slate-700 dark:text-slate-200">Birthday & Gender</p>
                                    <p className="text-xs text-slate-400">
                                        {profile.dateOfBirth ? new Date(profile.dateOfBirth).toLocaleDateString() : 'Unknown'} • {profile.gender}
                                    </p>
                                </div>
                            </div>
                            <span className="px-4 py-2 bg-pink-500 text-white rounded-2xl text-[10px] font-black uppercase tracking-wider shadow-lg shadow-pink-500/20">Private</span>
                        </div>

                        <div className="flex items-center justify-between group">
                            <div className="flex items-center gap-4">
                                <div className="w-3 h-3 rounded-full bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.5)]" />
                                <div>
                                    <p className="text-sm font-bold text-slate-700 dark:text-slate-200">Current Location</p>
                                    <p className="text-xs text-slate-400 truncate max-w-[200px]">
                                        {profile.city}, {profile.state}, {profile.nationality}
                                    </p>
                                </div>
                            </div>
                            <span className="px-4 py-2 bg-emerald-400 text-white rounded-2xl text-[10px] font-black uppercase tracking-wider shadow-lg shadow-emerald-400/20">Public</span>
                        </div>

                        <div className="flex items-center justify-between group">
                            <div className="flex items-center gap-4">
                                <div className="w-3 h-3 rounded-full bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.5)]" />
                                <div>
                                    <p className="text-sm font-bold text-slate-700 dark:text-slate-200">Marital Status</p>
                                    <p className="text-xs text-slate-400">{profile.maritalStatus}</p>
                                </div>
                            </div>
                            <span className="px-4 py-2 bg-emerald-400 text-white rounded-2xl text-[10px] font-black uppercase tracking-wider shadow-lg shadow-emerald-400/20">Active</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ProfileSection;
