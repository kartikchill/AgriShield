import React, { useState, useEffect } from 'react';
import { ShieldAlert, Microscope, Target, X, Zap, Download, Database, CheckCircle, Search, Settings } from 'lucide-react';

export default function App() {
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
        // If polling and we got a new ticket (higher count or new id)
        if (isPolling && prev && newTickets.length > prev.length) {
           showToast("New Ticket Received!");
        }
        return newTickets;
      });
      setStats(newStats);
      setActivity(newActivity);
      setAlStats(newAl);
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
    // Start seamless notification polling
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

    // Format the combined advisory for the DB schema
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
      
      alert("Action dispatched successfully!");
      setSelectedTicket(null);
      fetchData();
    } catch (e) {
      console.error("Submit Error:", e);
      alert("Failed to submit review. Check if the Admin server (port 8002) is running.");
    }
  };

  const getStatusGlow = (status) => {
    if (status === "PENDING_REVIEW") return "shadow-glow-amber border-amber-500/50 text-amber-400";
    if (status === "EXPERT_DIAGNOSED" || status === "RESOLVED") return "shadow-glow-green border-emerald-500/50 text-emerald-400";
    if (status === "SAMPLE_SUBMISSION_REQUIRED") return "shadow-glow-violet border-violet-500/50 text-violet-400";
    if (status === "CLOSED") return "border-slate-600 text-slate-400";
    return "shadow-glow-amber border-amber-500/50 text-amber-400";
  };

  const exportDataset = async (type) => {
    try {
      const res = await fetch(`http://127.0.0.1:8000/api/v1/learning/export-dataset/${type}`);
      const data = await res.json();
      alert(`Export Complete! Saved to: ${data.export_path}`);
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

  return (
    <div className="min-h-screen bg-cmdBg text-slate-200 font-sans tracking-wide selection:bg-indigo-500/30">
      
      {/* Top Navbar */}
      <nav className="backdrop-blur-md bg-cmdSurface/80 border-b border-cmdBorder px-8 py-4 flex justify-between items-center sticky top-0 z-10">
        <div className="flex items-center gap-4">
          <div className="w-10 h-10 rounded shadow-glow-violet bg-violet-600 flex items-center justify-center text-white font-bold text-xl border border-violet-400/50">
            <Zap size={22} />
          </div>
          <div>
            <h1 className="text-xl font-bold text-white tracking-wider">AgriCommand Center</h1>
            <p className="text-xs text-indigo-300 font-medium uppercase tracking-widest">KVK Triage Operations</p>
          </div>
        </div>
        
        <div className="flex gap-4">
          <button 
            onClick={() => setActiveTab("TRIAGE")}
            className={`px-5 py-2 rounded-full font-medium transition-all ${activeTab === "TRIAGE" ? 'bg-indigo-500/20 text-indigo-300 border border-indigo-500/50 shadow-glow-violet' : 'text-slate-400 hover:text-slate-200'}`}>
            Triage Dashboard
          </button>
          <button 
            onClick={() => setActiveTab("LEARNING")}
            className={`px-5 py-2 rounded-full font-medium transition-all ${activeTab === "LEARNING" ? 'bg-indigo-500/20 text-indigo-300 border border-indigo-500/50 shadow-glow-violet' : 'text-slate-400 hover:text-slate-200'}`}>
            Active Learning Hub
          </button>
        </div>
      </nav>

      <div className="max-w-[1600px] mx-auto p-8">
        
        {activeTab === "TRIAGE" && (
          <div className="space-y-8 animate-fade-in">
            {/* KPI Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div className="backdrop-blur-lg bg-cmdCard border border-red-500/30 rounded-2xl p-6 shadow-glow-red relative overflow-hidden group">
                <div className="absolute -right-4 -top-4 text-red-500/10 group-hover:scale-110 transition-transform"><ShieldAlert size={120} /></div>
                <p className="text-sm font-semibold text-red-400 uppercase tracking-widest mb-1">Active Outbreak Clusters</p>
                <h2 className="text-5xl font-bold text-white drop-shadow-md">{stats.total_active_outbreaks}</h2>
                <p className="text-xs mt-3 text-red-300/70 font-medium">Critical talukas requiring immediate action</p>
              </div>

              <div className="backdrop-blur-lg bg-cmdCard border border-amber-500/30 rounded-2xl p-6 shadow-glow-amber relative overflow-hidden group">
                <div className="absolute -right-4 -top-4 text-amber-500/10 group-hover:scale-110 transition-transform"><Microscope size={120} /></div>
                <p className="text-sm font-semibold text-amber-400 uppercase tracking-widest mb-1">Pending KVK Triage Queue</p>
                <h2 className="text-5xl font-bold text-white drop-shadow-md">{stats.pending_lab_reviews}</h2>
                <p className="text-xs mt-3 text-amber-300/70 font-medium">Tickets awaiting official diagnosis</p>
              </div>

              <div className="backdrop-blur-lg bg-cmdCard border border-indigo-500/30 rounded-2xl p-6 shadow-glow-violet relative overflow-hidden group">
                <div className="absolute -right-4 -top-4 text-indigo-500/10 group-hover:scale-110 transition-transform"><Target size={120} /></div>
                <p className="text-sm font-semibold text-indigo-400 uppercase tracking-widest mb-1">AI Diagnostic Accuracy</p>
                <h2 className="text-5xl font-bold text-white drop-shadow-md">{stats.ai_accuracy_rate}%</h2>
                <p className="text-xs mt-3 text-indigo-300/70 font-medium">Derived from expert override data</p>
              </div>
            </div>

            {/* Filter & Table Container */}
            <div className="backdrop-blur-lg bg-cmdCard border border-cmdBorder rounded-2xl overflow-hidden shadow-2xl">
              <div className="p-4 border-b border-cmdBorder bg-slate-900/50 flex justify-between items-center">
                <h3 className="text-lg font-bold text-white uppercase tracking-widest">Surveillance Queue</h3>
                <div className="flex gap-3 items-center">
                  <div className="relative">
                    <Search size={14} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-500" />
                    <input type="text" placeholder="Search ID, Crop, Farmer..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)} className="bg-cmdSurface border border-cmdBorder text-sm rounded-lg pl-9 pr-3 py-1.5 focus:border-indigo-500 outline-none text-slate-200 placeholder-slate-600" />
                  </div>
                  <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} className="bg-cmdSurface border border-cmdBorder text-sm rounded-lg px-3 py-1.5 focus:border-indigo-500 outline-none text-slate-300 cursor-pointer">
                    <option value="ALL">All Statuses</option>
                    <option value="PENDING_REVIEW">Pending Review</option>
                    <option value="EXPERT_DIAGNOSED">Diagnosed</option>
                    <option value="SAMPLE_SUBMISSION_REQUIRED">Sample Required</option>
                    <option value="CLOSED">Closed</option>
                  </select>
                  <select value={sortOrder} onChange={e => setSortOrder(e.target.value)} className="bg-cmdSurface border border-cmdBorder text-sm rounded-lg px-3 py-1.5 focus:border-indigo-500 outline-none text-slate-300 cursor-pointer">
                    <option value="DESC">Latest First</option>
                    <option value="ASC">Oldest First</option>
                  </select>
                </div>
              </div>
              
              <table className="w-full text-left text-sm whitespace-nowrap">
                <thead className="bg-slate-900/80 text-slate-400 uppercase text-xs font-semibold tracking-widest">
                  <tr>
                    <th className="px-6 py-4 border-b border-cmdBorder">Ticket ID</th>
                    <th className="px-6 py-4 border-b border-cmdBorder">Farmer & Location</th>
                    <th className="px-6 py-4 border-b border-cmdBorder">Crop & AI Guess</th>
                    <th className="px-6 py-4 border-b border-cmdBorder">Confidence</th>
                    <th className="px-6 py-4 border-b border-cmdBorder">Status</th>
                    <th className="px-6 py-4 border-b border-cmdBorder text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-cmdBorder">
                  {filteredTickets.map((t, i) => (
                    <tr key={i} className="hover:bg-slate-800/50 transition-colors">
                      <td className="px-6 py-4 font-mono text-indigo-300">{t.ticket_code}</td>
                      <td className="px-6 py-4">
                        <div className="font-semibold text-white">{t.farmer_name}</div>
                        <div className="text-xs text-slate-500 mt-1">{t.district || "Nashik"} District</div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="font-medium text-slate-300">{t.crop_name}</div>
                        <div className="text-xs text-indigo-400 font-mono mt-1">{t.ai_prediction}</div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="w-32 bg-slate-800 rounded-full h-1.5 mb-1 overflow-hidden">
                          <div className={`h-1.5 rounded-full ${t.ai_confidence < 0.6 ? 'bg-red-500 shadow-glow-red' : t.ai_confidence < 0.75 ? 'bg-amber-500 shadow-glow-amber' : 'bg-emerald-500 shadow-glow-green'}`} style={{width: `${Math.min(t.ai_confidence * 100, 100)}%`}}></div>
                        </div>
                        <span className="text-[10px] uppercase tracking-widest text-slate-500">{(t.ai_confidence * 100).toFixed(1)}% CONF</span>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-3 py-1 rounded-full text-[10px] font-bold tracking-widest bg-slate-900 border ${getStatusGlow(t.status)}`}>
                          {t.status.replace(/_/g, ' ')}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button 
                          onClick={() => openTriageRoom(t)}
                          className="px-4 py-2 bg-indigo-600/20 hover:bg-indigo-600/40 border border-indigo-500/50 text-indigo-300 font-semibold rounded-lg shadow-glow-violet transition-all text-xs uppercase tracking-wider">
                          Open Room
                        </button>
                      </td>
                    </tr>
                  ))}
                  {filteredTickets.length === 0 && !loading && (
                    <tr><td colSpan="6" className="px-6 py-12 text-center text-slate-500">No active tickets found matching filters.</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {activeTab === "LEARNING" && (
          <div className="space-y-8 animate-fade-in">
            <div className="backdrop-blur-lg bg-cmdCard border border-cmdBorder rounded-2xl p-8 shadow-2xl">
              <h2 className="text-2xl font-bold text-white mb-2 flex items-center gap-3"><Database className="text-indigo-400" /> Active Learning & Retraining Hub</h2>
              <p className="text-slate-400 mb-8 max-w-3xl">This module tracks human-verified overrides from the Triage Dashboard. Export these verified datasets directly into YOLO or XGBoost pipelines to continuously improve Model A and Model B accuracy.</p>
              
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
                  <div className="border border-indigo-500/30 bg-indigo-900/10 p-6 rounded-xl shadow-glow-violet">
                    <h3 className="text-indigo-300 font-semibold uppercase tracking-widest text-sm mb-4">Golden Dataset (Vision AI)</h3>
                    <div className="flex items-end gap-4 mb-6">
                      <span className="text-5xl font-bold text-white">{alStats.golden_dataset_count}</span>
                      <span className="text-slate-400 pb-1">/ 200 required for next YOLO fine-tune</span>
                    </div>
                    <div className="w-full bg-slate-800 rounded-full h-2 mb-6"><div className="bg-indigo-500 h-2 rounded-full" style={{width: `${Math.min((alStats.golden_dataset_count / 200) * 100, 100)}%`}}></div></div>
                    <button onClick={() => exportDataset('IMAGE_VISION')} className="w-full py-3 bg-indigo-600 hover:bg-indigo-500 text-white font-bold rounded-lg flex items-center justify-center gap-2 transition-colors">
                      <Download size={18} /> Export YOLO Dataset
                    </button>
                  </div>
                  
                  <div className="border border-emerald-500/30 bg-emerald-900/10 p-6 rounded-xl shadow-glow-green">
                    <h3 className="text-emerald-300 font-semibold uppercase tracking-widest text-sm mb-4">Feature Vectors (Weather XGBoost)</h3>
                    <div className="flex items-end gap-4 mb-6">
                      <span className="text-5xl font-bold text-white">{alStats.feature_vector_count}</span>
                      <span className="text-slate-400 pb-1">Verified outcomes logged</span>
                    </div>
                    <div className="w-full bg-slate-800 rounded-full h-2 mb-6"><div className="bg-emerald-500 h-2 rounded-full" style={{width: '100%'}}></div></div>
                    <button onClick={() => exportDataset('WEATHER_RISK')} className="w-full py-3 bg-emerald-600 hover:bg-emerald-500 text-white font-bold rounded-lg flex items-center justify-center gap-2 transition-colors">
                      <Download size={18} /> Export XGBoost CSV
                    </button>
                  </div>
                </div>

                <div className="mt-8 border border-cmdBorder bg-slate-900/50 rounded-xl overflow-hidden">
                  <div className="px-6 py-4 border-b border-cmdBorder bg-slate-950/80">
                    <h3 className="text-white font-semibold flex items-center gap-2"><CheckCircle size={16} className="text-indigo-400"/> Recently Queued Training Tickets</h3>
                  </div>
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="bg-slate-950 text-slate-400 text-sm uppercase tracking-wider">
                        <th className="p-4 font-medium border-b border-cmdBorder w-1/4">Ticket ID</th>
                        <th className="p-4 font-medium border-b border-cmdBorder w-1/4">Crop</th>
                        <th className="p-4 font-medium border-b border-cmdBorder w-1/3">Target Disease Label</th>
                        <th className="p-4 font-medium border-b border-cmdBorder w-1/4">Logged On</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-cmdBorder">
                      {alStats.recent_training_tickets && alStats.recent_training_tickets.map((t, idx) => (
                        <tr key={idx} className="hover:bg-slate-800/30 transition-colors">
                          <td className="p-4 font-mono text-indigo-300">{t.ticket_code}</td>
                          <td className="p-4 text-white font-medium">{t.crop}</td>
                          <td className="p-4 text-emerald-300 font-semibold">{t.disease}</td>
                          <td className="p-4 text-slate-400 text-sm">{new Date(t.timestamp).toLocaleDateString()}</td>
                        </tr>
                      ))}
                      {alStats.recent_training_tickets?.length === 0 && (
                        <tr>
                          <td colSpan="4" className="p-8 text-center text-slate-500 italic">No tickets queued for training yet.</td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>

              </div>
            </div>
        )}

      </div>

      {/* Triage Room Modal (Split Screen) */}
      {selectedTicket && (
        <div className="fixed inset-0 z-50 flex animate-fade-in">
          <div className="absolute inset-0 bg-black/80 backdrop-blur-sm" onClick={() => setSelectedTicket(null)}></div>
          
          <div className="relative w-full max-w-[1400px] h-[90vh] m-auto bg-cmdSurface border border-cmdBorder rounded-2xl shadow-2xl flex overflow-hidden">
            
            {/* Left Side: Evidence & Image */}
            <div className="w-1/2 border-r border-cmdBorder bg-cmdBg p-6 flex flex-col relative">
              <button onClick={() => setSelectedTicket(null)} className="absolute top-4 left-4 p-2 bg-slate-800/80 rounded-full hover:bg-slate-700 text-slate-300 z-10"><X size={20} /></button>
              
              <div className="flex-1 rounded-xl border border-slate-700 bg-slate-900 overflow-hidden relative flex items-center justify-center mt-8">
                {/* Simulated high-res image view */}
                {selectedTicket.image_url ? (
                  <img src={selectedTicket.image_url} alt="Crop Scan" className="max-w-full max-h-full object-contain" />
                ) : (
                  <div className="text-slate-600 flex flex-col items-center"><Search size={64} className="mb-4 opacity-50"/> No Image Provided</div>
                )}

                {/* AI HUD Overlay */}
                <div className="absolute bottom-4 left-4 right-4 bg-black/60 backdrop-blur-md border border-slate-600 rounded-lg p-4 flex justify-between items-center shadow-2xl">
                  <div>
                    <p className="text-[10px] text-slate-400 uppercase tracking-widest mb-1">Model B Prediction</p>
                    <p className="text-xl font-bold text-white font-mono">{selectedTicket.ai_prediction}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-[10px] text-slate-400 uppercase tracking-widest mb-1">Confidence</p>
                    <p className={`text-xl font-bold font-mono ${selectedTicket.ai_confidence < 0.6 ? 'text-red-400' : 'text-emerald-400'}`}>
                      {(selectedTicket.ai_confidence * 100).toFixed(1)}%
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Right Side: Prescription Console */}
            <div className="w-1/2 p-8 overflow-y-auto bg-slate-900">
              <h2 className="text-2xl font-bold text-white tracking-wide mb-6">Prescription & Action Console</h2>
              
              <form onSubmit={submitTriage} className="space-y-6">
                
                {/* AI Override */}
                <div className={`p-5 rounded-xl border ${overrideAi ? 'border-indigo-500 bg-indigo-900/20 shadow-glow-violet' : 'border-slate-700 bg-slate-800/50'} transition-all`}>
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input type="checkbox" checked={overrideAi} onChange={e => setOverrideAi(e.target.checked)} className="w-5 h-5 rounded border-slate-600 text-indigo-500 bg-slate-900 focus:ring-0 focus:ring-offset-0" />
                    <span className="font-semibold text-white tracking-wide">Override Model B Diagnosis</span>
                  </label>
                  
                  {overrideAi && (
                    <div className="mt-4 pt-4 border-t border-indigo-500/30 animate-fade-in">
                      <label className="block text-xs font-semibold text-indigo-300 uppercase tracking-wider mb-2">Verified Pathogen / Class</label>
                      <input 
                        type="text" 
                        value={confirmedDiagnosis} 
                        onChange={e => setConfirmedDiagnosis(e.target.value)} 
                        className="w-full bg-slate-950 border border-indigo-500/50 rounded-lg px-4 py-2 text-white font-mono focus:outline-none focus:border-indigo-400" 
                        required 
                        placeholder="e.g. Late Blight (Phytophthora infestans)"
                      />
                      <p className="text-[10px] text-indigo-300/70 mt-2">This triggers an automatic active learning capture to the Retraining Archive.</p>
                    </div>
                  )}
                </div>

                {/* Agronomy Form */}
                <div className="p-5 rounded-xl border border-slate-700 bg-slate-800/50 space-y-4">
                  <h3 className="text-sm font-bold text-slate-300 uppercase tracking-widest border-b border-slate-700 pb-2">Official Prescription</h3>
                  
                  <div>
                    <label className="block text-xs font-medium text-slate-400 mb-1">CIBRC Agrochemical / Bio-agent</label>
                    <input type="text" value={cibrcAgro} onChange={e => setCibrcAgro(e.target.value)} className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-emerald-500" placeholder="e.g. Mancozeb 75% WP" />
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-medium text-slate-400 mb-1">Dosage (g/L or ml/L)</label>
                      <input type="text" value={dosage} onChange={e => setDosage(e.target.value)} className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-emerald-500" placeholder="e.g. 2.0 g/L" />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-slate-400 mb-1">Pre-Harvest Interval (PHI)</label>
                      <input type="number" value={phi} onChange={e => setPhi(e.target.value)} className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-emerald-500" placeholder="Days" />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-medium text-slate-400 mb-1">Scientist Notes / Farmer Instructions</label>
                    <textarea value={advisoryNotes} onChange={e => setAdvisoryNotes(e.target.value)} rows="4" className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-emerald-500" placeholder="Detailed application instructions..."></textarea>
                  </div>
                </div>

                {/* Dispatch Action */}
                <div className="p-5 rounded-xl border border-slate-700 bg-slate-800/50">
                  <h3 className="text-sm font-bold text-slate-300 uppercase tracking-widest border-b border-slate-700 pb-2 mb-4">Dispatch Action</h3>
                  
                  <div className="space-y-3">
                    <label className={`flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-all ${actionType === 'SEND_ADVISORY' ? 'border-emerald-500 bg-emerald-900/20' : 'border-slate-700 hover:bg-slate-800'}`}>
                      <input type="radio" name="action" checked={actionType === 'SEND_ADVISORY'} onChange={() => setActionType('SEND_ADVISORY')} className="text-emerald-500 focus:ring-0 bg-slate-900 border-slate-600" />
                      <div className="flex flex-col"><span className="font-semibold text-white">Send Official Advisory</span><span className="text-xs text-slate-400">Pushes prescription instantly to Farmer Portal</span></div>
                    </label>

                    <label className={`flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-all ${actionType === 'REQUEST_PHYSICAL_SAMPLE' ? 'border-violet-500 bg-violet-900/20' : 'border-slate-700 hover:bg-slate-800'}`}>
                      <input type="radio" name="action" checked={actionType === 'REQUEST_PHYSICAL_SAMPLE'} onChange={() => setActionType('REQUEST_PHYSICAL_SAMPLE')} className="text-violet-500 focus:ring-0 bg-slate-900 border-slate-600" />
                      <div className="flex flex-col"><span className="font-semibold text-white">Request Physical Tissue Sample</span><span className="text-xs text-slate-400">Generates mailing instructions for the farmer</span></div>
                    </label>

                    <label className={`flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-all ${actionType === 'CLOSE_TICKET' ? 'border-slate-500 bg-slate-700/50' : 'border-slate-700 hover:bg-slate-800'}`}>
                      <input type="radio" name="action" checked={actionType === 'CLOSE_TICKET'} onChange={() => setActionType('CLOSE_TICKET')} className="text-slate-400 focus:ring-0 bg-slate-900 border-slate-600" />
                      <div className="flex flex-col"><span className="font-semibold text-slate-300">Close Ticket (Resolved)</span><span className="text-xs text-slate-500">No further action required</span></div>
                    </label>
                  </div>
                </div>

                <button type="submit" className="w-full py-4 rounded-xl font-bold tracking-widest uppercase bg-emerald-600 hover:bg-emerald-500 text-white shadow-glow-green transition-all flex justify-center items-center gap-2">
                  <CheckCircle size={20} /> Finalize Review & Dispatch
                </button>

              </form>
            </div>
          </div>
        </div>
      )}

      {/* Toast Notification */}
      {toast && (
        <div className="fixed bottom-6 right-6 bg-indigo-600 text-white px-6 py-4 rounded-xl shadow-glow-violet border border-indigo-400 flex items-center gap-3 animate-fade-in z-50 font-semibold tracking-wide">
          <Zap size={20} className="animate-pulse" />
          {toast}
        </div>
      )}

    </div>
  );
}
