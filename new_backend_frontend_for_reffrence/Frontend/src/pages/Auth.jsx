import React, { useState } from 'react';
import { CheckCircle2, Layout, Database, MessageSquare } from 'lucide-react';
import LoginForm from '../components/auth/LoginForm';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import Logo from '../assets/Logo.jpeg';

const FeatureItem = ({ icon: Icon, title, description, highlight }) => (
    <div className="flex gap-4 p-5 bg-[#1a2332]/50 border border-gray-800 rounded-xl transition-all hover:bg-[#1a2332] group">
        <div className="flex-shrink-0 w-12 h-12 flex items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-500 group-hover:bg-emerald-500/20 transition-colors">
            <Icon size={24} />
        </div>
        <div className="flex flex-col gap-1">
            <h3 className="text-white font-semibold flex items-center gap-1.5">
                {title.split(highlight)[0]}
                <span className="text-sky-400">{highlight}</span>
                {title.split(highlight)[1]}
            </h3>
            <p className="text-gray-400 text-sm leading-relaxed">{description}</p>
        </div>
    </div>
);

const Auth = () => {
    const navigate = useNavigate();

    const handleLoginSuccess = (data) => {
        console.log('Login success:', data);
        localStorage.setItem('user', JSON.stringify(data));
        navigate('/dashboard');
    };

    const features = [
        {
            icon: CheckCircle2,
            title: "AutomateTasks",
            highlight: "Tasks",
            description: "Delegate one time and recurring tasks to your team"
        },
        {
            icon: Layout,
            title: "AutomateLeaves & Attendance",
            highlight: "Leaves",
            description: "Manage your employee attendance, leaves and holidays"
        },
        {
            icon: Database,
            title: "AutomateCRM",
            highlight: "CRM",
            description: "Track and Convert and assign leads to your Sales Team"
        },
        {
            icon: MessageSquare,
            title: "AutomateWA",
            highlight: "WA",
            description: "Official WhatsApp API for all Business Communication"
        }
    ];

    return (
        <div className="min-h-screen bg-[#0f172a] flex">
            {/* Left Side - Features */}
            <div className="hidden lg:flex w-1/2 flex-col justify-center px-16 xl:px-24 bg-[radial-gradient(ellipse_at_top_left,_var(--tw-gradient-stops))] from-emerald-950/20 via-[#0f172a] to-[#0f172a]">
                <div className="max-w-xl">
                    <h1 className="text-3xl lg:text-5xl font-bold text-white mb-12 text-center leading-tight">
                        Grow your Business with <br />
                        <span className="text-sky-400">Automate</span> <span className="text-orange-500">Business</span>
                    </h1>

                    <div className="flex flex-col gap-5">
                        {features.map((feature, index) => (
                            <FeatureItem key={index} {...feature} />
                        ))}
                    </div>
                </div>
            </div>

            {/* Right Side - Auth Forms */}
            <div className="w-full lg:w-1/2 flex items-center justify-center p-6 bg-[#0a0f1d] relative overflow-hidden">
                {/* Decorative glow */}
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-emerald-500/5 rounded-full blur-[120px]" />

                <div className="w-full max-w-md relative z-10 flex flex-col items-center">
                    {/* Logo */}
                    <div className="flex items-center gap-3 mb-10 translate-x-1">
                        <img src={Logo} alt="Logo" className="h-12 w-auto rounded-xl shadow-lg shadow-emerald-500/10" />
                    </div>

                    {/* Card Container */}
                    <div className="w-full bg-[#111827]/40 border border-emerald-500/30 rounded-2xl p-8 backdrop-blur-sm shadow-2xl">
                        <LoginForm onLoginSuccess={handleLoginSuccess} />
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Auth;
