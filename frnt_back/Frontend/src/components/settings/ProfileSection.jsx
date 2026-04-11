import React, { useState, useEffect, useRef } from 'react';
import { 
    User, Mail, Phone, Briefcase, Building2, Calendar, MapPin, 
    Shield, Clock, Loader2, AlertCircle, Save, Edit3, Camera,
    Search, Bell, MoreVertical, CheckCircle2, XCircle, UserCircle,
    Image as ImageIcon, Monitor, FileText, Globe, Heart, Hash,
    Lock, Key, ChevronRight, Laptop, CreditCard, DollarSign
} from 'lucide-react';
import authService from '../../services/auth.service';
import api from '../../services/api';
import toast from 'react-hot-toast';
import PhoneInput from 'react-phone-input-2';
import 'react-phone-input-2/lib/style.css';

const SectionHeader = ({ icon: Icon, title, color }) => (
    <div className="flex items-center gap-4 mb-6">
        <div className={`p-2.5 rounded-2xl ${color} bg-opacity-10 shadow-sm border border-current border-opacity-10`}>
            <Icon size={22} className={color.replace('bg-', 'text-')} />
        </div>
        <h3 className="text-xl font-black text-slate-800 dark:text-white tracking-tight leading-none">{title}</h3>
    </div>
);

const FormInput = ({ label, name, value, type = 'text', readOnly = false, icon: Icon, onChange }) => (
    <div className="flex flex-col gap-2">
        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">{label}</label>
        <div className={`relative group ${readOnly ? 'opacity-70' : ''}`}>
            <input 
                type={type}
                name={name}
                value={value || ''}
                onChange={onChange}
                readOnly={readOnly}
                className={`w-full bg-slate-50 dark:bg-slate-900/50 border-2 border-slate-100 dark:border-slate-800 rounded-2xl px-5 py-3.5 text-sm font-bold text-slate-700 dark:text-slate-200 outline-none transition-all ${!readOnly ? 'focus:border-orange-400 dark:focus:border-orange-500/50 focus:bg-white dark:focus:bg-slate-900 shadow-sm' : 'cursor-not-allowed bg-slate-100/50 dark:bg-slate-800/20'}`}
            />
            {Icon && <Icon size={18} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-orange-400 transition-colors" />}
        </div>
    </div>
);

const InfoBadge = ({ label, value, color }) => (
    <div className="bg-slate-50 dark:bg-slate-900/50 rounded-2xl p-4 border border-slate-100 dark:border-slate-800 flex items-center justify-between">
        <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none">{label}</span>
        <span className={`px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-tighter ${color}`}>
            {value || 'N/A'}
        </span>
    </div>
);

const ProfileSection = () => {
    const [profile, setProfile] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [isSaving, setIsSaving] = useState(false);
    const [isUploading, setIsUploading] = useState(false);
    const [formData, setFormData] = useState({});
    const [showUploadMenu, setShowUploadMenu] = useState(false);
    
    // Credentials Modal States
    const [showPwdModal, setShowPwdModal] = useState(false);
    const [showEmailModal, setShowEmailModal] = useState(false);
    const [pwdData, setPwdData] = useState({ oldPassword: '', newPassword: '', confirmPassword: '' });
    const [emailData, setEmailData] = useState({ oldPassword: '', newEmail: '' });
    
    const fileInputRef = useRef(null);
    const cameraInputRef = useRef(null);

    const storedUser = JSON.parse(localStorage.getItem('user'));
    const userRole = storedUser?.user?.role || storedUser?.role;
    const isAdmin = userRole?.toUpperCase() === 'ADMIN' || userRole?.toUpperCase() === 'SUPERADMIN';

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
        const { name, value, type, checked } = e.target;
        setFormData(prev => ({ 
            ...prev, 
            [name]: type === 'checkbox' ? checked : value 
        }));
    };

    const handleSave = async () => {
        try {
            setIsSaving(true);
            await authService.updateUser(profile.userId, formData);
            setProfile(formData);
            toast.success('Settings updated successfully');
        } catch (err) {
            console.error('Error updating profile:', err);
            toast.error(err.response?.data?.message || 'Failed to update profile');
        } finally {
            setIsSaving(false);
        }
    };

    const handlePasswordChange = async () => {
        if (pwdData.newPassword !== pwdData.confirmPassword) {
            return toast.error("New passwords don't match");
        }
        try {
            setIsSaving(true);
            await authService.updatePassword(profile.userId, pwdData.oldPassword, pwdData.newPassword);
            toast.success('Password updated successfully');
            setShowPwdModal(false);
            setPwdData({ oldPassword: '', newPassword: '', confirmPassword: '' });
        } catch (err) {
            toast.error(err.response?.data?.message || 'Failed to update password');
        } finally {
            setIsSaving(false);
        }
    };

    const handleEmailChange = async () => {
        try {
            setIsSaving(true);
            await authService.updateCredentials(profile.userId, { 
                oldPassword: emailData.oldPassword, 
                newEmail: emailData.newEmail 
            });
            toast.success('Email updated successfully');
            setShowEmailModal(false);
            setEmailData({ oldPassword: '', newEmail: '' });
            // Update local profile view
            setProfile(prev => ({ ...prev, workEmail: emailData.newEmail }));
            setFormData(prev => ({ ...prev, workEmail: emailData.newEmail }));
        } catch (err) {
            toast.error(err.response?.data?.message || 'Failed to update email');
        } finally {
            setIsSaving(false);
        }
    };

    const handleFileUpload = async (e) => {
        const file = e.target.files[0];
        if (!file) return;

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
            toast.error('Failed to upload image');
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
            <div className="h-96 flex flex-col items-center justify-center">
                <Loader2 className="animate-spin text-emerald-500 mb-4" size={40} />
                <p className="text-slate-500 font-medium font-outfit">Loading secure profile data...</p>
            </div>
        );
    }


    return (
        <div className="max-w-7xl mx-auto pb-20">
            {/* Hidden Inputs */}
            <input type="file" ref={fileInputRef} className="hidden" accept="image/*" onChange={handleFileUpload} />
            <input type="file" ref={cameraInputRef} className="hidden" accept="image/*" capture="camera" onChange={handleFileUpload} />

            <div className="grid grid-cols-1 xl:grid-cols-12 gap-8 animate-in fade-in slide-in-from-bottom-6 duration-1000">
                {/* Profile Card Sidebar */}
                <div className="xl:col-span-4 space-y-8">
                    <div className="bg-white dark:bg-slate-800/40 backdrop-blur-xl rounded-[40px] border border-white/20 dark:border-slate-700/30 shadow-2xl shadow-slate-200/50 dark:shadow-none overflow-hidden relative">
                        {/* Status Pin */}
                        <div className="absolute top-6 right-6 z-10">
                            <div className="bg-white/80 dark:bg-slate-900/80 backdrop-blur-md px-3 py-1.5 rounded-full border border-slate-100 dark:border-slate-700 flex items-center gap-2">
                                <div className={`w-2 h-2 rounded-full ${profile.status === 'active' ? 'bg-emerald-500 animate-pulse' : 'bg-slate-400'}`} />
                                <span className="text-[10px] font-black uppercase tracking-widest text-slate-600 dark:text-slate-300">{profile.status}</span>
                            </div>
                        </div>

                        {/* Photo Area */}
                        <div className="relative h-72 bg-gradient-to-br from-slate-100 to-slate-200 dark:from-slate-900 dark:to-slate-800 group overflow-hidden">
                            {isUploading && (
                                <div className="absolute inset-0 z-20 bg-black/40 backdrop-blur-sm flex items-center justify-center">
                                    <Loader2 className="animate-spin text-white" size={32} />
                                </div>
                            )}
                            {profile.profilePhotoUrl ? (
                                <img src={profile.profilePhotoUrl} alt="Avatar" className="w-full h-full object-cover transition-transform duration-1000 group-hover:scale-110" />
                            ) : (
                                <div className="w-full h-full flex items-center justify-center text-slate-300">
                                    <UserCircle size={120} strokeWidth={0.5} />
                                </div>
                            )}
                            <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-end justify-center pb-8">
                                <button 
                                    onClick={() => setShowUploadMenu(true)}
                                    className="bg-white text-slate-900 px-6 py-2.5 rounded-full text-xs font-black uppercase tracking-widest shadow-xl flex items-center gap-2 transform translate-y-4 group-hover:translate-y-0 transition-transform"
                                >
                                    <Camera size={16} /> Update Photo
                                </button>
                            </div>
                        </div>

                        {/* Quick Info */}
                        <div className="p-10 pt-8 text-center border-b border-slate-100 dark:border-slate-800/50">
                            <h2 className="text-3xl font-black text-slate-900 dark:text-white tracking-tight leading-tight">
                                {profile.firstName} {profile.lastName}
                            </h2>
                            <p className="text-emerald-500 font-bold text-sm mt-1">{profile.designation}</p>
                            <p className="text-slate-400 font-medium text-xs mt-0.5">{profile.department}</p>
                        </div>

                        <div className="p-6 grid grid-cols-1 gap-3">
                            <InfoBadge label="Official Role" value={profile.role} color="bg-blue-500/10 text-blue-500" />
                            <InfoBadge label="Employee ID" value={profile.userId.slice(0, 8).toUpperCase()} color="bg-slate-500/10 text-slate-500" />
                            
                            <div className="mt-4 pt-4 border-t border-slate-100 dark:border-slate-800/50 space-y-4">
                                <button 
                                    onClick={() => setShowEmailModal(true)}
                                    className="w-full h-14 flex items-center justify-between px-6 bg-slate-50 dark:bg-slate-900 border-2 border-transparent hover:border-orange-400 rounded-3xl transition-all group"
                                >
                                    <div className="flex items-center gap-4">
                                        <div className="p-2 bg-white dark:bg-slate-800 rounded-xl group-hover:text-orange-400 transition-colors">
                                            <Mail size={18} />
                                        </div>
                                        <div className="text-left">
                                            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none mb-1 text-nowrap overflow-hidden max-w-[150px]">{profile.workEmail}</p>
                                            <p className="text-[10px] font-black text-orange-400 uppercase tracking-tight">Update Email</p>
                                        </div>
                                    </div>
                                    <ChevronRight size={16} className="text-slate-300 group-hover:translate-x-1 transition-transform" />
                                </button>

                                <button 
                                    onClick={() => setShowPwdModal(true)}
                                    className="w-full h-14 flex items-center justify-between px-6 bg-slate-50 dark:bg-slate-900 border-2 border-transparent hover:border-emerald-400 rounded-3xl transition-all group"
                                >
                                    <div className="flex items-center gap-4">
                                        <div className="p-2 bg-white dark:bg-slate-800 rounded-xl group-hover:text-emerald-400 transition-colors">
                                            <Lock size={18} />
                                        </div>
                                        <div className="text-left">
                                            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none mb-1">••••••••</p>
                                            <p className="text-[10px] font-black text-emerald-400 uppercase tracking-tight">Security Check</p>
                                        </div>
                                    </div>
                                    <ChevronRight size={16} className="text-slate-300 group-hover:translate-x-1 transition-transform" />
                                </button>
                            </div>
                        </div>
                    </div>

                    {/* Permissions Card */}
                    <div className="bg-white dark:bg-slate-800/40 backdrop-blur-xl rounded-[40px] border border-white/20 dark:border-slate-700/30 p-8">
                        <SectionHeader icon={Shield} title="System Access" color="bg-emerald-500" />
                        <div className="space-y-6">
                            {[
                                { label: 'Task Management', desc: 'Manage assignments and checklists', name: 'taskAccess', icon: CheckCircle2 },
                                { label: 'Leave & Attendance', desc: 'Request leaves and view logs', name: 'leaveAccess', icon: Calendar }
                            ].map(item => (
                                <div key={item.name} className="flex items-center justify-between group">
                                    <div className="flex items-center gap-4">
                                        <div className={`p-2 rounded-xl bg-slate-100 dark:bg-slate-900 ${formData[item.name] ? 'text-emerald-500' : 'text-slate-300'}`}>
                                            <item.icon size={20} />
                                        </div>
                                        <div>
                                            <p className="text-sm font-bold text-slate-700 dark:text-slate-200">{item.label}</p>
                                            <p className="text-[10px] text-slate-400 font-medium">{item.desc}</p>
                                        </div>
                                    </div>
                                    <div 
                                        onClick={() => !isAdmin ? null : setFormData(p => ({...p, [item.name]: !p[item.name]}))}
                                        className={`w-12 h-6 rounded-full p-1 cursor-pointer transition-all duration-300 flex items-center ${!isAdmin ? 'opacity-50 cursor-not-allowed' : ''} ${formData[item.name] ? 'bg-emerald-500' : 'bg-slate-300 dark:bg-slate-700'}`}
                                    >
                                        <div className={`w-4 h-4 rounded-full bg-white shadow-sm transition-transform duration-300 ${formData[item.name] ? 'translate-x-6' : 'translate-x-0'}`} />
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

                {/* Main Content Area */}
                <div className="xl:col-span-8 flex flex-col gap-8">
                    {/* General Information */}
                    <div className="bg-white dark:bg-slate-800/40 backdrop-blur-xl rounded-[40px] border border-white/20 dark:border-slate-700/30 p-10 shadow-xl">
                        <SectionHeader icon={User} title="General Information" color="bg-orange-400" />
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-6">
                            <FormInput label="First Name" name="firstName" value={formData.firstName} icon={User} onChange={handleInputChange} />
                            <FormInput label="Last Name" name="lastName" value={formData.lastName} icon={User} onChange={handleInputChange} />
                            
                            <div className="flex flex-col gap-2">
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Primary Mobile</label>
                                <PhoneInput
                                    country={'in'}
                                    value={formData.mobileNumber}
                                    onChange={val => setFormData(p => ({...p, mobileNumber: val}))}
                                    inputClass="!w-full !bg-slate-50 dark:!bg-slate-900/50 !border-2 !border-slate-100 dark:!border-slate-800 !rounded-2xl !px-12 !py-6 !text-sm !font-bold !text-slate-700 dark:!text-slate-200 !outline-none focus:!border-orange-400"
                                    containerClass="!w-full"
                                    buttonClass="!bg-transparent !border-0 !rounded-l-2xl"
                                />
                            </div>

                            <div className="flex flex-col gap-2">
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Emergency Mobile</label>
                                <PhoneInput
                                    country={'in'}
                                    value={formData.emergencyMobileNo}
                                    onChange={val => setFormData(p => ({...p, emergencyMobileNo: val}))}
                                    inputClass="!w-full !bg-slate-50 dark:!bg-slate-900/50 !border-2 !border-slate-100 dark:!border-slate-800 !rounded-2xl !px-12 !py-6 !text-sm !font-bold !text-slate-700 dark:!text-slate-200 !outline-none focus:!border-pink-400"
                                    containerClass="!w-full"
                                    buttonClass="!bg-transparent !border-0 !rounded-l-2xl"
                                />
                            </div>
                        </div>
                    </div>

                    {/* Professional Details */}
                    <div className="bg-white dark:bg-slate-800/40 backdrop-blur-xl rounded-[40px] border border-white/20 dark:border-slate-700/30 p-10 shadow-xl">
                        <SectionHeader icon={Briefcase} title="Professional Profile" color="bg-blue-500" />
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-6">
                            <FormInput label="Designation" name="designation" value={formData.designation} icon={Monitor} readOnly={!isAdmin} onChange={handleInputChange} />
                            <FormInput label="Department" name="department" value={formData.department} icon={Building2} readOnly={!isAdmin} onChange={handleInputChange} />
                            <FormInput label="Reporting Manager" name="manager" value={formData.manager} icon={UserCircle} readOnly={true} onChange={handleInputChange} />
                            <FormInput label="Joining Date" name="joiningDate" value={formData.joiningDate} type="date" icon={Calendar} readOnly={!isAdmin} onChange={handleInputChange} />
                            <div className="md:col-span-2">
                                <FormInput label="Contract / Agreement Details" name="contract" value={formData.contract} icon={FileText} onChange={handleInputChange} />
                            </div>
                        </div>
                    </div>

                    {/* Personal & Social */}
                    <div className="bg-white dark:bg-slate-800/40 backdrop-blur-xl rounded-[40px] border border-white/20 dark:border-slate-700/30 p-10 shadow-xl">
                        <SectionHeader icon={Heart} title="Personal Details" color="bg-pink-500" />
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-6">
                            <FormInput label="Personal Email" name="personalEmail" value={formData.personalEmail} icon={Mail} onChange={handleInputChange} />
                            <FormInput label="Date of Birth" name="dateOfBirth" value={formData.dateOfBirth} type="date" icon={Calendar} onChange={handleInputChange} />
                            
                            <div className="flex flex-col gap-2">
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Gender</label>
                                <select 
                                    name="gender" 
                                    value={formData.gender || ''} 
                                    onChange={handleInputChange}
                                    className="w-full bg-slate-50 dark:bg-slate-900/50 border-2 border-slate-100 dark:border-slate-800 rounded-2xl px-5 py-3.5 text-sm font-bold text-slate-700 dark:text-slate-200 outline-none focus:border-pink-400 appearance-none shadow-sm cursor-pointer"
                                >
                                    <option value="">Select Gender</option>
                                    <option value="Male">Male</option>
                                    <option value="Female">Female</option>
                                    <option value="Other">Other</option>
                                </select>
                            </div>

                            <div className="flex flex-col gap-2">
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">Marital Status</label>
                                <select 
                                    name="maritalStatus" 
                                    value={formData.maritalStatus || ''} 
                                    onChange={handleInputChange}
                                    className="w-full bg-slate-50 dark:bg-slate-900/50 border-2 border-slate-100 dark:border-slate-800 rounded-2xl px-5 py-3.5 text-sm font-bold text-slate-700 dark:text-slate-200 outline-none focus:border-pink-400 appearance-none shadow-sm cursor-pointer"
                                >
                                    <option value="">Select Status</option>
                                    <option value="Single">Single</option>
                                    <option value="Married">Married</option>
                                    <option value="Divorced">Divorced</option>
                                </select>
                            </div>

                            <FormInput label="Anniversary Date" name="anniversaryDate" value={formData.anniversaryDate} type="date" icon={Heart} onChange={handleInputChange} />
                            <FormInput label="Nationality" name="nationality" value={formData.nationality} icon={Globe} onChange={handleInputChange} />
                        </div>
                    </div>

                    {/* Address Information */}
                    <div className="bg-white dark:bg-slate-800/40 backdrop-blur-xl rounded-[40px] border border-white/20 dark:border-slate-700/30 p-10 shadow-xl">
                        <SectionHeader icon={MapPin} title="Residential Address" color="bg-emerald-500" />
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-x-6 gap-y-6">
                            <div className="md:col-span-3">
                                <FormInput label="Full Address" name="address" value={formData.address} icon={MapPin} onChange={handleInputChange} />
                            </div>
                            <FormInput label="City" name="city" value={formData.city} onChange={handleInputChange} />
                            <FormInput label="State" name="state" value={formData.state} onChange={handleInputChange} />
                            <FormInput label="Theme Preference" name="theme" value={formData.theme} onChange={handleInputChange} />
                        </div>
                    </div>

                    {/* Financial Information - Restricted to Admin or Self if needed */}
                    {isAdmin && (
                        <div className="bg-white dark:bg-slate-800/40 backdrop-blur-xl rounded-[40px] border border-white/20 dark:border-slate-700/30 p-10 shadow-xl border-dashed">
                            <SectionHeader icon={DollarSign} title="Compensation" color="bg-amber-500" />
                            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                                <FormInput label="Base Salary" name="salary" value={formData.salary} type="number" icon={CreditCard} onChange={handleInputChange} />
                                <FormInput label="Last Increment" name="lastIncrement" value={formData.lastIncrement} type="number" icon={Hash} onChange={handleInputChange} />
                                <FormInput label="Current Package" name="currentSalary" value={formData.currentSalary} type="number" icon={DollarSign} onChange={handleInputChange} />
                            </div>
                        </div>
                    )}

                    {/* Actions Pin Bar */}
                    <div className="sticky bottom-8 z-30">
                        <div className="bg-slate-900 dark:bg-white p-2 rounded-3xl shadow-2xl flex items-center justify-between gap-4 max-w-2xl mx-auto border border-white/10">
                            <div className="flex items-center gap-4 px-6 overflow-hidden">
                                <div className="hidden sm:flex flex-col">
                                    <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest text-nowrap">Platform Security</span>
                                    <span className="text-[10px] font-bold text-white dark:text-slate-900 truncate">All updates are logged and encrypted</span>
                                </div>
                            </div>
                            <button 
                                onClick={handleSave}
                                disabled={isSaving}
                                className="bg-emerald-500 text-white dark:text-white px-10 py-4 rounded-2xl text-xs font-black uppercase tracking-[0.2em] shadow-xl shadow-emerald-500/30 hover:shadow-emerald-500/50 hover:scale-[1.02] active:scale-[0.98] transition-all flex items-center gap-3 disabled:opacity-50"
                            >
                                {isSaving ? <Loader2 className="animate-spin" size={18} /> : <Save size={18} />}
                                {isSaving ? 'Synchronizing...' : 'Update Records'}
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            {/* Change Password Modal */}
            {showPwdModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-md animate-in fade-in duration-300">
                    <div className="bg-white dark:bg-slate-800 w-full max-w-md rounded-[40px] p-10 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-8">
                        <div className="text-center">
                            <div className="w-16 h-16 bg-emerald-500/10 rounded-3xl flex items-center justify-center mx-auto mb-4 text-emerald-500">
                                <Shield size={32} />
                            </div>
                            <h2 className="text-2xl font-black text-slate-900 dark:text-white">Security Verification</h2>
                            <p className="text-sm text-slate-400 font-medium">Please verify your current identity to update password</p>
                        </div>

                        <div className="space-y-4">
                            <FormInput 
                                label="Current Password" 
                                type="password" 
                                value={pwdData.oldPassword} 
                                icon={Key}
                                onChange={(e) => setPwdData(p => ({...p, oldPassword: e.target.value}))}
                            />
                            <div className="h-px bg-slate-100 dark:bg-slate-700 my-2" />
                            <FormInput 
                                label="New Password" 
                                type="password" 
                                value={pwdData.newPassword} 
                                icon={Lock}
                                onChange={(e) => setPwdData(p => ({...p, newPassword: e.target.value}))}
                            />
                            <FormInput 
                                label="Confirm New Password" 
                                type="password" 
                                value={pwdData.confirmPassword} 
                                icon={CheckCircle2}
                                onChange={(e) => setPwdData(p => ({...p, confirmPassword: e.target.value}))}
                            />
                        </div>

                        <div className="flex gap-3">
                            <button onClick={() => setShowPwdModal(false)} className="flex-1 py-4 bg-slate-100 dark:bg-slate-700/30 text-slate-600 dark:text-slate-300 font-black rounded-2xl text-[10px] uppercase tracking-widest transition-all">Cancel</button>
                            <button onClick={handlePasswordChange} className="flex-1 py-4 bg-emerald-500 text-white font-black rounded-2xl text-[10px] uppercase tracking-widest shadow-xl shadow-emerald-400/20 active:scale-95 transition-all">Apply Change</button>
                        </div>
                    </div>
                </div>
            )}

            {/* Change Email Modal */}
            {showEmailModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-md animate-in fade-in duration-300">
                    <div className="bg-white dark:bg-slate-800 w-full max-w-md rounded-[40px] p-10 shadow-2xl border border-slate-200 dark:border-slate-700 space-y-8">
                        <div className="text-center">
                            <div className="w-16 h-16 bg-orange-500/10 rounded-3xl flex items-center justify-center mx-auto mb-4 text-orange-500">
                                <Mail size={32} />
                            </div>
                            <h2 className="text-2xl font-black text-slate-900 dark:text-white">Credentials Update</h2>
                            <p className="text-sm text-slate-400 font-medium">Verify your password to change official email</p>
                        </div>

                        <div className="space-y-4">
                            <FormInput 
                                label="Verify Password" 
                                type="password" 
                                value={emailData.oldPassword} 
                                icon={Lock}
                                onChange={(e) => setEmailData(p => ({...p, oldPassword: e.target.value}))}
                            />
                            <FormInput 
                                label="New Official Email" 
                                type="email" 
                                value={emailData.newEmail} 
                                icon={Mail}
                                onChange={(e) => setEmailData(p => ({...p, newEmail: e.target.value}))}
                            />
                        </div>

                        <div className="flex gap-3">
                            <button onClick={() => setShowEmailModal(false)} className="flex-1 py-4 bg-slate-100 dark:bg-slate-700/30 text-slate-600 dark:text-slate-300 font-black rounded-2xl text-[10px] uppercase tracking-widest transition-all">Cancel</button>
                            <button onClick={handleEmailChange} className="flex-1 py-4 bg-orange-400 text-white font-black rounded-2xl text-[10px] uppercase tracking-widest shadow-xl shadow-orange-400/20 active:scale-95 transition-all text-nowrap">Verify & Update</button>
                        </div>
                    </div>
                </div>
            )}

            {/* Upload Menu Modal */}
            {showUploadMenu && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm animate-in fade-in duration-300" onClick={() => setShowUploadMenu(false)}>
                    <div className="bg-white dark:bg-slate-800 p-2 rounded-3xl shadow-2xl border border-slate-200 dark:border-slate-700 w-full max-w-xs space-y-1 animate-in zoom-in-95 duration-200" onClick={e => e.stopPropagation()}>
                        <button onClick={triggerCamera} className="w-full h-14 flex items-center gap-4 px-4 hover:bg-slate-50 dark:hover:bg-slate-700/50 text-slate-600 dark:text-slate-300 transition-colors rounded-2xl group">
                            <div className="w-10 h-10 rounded-xl bg-orange-50 dark:bg-orange-500/10 flex items-center justify-center group-hover:bg-orange-500 group-hover:text-white transition-all">
                                <Camera size={18} />
                            </div>
                            <span className="text-xs font-black uppercase tracking-[0.2em]">Capture Photo</span>
                        </button>
                        <button onClick={triggerBrowse} className="w-full h-14 flex items-center gap-4 px-4 hover:bg-slate-50 dark:hover:bg-slate-700/50 text-slate-600 dark:text-slate-300 transition-colors rounded-2xl group">
                            <div className="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-500/10 flex items-center justify-center group-hover:bg-emerald-500 group-hover:text-white transition-all">
                                <ImageIcon size={18} />
                            </div>
                            <span className="text-xs font-black uppercase tracking-[0.2em]">Upload Gallery</span>
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
};

export default ProfileSection;
