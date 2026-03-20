import React, { useState, useEffect } from 'react';
import { Plus, Trash2, Calendar, X, ChevronLeft, ChevronRight } from 'lucide-react';
import toast from 'react-hot-toast';
import holidayService from '../services/holidayService';

const getDaysInMonth = (year, month) => new Date(year, month + 1, 0).getDate();
const getFirstDayOfMonth = (year, month) => new Date(year, month, 1).getDay();

const Holidays = () => {
  const [holidays, setHolidays] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [newHolidayName, setNewHolidayName] = useState('');
  const [selectedDate, setSelectedDate] = useState(null);
  const [isDatePickerOpen, setIsDatePickerOpen] = useState(false);
  const [currentCalMonth, setCurrentCalMonth] = useState(new Date());

  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const userRole = (user?.user?.role || user?.role || '').toUpperCase();
  const isAdmin = userRole === 'SUPERADMIN' || userRole === 'ADMIN';

  useEffect(() => {
    fetchHolidays();
  }, []);

  const fetchHolidays = async () => {
    try {
      setIsLoading(true);
      const data = await holidayService.getHolidays();
      setHolidays(data);
    } catch (error) {
      toast.error('Failed to fetch holidays');
      console.error(error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleDelete = async (id) => {
    try {
      await holidayService.deleteHoliday(id);
      toast.success('Holiday deleted successfully');
      fetchHolidays();
    } catch (error) {
      toast.error('Failed to delete holiday');
      console.error(error);
    }
  };

  const handleAddHoliday = async () => {
    if (!newHolidayName.trim()) {
      toast.error('Please enter a holiday name');
      return;
    }
    if (!selectedDate) {
      toast.error('Please select a date');
      return;
    }

    try {
      const formattedDate = `${selectedDate.getFullYear()}-${String(selectedDate.getMonth() + 1).padStart(2, '0')}-${String(selectedDate.getDate()).padStart(2, '0')}`;
      
      await holidayService.createHoliday({
        name: newHolidayName,
        date: formattedDate
      });
      
      toast.success('Holiday added successfully');
      setIsModalOpen(false);
      setNewHolidayName('');
      setSelectedDate(null);
      fetchHolidays();
    } catch (error) {
      toast.error('Failed to add holiday');
      console.error(error);
    }
  };

  const isSameDate = (d1, d2) => d1 && d2 && d1.getDate() === d2.getDate() && d1.getMonth() === d2.getMonth() && d1.getFullYear() === d2.getFullYear();

  return (
    <div className="flex-1 w-full max-w-6xl mx-auto">
      
      {/* Header section */}
      {isAdmin && (
        <div className="mb-6 flex">
          <button 
            onClick={() => setIsModalOpen(true)}
            className="bg-emerald-400 hover:bg-emerald-500 text-white px-4 py-2 rounded flex items-center gap-2 font-medium transition-colors"
          >
            <Plus size={18} />
            Holiday
          </button>
        </div>
      )}

      {/* Table section */}
      <div className="w-full border border-gray-100 rounded md:max-w-6xl mx-auto shadow-sm">
        <div className={`bg-emerald-400 text-white grid ${isAdmin ? 'grid-cols-3' : 'grid-cols-2'} p-3 font-medium text-sm rounded-t`}>
          <div>Holiday</div>
          <div className="text-center">Date</div>
          {isAdmin && <div className="text-right pr-4">Action</div>}
        </div>
        
        {isLoading ? (
          <div className="p-8 text-center text-gray-500">Loading...</div>
        ) : holidays.length === 0 ? (
          <div className="p-16 flex flex-col items-center justify-center text-center">
            <h3 className="text-xl font-bold text-gray-800 mb-2">Empty List</h3>
            <p className="text-gray-500 text-sm">No Holidays Found</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {holidays.map((holiday) => (
              <div key={holiday.id} className={`grid ${isAdmin ? 'grid-cols-3' : 'grid-cols-2'} p-4 items-center hover:bg-gray-50 transition-colors`}>
                <div className="font-medium text-gray-800">{holiday.name}</div>
                <div className="text-center text-gray-600">
                  {new Date(holiday.date).toLocaleDateString()}
                </div>
                {isAdmin && (
                  <div className="text-right pr-4 flex justify-end">
                    <button 
                      onClick={() => handleDelete(holiday.id)}
                      className="text-red-500 hover:text-red-700 bg-red-50 hover:bg-red-100 p-2 rounded-full transition-colors"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Add Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-[#1b2128] border border-gray-800 rounded-2xl w-full max-w-sm relative shadow-2xl animate-in zoom-in-95 duration-200">
            <div className="flex justify-between items-center px-6 py-4 border-b border-gray-800">
              <h2 className="text-white text-base font-bold">Add New Holiday</h2>
              <button 
                onClick={() => setIsModalOpen(false)}
                className="text-gray-400 hover:text-white transition-colors"
                title="Close"
              >
                <X size={18} />
              </button>
            </div>
            
            <div className="p-5 space-y-4">
              <div>
                <input 
                  type="text"
                  placeholder="Holiday Name"
                  value={newHolidayName}
                  onChange={(e) => setNewHolidayName(e.target.value)}
                  className="w-full bg-[#1e252c] border border-gray-700 text-white px-4 py-2.5 rounded-xl text-sm focus:outline-none focus:border-emerald-500 transition-colors placeholder-gray-500"
                />
              </div>
              
              <div className="relative">
                <button 
                  onClick={() => setIsDatePickerOpen(!isDatePickerOpen)}
                  className="w-full bg-[#1e252c] border border-gray-700 text-gray-400 px-4 py-2.5 rounded-xl text-sm flex items-center gap-3 focus:outline-none focus:border-emerald-500 transition-colors hover:bg-[#232a32]"
                >
                  <Calendar size={16} className="text-emerald-400" />
                  {selectedDate ? selectedDate.toLocaleDateString() : 'Select Date'}
                </button>

                {isDatePickerOpen && (
                  <div className="absolute top-full left-0 right-0 mt-2 bg-[#232a32] border border-gray-700 rounded-xl shadow-xl z-50 p-4">
                    <div className="flex items-center justify-between mb-4">
                      <div className="flex items-center gap-1">
                        <select 
                          value={currentCalMonth.getMonth()} 
                          onChange={(e) => setCurrentCalMonth(new Date(currentCalMonth.getFullYear(), parseInt(e.target.value), 1))}
                          className="bg-transparent text-white font-bold text-xs outline-none cursor-pointer hover:text-emerald-400 appearance-none [&>option]:bg-[#232a32]"
                        >
                          {['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'].map((m, i) => (
                            <option key={m} value={i}>{m}</option>
                          ))}
                        </select>
                        <select 
                          value={currentCalMonth.getFullYear()} 
                          onChange={(e) => setCurrentCalMonth(new Date(parseInt(e.target.value), currentCalMonth.getMonth(), 1))}
                          className="bg-transparent text-white font-bold text-xs outline-none cursor-pointer hover:text-emerald-400 appearance-none [&>option]:bg-[#232a32]"
                        >
                          {Array.from({ length: 15 }).map((_, i) => {
                            const year = new Date().getFullYear() - 5 + i;
                            return <option key={year} value={year}>{year}</option>
                          })}
                        </select>
                      </div>
                      <div className="flex items-center gap-2">
                        <button onClick={() => setCurrentCalMonth(new Date(currentCalMonth.getFullYear(), currentCalMonth.getMonth() - 1, 1))} className="text-gray-400 hover:text-white p-1 rounded transition-colors"><ChevronLeft size={16} /></button>
                        <button onClick={() => setCurrentCalMonth(new Date(currentCalMonth.getFullYear(), currentCalMonth.getMonth() + 1, 1))} className="text-gray-400 hover:text-white p-1 rounded transition-colors"><ChevronRight size={16} /></button>
                      </div>
                    </div>
                    
                    <div className="grid grid-cols-7 gap-1 text-center mb-2">
                        {['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d, index) => <div key={index} className="text-xs font-semibold text-gray-500 py-1">{d}</div>)}
                        {Array.from({ length: getFirstDayOfMonth(currentCalMonth.getFullYear(), currentCalMonth.getMonth()) }).map((_, i) => <div key={`blank-${i}`} />)}
                        {Array.from({ length: getDaysInMonth(currentCalMonth.getFullYear(), currentCalMonth.getMonth()) }).map((_, i) => {
                            const d = i + 1;
                            const dateObj = new Date(currentCalMonth.getFullYear(), currentCalMonth.getMonth(), d);
                            const isSelected = isSameDate(selectedDate, dateObj);
                            return (
                                <div key={d} className="flex justify-center items-center h-8">
                                    <button 
                                      onClick={() => { setSelectedDate(dateObj); setIsDatePickerOpen(false); }} 
                                      className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-medium transition-all ${isSelected ? 'bg-emerald-500 text-white shadow-lg' : 'text-gray-300 hover:bg-gray-700'}`}
                                    >
                                        {d}
                                    </button>
                                </div>
                            );
                        })}
                    </div>
                  </div>
                )}
              </div>
            </div>

            <div className="px-6 py-4 flex justify-end gap-3 border-t border-gray-800">
              <button 
                onClick={() => setIsModalOpen(false)}
                className="px-4 py-2 rounded-xl text-sm font-bold text-gray-400 hover:text-white hover:bg-gray-800 transition-all"
              >
                Cancel
              </button>
              <button 
                onClick={handleAddHoliday}
                className="bg-emerald-500 hover:bg-emerald-600 text-white px-5 py-2 rounded-xl text-sm font-bold transition-all shadow-lg shadow-emerald-500/20"
              >
                Add Holiday
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Holidays;
