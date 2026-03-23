import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';

const PublicRoute = () => {
    const user = JSON.parse(localStorage.getItem('user'));

    if (user && user.token) {
        // Redirect to dashboard if already authenticated
        return <Navigate to="/dashboard" replace />;
    }

    return <Outlet />;
};

export default PublicRoute;
