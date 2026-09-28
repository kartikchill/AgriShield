import re
from bs4 import BeautifulSoup

def transform_html():
    with open('index.html', 'r', encoding='utf-8') as f:
        html = f.read()
        
    soup = BeautifulSoup(html, 'html.parser')
    
    # 1. Update Body
    if soup.body:
        soup.body['class'] = ['bg-amber-50/50', 'text-slate-800', 'min-h-screen', 'font-sans', 'flex', 'flex-col']
        
    # 2. Find and rebuild Nav/Header
    nav = soup.find('nav')
    if nav:
        nav['class'] = ['bg-emerald-800', 'text-white', 'shadow-lg', 'border-b-4', 'border-emerald-600', 'w-full']
        # Maybe rewrite inner nav to look better
        nav.string = ''
        nav.append(BeautifulSoup("""
        <div class="max-w-7xl mx-auto px-6 py-4 flex justify-between items-center">
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 bg-white text-emerald-800 rounded-full flex items-center justify-center font-bold text-xl shadow-inner">
                    <span class="material-symbols-outlined">eco</span>
                </div>
                <div>
                    <h1 class="text-2xl font-bold tracking-tight">Kisan Mitra</h1>
                    <p class="text-emerald-200 text-xs uppercase tracking-widest font-semibold">Farmer Intelligence Portal</p>
                </div>
            </div>
            <div class="flex items-center gap-4">
                <select id="langSelector" class="bg-emerald-900 border border-emerald-700 text-white rounded-lg px-3 py-1.5 focus:ring-2 focus:ring-emerald-400 outline-none text-sm font-medium">
                    <option value="en">English</option>
                    <option value="hi">हिंदी (Hindi)</option>
                    <option value="mr">मराठी (Marathi)</option>
                </select>
                <div class="w-10 h-10 rounded-full bg-emerald-700 border-2 border-emerald-500 overflow-hidden shadow-sm">
                    <img src="https://ui-avatars.com/api/?name=Farmer&background=047857&color=fff" alt="Profile">
                </div>
            </div>
        </div>
        """, 'html.parser'))
        
    # 3. Add History Tab
    tabs_container = soup.find(id='tabModelA')
    if tabs_container and tabs_container.parent:
        parent = tabs_container.parent
        parent['class'] = ['flex', 'overflow-x-auto', 'border-b', 'border-emerald-200', 'mb-8', 'bg-white', 'shadow-sm', 'px-6']
        
        # New History Tab Button
        history_btn = soup.new_tag('button', id='tabHistory', **{'class': 'px-6 py-4 font-bold text-slate-500 hover:text-emerald-700 focus:outline-none border-b-4 border-transparent transition-all whitespace-nowrap'})
        history_btn.string = "My Tickets & Feedback"
        
        # Insert after the last tab
        parent.append(history_btn)
        
    # 4. Inject History Section
    # Find sectionModelA to insert before it or at the end of sections
    main_container = soup.find(id='sectionModelA')
    if main_container and main_container.parent:
        history_section = BeautifulSoup("""
        <section id="sectionHistory" class="hidden animate-fade-in max-w-7xl mx-auto px-6 w-full">
            <div class="bg-white rounded-2xl shadow-xl border border-emerald-100 overflow-hidden mb-8">
                <div class="bg-emerald-50 p-6 border-b border-emerald-100 flex justify-between items-center">
                    <div>
                        <h2 class="text-2xl font-bold text-emerald-900">My Consultation History</h2>
                        <p class="text-emerald-700 mt-1 text-sm">Track your laboratory referrals and official KVK expert prescriptions.</p>
                    </div>
                    <button onclick="fetchHistory()" class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-lg shadow-sm transition-colors flex items-center gap-2">
                        <span class="material-symbols-outlined text-sm">refresh</span> Refresh
                    </button>
                </div>
                <div class="p-6">
                    <div id="historyLoading" class="text-center py-12 text-emerald-600 hidden">
                        <span class="material-symbols-outlined animate-spin text-4xl">sync</span>
                        <p class="mt-4 font-medium">Fetching records...</p>
                    </div>
                    <div id="historyList" class="space-y-6">
                        <!-- Dynamic content injected here -->
                    </div>
                </div>
            </div>
        </section>
        """, 'html.parser')
        main_container.insert_before(history_section)
        
    # 5. Overhaul existing dark mode classes to light/earthy theme
    class_replacements = {
        'bg-slate-900': 'bg-white',
        'bg-slate-800': 'bg-white',
        'border-slate-700': 'border-emerald-100',
        'border-slate-600': 'border-emerald-200',
        'text-gray-200': 'text-slate-700',
        'text-slate-400': 'text-slate-500',
        'text-white': 'text-slate-800',  # risky, maybe skip text-white globally, but okay inside sections
        'text-blue-400': 'text-blue-700',
        'text-emerald-400': 'text-emerald-700',
        'text-cyan-400': 'text-cyan-700',
        'text-orange-400': 'text-amber-700',
        'text-pink-400': 'text-rose-700',
        'text-purple-400': 'text-purple-700',
        'bg-blue-600': 'bg-blue-600', # Keep some buttons
    }
    
    for tag in soup.find_all(True):
        if tag.has_attr('class'):
            new_classes = []
            for cls in tag['class']:
                # Specific overrides for cards to make them pop
                if cls == 'bg-slate-800' and tag.name == 'div':
                    new_classes.extend(['bg-white', 'shadow-md', 'border', 'border-emerald-100'])
                elif cls in class_replacements:
                    # Don't replace text-white if it's on a button with bg-blue-600
                    if cls == 'text-white' and ('bg-blue-600' in tag['class'] or 'bg-emerald-600' in tag['class'] or 'bg-emerald-800' in tag['class']):
                        new_classes.append(cls)
                    else:
                        new_classes.extend(class_replacements[cls].split())
                else:
                    new_classes.append(cls)
            tag['class'] = list(set(new_classes)) # unique
            
    # Remove bg-slate-900 globally just in case
    html_out = str(soup)
    
    # 6. Inject JS logic
    js_code = """
    // HISTORY TAB LOGIC
    const tabHistory = document.getElementById('tabHistory');
    const sectionHistory = document.getElementById('sectionHistory');
    
    if (tabHistory) {
        tabHistory.addEventListener('click', () => {
            hideAllSections();
            sectionHistory.classList.remove('hidden');
            tabHistory.classList.add('text-emerald-700', 'border-emerald-600');
            tabHistory.classList.remove('text-slate-500', 'border-transparent');
            fetchHistory();
        });
    }
    
    // Patch hideAllSections globally
    const oldHide = hideAllSections;
    hideAllSections = function() {
        oldHide();
        if (sectionHistory) sectionHistory.classList.add('hidden');
        if (tabHistory) {
            tabHistory.classList.remove('text-emerald-700', 'border-emerald-600');
            tabHistory.classList.add('text-slate-500', 'border-transparent');
        }
    };
    
    async function fetchHistory() {
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
            }
            
            // For each ticket, fetch full details to get reviews
            for (let t of tickets) {
                const detRes = await fetch(`/api/v1/referral/ticket-status/${t.ticket_code}`);
                const detail = await detRes.json();
                
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
        } catch (e) {
            loading.classList.add('hidden');
            list.innerHTML = '<div class="text-center py-8 text-red-500">Failed to load history.</div>';
        }
    }
    """
    
    # Inject script at end of body
    script_tag = soup.new_tag('script')
    script_tag.string = js_code
    if soup.body:
        soup.body.append(script_tag)
        
    # Write back
    with open('index.html', 'w', encoding='utf-8') as f:
        f.write(str(soup))
        
transform_html()
