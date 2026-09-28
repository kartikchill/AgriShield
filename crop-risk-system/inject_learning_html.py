import codecs
import re

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'r', 'utf-8') as f:
    html = f.read()

HTML_TAB = '''            <button id="tabLearning" class="px-6 py-3 font-semibold text-slate-400 hover:text-pink-400 focus:outline-none border-b-2 border-transparent transition-colors">Active Learning Loop</button>\n'''

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

# 1. Insert Tab Button
# Find tabHotspots and append
hotspot_btn_match = re.search(r'<button id="tabHotspots"[^>]*>.*?</button>', html)
if hotspot_btn_match:
    hotspot_html = hotspot_btn_match.group(0)
    html = html.replace(hotspot_html, hotspot_html + '\n' + HTML_TAB)

# 2. Insert HTML Section
# Find the start of the JS script `<script>` that contains `tabModelA`
js_script_match = re.search(r'<script>\s*(?://.*?)*\s*const tabModelA', html)
if js_script_match:
    inject_point = js_script_match.start()
    # Go back to the preceding </div>
    div_match = html.rfind('</div>', 0, inject_point)
    if div_match != -1:
        # Insert after this </div>
        html = html[:div_match + 6] + '\n' + HTML_SECTION + '\n' + html[div_match + 6:]

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'w', 'utf-8') as f:
    f.write(html)

print("Injected HTML successfully.")
