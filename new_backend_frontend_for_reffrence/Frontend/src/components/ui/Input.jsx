import React from 'react';

const Input = ({ label, type = 'text', placeholder, value, onChange, name, icon: Icon, error, suffix: Suffix }) => {
    return (
        <div className="flex flex-col gap-1 w-full">
            {label && <label className="text-slate-500 text-[10px] font-bold uppercase tracking-widest ml-1 opacity-70">{label}</label>}
            <div className="relative group">
                {Icon && (
                    <div className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 group-focus-within:text-emerald-500 transition-colors">
                        <Icon size={18} />
                    </div>
                )}
                <input
                    type={type}
                    name={name}
                    value={value}
                    onChange={onChange}
                    placeholder={placeholder}
                    className={`
                        w-full bg-slate-50 dark:bg-slate-950/50 border border-slate-200 dark:border-slate-800 text-slate-900 dark:text-white rounded-xl py-2 px-3.5 
                        ${Icon ? 'pl-9' : ''} 
                        ${Suffix ? 'pr-11' : ''}
                        focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500/50
                        placeholder:text-slate-400 dark:placeholder:text-slate-600 transition-all duration-200 text-xs font-medium
                        ${error ? 'border-red-500 focus:border-red-500 focus:ring-red-500/20' : ''}
                    `}
                />
                {Suffix && (
                    <div className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 transition-colors">
                        {Suffix}
                    </div>
                )}
            </div>
            {error && <span className="text-red-500 text-[10px] font-bold uppercase tracking-tighter mt-1 ml-1 animate-shake">{error}</span>}
        </div>
    );
};

export default Input;
