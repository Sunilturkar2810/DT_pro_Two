import React, { useState, useEffect } from 'react';
import { ArrowLeft, Trash2, Edit2, X, Plus } from 'lucide-react';
import toast from 'react-hot-toast';
import roleService from '../../services/roleService';

/* ─── Shared Components ─── */

const CustomCheckbox = ({ checked = false, onChange, disabled }) => (
    <label className="flex items-center justify-center cursor-pointer">
        <input
            type="checkbox"
            className="hidden"
            checked={!!checked}
            onChange={onChange}
            disabled={disabled}
        />
        <div className={`w-5 h-5 rounded flex items-center justify-center border-2 transition-all ${
            disabled && checked
                ? 'bg-slate-300 border-slate-300'
            : checked
                ? 'bg-[#1ed760] border-[#1ed760]'
                : 'bg-white border-slate-300'
        }`}>
            {checked && <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={4}><path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" /></svg>}
        </div>
    </label>
);

const CustomSelect = ({ value, onChange, options, disabled }) => (
    <select
        value={value || options[0] || ''}
        onChange={onChange}
        disabled={disabled}
        className="w-full max-w-[150px] bg-slate-100 border-none rounded-lg px-3 py-1.5 text-sm font-semibold text-slate-700 outline-none focus:ring-2 focus:ring-[#1ed760]/50 appearance-none cursor-pointer"
        style={{
            backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%2364748b'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M19 9l-7 7-7-7'%3E%3C/path%3E%3C/svg%3E")`,
            backgroundRepeat: 'no-repeat',
            backgroundPosition: 'right 0.5rem center',
            backgroundSize: '1em'
        }}
    >
        {options.map((opt, idx) => (
            <option key={idx} value={opt}>{opt}</option>
        ))}
    </select>
);

const defaultPermissionsStruct = {
    taskTemplate: { create: false, edit: false, view: false, delete: false },
    task: { create: false, edit: 'None', delete: 'None', importTask: false, exportTask: 'None' },
    myTeam: { add: false, edit: 'None', delete: 'None', view: 'None' },
    holidays: { create: false, edit: false, view: true, delete: false },
    groups: { create: false, edit: false, view: false, delete: false },
    activity: { view: false },
    ideaBoard: { view: false },
    taskDirectory: { view: false }
};

const defaultAdminPermissions = {
    taskTemplate: { create: true, edit: true, view: true, delete: true },
    task: { create: true, edit: 'All', delete: 'All', importTask: true, exportTask: 'All' },
    myTeam: { add: true, edit: 'All', delete: 'All', view: 'All' },
    holidays: { create: true, edit: true, view: true, delete: true },
    groups: { create: true, edit: true, view: true, delete: true },
    activity: { view: true },
    ideaBoard: { view: true },
    taskDirectory: { view: true }
};

/* ─── Default Roles View ─── */

const DefaultRolesView = ({ defaultRoles, fetchRoles }) => {
    // We assume defaultRoles contains Admin, Manager, Team Member.
    // If we want to allow editing default roles, we'd keep local state here.
    // But per typical system rules, default roles are locked from editing,
    // though the design has "Save" and "Reset". Let's assume we can edit them.

    const [editedRoles, setEditedRoles] = useState({});

    useEffect(() => {
        const initialMap = {};
        defaultRoles.forEach(r => {
            let perms = r.permissions;
            if (r.name?.toUpperCase() === 'ADMIN') {
                perms = JSON.parse(JSON.stringify(defaultAdminPermissions));
            } else if (!perms) {
                perms = JSON.parse(JSON.stringify(defaultPermissionsStruct));
            }
            // Store a normalized uppercase name so lookups always work
            initialMap[r.id] = { ...r, _nameUpper: r.name?.toUpperCase(), permissions: perms };
        });
        setEditedRoles(initialMap);
    }, [defaultRoles]);

    const handleSave = async () => {
        try {
            for (const r of Object.values(editedRoles)) {
                await roleService.updateRole(r.id, r);
            }
            toast.success('Default roles updated');
            fetchRoles();
        } catch (error) {
            toast.error('Failed to update default roles');
        }
    };

    const handleReset = () => {
        const initialMap = {};
        defaultRoles.forEach(r => {
            let perms = r.permissions;
            if (r.name?.toUpperCase() === 'ADMIN') {
                perms = JSON.parse(JSON.stringify(defaultAdminPermissions));
            } else if (!perms) {
                perms = JSON.parse(JSON.stringify(defaultPermissionsStruct));
            }
            initialMap[r.id] = { ...r, _nameUpper: r.name?.toUpperCase(), permissions: perms };
        });
        setEditedRoles(initialMap);
    };

    const getVal = (roleName, category, action) => {
        const upper = roleName?.toUpperCase();
        const role = Object.values(editedRoles).find(r => (r._nameUpper || r.name?.toUpperCase()) === upper);
        return role?.permissions?.[category]?.[action];
    };

    const updateVal = (roleName, category, action, value) => {
        const upper = roleName?.toUpperCase();
        setEditedRoles(prev => {
            const roleKey = Object.keys(prev).find(key => (prev[key]._nameUpper || prev[key].name?.toUpperCase()) === upper);
            if (!roleKey) return prev;
            return {
                ...prev,
                [roleKey]: {
                    ...prev[roleKey],
                    permissions: {
                        ...prev[roleKey].permissions,
                        [category]: {
                            ...prev[roleKey].permissions[category],
                            [action]: value
                        }
                    }
                }
            };
        });
    };

    const renderCheckboxRow = (category, action, title, disabledRule = () => false) => (
        <div className="grid grid-cols-4 p-4 border-b border-slate-100 last:border-0 items-center hover:bg-slate-50 transition-colors">
            <div className="font-extrabold text-sm text-slate-700">{title}</div>
            <div className="flex justify-center"><CustomCheckbox checked={!!getVal('ADMIN', category, action)} onChange={(e) => updateVal('ADMIN', category, action, e.target.checked)} disabled={disabledRule('ADMIN')} /></div>
            <div className="flex justify-center"><CustomCheckbox checked={!!getVal('MANAGER', category, action)} onChange={(e) => updateVal('MANAGER', category, action, e.target.checked)} disabled={disabledRule('MANAGER')} /></div>
            <div className="flex justify-center"><CustomCheckbox checked={!!getVal('TEAM MEMBER', category, action)} onChange={(e) => updateVal('TEAM MEMBER', category, action, e.target.checked)} disabled={disabledRule('TEAM MEMBER')} /></div>
        </div>
    );

    const renderSelectRow = (category, action, title, optionsMap, disabledRule = () => false) => (
        <div className="grid grid-cols-4 p-4 border-b border-slate-100 items-center hover:bg-slate-50 transition-colors">
            <div className="font-extrabold text-sm text-slate-700">{title}</div>
            <div className="flex justify-center"><CustomSelect value={getVal('ADMIN', category, action) || ''} onChange={(e) => updateVal('ADMIN', category, action, e.target.value)} disabled={disabledRule('ADMIN')} options={optionsMap['ADMIN']} /></div>
            <div className="flex justify-center"><CustomSelect value={getVal('MANAGER', category, action) || ''} onChange={(e) => updateVal('MANAGER', category, action, e.target.value)} disabled={disabledRule('MANAGER')} options={optionsMap['MANAGER']} /></div>
            <div className="flex justify-center"><CustomSelect value={getVal('TEAM MEMBER', category, action) || ''} onChange={(e) => updateVal('TEAM MEMBER', category, action, e.target.value)} disabled={disabledRule('TEAM MEMBER')} options={optionsMap['TEAM MEMBER']} /></div>
        </div>
    );

    // If roles aren't loaded yet
    if (Object.keys(editedRoles).length === 0) return null;

    return (
        <div className="flex flex-col gap-6 animate-in fade-in duration-300">
            {/* Header Actions */}
            <div className="flex justify-between items-center px-2">
                <button className="p-2 hover:bg-slate-100 rounded-full transition-colors hidden">
                    <ArrowLeft size={20} className="text-slate-600" />
                </button>
                <div className="flex gap-3 ml-auto">
                    <button onClick={handleReset} className="px-6 py-2 rounded-xl bg-[#ff4a5a] text-white font-bold text-sm hover:bg-[#ff3043] transition-colors shadow-sm">
                        Reset
                    </button>
                    <button onClick={handleSave} className="px-6 py-2 rounded-xl bg-[#1ed760] text-white font-bold text-sm hover:bg-[#1bc055] transition-colors shadow-sm">
                        Save
                    </button>
                </div>
            </div>

            <div className="space-y-8">
                {/* Task Template Section */}
                <div className="border border-slate-200 rounded-lg overflow-hidden flex flex-col">
                    <div className="grid grid-cols-4 bg-[#1ed760] text-white p-3 font-bold text-sm">
                        <div>Task Template</div>
                        <div className="text-center">ADMIN</div>
                        <div className="text-center">MANAGER</div>
                        <div className="text-center">TEAM MEMBER</div>
                    </div>
                    {renderCheckboxRow('taskTemplate', 'create', 'Create', r => r === 'ADMIN')}
                    {renderCheckboxRow('taskTemplate', 'edit', 'Edit', r => r === 'ADMIN')}
                    {renderCheckboxRow('taskTemplate', 'view', 'View', r => r === 'ADMIN')}
                    {renderCheckboxRow('taskTemplate', 'delete', 'Delete', r => r === 'ADMIN')}
                </div>

                {/* Task Section */}
                <div className="border border-slate-200 rounded-lg overflow-hidden flex flex-col">
                    <div className="grid grid-cols-4 bg-[#1ed760] text-white p-3 font-bold text-sm">
                        <div>Task</div>
                        <div className="text-center">ADMIN</div>
                        <div className="text-center">MANAGER</div>
                        <div className="text-center">TEAM MEMBER</div>
                    </div>
                    {renderCheckboxRow('task', 'create', 'Create', r => r === 'ADMIN')}
                    {renderSelectRow('task', 'edit', 'Edit', {
                        'ADMIN': ['All'],
                        'MANAGER': ['My Team + Assigned', 'Assigned', 'None', 'All'],
                        'TEAM MEMBER': ['Assigned', 'None']
                    }, r => r === 'ADMIN')}
                    {renderSelectRow('task', 'delete', 'Delete', {
                        'ADMIN': ['All'],
                        'MANAGER': ['Assigned', 'None', 'All'],
                        'TEAM MEMBER': ['Assigned', 'None']
                    }, r => r === 'ADMIN')}
                    {renderCheckboxRow('task', 'importTask', 'Import Task', r => r === 'ADMIN')}
                    {renderSelectRow('task', 'exportTask', 'Export Task', {
                        'ADMIN': ['All'],
                        'MANAGER': ['My Team + Me', 'None'],
                        'TEAM MEMBER': ['None', 'Me']
                    }, r => r === 'ADMIN')}
                </div>

                {/* My Team Section */}
                <div className="border border-slate-200 rounded-lg overflow-hidden flex flex-col">
                    <div className="grid grid-cols-4 bg-[#1ed760] text-white p-3 font-bold text-sm">
                        <div>My Team</div>
                        <div className="text-center">ADMIN</div>
                        <div className="text-center">MANAGER</div>
                        <div className="text-center">TEAM MEMBER</div>
                    </div>
                    {renderCheckboxRow('myTeam', 'add', 'Add', r => r === 'ADMIN')}
                    {renderSelectRow('myTeam', 'edit', 'Edit', {
                        'ADMIN': ['All'],
                        'MANAGER': ['My Team', 'None'],
                        'TEAM MEMBER': ['None']
                    }, r => r === 'ADMIN')}
                    {renderSelectRow('myTeam', 'delete', 'Delete', {
                        'ADMIN': ['All'],
                        'MANAGER': ['None'],
                        'TEAM MEMBER': ['None']
                    }, r => r === 'ADMIN')}
                    {renderSelectRow('myTeam', 'view', 'View', {
                        'ADMIN': ['All'],
                        'MANAGER': ['All', 'My Team'],
                        'TEAM MEMBER': ['All', 'None']
                    }, r => r === 'ADMIN')}
                </div>

                {/* Holidays Section */}
                <div className="border border-slate-200 rounded-lg overflow-hidden flex flex-col">
                    <div className="grid grid-cols-4 bg-[#1ed760] text-white p-3 font-bold text-sm">
                        <div>Holidays</div>
                        <div className="text-center">ADMIN</div>
                        <div className="text-center">MANAGER</div>
                        <div className="text-center">TEAM MEMBER</div>
                    </div>
                    {renderCheckboxRow('holidays', 'create', 'Create', r => r === 'ADMIN')}
                    {renderCheckboxRow('holidays', 'edit', 'Edit', r => r === 'ADMIN')}
                    {renderCheckboxRow('holidays', 'view', 'View', r => r === 'ADMIN')}
                    {renderCheckboxRow('holidays', 'delete', 'Delete', r => r === 'ADMIN')}
                </div>

                {/* Groups Section */}
                <div className="border border-slate-200 rounded-lg overflow-hidden flex flex-col">
                    <div className="grid grid-cols-4 bg-[#1ed760] text-white p-3 font-bold text-sm">
                        <div>Groups</div>
                        <div className="text-center">ADMIN</div>
                        <div className="text-center">MANAGER</div>
                        <div className="text-center">TEAM MEMBER</div>
                    </div>
                    {renderCheckboxRow('groups', 'create', 'Create', r => r === 'ADMIN')}
                    {renderCheckboxRow('groups', 'edit', 'Edit', r => r === 'ADMIN')}
                    {renderCheckboxRow('groups', 'view', 'View', r => r === 'ADMIN')}
                    {renderCheckboxRow('groups', 'delete', 'Delete', r => r === 'ADMIN')}
                </div>

                {/* Activity Section */}
                <div className="border border-slate-200 rounded-lg overflow-hidden flex flex-col">
                    <div className="grid grid-cols-4 bg-[#1ed760] text-white p-3 font-bold text-sm">
                        <div>Activity</div>
                        <div className="text-center">ADMIN</div>
                        <div className="text-center">MANAGER</div>
                        <div className="text-center">TEAM MEMBER</div>
                    </div>
                    {renderCheckboxRow('activity', 'view', 'View History', r => r === 'ADMIN')}
                </div>

                {/* Idea Board Section */}
                <div className="border border-slate-200 rounded-lg overflow-hidden flex flex-col">
                    <div className="grid grid-cols-4 bg-[#1ed760] text-white p-3 font-bold text-sm">
                        <div>Idea Board</div>
                        <div className="text-center">ADMIN</div>
                        <div className="text-center">MANAGER</div>
                        <div className="text-center">TEAM MEMBER</div>
                    </div>
                    {renderCheckboxRow('ideaBoard', 'view', 'View Board', r => r === 'ADMIN')}
                </div>

                {/* Task Directory Section */}
                <div className="border border-slate-200 rounded-lg overflow-hidden flex flex-col">
                    <div className="grid grid-cols-4 bg-[#1ed760] text-white p-3 font-bold text-sm">
                        <div>Task Directory</div>
                        <div className="text-center">ADMIN</div>
                        <div className="text-center">MANAGER</div>
                        <div className="text-center">TEAM MEMBER</div>
                    </div>
                    {renderCheckboxRow('taskDirectory', 'view', 'View Directory', r => r === 'ADMIN')}
                </div>
            </div>
        </div>
    );
};


/* ─── Custom Roles View ─── */

const CustomRolesView = ({ customRoles, onAddRoleClick, onDeleteRole, onEditRole }) => {
    return (
        <div className="flex flex-col gap-6 animate-in fade-in duration-300">
            {/* Header Actions */}
            <div className="flex justify-between items-center px-2">
                <button className="p-2 hover:bg-slate-100 rounded-full transition-colors hidden">
                    <ArrowLeft size={20} className="text-slate-600" />
                </button>
                <div className="flex ml-auto">
                    <button 
                        onClick={() => onAddRoleClick(null)}
                        className="px-6 py-2 rounded-xl bg-[#1ed760] text-white font-bold text-sm hover:bg-[#1bc055] transition-colors shadow-sm">
                        Add Role
                    </button>
                </div>
            </div>

            {/* Roles Table */}
            <div className="border border-slate-200 rounded-lg overflow-hidden flex flex-col">
                <div className="grid grid-cols-12 bg-[#1ed760] text-white p-3 font-bold text-sm">
                    <div className="col-span-3">Role</div>
                    <div className="col-span-7">Description</div>
                    <div className="col-span-2 text-center">Actions</div>
                </div>
                {customRoles.length === 0 ? (
                    <div className="p-8 text-center text-slate-500 font-medium">No custom roles created.</div>
                ) : customRoles.map((role) => (
                    <div key={role.id} className="grid grid-cols-12 p-4 border-b border-slate-100 hover:bg-slate-50 transition-colors items-center">
                        <div className="col-span-3 font-extrabold text-sm text-slate-700">{role.name}</div>
                        <div className="col-span-7 text-sm text-slate-600 font-medium">{role.description || '-'}</div>
                        <div className="col-span-2 flex justify-center gap-4">
                            <button onClick={() => onEditRole(role)} className="text-orange-400 hover:text-orange-500 transition-colors"><Edit2 size={16} /></button>
                            <button onClick={() => onDeleteRole(role.id)} className="text-red-400 hover:text-red-500 transition-colors"><Trash2 size={16} /></button>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
};


/* ─── Add Role Modal ─── */

const AddRoleModal = ({ isOpen, onClose, roleToEdit, fetchRoles }) => {
    const [name, setName] = useState('');
    const [description, setDescription] = useState('');
    const [permissions, setPermissions] = useState(defaultPermissionsStruct);

    useEffect(() => {
        if (roleToEdit) {
            setName(roleToEdit.name);
            setDescription(roleToEdit.description || '');
            setPermissions(roleToEdit.permissions || JSON.parse(JSON.stringify(defaultPermissionsStruct)));
        } else {
            setName('');
            setDescription('');
            setPermissions(JSON.parse(JSON.stringify(defaultPermissionsStruct)));
        }
    }, [roleToEdit, isOpen]);

    if (!isOpen) return null;

    const handleSubmit = async () => {
        if (!name) return toast.error('Role name is required');
        
        try {
            if (roleToEdit) {
                await roleService.updateRole(roleToEdit.id, { name, description, permissions });
                toast.success('Role updated successfully');
            } else {
                await roleService.createRole({ name, description, permissions });
                toast.success('Role created successfully');
            }
            fetchRoles();
            onClose();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Action failed');
        }
    };

    const updatePerm = (category, action, val) => {
        setPermissions(prev => ({
            ...prev,
            [category]: {
                ...prev[category],
                [action]: val
            }
        }));
    };

    return (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={onClose} />
            
            <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg z-10 flex flex-col max-h-[90vh] overflow-hidden animate-in zoom-in-95 duration-200 border border-slate-100 dark:border-slate-800">
                {/* Modal Header */}
                <div className="flex justify-between items-center px-6 py-4 border-b border-slate-100 shrink-0">
                    <div>
                        <h2 className="text-base font-bold text-slate-800">{roleToEdit ? 'Edit Role' : 'Add Role'}</h2>
                        <p className="text-[10px] font-bold text-slate-500">Configure role permissions and features.</p>
                    </div>
                    <button onClick={onClose} className="p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600 rounded-full transition-colors">
                        <X size={18} />
                    </button>
                </div>

                {/* Modal Body */}
                <div className="p-5 overflow-y-auto">
                    <div className="space-y-5">
                        {/* Name Input */}
                        <div>
                            <label className="block text-[11px] font-bold tracking-widest text-slate-500 uppercase mb-2">Role Name</label>
                            <div className="relative">
                                <input 
                                    type="text" 
                                    value={name}
                                    onChange={(e) => setName(e.target.value)}
                                    placeholder="Enter Role Name" 
                                    className="w-full border-2 border-[#1ed760] rounded-xl px-4 py-2.5 text-sm font-semibold outline-none bg-slate-50 focus:bg-white"
                                />
                            </div>
                            <p className="text-slate-400 text-[10px] font-bold text-right mt-1.5">{name.length}/25</p>
                        </div>

                        {/* Description Input */}
                        <div>
                            <label className="block text-[11px] font-bold tracking-widest text-slate-500 uppercase mb-2">Role Description</label>
                            <input 
                                type="text"
                                value={description}
                                onChange={(e) => setDescription(e.target.value)} 
                                placeholder="Enter Role Description" 
                                className="w-full border-2 border-slate-100 rounded-xl px-4 py-2.5 text-sm font-semibold outline-none focus:border-[#1ed760] bg-slate-50 focus:bg-white transition-colors"
                            />
                            <p className="text-slate-400 text-[10px] font-bold text-right mt-1.5">{description.length}/50</p>
                        </div>

                        {/* Permissions Grid */}
                        <div className="border border-slate-100 rounded-xl overflow-hidden flex flex-col mt-4">
                            <div className="bg-[#1ed760] text-white px-4 py-2.5 font-bold text-xs">
                                Task Template
                            </div>
                            {['create', 'edit', 'view', 'delete'].map((action, idx) => (
                                <div key={idx} className="flex justify-between items-center px-4 py-3 border-b border-slate-100 last:border-0 hover:bg-slate-50 transition-colors">
                                    <div className="font-bold text-xs text-slate-700 capitalize">{action}</div>
                                    <CustomCheckbox checked={permissions.taskTemplate[action]} onChange={(e) => updatePerm('taskTemplate', action, e.target.checked)} />
                                </div>
                            ))}
                        </div>

                        <div className="border border-slate-100 rounded-xl overflow-hidden flex flex-col mt-4">
                            <div className="bg-[#1ed760] text-white px-4 py-2.5 font-bold text-xs">
                                Task
                            </div>
                            <div className="flex justify-between items-center px-4 py-3 border-b border-slate-100 hover:bg-slate-50 transition-colors">
                                <div className="font-bold text-xs text-slate-700">Create</div>
                                <CustomCheckbox checked={permissions.task.create} onChange={(e) => updatePerm('task', 'create', e.target.checked)} />
                            </div>
                            <div className="flex justify-between items-center px-4 py-3 border-b border-slate-100 hover:bg-slate-50 transition-colors">
                                <div className="font-bold text-xs text-slate-700">Edit</div>
                                <CustomSelect value={permissions.task.edit} onChange={(e) => updatePerm('task', 'edit', e.target.value)} options={['All', 'My Team + Assigned', 'Assigned', 'None']} />
                            </div>
                            <div className="flex justify-between items-center px-4 py-3 border-b border-slate-100 hover:bg-slate-50 transition-colors">
                                <div className="font-bold text-xs text-slate-700">Delete</div>
                                <CustomSelect value={permissions.task.delete} onChange={(e) => updatePerm('task', 'delete', e.target.value)} options={['All', 'Assigned', 'None']} />
                            </div>
                            <div className="flex justify-between items-center px-4 py-3 border-b border-slate-100 hover:bg-slate-50 transition-colors">
                                <div className="font-bold text-xs text-slate-700">Import Task</div>
                                <CustomCheckbox checked={permissions.task.importTask} onChange={(e) => updatePerm('task', 'importTask', e.target.checked)} />
                            </div>
                            <div className="flex justify-between items-center px-4 py-3 border-b border-slate-100 hover:bg-slate-50 transition-colors">
                                <div className="font-bold text-xs text-slate-700">Export Task</div>
                                <CustomSelect value={permissions.task.exportTask} onChange={(e) => updatePerm('task', 'exportTask', e.target.value)} options={['All', 'My Team + Me', 'Me', 'None']} />
                            </div>
                        </div>

                        <div className="border border-slate-100 rounded-xl overflow-hidden flex flex-col mt-4">
                            <div className="bg-[#1ed760] text-white px-4 py-2.5 font-bold text-xs">
                                My Team
                            </div>
                            <div className="flex justify-between items-center px-4 py-3 border-b border-slate-100 hover:bg-slate-50 transition-colors">
                                <div className="font-bold text-xs text-slate-700">Add</div>
                                <CustomCheckbox checked={permissions.myTeam.add} onChange={(e) => updatePerm('myTeam', 'add', e.target.checked)} />
                            </div>
                            <div className="flex justify-between items-center px-4 py-3 border-b border-slate-100 hover:bg-slate-50 transition-colors">
                                <div className="font-bold text-xs text-slate-700">Edit</div>
                                <CustomSelect value={permissions.myTeam.edit} onChange={(e) => updatePerm('myTeam', 'edit', e.target.value)} options={['All', 'My Team', 'None']} />
                            </div>
                            <div className="flex justify-between items-center px-4 py-3 border-b border-slate-100 hover:bg-slate-50 transition-colors">
                                <div className="font-bold text-xs text-slate-700">Delete</div>
                                <CustomSelect value={permissions.myTeam.delete} onChange={(e) => updatePerm('myTeam', 'delete', e.target.value)} options={['All', 'None']} />
                            </div>
                            <div className="flex justify-between items-center px-4 py-3 border-b border-slate-100 hover:bg-slate-50 transition-colors">
                                <div className="font-bold text-xs text-slate-700">View</div>
                                <CustomSelect value={permissions.myTeam.view} onChange={(e) => updatePerm('myTeam', 'view', e.target.value)} options={['All', 'My Team', 'None']} />
                            </div>
                        </div>

                        {/* Holidays */}
                        <div className="border border-slate-100 rounded-xl overflow-hidden flex flex-col mt-4">
                            <div className="bg-[#1ed760] text-white px-4 py-2.5 font-bold text-xs">Holidays</div>
                            {['create', 'edit', 'view', 'delete'].map((action, idx) => (
                                <div key={idx} className="flex justify-between items-center px-4 py-3 border-b border-slate-100 last:border-0 hover:bg-slate-50 transition-colors">
                                    <div className="font-bold text-xs text-slate-700 capitalize">{action}</div>
                                    <CustomCheckbox checked={permissions.holidays?.[action]} onChange={(e) => updatePerm('holidays', action, e.target.checked)} />
                                </div>
                            ))}
                        </div>

                        {/* Groups */}
                        <div className="border border-slate-100 rounded-xl overflow-hidden flex flex-col mt-4">
                            <div className="bg-[#1ed760] text-white px-4 py-2.5 font-bold text-xs">Groups</div>
                            {['create', 'edit', 'view', 'delete'].map((action, idx) => (
                                <div key={idx} className="flex justify-between items-center px-4 py-3 border-b border-slate-100 last:border-0 hover:bg-slate-50 transition-colors">
                                    <div className="font-bold text-xs text-slate-700 capitalize">{action}</div>
                                    <CustomCheckbox checked={permissions.groups?.[action]} onChange={(e) => updatePerm('groups', action, e.target.checked)} />
                                </div>
                            ))}
                        </div>

                        {/* Activity */}
                        <div className="border border-slate-100 rounded-xl overflow-hidden flex flex-col mt-4">
                            <div className="bg-[#1ed760] text-white px-4 py-2.5 font-bold text-xs">Activity</div>
                            <div className="flex justify-between items-center px-4 py-3 border-b border-slate-100 last:border-0 hover:bg-slate-50 transition-colors">
                                <div className="font-bold text-xs text-slate-700">View History</div>
                                <CustomCheckbox checked={permissions.activity?.view} onChange={(e) => updatePerm('activity', 'view', e.target.checked)} />
                            </div>
                        </div>

                        {/* Idea Board */}
                        <div className="border border-slate-100 rounded-xl overflow-hidden flex flex-col mt-4">
                            <div className="bg-[#1ed760] text-white px-4 py-2.5 font-bold text-xs">Idea Board</div>
                            <div className="flex justify-between items-center px-4 py-3 border-b border-slate-100 last:border-0 hover:bg-slate-50 transition-colors">
                                <div className="font-bold text-xs text-slate-700">View Board</div>
                                <CustomCheckbox checked={permissions.ideaBoard?.view} onChange={(e) => updatePerm('ideaBoard', 'view', e.target.checked)} />
                            </div>
                        </div>

                        {/* Task Directory */}
                        <div className="border border-slate-100 rounded-xl overflow-hidden flex flex-col mt-4">
                            <div className="bg-[#1ed760] text-white px-4 py-2.5 font-bold text-xs">Task Directory</div>
                            <div className="flex justify-between items-center px-4 py-3 border-b border-slate-100 last:border-0 hover:bg-slate-50 transition-colors">
                                <div className="font-bold text-xs text-slate-700">View Directory</div>
                                <CustomCheckbox checked={permissions.taskDirectory?.view} onChange={(e) => updatePerm('taskDirectory', 'view', e.target.checked)} />
                            </div>
                        </div>

                    </div>
                </div>

                {/* Modal Footer */}
                <div className="px-6 py-4 border-t border-slate-100 flex justify-end gap-3 bg-slate-50 shrink-0">
                    <button onClick={onClose} className="px-4 py-2 rounded-xl text-slate-600 text-sm font-bold hover:bg-slate-200 transition-colors">
                        Cancel
                    </button>
                    <button onClick={handleSubmit} className="px-5 py-2 rounded-xl bg-[#1ed760] text-white text-sm font-bold hover:bg-[#1bc055] transition-colors shadow-sm shadow-[#1ed760]/20">
                        {roleToEdit ? 'Save Changes' : 'Create Role'}
                    </button>
                </div>
            </div>
        </div>
    );
};


/* ─── Main Component ─── */

const RolesPermissions = () => {
    const [activeTab, setActiveTab] = useState('default'); // 'default' | 'custom'
    const [isAddRoleModalOpen, setIsAddRoleModalOpen] = useState(false);
    const [roles, setRoles] = useState([]);
    const [roleToEdit, setRoleToEdit] = useState(null);

    const fetchRoles = async () => {
        try {
            const res = await roleService.getRoles();
            setRoles(res.data);
        } catch (error) {
            toast.error('Failed to fetch roles');
        }
    };

    useEffect(() => {
        fetchRoles();
    }, []);

    const defaultRoles = roles.filter(r => !r.isCustom);
    const customRoles = roles.filter(r => r.isCustom);

    const handleAddRoleClick = (role) => {
        setRoleToEdit(role);
        setIsAddRoleModalOpen(true);
    };

    const handleDeleteRole = async (id) => {
        if (!window.confirm('Are you sure you want to delete this role?')) return;
        try {
            await roleService.deleteRole(id);
            toast.success('Role deleted successfully');
            fetchRoles();
        } catch (error) {
            toast.error(error.response?.data?.message || 'Failed to delete role');
        }
    };

    return (
        <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-800 flex flex-col overflow-hidden min-h-[600px]">
            {/* Tabs Header */}
            <div className="flex items-center justify-center border-b border-slate-200 dark:border-slate-800 pt-6">
                <div className="flex gap-8 relative">
                    <button 
                        onClick={() => setActiveTab('default')}
                        className={`pb-4 text-sm font-extrabold transition-colors relative ${activeTab === 'default' ? 'text-slate-800 dark:text-white' : 'text-slate-500 hover:text-slate-700'}`}
                    >
                        Default Roles
                        {activeTab === 'default' && (
                            <div className="absolute bottom-0 left-[-10%] right-[-10%] h-1 bg-[#1ed760] rounded-t-full" />
                        )}
                    </button>
                    <button 
                        onClick={() => setActiveTab('custom')}
                        className={`pb-4 text-sm font-extrabold transition-colors relative ${activeTab === 'custom' ? 'text-slate-800 dark:text-white' : 'text-slate-500 hover:text-slate-700'}`}
                    >
                        Custom Roles
                        {activeTab === 'custom' && (
                            <div className="absolute bottom-0 left-[-10%] right-[-10%] h-1 bg-[#1ed760] rounded-t-full" />
                        )}
                    </button>
                </div>
            </div>

            {/* Content Body */}
            <div className="p-6 overflow-y-auto">
                {activeTab === 'default' ? (
                    <DefaultRolesView defaultRoles={defaultRoles} fetchRoles={fetchRoles} />
                ) : (
                    <CustomRolesView 
                        customRoles={customRoles} 
                        onAddRoleClick={handleAddRoleClick} 
                        onDeleteRole={handleDeleteRole}
                        onEditRole={handleAddRoleClick}
                    />
                )}
            </div>

            <AddRoleModal 
                isOpen={isAddRoleModalOpen} 
                onClose={() => setIsAddRoleModalOpen(false)} 
                roleToEdit={roleToEdit}
                fetchRoles={fetchRoles}
            />
        </div>
    );
};

export default RolesPermissions;
