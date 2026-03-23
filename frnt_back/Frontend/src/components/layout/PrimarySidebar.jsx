import React from 'react';
import { NavLink, useLocation, useNavigate } from 'react-router-dom';
import { 
    CheckSquare, LayoutGrid, Link2, Users, 
    Settings, CreditCard, HelpCircle, Sparkles, Package
} from 'lucide-react';

const PrimarySidebar = ({ activeModule, onModuleChange, onHover }) => {
    const location = useLocation();
    const navigate = useNavigate();

    const topModules = [
        { id: 'tasks', icon: CheckSquare, label: 'Tasks', paths: ['/dashboard', '/my-tasks', '/delegated-tasks', '/all-tasks', '/in-loop-tasks', '/holidays', '/idea-board'] },
        { id: 'groups', icon: Package, label: 'Groups', paths: ['/groups'] },
        { id: 'team', icon: Users, label: 'My Team', paths: ['/my-team'] }
    ];

    const bottomModules = [
        { id: 'settings', icon: Settings, label: 'Settings', paths: ['/settings'] }
    ];

    const isModuleActive = (module) => {
        if (activeModule === module.id) return true;
        return module.paths.some(path => location.pathname.startsWith(path));
    };

    const ModuleItem = ({ module }) => {
        const active = isModuleActive(module);
        return (
            <button
                onClick={() => {
                    if (module.paths && module.paths.length > 0) {
                        navigate(module.paths[0]);
                    }
                    onModuleChange(module.id);
                }}
                onMouseEnter={() => onHover && onHover(module.id)}
                className={`w-full flex flex-col items-center justify-center py-4 gap-2 transition-all relative ${
                    active ? 'text-white' : 'text-emerald-100/70 hover:text-white hover:bg-white/5'
                }`}
            >
                {active && <div className="absolute left-0 top-1 bottom-1 w-1 bg-white rounded-r-md" />}
                <div className="relative">
                    <module.icon size={26} strokeWidth={active ? 2.5 : 2} />
                </div>
                <span className="text-[10px] font-bold uppercase tracking-tight">{module.label}</span>
            </button>
        );
    };

    return (
        <aside className="w-[80px] bg-[#04d092] flex flex-col h-full overflow-y-auto overflow-x-hidden scrollbar-none z-50">
            <div className="flex flex-col flex-1 py-4">
                {topModules.map(m => <ModuleItem key={m.id} module={m} />)}
            </div>

            <div className="flex flex-col mt-auto pb-6">
                {bottomModules.map(m => <ModuleItem key={m.id} module={m} />)}
            </div>
        </aside>
    );
};

export default PrimarySidebar;
