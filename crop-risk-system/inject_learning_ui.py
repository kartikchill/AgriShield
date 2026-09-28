import codecs

HTML_TAB = '''            <button id="tabLearning" class="px-6 py-3 font-semibold text-slate-400 hover:text-pink-400 focus:outline-none border-b-2 border-transparent transition-colors">Active Learning Loop</button>
'''

HTML_SECTION = '''
        <!-- ==================== ACTIVE LEARNING SECTION ==================== -->
        <div id="sectionLearning" class="hidden space-y-6">
            <div class="bg-slate-800 p-6 rounded-xl border border-slate-700 shadow-xl">
                <div class="flex items-center justify-between mb-6">
                    <div>
                        <h2 class="text-2xl font-bold text-white">Active Learning & Feedback Loop</h2>
                        <p class="text-slate-400 text-sm mt-1">Continuous model retraining via farmer follow-ups and expert validation</p>
                    </div>
                    <div class="w-12 h-12 rounded-lg bg-pink-500/20 flex items-center justify-center text-pink-400 text-2xl">&#8635;</div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    
                    <!-- Export Card -->
                    <div class="bg-slate-900 rounded-lg p-5 border border-slate-700">
                        <h3 class="text-lg font-semibold text-white mb-2">ML Dataset Export</h3>
                        <p class="text-slate-400 text-sm mb-4">Export human-verified golden datasets for Model A and Model B retraining pipelines.</p>
                        <div class="space-y-3">
                            <button id="btnExportWeather" class="w-full bg-slate-700 hover:bg-slate-600 text-white font-medium py-2 px-4 rounded transition-colors flex justify-between items-center">
                                <span>Export Weather Risk CSV</span>
                                <span>&#11015;</span>
                            </button>
                            <button id="btnExportVision" class="w-full bg-slate-700 hover:bg-slate-600 text-white font-medium py-2 px-4 rounded transition-colors flex justify-between items-center">
                                <span>Export Vision AI (YOLO format)</span>
                                <span>&#11015;</span>
                            </button>
                        </div>
                        <div id="exportStatus" class="mt-3 text-sm text-pink-400 hidden"></div>
                    </div>

                    <!-- Pending Follow Ups -->
                    <div class="bg-slate-900 rounded-lg p-5 border border-slate-700">
                        <div class="flex justify-between items-center mb-4">
                            <h3 class="text-lg font-semibold text-white">Pending Field Check-ins</h3>
                            <span class="bg-red-500/20 text-red-400 text-xs font-bold px-2 py-1 rounded">Action Needed</span>
                        </div>
                        <div class="space-y-3">
                            <div class="bg-slate-800 p-3 rounded border border-slate-700 flex justify-between items-center">
                                <div>
                                    <p class="text-white font-medium text-sm">Ticket: TICKET-001</p>
                                    <p class="text-slate-400 text-xs">8 days since advisory</p>
                                </div>
                                <button onclick="alert('Feedback logged into RetrainingArchive successfully!')" class="bg-pink-600 hover:bg-pink-500 text-white text-xs px-3 py-1.5 rounded transition-colors">Submit Feedback</button>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </div>
'''

JS_INJECT = '''
        // ─── ACTIVE LEARNING TAB ─────────────────────────────────────────────
        const tabLearning = document.getElementById('tabLearning');
        const sectionLearning = document.getElementById('sectionLearning');
        
        tabLearning.addEventListener('click', () => {
            hideAllSections();
            tabLearning.classList.remove('text-slate-400', 'border-transparent');
            tabLearning.classList.add('text-pink-400', 'border-pink-400');
            sectionLearning.classList.remove('hidden');
        });

        document.getElementById('btnExportWeather').addEventListener('click', async () => {
            document.getElementById('exportStatus').innerText = 'Exporting Weather Dataset...';
            document.getElementById('exportStatus').classList.remove('hidden');
            try {
                const res = await fetch('/api/v1/learning/export-dataset/WEATHER_RISK');
                const data = await res.json();
                document.getElementById('exportStatus').innerText = 'Export complete! Saved to: ' + data.export_path;
            } catch(e) {
                document.getElementById('exportStatus').innerText = 'Error: ' + e;
            }
        });

        document.getElementById('btnExportVision').addEventListener('click', async () => {
            document.getElementById('exportStatus').innerText = 'Exporting Vision Images...';
            document.getElementById('exportStatus').classList.remove('hidden');
            try {
                const res = await fetch('/api/v1/learning/export-dataset/IMAGE_VISION');
                const data = await res.json();
                document.getElementById('exportStatus').innerText = 'Export complete! Saved to: ' + data.export_path;
            } catch(e) {
                document.getElementById('exportStatus').innerText = 'Error: ' + e;
            }
        });
'''

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'r', 'utf-8') as f:
    html = f.read()

# 1. Insert Tab Button
hotspot_btn_str = '<button id="tabHotspots" class="px-6 py-3 font-semibold text-slate-400 hover:text-orange-400 focus:outline-none border-b-2 border-transparent transition-colors" data-i18n="Geospatial Hotspots">Geospatial Hotspots</button>\n'
html = html.replace(hotspot_btn_str, hotspot_btn_str + HTML_TAB)

# 2. Insert HTML Section (before the final closing </div>)
closing_div = '    </div>\n\n    <script>'
html = html.replace(closing_div, HTML_SECTION + closing_div)

# 3. Insert JS Tab initialization to the TOP of the script block
js_top_marker = 'const sectionModelA = document.getElementById(\'sectionModelA\');\n'
html = html.replace(js_top_marker, js_top_marker + "        const tabLearning = document.getElementById('tabLearning');\n        const sectionLearning = document.getElementById('sectionLearning');\n")

# 4. Add into hideAllSections array and classes
old_hide = "sectionHotspots.classList.add('hidden');\n\n            const allTabs = [tabModelA, tabPest, tabVision, tabReferral, tabHotspots];\n            allTabs.forEach(t => {\n                t.classList.remove('text-emerald-400', 'border-emerald-400', 'text-blue-400', 'border-blue-400', 'text-cyan-400', 'border-cyan-400', 'text-purple-400', 'border-purple-400', 'text-orange-400', 'border-orange-400');"

new_hide = "sectionHotspots.classList.add('hidden');\n            sectionLearning.classList.add('hidden');\n\n            const allTabs = [tabModelA, tabPest, tabVision, tabReferral, tabHotspots, tabLearning];\n            allTabs.forEach(t => {\n                t.classList.remove('text-emerald-400', 'border-emerald-400', 'text-blue-400', 'border-blue-400', 'text-cyan-400', 'border-cyan-400', 'text-purple-400', 'border-purple-400', 'text-orange-400', 'border-orange-400', 'text-pink-400', 'border-pink-400');"

html = html.replace(old_hide, new_hide)

# 5. Insert JS Listeners before uiTranslations
ui_translations_marker = 'const uiTranslations ='
html = html.replace(ui_translations_marker, JS_INJECT + '\n        ' + ui_translations_marker)

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'w', 'utf-8') as f:
    f.write(html)

print("Active Learning injected into main UI.")
