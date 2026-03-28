import React, { useState, useEffect } from 'react';
import { Search, Plus, Folder, Clock, LayoutGrid, List, MoreVertical, Edit2, Trash2, X, Tag } from 'lucide-react';
import toast from 'react-hot-toast';
import delegationService from '../services/delegationService';

const CategorySettings = ({ hideHeader = false }) => {
    const [categories, setCategories] = useState([]);
    const [isLoading, setIsLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [viewMode, setViewMode] = useState('list'); // 'list' | 'grid'
    
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [newCategoryData, setNewCategoryData] = useState({ name: '', color: '#10b981' });
    const [isSubmitting, setIsSubmitting] = useState(false);

    const presetColors = [
        '#e91e63', '#9c27b0', '#673ab7', '#3f51b5', '#2196f3', '#42a5f5', '#64b5f6',
        '#4dd0e1', '#26a69a', '#10b981', '#8bc34a', '#cddc39', '#ffeb3b', '#ffc107', 
        '#ff9800', '#607d8b', '#455a64'
    ];

    useEffect(() => {
        fetchCategories();
    }, []);

    const fetchCategories = async () => {
        try {
            setIsLoading(true);
            const data = await delegationService.getCategories();
            setCategories(Array.isArray(data) ? data : []);
        } catch (error) {
            console.error('Failed to fetch categories:', error);
            toast.error('Failed to load categories');
        } finally {
            setIsLoading(false);
        }
    };

    const handleCreateCategory = async () => {
        if (!newCategoryData.name.trim()) {
            toast.error('Category name is required');
            return;
        }
        try {
            setIsSubmitting(true);
            const user = JSON.parse(localStorage.getItem('user'));
            const userId = user?.user?.id || user?.id;
            
            await delegationService.createCategory({
                name: newCategoryData.name.trim(),
                color: newCategoryData.color,
                createdBy: userId
            });
            
            toast.success('Category created successfully');
            setIsAddModalOpen(false);
            setNewCategoryData({ name: '', color: '#10b981' });
            fetchCategories();
        } catch (error) {
            console.error('Failed to create category:', error);
            toast.error('Failed to create category');
        } finally {
            setIsSubmitting(false);
        }
    };

    const handleDeleteCategory = async (id) => {
        if (window.confirm('Are you sure you want to delete this category?')) {
            try {
                await delegationService.deleteCategory(id);
                toast.success('Category deleted successfully');
                fetchCategories();
            } catch (error) {
                console.error('Failed to delete category:', error);
                toast.error('Failed to delete category');
            }
        }
    };

    const filteredCategories = categories.filter(c => 
        (c.name || '').toLowerCase().includes((searchQuery || '').toLowerCase())
    );

    const recentlyAdded = categories.length > 0 
        ? categories.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))[0] 
        : null;

    return (
        <div className="flex flex-col gap-6 animate-in fade-in duration-500">
            {/* Header */}
            {!hideHeader && (
                <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                    <div>
                        <h1 className="text-2xl font-black text-slate-800 dark:text-white tracking-tight">Categories Overview</h1>
                        <p className="text-sm font-medium text-slate-500 mt-1">Manage your task categories</p>
                    </div>
                    
                    <div className="flex items-center gap-3 w-full sm:w-auto">
                        <div className="relative flex-1 sm:w-64">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                            <input 
                                type="text" 
                                placeholder="Search categories..." 
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-sm font-medium text-slate-800 dark:text-white placeholder:text-slate-400 focus:outline-none focus:border-emerald-500/50 focus:ring-2 focus:ring-emerald-500/20 transition-all shadow-sm"
                            />
                        </div>
                        <button 
                            onClick={() => setIsAddModalOpen(true)}
                            className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-sm shadow-lg shadow-emerald-500/20 active:scale-95 transition-all whitespace-nowrap"
                        >
                            <Plus size={18} strokeWidth={3} /> Add Category
                        </button>
                    </div>
                </div>
            )}

            {/* If header is hidden, we still need the search and add button somewhere. 
                Actually, the original design had them in the header. 
                If the header is hidden, I'll move them to a new sub-header row.
            */}
            {hideHeader && (
                <div className="flex items-center justify-end gap-3 w-full animate-in fade-in duration-300">
                    <div className="relative w-64">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                        <input 
                            type="text" 
                            placeholder="Search categories..." 
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="w-full pl-9 pr-4 py-2 bg-white dark:bg-slate-800 rounded-xl border border-slate-100 dark:border-slate-800 text-xs font-bold"
                        />
                    </div>
                    <button 
                        onClick={() => setIsAddModalOpen(true)}
                        className="flex items-center gap-2 px-4 py-2 rounded-xl bg-emerald-500 text-white font-bold text-xs shadow-lg shadow-emerald-500/20 transition-all active:scale-95"
                    >
                        <Plus size={16} strokeWidth={3} /> Add Category
                    </button>
                </div>
            )}

            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200 dark:border-slate-700 shadow-sm flex items-center gap-4">
                    <div className="w-14 h-14 rounded-2xl bg-emerald-50 text-emerald-500 flex items-center justify-center shrink-0">
                        <Folder size={26} strokeWidth={2.5} />
                    </div>
                    <div>
                        <p className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">Total Categories</p>
                        <h3 className="text-2xl font-black text-slate-800 dark:text-white">{categories.length}</h3>
                    </div>
                </div>
                
                <div className="bg-white dark:bg-slate-800 rounded-2xl p-5 border border-slate-200 dark:border-slate-700 shadow-sm flex items-center gap-4">
                    <div className="w-14 h-14 rounded-2xl bg-blue-50 text-blue-500 flex items-center justify-center shrink-0">
                        <Clock size={26} strokeWidth={2.5} />
                    </div>
                    <div>
                        <p className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">Recently Added</p>
                        <h3 className="text-xl font-bold text-slate-800 dark:text-white truncate max-w-[200px]">
                            {recentlyAdded?.name || 'None'}
                        </h3>
                    </div>
                </div>
            </div>

            {/* List/Grid Header Section */}
            <div className="flex items-center justify-between mt-2">
                <h2 className="text-lg font-black text-slate-800 dark:text-white">
                    All Categories <span className="text-emerald-500">({filteredCategories.length})</span>
                </h2>
                
                <div className="flex items-center gap-1 bg-slate-100 dark:bg-slate-800 p-1 rounded-lg border border-slate-200 dark:border-slate-700">
                    <button 
                        onClick={() => setViewMode('list')}
                        className={`p-1.5 rounded-md transition-all ${viewMode === 'list' ? 'bg-white dark:bg-slate-700 text-emerald-500 shadow-sm' : 'text-slate-400 hover:text-slate-600'}`}
                    >
                        <List size={18} />
                    </button>
                    <button 
                        onClick={() => setViewMode('grid')}
                        className={`p-1.5 rounded-md transition-all ${viewMode === 'grid' ? 'bg-white dark:bg-slate-700 text-emerald-500 shadow-sm' : 'text-slate-400 hover:text-slate-600'}`}
                    >
                        <LayoutGrid size={18} />
                    </button>
                </div>
            </div>

            {/* Categories Content */}
            {isLoading ? (
                <div className="flex justify-center items-center py-12">
                    <div className="w-8 h-8 rounded-full border-4 border-slate-200 border-t-emerald-500 animate-spin"></div>
                </div>
            ) : filteredCategories.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 text-center bg-white dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700 border-dashed">
                    <Folder className="text-slate-300 dark:text-slate-600 mb-3" size={48} strokeWidth={1.5} />
                    <h3 className="text-base font-bold text-slate-700 dark:text-white mb-1">No Categories Found</h3>
                    <p className="text-sm font-medium text-slate-500">Create a new category to get started.</p>
                </div>
            ) : viewMode === 'list' ? (
                <div className="bg-white dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm overflow-hidden">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="border-b border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50">
                                <th className="py-4 px-6 text-xs font-bold tracking-wider text-slate-500 uppercase">Category Name</th>
                                <th className="py-4 px-6 text-xs font-bold tracking-wider text-slate-500 uppercase">Created At</th>
                                <th className="py-4 px-6 text-xs font-bold tracking-wider text-slate-500 uppercase text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredCategories.map(category => (
                                <tr key={category.id} className="border-b border-slate-100 dark:border-slate-700/50 last:border-0 hover:bg-slate-50/50 dark:hover:bg-slate-800/80 transition-colors group">
                                    <td className="py-4 px-6">
                                        <div className="flex items-center gap-3">
                                            <div className="w-3 h-3 rounded-full shadow-sm" style={{ backgroundColor: category.color || '#10b981' }}></div>
                                            <span className="font-bold text-slate-700 dark:text-white text-sm">{category.name}</span>
                                        </div>
                                    </td>
                                    <td className="py-4 px-6">
                                        <div className="flex items-center gap-2 text-sm font-medium text-slate-500">
                                            <Clock size={14} className="opacity-70" />
                                            Created: {new Date(category.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                                        </div>
                                    </td>
                                    <td className="py-4 px-6 text-right">
                                        <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                            <button onClick={() => handleDeleteCategory(category.id)} className="p-2 text-slate-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors" title="Delete">
                                                <Trash2 size={16} />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                    {filteredCategories.map(category => (
                        <div key={category.id} className="bg-white dark:bg-slate-800 p-5 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm hover:shadow-md transition-all group flex flex-col relative overflow-hidden">
                            <div className="absolute top-0 right-0 w-24 h-24 bg-gradient-to-br from-white/0 to-current opacity-10 blur-2xl -mr-8 -mt-8 rounded-full pointer-events-none" style={{ color: category.color || '#10b981' }}></div>
                            <div className="flex justify-between items-start mb-4">
                                <div className="w-10 h-10 rounded-xl flex items-center justify-center shadow-sm" style={{ backgroundColor: `${category.color || '#10b981'}20`, color: category.color || '#10b981' }}>
                                    <Tag size={20} strokeWidth={2.5} />
                                </div>
                                <button onClick={() => handleDeleteCategory(category.id)} className="p-1.5 text-slate-400 hover:text-red-500 bg-white hover:bg-red-50 rounded-lg transition-colors opacity-0 group-hover:opacity-100 shadow-sm border border-slate-100">
                                    <Trash2 size={14} />
                                </button>
                            </div>
                            <h3 className="font-bold text-slate-800 dark:text-white text-[15px] mb-1 truncate">{category.name}</h3>
                            <div className="flex items-center gap-1.5 text-xs font-medium text-slate-400 mt-auto">
                                <Clock size={12} />
                                {new Date(category.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Create Category Modal */}
            {isAddModalOpen && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/40 backdrop-blur-sm p-4 animate-in fade-in duration-200">
                    <div className="w-full max-w-[400px] bg-white dark:bg-[#1e2329] rounded-2xl shadow-2xl flex flex-col overflow-hidden animate-in zoom-in-95 duration-200 border border-slate-100 dark:border-slate-800">
                        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 dark:border-slate-800/50 bg-emerald-50/30 dark:bg-emerald-500/5">
                            <h3 className="font-bold text-base text-slate-800 dark:text-white tracking-tight">Create New Category</h3>
                            <button onClick={() => setIsAddModalOpen(false)} className="w-8 h-8 rounded-full flex items-center justify-center text-slate-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors">
                                <X size={18} strokeWidth={2.5} />
                            </button>
                        </div>
                        
                        <div className="p-5">
                            <div className="mb-5">
                                <label className="block text-[11px] font-bold tracking-widest text-slate-500 uppercase mb-2">Category Name</label>
                                <input 
                                    type="text" 
                                    value={newCategoryData.name}
                                    onChange={(e) => setNewCategoryData(prev => ({...prev, name: e.target.value}))}
                                    placeholder="e.g. Design, Marketing..."
                                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50 text-sm font-bold text-slate-800 dark:text-white placeholder:text-slate-400 placeholder:font-medium focus:outline-none focus:border-emerald-500/50 focus:ring-2 focus:ring-emerald-500/20 transition-all"
                                    autoFocus
                                />
                            </div>
                            
                            <div>
                                <label className="block text-[11px] font-bold tracking-widest text-slate-500 uppercase mb-3">Color Label</label>
                                <div className="flex flex-wrap gap-2.5">
                                    {presetColors.map(color => (
                                        <button
                                            key={color}
                                            type="button"
                                            onClick={() => setNewCategoryData(prev => ({...prev, color}))}
                                            className={`w-7 h-7 rounded-full transition-all shadow-sm flex items-center justify-center ${newCategoryData.color === color ? 'scale-110 ring-4 ring-offset-1 ring-emerald-500/30' : 'hover:scale-110'}`}
                                            style={{ backgroundColor: color }}
                                            title={color}
                                        />
                                    ))}
                                </div>
                            </div>
                        </div>

                        <div className="px-6 py-4 border-t border-slate-100 dark:border-slate-800/50 flex justify-end gap-3 bg-slate-50/50 dark:bg-slate-800/20">
                            <button 
                                onClick={() => setIsAddModalOpen(false)} 
                                className="px-4 py-2 rounded-xl text-sm font-bold text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                            >
                                Cancel
                            </button>
                            <button 
                                onClick={handleCreateCategory}
                                disabled={isSubmitting}
                                className={`px-5 py-2 rounded-xl bg-emerald-500 text-white text-sm font-bold shadow-lg shadow-emerald-500/20 transition-all active:scale-95 flex items-center gap-2 ${isSubmitting ? 'opacity-70 pointer-events-none' : 'hover:bg-emerald-600'}`}
                            >
                                {isSubmitting ? (
                                    <>
                                        <div className="w-4 h-4 rounded-full border-2 border-white/30 border-t-white animate-spin" />
                                        Saving...
                                    </>
                                ) : (
                                    'Create'
                                )}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default CategorySettings;
