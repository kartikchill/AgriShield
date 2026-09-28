import re

with open(r'static\index.html', 'r', encoding='utf-8') as f:
    html = f.read()

# 1. Revert the bad block in top3.innerHTML
bad_block = """<div class="flex flex-col md:flex-row gap-3 mb-6 bg-emerald-50/50 p-4 rounded-xl border border-emerald-100">
                        <input type="text" id="farmerSearch" placeholder="Search Ticket ID or Crop..." class="flex-1 bg-white border border-emerald-200 text-sm rounded-lg px-4 py-2 focus:ring-2 focus:ring-emerald-400 outline-none text-slate-700" onkeyup="renderHistoryTickets()">
                        <select id="farmerStatus" class="bg-white border border-emerald-200 text-sm rounded-lg px-4 py-2 focus:ring-2 focus:ring-emerald-400 outline-none text-slate-700 cursor-pointer" onchange="renderHistoryTickets()">
                            <option value="ALL">All Statuses</option>
                            <option value="PENDING_REVIEW">Pending Review</option>
                            <option value="EXPERT_DIAGNOSED">Diagnosed by Expert</option>
                        </select>
                        <select id="farmerSort" class="bg-white border border-emerald-200 text-sm rounded-lg px-4 py-2 focus:ring-2 focus:ring-emerald-400 outline-none text-slate-700 cursor-pointer" onchange="renderHistoryTickets()">
                            <option value="DESC">Latest First</option>
                            <option value="ASC">Oldest First</option>
                        </select>
                    </div>
                    <div id="historyList" class="space-y-6">"""

if bad_block in html:
    html = html.replace(bad_block, '<div class="space-y-1">')

# 2. Insert the actual filter UI above historyList div inside sectionHistory
target = '<div id="historyList" class="space-y-6">'
replacement = bad_block # we can reuse the block
html = html.replace(target, replacement)

# 3. Add the logic to the fetchHistory function
# We will inject renderHistoryTickets()
old_fetch = '''    async function fetchHistory() {
        const loading = document.getElementById('historyLoading');
        const list = document.getElementById('historyList');
        loading.classList.remove('hidden');
        list.innerHTML = '';
        
        try {
            // Fetch all tickets to display them
            const res = await fetch('/api/v1/referral/tickets/all');
            const tickets = await res.json();
            
            loading.classList.add('hidden');
            if (tickets.length === 0) {
                list.innerHTML = '<div class="text-center py-8 text-slate-500">No consultation history found.</div>';
                return;
            }'''

new_fetch = '''
    window.allHistoryTickets = [];
    async function renderHistoryTickets() {
        const list = document.getElementById('historyList');
        if (!list) return;
        list.innerHTML = '';
        
        let tickets = window.allHistoryTickets || [];
        
        const search = (document.getElementById('farmerSearch')?.value || '').toLowerCase();
        const status = document.getElementById('farmerStatus')?.value || 'ALL';
        const sort = document.getElementById('farmerSort')?.value || 'DESC';
        
        tickets = tickets.filter(t => {
            const matchSearch = t.ticket_code.toLowerCase().includes(search) || t.crop_name.toLowerCase().includes(search);
            const matchStatus = status === 'ALL' || t.status === status || (status === 'EXPERT_DIAGNOSED' && t.status !== 'PENDING_REVIEW');
            return matchSearch && matchStatus;
        });
        
        tickets.sort((a, b) => sort === 'DESC' ? b.id - a.id : a.id - b.id);
        
        if (tickets.length === 0) {
            list.innerHTML = '<div class="text-center py-8 text-slate-500">No consultation history found matching filters.</div>';
            return;
        }
        
        for (let t of tickets) {
            let detail = t;
            try {
                const detRes = await fetch(`/api/v1/referral/ticket-status/${t.ticket_code}`);
                detail = await detRes.json();
            } catch(e) {}
            
            let reviewHtml = '';
            if (detail.reviews && detail.reviews.length > 0) {
                const rev = detail.reviews[0];
                reviewHtml = `
                <div class="mt-4 p-4 bg-emerald-50 rounded-xl border border-emerald-200 relative">
                    <div class="absolute -top-3 right-4 bg-emerald-600 text-white text-[10px] font-bold uppercase tracking-widest px-3 py-1 rounded-full shadow-sm flex items-center gap-1">
                        <span class="material-symbols-outlined text-[12px]">verified</span> KVK Official Review
                    </div>
                    <p class="text-sm font-semibold text-emerald-900 flex items-center gap-2"><span class="material-symbols-outlined text-sm">science</span> Expert: ${rev.expert_name}</p>
                    <p class="text-sm text-emerald-800 mt-2 font-medium">Confirmed Diagnosis: <span class="text-red-700">${rev.confirmed_diagnosis}</span></p>
                    <div class="mt-3 text-sm text-emerald-900 bg-white p-4 rounded-lg border border-emerald-100 whitespace-pre-line shadow-inner font-mono text-xs">
                        ${rev.custom_advisory}
                    </div>
                </div>`;
            }
            
            let statusColor = t.status === 'PENDING_REVIEW' ? 'bg-amber-100 text-amber-800 border-amber-300' : 'bg-emerald-100 text-emerald-800 border-emerald-300';
            
            const card = document.createElement('div');
            card.className = "p-6 bg-white border border-slate-200 rounded-xl shadow-sm hover:shadow-md transition-shadow";
            card.innerHTML = `
                <div class="flex justify-between items-start mb-4">
                    <div>
                        <span class="text-xs font-bold text-slate-400 tracking-widest uppercase">Ticket ID</span>
                        <h3 class="text-lg font-bold text-slate-800 font-mono">${t.ticket_code}</h3>
                    </div>
                    <span class="px-3 py-1 rounded-full text-xs font-bold border ${statusColor}">
                        ${t.status.replace(/_/g, ' ')}
                    </span>
                </div>
                <div class="grid grid-cols-2 gap-4 text-sm mb-2">
                    <div><span class="text-slate-500">Crop:</span> <span class="font-semibold text-slate-800">${t.crop_name}</span></div>
                    <div><span class="text-slate-500">AI Diagnosis:</span> <span class="font-semibold text-slate-800">${t.ai_prediction}</span></div>
                </div>
                <div class="text-sm mb-4"><span class="text-slate-500">Reported Symptoms:</span> <span class="text-slate-800 italic">"${t.reported_symptoms}"</span></div>
                ${reviewHtml}
            `;
            list.appendChild(card);
        }
    }

    async function fetchHistory() {
        const loading = document.getElementById('historyLoading');
        loading.classList.remove('hidden');
        
        try {
            const res = await fetch('/api/v1/referral/tickets/all');
            window.allHistoryTickets = await res.json();
            loading.classList.add('hidden');
            renderHistoryTickets();
            return;
'''

if 'async function renderHistoryTickets()' not in html:
    html = html.replace(old_fetch, new_fetch)

# Need to strip out the old rendering loop in fetchHistory so it doesn't run twice
import re
# The old render loop was inside fetchHistory after the `if (tickets.length === 0)` block
html = re.sub(r'for \(let t of tickets\) \{.*?list\.appendChild\(card\);\s*\}', '', html, flags=re.DOTALL)

with open(r'static\index.html', 'w', encoding='utf-8') as f:
    f.write(html)
print("Farmer filters injected cleanly.")
