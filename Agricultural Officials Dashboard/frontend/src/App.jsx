import './App.css';
import React, { useState, useEffect } from 'react';
import { ShieldAlert, Microscope, Target, X, Zap, Download, Database, CheckCircle, Search, Settings, Activity, ChevronRight, FileText, AlertTriangle } from 'lucide-react';

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [activeTab, setActiveTab] = useState("TRIAGE");
  const [stats, setStats] = useState({ total_active_outbreaks: 0, pending_lab_reviews: 0, ai_accuracy_rate: 0 });
  const [tickets, setTickets] = useState([]);
  const [activity, setActivity] = useState([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState(null);


  // Filter & Sort States
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [sortOrder, setSortOrder] = useState('DESC');

  // Triage Room Modal State
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [expertName, setExpertName] = useState("Dr. R. Sharma (KVK)");
  const [overrideAi, setOverrideAi] = useState(false);
  const [confirmedDiagnosis, setConfirmedDiagnosis] = useState("");
  const [cibrcAgro, setCibrcAgro] = useState("");
  const [dosage, setDosage] = useState("");
  const [phi, setPhi] = useState("");
  const [advisoryNotes, setAdvisoryNotes] = useState("");
  const [actionType, setActionType] = useState("SEND_ADVISORY");

  const [alStats, setAlStats] = useState({ golden_dataset_count: 0, feature_vector_count: 0, recent_training_tickets: [] });

  const simCount = React.useRef(0);
  const simTickets = React.useRef([]);

  const fetchData = async (isPolling = false) => {
    try {
      const [statsRes, ticketsRes, activityRes, alRes] = await Promise.all([
        fetch('http://127.0.0.1:8002/api/v1/admin/analytics/summary-stats'),
        fetch('http://127.0.0.1:8002/api/v1/admin/triage/tickets'),
        fetch('http://127.0.0.1:8002/api/v1/admin/analytics/recent-activity'),
        fetch('http://127.0.0.1:8002/api/v1/admin/analytics/active-learning-stats')
      ]);
      const newStats = await statsRes.json();
      const newTickets = await ticketsRes.json();
      const newActivity = await activityRes.json();
      const newAl = await alRes.json();

      setTickets(prev => {
        if (isPolling && prev && newTickets.length > prev.length) {
           showToast("New Ticket Received!");
        }
        return newTickets;
      });
      setStats(newStats);
      setActivity(newActivity);
      
      // Inject simulated active learning data for demo purposes
      setAlStats({
        golden_dataset_count: newAl.golden_dataset_count + simCount.current,
        feature_vector_count: newAl.feature_vector_count + simCount.current,
        recent_training_tickets: [...simTickets.current, ...newAl.recent_training_tickets]
      });
    } catch (e) {
      console.error("Fetch Error:", e);
    } finally {
      if (!isPolling) setLoading(false);
    }
  };

  const showToast = (msg) => {
    setToast(msg);
    setTimeout(() => setToast(null), 5000);
  };

  useEffect(() => {
    fetchData();
    const interval = setInterval(() => {
      fetchData(true);
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  const openTriageRoom = (ticket) => {
    setSelectedTicket(ticket);
    setOverrideAi(false);
    setConfirmedDiagnosis(ticket.ai_prediction);
    setCibrcAgro("");
    setDosage("");
    setPhi("");
    setAdvisoryNotes("");
    setActionType("SEND_ADVISORY");
  };

  const submitTriage = async (e) => {
    e.preventDefault();
    if (!selectedTicket) return;

    const combinedNotes = `[Prescription]\nAgrochemical: ${cibrcAgro || 'N/A'}\nDosage: ${dosage || 'N/A'}\nPHI: ${phi ? phi + ' days' : 'N/A'}\n\n[Notes]\n${advisoryNotes}`;

    try {
      const res = await fetch(`http://127.0.0.1:8002/api/v1/admin/triage/tickets/${selectedTicket.id}/action`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          expert_name: expertName,
          confirmed_diagnosis: overrideAi ? confirmedDiagnosis : selectedTicket.ai_prediction,
          advisory_notes: combinedNotes,
          override_ai: overrideAi,
          action_type: actionType
        })
      });
      
      if (!res.ok) {
         throw new Error(`Server returned ${res.status}`);
      }
      
      showToast("Action dispatched successfully!");
      setSelectedTicket(null);
      fetchData();
    } catch (e) {
      console.error("Submit Error:", e);
      alert("Failed to submit review. Check if the Admin server (port 8002) is running.");
    }
  };

  const getStatusBadge = (status) => {
    switch(status) {
      case "PENDING_REVIEW":
        return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/20 shadow-[0_0_10px_rgba(245,158,11,0.2)]"><AlertTriangle size={12}/> Pending</span>;
      case "EXPERT_DIAGNOSED":
      case "RESOLVED":
        return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 shadow-[0_0_10px_rgba(16,185,129,0.2)]"><CheckCircle size={12}/> Diagnosed</span>;
      case "SAMPLE_SUBMISSION_REQUIRED":
        return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-violet-500/10 text-violet-400 border border-violet-500/20 shadow-[0_0_10px_rgba(139,92,246,0.2)]"><FileText size={12}/> Sample Req.</span>;
      case "CLOSED":
        return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-slate-500/10 text-slate-400 border border-slate-500/20"><CheckCircle size={12}/> Closed</span>;
      default:
        return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/20 shadow-[0_0_10px_rgba(245,158,11,0.2)]">{status}</span>;
    }
  };

  const exportDataset = async (type) => {
    try {
      const res = await fetch(`http://127.0.0.1:8000/api/v1/learning/export-dataset/${type}`);
      const data = await res.json();
      showToast(`Export Complete! Saved to: ${data.export_path}`);
    } catch(e) {
      alert("Export failed: Ensure Farmer API (port 8000) is running.");
    }
  };

  const filteredTickets = tickets
    .filter(t => statusFilter === 'ALL' || t.status === statusFilter)
    .filter(t => 
      t.ticket_code.toLowerCase().includes(searchTerm.toLowerCase()) || 
      t.farmer_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      t.crop_name.toLowerCase().includes(searchTerm.toLowerCase())
    )
    .sort((a, b) => sortOrder === 'DESC' ? b.id - a.id : a.id - b.id);

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center font-sans">
        <div className="fixed top-[-20%] left-[-10%] w-[50%] h-[50%] rounded-full bg-emerald-400/20 blur-[120px] pointer-events-none"></div>
        <div className="fixed bottom-[-20%] right-[-10%] w-[50%] h-[50%] rounded-full bg-indigo-400/20 blur-[120px] pointer-events-none"></div>
        
        <div className="bg-white/80 backdrop-blur-2xl border border-slate-200 p-10 rounded-3xl shadow-xl w-full max-w-md relative z-10">
          <div className="text-center mb-10">
            <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-emerald-500 to-teal-600 shadow-[0_4px_20px_rgba(16,185,129,0.3)] flex items-center justify-center text-white mx-auto mb-6">
              <Activity size={32} />
            </div>
            <h1 className="text-3xl font-black text-transparent bg-clip-text bg-gradient-to-r from-emerald-800 to-teal-800">AgriShield</h1>
            <p className="text-sm text-emerald-600 font-bold uppercase tracking-widest mt-2">Command Center Login</p>
          </div>
          
          <form onSubmit={(e) => { e.preventDefault(); setIsAuthenticated(true); }} className="space-y-6">
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-2 uppercase tracking-wider">Admin ID</label>
              <div className="relative">
                <input type="text" className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-10 pr-4 py-3.5 text-slate-800 focus:outline-none focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all shadow-sm" placeholder="Enter ID..." defaultValue="admin.kvk" />
                <Settings size={18} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" />
              </div>
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-2 uppercase tracking-wider">Passcode</label>
              <div className="relative">
                <input type="password" className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-10 pr-4 py-3.5 text-slate-800 focus:outline-none focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 transition-all shadow-sm" placeholder="••••••••" defaultValue="password123" />
                <AlertTriangle size={18} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" />
              </div>
            </div>
            
            <button type="submit" className="w-full py-4 rounded-xl font-black tracking-widest uppercase bg-emerald-500 hover:bg-emerald-600 text-white shadow-[0_4px_15px_rgba(16,185,129,0.3)] hover:shadow-[0_6px_25px_rgba(16,185,129,0.4)] transition-all duration-300 mt-4 flex items-center justify-center gap-2">
              Secure Login <ChevronRight size={18} />
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 font-sans tracking-wide selection:bg-emerald-500/30 overflow-hidden relative">
      
      {/* Background Ambient Glow */}
      <div className="fixed top-[-20%] left-[-10%] w-[50%] h-[50%] rounded-full bg-emerald-400/20 blur-[120px] pointer-events-none"></div>
      <div className="fixed bottom-[-20%] right-[-10%] w-[50%] h-[50%] rounded-full bg-indigo-400/20 blur-[120px] pointer-events-none"></div>

      {/* Main Layout */}
      <div className="flex h-screen overflow-hidden">
        
        {/* Sidebar */}
        <aside className="w-72 bg-white border-r border-slate-200 backdrop-blur-3xl flex flex-col z-10 relative shadow-sm">
          <div className="p-8 pb-4">
            <div className="flex items-center gap-4 mb-2">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 shadow-md flex items-center justify-center text-white relative">
                <Activity size={24} />
                <div className="absolute top-0 right-0 w-3 h-3 bg-white rounded-full border-2 border-teal-600 animate-ping"></div>
              </div>
              <div>
                <h1 className="text-xl font-black text-transparent bg-clip-text bg-gradient-to-r from-emerald-800 to-teal-800 tracking-tight">AgriShield</h1>
                <p className="text-[10px] text-emerald-600 font-bold uppercase tracking-widest mt-0.5">Command Center</p>
              </div>
            </div>
          </div>

          <nav className="flex-1 px-4 py-8 space-y-2">
            {[
              { id: 'TRIAGE', icon: <Target size={20} />, label: 'Triage Queue' },
              { id: 'LEARNING', icon: <Database size={20} />, label: 'Active Learning' }
            ].map(tab => (
              <button 
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`w-full flex items-center justify-between px-4 py-3.5 rounded-xl transition-all duration-300 group ${activeTab === tab.id ? 'bg-emerald-50 border border-emerald-200 text-emerald-700 shadow-sm' : 'text-slate-500 hover:bg-slate-100 hover:text-slate-800 border border-transparent'}`}
              >
                <div className="flex items-center gap-3 font-semibold text-sm">
                  <span className={activeTab === tab.id ? 'text-emerald-600' : 'text-slate-400 group-hover:text-slate-600 transition-colors'}>{tab.icon}</span>
                  {tab.label}
                </div>
                {activeTab === tab.id && <ChevronRight size={16} className="text-emerald-500/70" />}
              </button>
            ))}
          </nav>

          <div className="p-6 border-t border-slate-200">
            <div className="bg-slate-50 rounded-xl p-4 border border-slate-200 flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-slate-200 to-slate-100 border border-slate-300 flex items-center justify-center font-bold text-slate-700 shadow-sm">
                RS
              </div>
              <div className="flex-1 overflow-hidden">
                <p className="text-sm font-bold text-slate-900 truncate">{expertName}</p>
                <p className="text-[10px] text-emerald-600 uppercase tracking-wider font-semibold">Chief Agronomist</p>
              </div>
            </div>
          </div>
        </aside>

        {/* Main Content Area */}
        <main className="flex-1 h-screen overflow-y-auto relative scroll-smooth">
          <div className="max-w-7xl mx-auto p-10 pb-24">
            
            {activeTab === "TRIAGE" && (
              <div className="space-y-8 animate-fade-in">
                {/* Header Section */}
                <div className="flex justify-between items-end mb-10">
                  <div>
                    <h2 className="text-3xl font-bold text-slate-900 tracking-tight mb-2">Triage Operations</h2>
                    <p className="text-slate-500 text-sm">Monitor, diagnose, and dispatch advisories for incoming field anomalies.</p>
                  </div>
                  <div className="flex gap-4">
                    <div className="px-4 py-2 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-700 text-sm font-semibold flex items-center gap-2">
                      <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                      System Online
                    </div>
                  </div>
                </div>

                {/* KPI Cards */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <div className="bg-white border border-slate-200 shadow-sm rounded-2xl p-6 relative overflow-hidden group hover:border-red-300 transition-colors">
                    <div className="absolute -right-6 -top-6 text-red-50 group-hover:scale-110 transition-transform duration-500"><ShieldAlert size={140} /></div>
                    <div className="flex justify-between items-start mb-6">
                      <div className="p-3 bg-red-50 rounded-xl text-red-600 border border-red-100"><ShieldAlert size={20} /></div>
                    </div>
                    <h2 className="text-5xl font-black text-slate-900 mb-2">{stats.total_active_outbreaks}</h2>
                    <p className="text-sm font-medium text-red-600 uppercase tracking-wider">Active Outbreaks</p>
                  </div>

                  <div className="bg-white border border-slate-200 shadow-sm rounded-2xl p-6 relative overflow-hidden group hover:border-amber-300 transition-colors">
                    <div className="absolute -right-6 -top-6 text-amber-50 group-hover:scale-110 transition-transform duration-500"><Microscope size={140} /></div>
                    <div className="flex justify-between items-start mb-6">
                      <div className="p-3 bg-amber-50 rounded-xl text-amber-600 border border-amber-100"><Microscope size={20} /></div>
                    </div>
                    <h2 className="text-5xl font-black text-slate-900 mb-2">{stats.pending_lab_reviews}</h2>
                    <p className="text-sm font-medium text-amber-600 uppercase tracking-wider">Pending Review</p>
                  </div>

                  <div className="bg-white border border-slate-200 shadow-sm rounded-2xl p-6 relative overflow-hidden group hover:border-indigo-300 transition-colors">
                    <div className="absolute -right-6 -top-6 text-indigo-50 group-hover:scale-110 transition-transform duration-500"><Target size={140} /></div>
                    <div className="flex justify-between items-start mb-6">
                      <div className="p-3 bg-indigo-50 rounded-xl text-indigo-600 border border-indigo-100"><Target size={20} /></div>
                    </div>
                    <h2 className="text-5xl font-black text-slate-900 mb-2">{stats.ai_accuracy_rate}%</h2>
                    <p className="text-sm font-medium text-indigo-600 uppercase tracking-wider">AI Accuracy Rate</p>
                  </div>
                </div>

                {/* Data Table */}
                <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-md mt-8">
                  <div className="p-5 border-b border-slate-200 flex flex-col md:flex-row justify-between items-center gap-4 bg-slate-50">
                    <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                      <Activity className="text-emerald-600" size={20} /> Live Surveillance Queue
                    </h3>
                    <div className="flex gap-3 items-center w-full md:w-auto">
                      <div className="relative flex-1 md:w-64">
                        <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" />
                        <input type="text" placeholder="Search ID, Crop, Farmer..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)} className="w-full bg-white border border-slate-200 text-sm rounded-xl pl-10 pr-4 py-2.5 focus:border-emerald-400 focus:ring-1 focus:ring-emerald-400 outline-none text-slate-800 placeholder-slate-400 transition-all shadow-sm" />
                      </div>
                      <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} className="bg-white border border-slate-200 text-sm rounded-xl px-4 py-2.5 focus:border-emerald-400 outline-none text-slate-700 cursor-pointer appearance-none min-w-[140px] shadow-sm">
                        <option value="ALL">All Statuses</option>
                        <option value="PENDING_REVIEW">Pending Review</option>
                        <option value="EXPERT_DIAGNOSED">Diagnosed</option>
                        <option value="SAMPLE_SUBMISSION_REQUIRED">Sample Required</option>
                        <option value="CLOSED">Closed</option>
                      </select>
                    </div>
                  </div>
                  
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm whitespace-nowrap">
                      <thead className="bg-slate-50 text-slate-500 text-xs font-semibold tracking-wider">
                        <tr>
                          <th className="px-6 py-4 border-b border-slate-200 font-medium">Ticket ID</th>
                          <th className="px-6 py-4 border-b border-slate-200 font-medium">Farmer & Location</th>
                          <th className="px-6 py-4 border-b border-slate-200 font-medium">Crop & AI Guess</th>
                          <th className="px-6 py-4 border-b border-slate-200 font-medium">Confidence</th>
                          <th className="px-6 py-4 border-b border-slate-200 font-medium">Status</th>
                          <th className="px-6 py-4 border-b border-slate-200 text-right font-medium">Action</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {filteredTickets.map((t, i) => (
                          <tr key={i} className="hover:bg-slate-50 transition-colors group">
                            <td className="px-6 py-4 font-mono text-emerald-600 font-medium">{t.ticket_code}</td>
                            <td className="px-6 py-4">
                              <div className="font-semibold text-slate-900 group-hover:text-emerald-700 transition-colors">{t.farmer_name}</div>
                              <div className="text-xs text-slate-500 mt-1">{t.district || "Nashik"} District</div>
                            </td>
                            <td className="px-6 py-4">
                              <div className="font-medium text-slate-800">{t.crop_name}</div>
                              <div className="text-xs text-slate-500 mt-1">{t.ai_prediction}</div>
                            </td>
                            <td className="px-6 py-4">
                              <div className="flex items-center gap-3">
                                <div className="w-24 bg-slate-200 rounded-full h-1.5 overflow-hidden border border-slate-200">
                                  <div className={`h-full rounded-full ${t.ai_confidence < 0.6 ? 'bg-red-500' : t.ai_confidence < 0.75 ? 'bg-amber-500' : 'bg-emerald-500'}`} style={{width: `${Math.min(t.ai_confidence * 100, 100)}%`}}></div>
                                </div>
                                <span className="text-xs font-semibold text-slate-600">{(t.ai_confidence * 100).toFixed(1)}%</span>
                              </div>
                            </td>
                            <td className="px-6 py-4">
                              {getStatusBadge(t.status)}
                            </td>
                            <td className="px-6 py-4 text-right">
                              <button 
                                onClick={() => openTriageRoom(t)}
                                className="px-4 py-2 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 text-emerald-700 font-semibold rounded-lg transition-all text-xs uppercase tracking-wider shadow-sm">
                                Open Room
                              </button>
                            </td>
                          </tr>
                        ))}
                        {filteredTickets.length === 0 && !loading && (
                          <tr><td colSpan="6" className="px-6 py-16 text-center text-slate-400">
                            <div className="flex flex-col items-center justify-center">
                              <CheckCircle size={48} className="text-slate-300 mb-4" />
                              <p className="text-lg font-medium text-slate-500">Queue is clear.</p>
                              <p className="text-sm text-slate-400 mt-1">No active tickets matching the current filters.</p>
                            </div>
                          </td></tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}

            {activeTab === "LEARNING" && (
              <div className="space-y-8 animate-fade-in">
                <div className="mb-10 flex justify-between items-start">
                  <div>
                    <h2 className="text-3xl font-bold text-slate-900 tracking-tight mb-2">Active Learning Hub</h2>
                    <p className="text-slate-500 text-sm max-w-2xl">Track human-verified overrides. Export these verified datasets directly into YOLO or XGBoost pipelines to continuously improve AI accuracy.</p>
                  </div>
                  <button onClick={() => {
                    simCount.current += 1;
                    simTickets.current = [
                      {
                        ticket_code: `TKT-${Math.floor(1000 + Math.random() * 9000)}`,
                        crop: "Cotton",
                        disease: "Pink Bollworm (Verified)",
                        timestamp: new Date().toISOString()
                      },
                      ...simTickets.current
                    ];
                    fetchData(false);
                    showToast("Simulated data synced from field app.");
                  }} className="px-4 py-2 bg-slate-900 text-white rounded-lg text-sm font-semibold hover:bg-slate-800 transition-colors flex items-center gap-2">
                    <Zap size={16} /> Force Sync Telemetry
                  </button>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                  <div className="bg-white border border-slate-200 shadow-sm rounded-2xl p-8 relative overflow-hidden group">
                    <div className="absolute -right-8 -bottom-8 text-indigo-50 group-hover:scale-110 transition-transform duration-500"><Database size={160} /></div>
                    <div className="relative z-10">
                      <div className="flex items-center gap-3 mb-6">
                        <div className="p-2.5 bg-indigo-50 rounded-lg text-indigo-600 border border-indigo-100"><Database size={20} /></div>
                        <h3 className="text-indigo-600 font-bold uppercase tracking-widest text-sm">Vision AI Dataset</h3>
                      </div>
                      <div className="flex items-end gap-3 mb-4">
                        <span className="text-6xl font-black text-slate-900">{alStats.golden_dataset_count}</span>
                        <span className="text-slate-500 font-medium pb-1.5">/ 200 required</span>
                      </div>
                      <p className="text-sm text-slate-500 mb-6">Next YOLO fine-tuning threshold</p>
                      
                      <div className="w-full bg-slate-100 rounded-full h-2 mb-8 border border-slate-200 overflow-hidden">
                        <div className="bg-gradient-to-r from-indigo-500 to-indigo-400 h-full rounded-full" style={{width: `${Math.min((alStats.golden_dataset_count / 200) * 100, 100)}%`}}></div>
                      </div>
                      
                      <button onClick={() => exportDataset('IMAGE_VISION')} className="w-full py-3.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 border border-indigo-200 font-bold rounded-xl flex items-center justify-center gap-2 transition-all shadow-sm">
                        <Download size={18} /> Export YOLO Format
                      </button>
                    </div>
                  </div>
                  
                  <div className="bg-white border border-slate-200 shadow-sm rounded-2xl p-8 relative overflow-hidden group">
                    <div className="absolute -right-8 -bottom-8 text-teal-50 group-hover:scale-110 transition-transform duration-500"><Activity size={160} /></div>
                    <div className="relative z-10">
                      <div className="flex items-center gap-3 mb-6">
                        <div className="p-2.5 bg-teal-50 rounded-lg text-teal-600 border border-teal-100"><Activity size={20} /></div>
                        <h3 className="text-teal-600 font-bold uppercase tracking-widest text-sm">Weather Risk Model</h3>
                      </div>
                      <div className="flex items-end gap-3 mb-4">
                        <span className="text-6xl font-black text-slate-900">{alStats.feature_vector_count}</span>
                        <span className="text-slate-500 font-medium pb-1.5">outcomes</span>
                      </div>
                      <p className="text-sm text-slate-500 mb-6">Verified feature vectors logged</p>
                      
                      <div className="w-full bg-slate-100 rounded-full h-2 mb-8 border border-slate-200 overflow-hidden">
                        <div className="bg-gradient-to-r from-teal-500 to-teal-400 h-full rounded-full" style={{width: '100%'}}></div>
                      </div>
                      
                      <button onClick={() => exportDataset('WEATHER_RISK')} className="w-full py-3.5 bg-teal-50 hover:bg-teal-100 text-teal-700 border border-teal-200 font-bold rounded-xl flex items-center justify-center gap-2 transition-all shadow-sm">
                        <Download size={18} /> Export XGBoost CSV
                      </button>
                    </div>
                  </div>
                </div>

                <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-md">
                  <div className="px-6 py-5 border-b border-slate-200 bg-slate-50">
                    <h3 className="text-slate-900 font-bold text-lg flex items-center gap-2"><Settings size={18} className="text-slate-500"/> Recent Training Captures</h3>
                  </div>
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="bg-slate-50 text-slate-500 text-xs uppercase tracking-wider font-semibold">
                        <th className="px-6 py-4 border-b border-slate-200 w-1/4">Ticket ID</th>
                        <th className="px-6 py-4 border-b border-slate-200 w-1/4">Crop</th>
                        <th className="px-6 py-4 border-b border-slate-200 w-1/3">Verified Label</th>
                        <th className="px-6 py-4 border-b border-slate-200 w-1/4">Timestamp</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {alStats.recent_training_tickets && alStats.recent_training_tickets.map((t, idx) => (
                        <tr key={idx} className="hover:bg-slate-50 transition-colors">
                          <td className="px-6 py-4 font-mono text-indigo-600 font-medium">{t.ticket_code}</td>
                          <td className="px-6 py-4 text-slate-800 font-medium">{t.crop}</td>
                          <td className="px-6 py-4"><span className="px-3 py-1 bg-emerald-50 text-emerald-600 border border-emerald-200 rounded-lg text-xs font-bold">{t.disease}</span></td>
                          <td className="px-6 py-4 text-slate-500 text-sm">{new Date(t.timestamp).toLocaleDateString()}</td>
                        </tr>
                      ))}
                      {alStats.recent_training_tickets?.length === 0 && (
                        <tr>
                          <td colSpan="4" className="px-6 py-12 text-center text-slate-400 italic">No training data captured yet.</td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>

              </div>
            )}


          </div>
        </main>
      </div>

      {/* Triage Room Modal - Light Redesign */}
      {selectedTicket && (
        <div className="fixed inset-0 z-50 flex animate-fade-in p-6">
          <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" onClick={() => setSelectedTicket(null)}></div>
          
          <div className="relative w-full max-w-6xl m-auto bg-white border border-slate-200 rounded-3xl shadow-2xl flex flex-col md:flex-row overflow-hidden max-h-full">
            
            {/* Left Side: Diagnostics */}
            <div className="w-full md:w-5/12 bg-slate-50 border-r border-slate-200 p-8 flex flex-col relative">
              <button onClick={() => setSelectedTicket(null)} className="absolute top-6 left-6 p-2 bg-white rounded-full hover:bg-slate-100 border border-slate-200 text-slate-600 transition-colors z-10 shadow-sm"><X size={20} /></button>
              
              <div className="mt-12 mb-6">
                <h3 className="text-lg font-bold text-slate-900 tracking-wide">Image Analysis</h3>
                <p className="text-xs text-slate-500">High-resolution field capture</p>
              </div>

              <div className="flex-1 rounded-2xl border border-slate-200 bg-white overflow-hidden relative flex items-center justify-center shadow-inner">
                {selectedTicket.image_url ? (
                  <img src={selectedTicket.image_url} alt="Crop Scan" className="max-w-full max-h-full object-contain" />
                ) : (
                  <div className="text-slate-400 flex flex-col items-center"><Search size={48} className="mb-4 opacity-50"/> No Image Available</div>
                )}

                {/* HUD Overlay */}
                <div className="absolute bottom-4 left-4 right-4 bg-white/90 backdrop-blur-md border border-slate-200 rounded-xl p-4 flex justify-between items-center shadow-lg">
                  <div>
                    <p className="text-[10px] text-slate-500 uppercase tracking-widest mb-1">AI Prediction (Model B)</p>
                    <p className="text-lg font-bold text-slate-900 font-mono">{selectedTicket.ai_prediction}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-[10px] text-slate-500 uppercase tracking-widest mb-1">Confidence</p>
                    <p className={`text-lg font-bold font-mono ${selectedTicket.ai_confidence < 0.6 ? 'text-red-600' : 'text-emerald-600'}`}>
                      {(selectedTicket.ai_confidence * 100).toFixed(1)}%
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Right Side: Action Console */}
            <div className="w-full md:w-7/12 p-8 overflow-y-auto bg-white">
              <div className="flex justify-between items-center mb-8">
                <h2 className="text-2xl font-bold text-slate-900 tracking-wide">Diagnostic Console</h2>
                <span className="px-3 py-1 bg-slate-100 rounded-lg text-xs font-mono text-slate-500 border border-slate-200">ID: {selectedTicket.ticket_code}</span>
              </div>
              
              <form onSubmit={submitTriage} className="space-y-6">
                
                {/* AI Override */}
                <div className={`p-6 rounded-2xl border transition-all duration-300 ${overrideAi ? 'border-indigo-300 bg-indigo-50 shadow-sm' : 'border-slate-200 bg-slate-50'}`}>
                  <label className="flex items-center gap-4 cursor-pointer">
                    <div className="relative flex items-center justify-center">
                      <input type="checkbox" checked={overrideAi} onChange={e => setOverrideAi(e.target.checked)} className="peer sr-only" />
                      <div className="w-6 h-6 rounded border border-slate-300 bg-white peer-checked:bg-indigo-500 peer-checked:border-indigo-500 transition-all"></div>
                      <CheckCircle size={14} className="absolute text-white opacity-0 peer-checked:opacity-100 transition-opacity" />
                    </div>
                    <span className="font-bold text-slate-900 text-lg">Override AI Diagnosis</span>
                  </label>
                  
                  {overrideAi && (
                    <div className="mt-6 pt-6 border-t border-indigo-200 animate-fade-in">
                      <label className="block text-xs font-bold text-indigo-600 uppercase tracking-widest mb-3">Verified Pathogen / Label</label>
                      <input 
                        type="text" 
                        value={confirmedDiagnosis} 
                        onChange={e => setConfirmedDiagnosis(e.target.value)} 
                        className="w-full bg-white border border-indigo-200 rounded-xl px-5 py-3.5 text-slate-900 font-mono focus:outline-none focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400/50 transition-all shadow-sm" 
                        required 
                        placeholder="e.g. Late Blight (Phytophthora infestans)"
                      />
                      <p className="text-[11px] text-slate-500 mt-2 font-medium flex items-center gap-1.5"><Database size={12}/> Automatically queues to Active Learning dataset</p>
                    </div>
                  )}
                </div>

                {/* Prescription */}
                <div className="p-6 rounded-2xl border border-slate-200 bg-slate-50 space-y-5">
                  <h3 className="text-xs font-bold text-slate-500 uppercase tracking-widest">Official Prescription</h3>
                  
                  <div>
                    <label className="block text-xs font-semibold text-slate-600 mb-2">Agrochemical / Bio-agent (CIBRC Approved)</label>
                    <input type="text" value={cibrcAgro} onChange={e => setCibrcAgro(e.target.value)} className="w-full bg-white border border-slate-200 rounded-xl px-5 py-3 text-slate-800 focus:outline-none focus:border-emerald-400 transition-all shadow-sm" placeholder="e.g. Mancozeb 75% WP" />
                  </div>
                  
                  <div className="grid grid-cols-2 gap-5">
                    <div>
                      <label className="block text-xs font-semibold text-slate-600 mb-2">Dosage (g/L or ml/L)</label>
                      <input type="text" value={dosage} onChange={e => setDosage(e.target.value)} className="w-full bg-white border border-slate-200 rounded-xl px-5 py-3 text-slate-800 focus:outline-none focus:border-emerald-400 transition-all shadow-sm" placeholder="e.g. 2.0 g/L" />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-600 mb-2">Pre-Harvest Interval (PHI)</label>
                      <input type="number" value={phi} onChange={e => setPhi(e.target.value)} className="w-full bg-white border border-slate-200 rounded-xl px-5 py-3 text-slate-800 focus:outline-none focus:border-emerald-400 transition-all shadow-sm" placeholder="Days" />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-slate-600 mb-2">Farmer Instructions</label>
                    <textarea value={advisoryNotes} onChange={e => setAdvisoryNotes(e.target.value)} rows="3" className="w-full bg-white border border-slate-200 rounded-xl px-5 py-3 text-slate-800 focus:outline-none focus:border-emerald-400 transition-all shadow-sm resize-none" placeholder="Detailed application instructions..."></textarea>
                  </div>
                </div>

                {/* Dispatch Action */}
                <div className="p-6 rounded-2xl border border-slate-200 bg-slate-50">
                  <h3 className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-4">Resolution Action</h3>
                  
                  <div className="space-y-3">
                    <label className={`flex items-center p-4 rounded-xl border cursor-pointer transition-all duration-300 ${actionType === 'SEND_ADVISORY' ? 'border-emerald-300 bg-emerald-50 shadow-sm' : 'border-slate-200 bg-white hover:bg-slate-50'}`}>
                      <input type="radio" name="action" checked={actionType === 'SEND_ADVISORY'} onChange={() => setActionType('SEND_ADVISORY')} className="sr-only" />
                      <div className={`w-5 h-5 rounded-full border-2 mr-4 flex items-center justify-center ${actionType === 'SEND_ADVISORY' ? 'border-emerald-500' : 'border-slate-300'}`}>
                        {actionType === 'SEND_ADVISORY' && <div className="w-2.5 h-2.5 rounded-full bg-emerald-500"></div>}
                      </div>
                      <div className="flex flex-col"><span className={`font-bold ${actionType === 'SEND_ADVISORY' ? 'text-emerald-700' : 'text-slate-800'}`}>Send Official Advisory</span><span className="text-xs text-slate-500 mt-0.5">Pushes prescription instantly to Farmer App</span></div>
                    </label>

                    <label className={`flex items-center p-4 rounded-xl border cursor-pointer transition-all duration-300 ${actionType === 'REQUEST_PHYSICAL_SAMPLE' ? 'border-violet-300 bg-violet-50 shadow-sm' : 'border-slate-200 bg-white hover:bg-slate-50'}`}>
                      <input type="radio" name="action" checked={actionType === 'REQUEST_PHYSICAL_SAMPLE'} onChange={() => setActionType('REQUEST_PHYSICAL_SAMPLE')} className="sr-only" />
                      <div className={`w-5 h-5 rounded-full border-2 mr-4 flex items-center justify-center ${actionType === 'REQUEST_PHYSICAL_SAMPLE' ? 'border-violet-500' : 'border-slate-300'}`}>
                        {actionType === 'REQUEST_PHYSICAL_SAMPLE' && <div className="w-2.5 h-2.5 rounded-full bg-violet-500"></div>}
                      </div>
                      <div className="flex flex-col"><span className={`font-bold ${actionType === 'REQUEST_PHYSICAL_SAMPLE' ? 'text-violet-700' : 'text-slate-800'}`}>Request Physical Sample</span><span className="text-xs text-slate-500 mt-0.5">Generates mailing instructions for lab testing</span></div>
                    </label>
                  </div>
                </div>

                <button type="submit" className="w-full py-4 rounded-xl font-black tracking-widest uppercase bg-emerald-500 hover:bg-emerald-600 text-white shadow-lg transition-all duration-300 flex justify-center items-center gap-2 mt-4">
                  <CheckCircle size={20} /> Finalize & Dispatch
                </button>

              </form>
            </div>
          </div>
        </div>
      )}

      {/* Modern Toast Notification */}
      {toast && (
        <div className="fixed bottom-8 right-8 bg-white/95 backdrop-blur-xl text-slate-800 px-6 py-4 rounded-2xl shadow-xl border border-slate-200 flex items-center gap-4 animate-fade-in z-50">
          <div className="w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-600 border border-emerald-200">
            <CheckCircle size={16} />
          </div>
          <div>
            <p className="font-bold text-sm text-slate-900">System Update</p>
            <p className="text-xs text-slate-500 mt-0.5">{toast}</p>
          </div>
        </div>
      )}

    </div>
  );
}
