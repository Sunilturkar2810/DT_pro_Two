import React, { useState, useRef, useEffect } from 'react';
import { Search, Bell, Sun, Moon, Volume2, User, LogOut, ChevronDown } from 'lucide-react';
import { useTheme } from '../../context/ThemeContext';
import { useNavigate } from 'react-router-dom';
import NotificationDrawer from './NotificationDrawer';
import notificationService from '../../services/notificationService';
import Logo from '../../assets/Logo.jpeg';

const Navbar = ({ hideLogo }) => {
    const { theme, toggleTheme } = useTheme();
    const [showDropdown, setShowDropdown] = useState(false);
    const [showNotifications, setShowNotifications] = useState(false);
    const [unreadCount, setUnreadCount] = useState(0);
    const dropdownRef = useRef(null);
    const navigate = useNavigate();
    const [user, setUser] = useState(null);

    useEffect(() => {
        const fetchUnreadCount = async () => {
            try {
                const response = await notificationService.getNotifications();
                if (response.success) {
                    const count = response.data.filter(n => !n.isRead).length;
                    setUnreadCount(count);
                }
            } catch (error) {
                console.error('Failed to fetch notifications:', error);
            }
        };

        fetchUnreadCount();
        const interval = setInterval(fetchUnreadCount, 30000); // Poll every 30s

        const storedUser = localStorage.getItem('user');
        console.log("stored user", storedUser);
        if (storedUser) {
            try {
                const parsed = JSON.parse(storedUser);
                setUser(parsed.user || parsed);
            } catch (e) {
                console.error('Failed to parse user data');
            }
        }

        const handleClickOutside = (event) => {
            if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
                setShowDropdown(false);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
            clearInterval(interval);
        };
    }, []);

    const handleLogout = () => {
        localStorage.removeItem('user');
        navigate('/login');
    };

    const getInitials = () => {
        if (!user) return '??';
        const first = user.firstName?.charAt(0) || '';
        const last = user.lastName?.charAt(0) || '';
        const initials = (first + last).toUpperCase();
        return initials || 'U';
    };


    return (
        <nav className="h-16 flex items-center justify-between px-2 md:px-6 bg-transparent">
            {/* Logo */}
            {!hideLogo && (
                <div className="flex items-center gap-3">
                    <img src={Logo} alt="Logo" className="h-8 md:h-10 w-auto rounded-lg shadow-sm" />
                </div>
            )}

            {/* Search - Desktop Only */}
            <div className="max-w-md w-full relative group hidden lg:block">
                <div className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-emerald-500 transition-colors">
                    <Search size={18} />
                </div>
                <input
                    type="text"
                    placeholder="Search (CTRL/CMD+K)"
                    className="w-full bg-slate-100 dark:bg-slate-900 border-none rounded-lg py-2 pl-10 pr-4 text-sm focus:ring-2 focus:ring-emerald-500/20 text-slate-700 dark:text-slate-200"
                />
            </div>

            {/* Actions */}
            <div className="flex items-center gap-2 md:gap-4">
                <button className="text-slate-500 hover:text-emerald-500 transition-colors hidden sm:block">
                    <Volume2 size={20} />
                </button>

                <div className="relative">
                    <button
                        onClick={() => setShowNotifications(true)}
                        className="text-slate-500 hover:text-emerald-500 transition-colors p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg relative group"
                    >
                        <Bell size={18} md:size={20} className="group-hover:rotate-12 transition-transform" />
                        {unreadCount > 0 && (
                            <span className="absolute top-1 right-1 w-3.5 h-3.5 bg-red-500 text-white text-[9px] font-black flex items-center justify-center rounded-full border-2 border-[var(--bg-secondary)] animate-in zoom-in duration-300">
                                {unreadCount > 9 ? '9+' : unreadCount}
                            </span>
                        )}
                    </button>
                </div>

                <NotificationDrawer
                    isOpen={showNotifications}
                    onClose={() => setShowNotifications(false)}
                />

                <div className="flex bg-slate-100 dark:bg-slate-900 p-1 rounded-full border border-gray-200 dark:border-slate-800 scale-90 md:scale-100">
                    <button
                        onClick={() => theme === 'dark' && toggleTheme()}
                        className={`p-1 md:p-1.5 rounded-full transition-all ${theme === 'light' ? 'bg-white shadow-sm text-yellow-500' : 'text-slate-500'}`}
                    >
                        <Sun size={12} md:size={14} />
                    </button>
                    <button
                        onClick={() => theme === 'light' && toggleTheme()}
                        className={`p-1 md:p-1.5 rounded-full transition-all ${theme === 'dark' ? 'bg-slate-800 shadow-sm text-sky-400' : 'text-slate-500'}`}
                    >
                        <Moon size={12} md:size={14} />
                    </button>
                </div>

                {/* Profile Dropdown */}
                <div className="relative" ref={dropdownRef}>
                    <button
                        onClick={() => setShowDropdown(!showDropdown)}
                        className="flex items-center gap-2 md:gap-3 pl-2 md:pl-4 border-l border-gray-200 dark:border-slate-800 hover:opacity-80 transition-opacity"
                    >
                        <div className="hidden md:flex flex-col items-end text-right">
                            <span className="text-sm font-semibold text-slate-700 dark:text-slate-200 leading-none">
                                {user ? `${user.firstName} ${user.lastName}` : 'User'}
                            </span>
                            <span className="text-[10px] font-medium text-slate-500 dark:text-slate-400 mt-1 uppercase tracking-wider">
                                {user?.designation || 'Guest'}
                            </span>
                        </div>
                        {user?.profilePhoto ? (
                            <img src={user.profilePhoto} alt="Profile" className="w-8 h-8 md:w-9 md:h-9 rounded-full ring-2 ring-yellow-500/20 object-cover" />
                        ) : (
                            <div className="w-8 h-8 md:w-9 md:h-9 rounded-full bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-500 flex items-center justify-center font-bold text-[12px] md:text-sm ring-2 ring-yellow-500/20">
                                {getInitials()}
                            </div>
                        )}
                        <ChevronDown size={14} className={`text-slate-400 hidden sm:block transition-transform ${showDropdown ? 'rotate-180' : ''}`} />
                    </button>

                    {showDropdown && (
                        <div className="absolute right-0 mt-2 w-48 bg-white dark:bg-slate-900 rounded-xl shadow-xl border border-gray-100 dark:border-slate-800 py-2 animate-in fade-in zoom-in-95 duration-200 z-50">
                            <button
                                onClick={() => { setShowDropdown(false); navigate('/settings/general'); }}
                                className="w-full px-4 py-2 text-sm text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-800 flex items-center gap-2 transition-colors"
                            >
                                <User size={16} />
                                Profile
                            </button>
                            <div className="h-px bg-gray-100 dark:bg-slate-800 my-1" />
                            <button
                                onClick={handleLogout}
                                className="w-full px-4 py-2 text-sm text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 flex items-center gap-2 transition-colors"
                            >
                                <LogOut size={16} />
                                Logout
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </nav>
    );
};

export default Navbar;
