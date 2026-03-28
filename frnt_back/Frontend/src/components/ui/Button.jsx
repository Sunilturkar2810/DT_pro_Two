import React from 'react';

const Button = ({ children, onClick, type = 'button', variant = 'primary', size = 'md', className = '', isLoading = false, disabled = false, icon: Icon }) => {
    const variants = {
        primary: 'bg-emerald-500 hover:bg-emerald-600 text-[#0f172a] font-bold shadow-lg shadow-emerald-500/20',
        secondary: 'bg-gray-800 hover:bg-gray-700 text-white border border-gray-700',
        outline: 'bg-transparent border-2 border-emerald-500 text-emerald-500 hover:bg-emerald-500 hover:text-white',
        ghost: 'bg-transparent hover:bg-gray-800 text-gray-400 hover:text-white',
        white: 'bg-white hover:bg-gray-100 text-[#0f172a] border border-gray-200 hover:border-gray-300'
    };

    const sizes = {
        sm: 'py-1.5 px-3 text-xs',
        md: 'py-2.5 px-5 text-sm font-semibold',
        lg: 'py-3.5 px-7 text-base font-bold'
    };

    return (
        <button
            type={type}
            onClick={onClick}
            disabled={disabled || isLoading}
            className={`
                flex items-center justify-center gap-2 rounded-xl transition-all duration-200 
                active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed disabled:active:scale-100
                ${variants[variant]} ${sizes[size]} ${className}
            `}
        >
            {isLoading ? (
                <div className="w-5 h-5 border-2 border-current border-t-transparent rounded-full animate-spin" />
            ) : (
                <>
                    {Icon && <Icon size={20} />}
                    {children}
                </>
            )}
        </button>
    );
};

export default Button;
