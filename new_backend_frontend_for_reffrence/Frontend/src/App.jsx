import { BrowserRouter as Router, Routes, Route, Navigate, Outlet } from 'react-router-dom';
import { ThemeProvider } from './context/ThemeContext';
import Auth from './pages/Auth';
import Dashboard from './pages/Dashboard';
import MyTeam from './pages/MyTeam';
import Settings from './pages/Settings';
import MyTasks from './pages/MyTasks';
import GroupTasks from './pages/GroupTasks';
import DelegatedTasks from './pages/DelegatedTasks';
import AllTasks from './pages/AllTasks';
import InLoopTasks from './pages/InLoopTasks';
import TaskTemplates from './pages/TaskTemplates';
import DeletedTasks from './pages/DeletedTasks';
import AddUserPage from './pages/AddUserPage';
import Activities from './pages/Activities';
import Holidays from './pages/Holidays';
import CategorySettings from './pages/CategorySettings';
import DashboardLayout from './components/layout/DashboardLayout';
import './App.css';

import { Toaster } from 'react-hot-toast';

function App() {
  return (
    <ThemeProvider>
      <Toaster position="top-right" reverseOrder={false} />
      <Router>
        <Routes>
          <Route path="/login" element={<Auth />} />
          <Route element={<DashboardLayout children={<Outlet />} />}>
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/my-tasks" element={<MyTasks />} />
            <Route path="/my-team" element={<MyTeam />} />
            <Route path="/my-team/:teamId" element={<MyTeam />} />
            <Route path="/add-user" element={<AddUserPage />} />
            <Route path="/settings" element={<Settings />} />
              <Route path="/settings/:tab" element={<Settings />} />
            <Route path="/groups" element={<GroupTasks />} />
            <Route path="/groups/:id" element={<GroupTasks />} />
            <Route path="/delegated-tasks" element={<DelegatedTasks />} />
            <Route path="/all-tasks" element={<AllTasks />} />
            <Route path="/deleted-tasks" element={<DeletedTasks />} />
            <Route path="/holidays" element={<Holidays />} />
            <Route path="/idea-board" element={<Dashboard />} />
            <Route path="/in-loop-tasks" element={<InLoopTasks />} />
            <Route path="/task-templates" element={<TaskTemplates />} />
            <Route path="/activities" element={<Activities />} />
          </Route>
          <Route path="/" element={<Navigate to="/login" replace />} />
        </Routes>
      </Router>
    </ThemeProvider>
  );
}

export default App;
