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
  
  // State for multiple holiday entries
  const [holidayFields, setHolidayFields] = useState([
    { name: '', date: null, id: Date.now() }
  ]);
  
  const [activeDatePickerIndex, setActiveDatePickerIndex] = useState(null);
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

  const addHolidayField = () => {
    setHolidayFields([...holidayFields, { name: '', date: null, id: Date.now() }]);
  };

  const removeHolidayField = (index) => {
    if (holidayFields.length === 1) return;
    setHolidayFields(holidayFields.filter((_, i) => i !== index));
    if (activeDatePickerIndex === index) setActiveDatePickerIndex(null);
  };

  const updateHolidayField = (index, field, value) => {
    const updated = [...holidayFields];
    updated[index][field] = value;
    setHolidayFields(updated);
  };

  const handleAddHoliday = async () => {
    const validHolidays = holidayFields.filter(h => h.name.trim() && h.date);
    
    if (validHolidays.length === 0) {
      toast.error('Please add at least one valid holiday (name and date)');
      return;
    }

    try {
      const submissionData = validHolidays.map(h => ({
        name: h.name.trim(),
        date: `${h.date.getFullYear()}-${String(h.date.getMonth() + 1).padStart(2, '0')}-${String(h.date.getDate()).padStart(2, '0')}`
      }));
      
      await holidayService.createHoliday(submissionData);
      
      toast.success('Holidays added successfully');
      setIsModalOpen(false);
      setHolidayFields([{ name: '', date: null, id: Date.now() }]);
      fetchHolidays();
    } catch (error) {
      toast.error('Failed to add holidays');
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
            
            <div className="p-5 max-h-[450px] overflow-y-auto space-y-5 custom-scrollbar">
              {holidayFields.map((field, index) => (
                <div key={field.id} className="relative p-5 bg-[#1b2128] rounded-2xl border border-gray-700/50 space-y-4 shadow-inner">
                  {holidayFields.length > 1 && (
                    <button 
                      onClick={() => removeHolidayField(index)}
                      className="absolute -top-2 -right-2 px-2 py-1 bg-red-500 hover:bg-red-600 text-white text-[10px] font-black uppercase tracking-widest rounded-lg flex items-center justify-center gap-1 shadow-lg z-10 transition-all active:scale-90"
                    >
                      <X size={12} strokeWidth={3} />
                      Remove
                    </button>
                  )}
                  
                  <div className="space-y-1">
                    <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest px-1">Holiday Name</label>
                    <input 
                      type="text"
                      placeholder="e.g. Diwali House"
                      value={field.name}
                      onChange={(e) => updateHolidayField(index, 'name', e.target.value)}
                      className="w-full bg-[#15191e] border border-gray-700 text-white px-4 py-3 rounded-xl text-sm font-bold focus:outline-none focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/10 transition-all placeholder-gray-600"
                    />
                  </div>
                  
                  <div className="space-y-1">
                    <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest px-1">Selected Date</label>
                    <div className="relative">
                      <button 
                        onClick={() => setActiveDatePickerIndex(activeDatePickerIndex === index ? null : index)}
                        className={`w-full bg-[#15191e] border border-gray-700 px-4 py-3 rounded-xl text-sm font-bold flex items-center justify-between focus:outline-none focus:border-emerald-500 transition-all group ${field.date ? 'text-white' : 'text-gray-500'}`}
                      >
                        <div className="flex items-center gap-3">
                          <Calendar size={18} className="text-emerald-400" />
                          {field.date ? field.date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }) : 'Pick a Date'}
                        </div>
                        <ChevronDown size={14} className={`transition-transform duration-200 ${activeDatePickerIndex === index ? 'rotate-180' : ''}`} />
                      </button>
                    </div>

                    {activeDatePickerIndex === index && (
                      <div className="absolute top-full left-0 right-0 mt-2 bg-[#232a32] border border-gray-700 rounded-xl shadow-2xl z-[110] p-4 scale-100 animate-in fade-in zoom-in-95 duration-200">
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
                                const isSelected = isSameDate(field.date, dateObj);
                                return (
                                    <div key={d} className="flex justify-center items-center h-8">
                                        <button 
                                          onClick={() => { updateHolidayField(index, 'date', dateObj); setActiveDatePickerIndex(null); }} 
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
              ))}
              
              <button 
                onClick={addHolidayField}
                className="w-full py-3 bg-[#1e252c] border-2 border-dashed border-gray-700 rounded-2xl text-gray-400 hover:text-emerald-400 hover:border-emerald-500/50 hover:bg-emerald-500/5 transition-all text-xs font-bold flex items-center justify-center gap-2"
              >
                <Plus size={14} />
                Add More Holiday
              </button>
            </div>

            <div className="px-6 py-4 flex justify-end gap-3 border-t border-gray-800 bg-[#1b2128] rounded-b-2xl">
              <button 
                onClick={() => {
                  setIsModalOpen(false);
                  setHolidayFields([{ name: '', date: null, id: Date.now() }]);
                  setActiveDatePickerIndex(null);
                }}
                className="px-4 py-2 rounded-xl text-sm font-bold text-gray-400 hover:text-white hover:bg-gray-800 transition-all"
              >
                Cancel
              </button>
              <button 
                onClick={handleAddHoliday}
                className="bg-emerald-500 hover:bg-emerald-600 text-white px-5 py-2 rounded-xl text-sm font-bold transition-all shadow-lg shadow-emerald-500/20"
              >
                Add Holidays
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Holidays;
