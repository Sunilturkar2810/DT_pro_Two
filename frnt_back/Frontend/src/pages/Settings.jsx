import React, { useState, useEffect } from 'react';
import { Settings as SettingsIcon, UserCircle, Users, Bell, Shield, Database, ChevronRight, Folder, Tag } from 'lucide-react';
import { useLocation, useParams, useNavigate } from 'react-router-dom';
import UserRegistrationForm from '../components/settings/UserRegistrationForm';
import ProfileSection from '../components/settings/ProfileSection';
import RolesPermissions from '../components/settings/RolesPermissions';
import NotificationSettings from '../components/settings/NotificationSettings';
import CategorySettings from './CategorySettings';
import TagSettings from './TagSettings';

const Settings = () => {
    const location = useLocation();
    const { tab } = useParams();
    const navigate = useNavigate();
    const storedUser = JSON.parse(localStorage.getItem('user'));
    const userRole = storedUser?.user?.role || storedUser?.role;

    const allTabs = [
        { id: 'general', icon: SettingsIcon, label: 'General', description: 'Update profile and workspace preferences' },
        { id: 'roles', icon: Users, label: 'Roles and Permissions', description: 'Manage user access and feature permissions', restricted: true },
        { id: 'notifications', icon: Bell, label: 'Notifications', description: 'Configure alert preferences' },
        { id: 'security', icon: Shield, label: 'Security', description: 'Password and access controls' },
        { id: 'categories', icon: Folder, label: 'Categories', description: 'Manage your task categories' },
        { id: 'tags', icon: Tag, label: 'Tags', description: 'Manage task tags and labels' }
    ];

    const isAdmin = userRole?.toUpperCase() === 'ADMIN' || userRole?.toUpperCase() === 'SUPERADMIN';
    const tabs = allTabs.filter(tab => !tab.restricted || isAdmin);

    const [activeTab, setActiveTab] = useState(() => {
        if (tab) return tab;
        if (location.state?.activeTab) return location.state.activeTab;
        return 'general';
    });

    useEffect(() => {
        if (tab && tab !== activeTab) {
            setActiveTab(tab);
        }
    }, [tab]);

    const handleTabClick = (tabId) => {
        setActiveTab(tabId);
        navigate(`/settings/${tabId}`);
    };

    return (
        <div className="flex flex-col gap-8 animate-in fade-in duration-700 pb-12">
            {/* Page Header */}
            <div>
                <h1 className="text-3xl font-extrabold text-slate-900 dark:text-white flex items-center gap-3 tracking-tight">
                    <div className="p-2 bg-emerald-500/10 rounded-xl">
                        <SettingsIcon className="text-emerald-500" size={32} />
                    </div>
                    {allTabs.find(t => t.id === activeTab)?.label || 'Settings'}
                </h1>
                <p className="mt-2 text-slate-500 font-medium">{allTabs.find(t => t.id === activeTab)?.description || 'Manage your workspace preferences'}</p>
            </div>

            <div className="w-full">
                {activeTab === 'general' ? (
                    <ProfileSection />
                ) : activeTab === 'roles' ? (
                    <RolesPermissions />
                ) : activeTab === 'notifications' ? (
                    <NotificationSettings />
                ) : activeTab === 'categories' ? (
                    <CategorySettings hideHeader={true} />
                ) : activeTab === 'tags' ? (
                    <TagSettings hideHeader={true} />
                ) : (
                    <div className="h-64 flex flex-col items-center justify-center bg-(--bg-secondary) rounded-2xl border border-(--border-color) border-dashed">
                        <div className="p-4 bg-slate-100 dark:bg-slate-800 rounded-full mb-4">
                            {React.createElement(allTabs.find(t => t.id === activeTab)?.icon || Database, {
                                className: "text-slate-300",
                                size: 32
                            })}
                        </div>
                        <p className="font-bold text-slate-400 italic">This section is coming soon...</p>
                        <p className="text-sm text-slate-500 mt-1">We're working hard to bring you more configuration options.</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Settings;
