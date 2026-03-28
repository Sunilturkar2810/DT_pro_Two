import React, { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import Navbar from './Navbar';
import PrimarySidebar from './PrimarySidebar';
import SecondarySidebar from './SecondarySidebar';
import { LayoutGrid, Menu, X } from 'lucide-react';
import Logo from '../../assets/Logo.jpeg';

const DashboardLayout = ({ children }) => {
    const location = useLocation();
    const [activeModule, setActiveModule] = useState('tasks');
    const [isSecondaryCollapsed, setIsSecondaryCollapsed] = useState(true);
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

    useEffect(() => {
        const path = location.pathname;
        if (path.startsWith('/groups')) setActiveModule('groups');
        else if (path.startsWith('/my-team')) setActiveModule('team');
        else if (path.startsWith('/settings') || path.startsWith('/holidays')) setActiveModule('settings');
        else setActiveModule('tasks');

        // Close mobile menu on path change
        setIsMobileMenuOpen(false);
    }, [location.pathname]);

    const handlePrimaryHover = (moduleId) => {
        if (window.innerWidth < 1024) return; // Disable hover effects on mobile/tablet
        if (moduleId === 'team') return;
        setActiveModule(moduleId);
        setIsSecondaryCollapsed(false);
    };

    return (
        <div className="h-screen flex flex-col bg-white dark:bg-[#1e2329] overflow-hidden">
            {/* Top Global Header */}
            <header className="h-16 flex items-center justify-between px-4 md:px-6 border-b border-slate-200 dark:border-slate-800 shrink-0 bg-white dark:bg-[#1e2329] z-[60]">
                <div className="flex items-center gap-3">
                    <button
                        onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                        className="lg:hidden p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg text-slate-600 dark:text-slate-300"
                    >
                        {isMobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
                    </button>
                    <img src={Logo} alt="Logo" className="h-8 md:h-9 w-auto" />
                </div>

                <div className="flex-1 max-w-5xl ml-4 md:ml-10">
                    <Navbar hideLogo={true} />
                </div>
            </header>

            <div className="flex flex-1 overflow-hidden relative">
                {/* Mobile Overlay */}
                {isMobileMenuOpen && (
                    <div
                        className="lg:hidden fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[55] animate-in fade-in duration-300"
                        onClick={() => setIsMobileMenuOpen(false)}
                    />
                )}

                {/* Sidebars Container */}
                <div
                    className={`
                        fixed lg:relative inset-y-0 left-0 z-[56] flex shrink-0 transition-transform duration-300 ease-in-out
                        ${isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
                    `}
                    onMouseLeave={() => {
                        if (window.innerWidth >= 1024) setIsSecondaryCollapsed(true);
                    }}
                >
                    <PrimarySidebar
                        activeModule={activeModule}
                        onModuleChange={(id) => {
                            setActiveModule(id);
                            if (id !== 'team') setIsSecondaryCollapsed(false);
                            else setIsSecondaryCollapsed(true);
                        }}
                        onHover={handlePrimaryHover}
                    />
                    {!location.pathname.startsWith('/my-team') && activeModule !== 'team' && (
                        <SecondarySidebar
                            activeModule={activeModule}
                            isCollapsed={isSecondaryCollapsed && window.innerWidth >= 1024}
                        />
                    )}
                </div>

                {/* Main Content Area */}
                <main className={`flex-1 overflow-y-auto bg-slate-50/50 dark:bg-[#12161b] ${location.pathname.startsWith('/my-team') ? 'p-0' : ''} relative`}>
                    {children}
                </main>
            </div>
        </div>
    );
};

export default DashboardLayout;
