import codecs

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'r', 'utf-8') as f:
    content = f.read()

vision_html = '''
        <!-- ==================== VISION AI SECTION (MODEL B) ==================== -->
        <div id="sectionVision" class="hidden">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <!-- Upload Card -->
                <div class="bg-slate-800 p-6 rounded-xl border border-slate-700 shadow-xl h-fit">
                    <div class="flex items-center space-x-3 mb-4">
                        <div class="w-10 h-10 rounded-lg bg-cyan-500/20 flex items-center justify-center text-cyan-400 text-xl">&#128247;</div>
                        <div>
                            <h2 class="text-xl font-semibold text-white">Vision AI (Model B)</h2>
                            <p class="text-slate-400 text-sm">EfficientNetV2-S &bull; 23 Classes &bull; ~99.7% Accuracy</p>
                        </div>
                    </div>
                    <div id="dropZone" class="border-2 border-dashed border-slate-600 rounded-xl p-8 text-center cursor-pointer hover:border-cyan-500 transition-colors">
                        <div id="dropPlaceholder">
                            <div class="text-4xl mb-3">&#127807;</div>
                            <p class="text-slate-300 font-medium">Drag & drop a leaf image here</p>
                            <p class="text-slate-500 text-sm mt-1">or click to browse &bull; JPEG / PNG &bull; Max 10 MB</p>
                        </div>
                        <img id="previewImage" class="hidden max-h-64 mx-auto rounded-lg object-cover" alt="Preview" />
                        <input type="file" id="imageInput" accept="image/jpeg,image/png,image/webp" class="hidden" />
                    </div>
                    <button id="analyzeImageBtn" disabled
                        class="w-full mt-4 bg-cyan-600 hover:bg-cyan-500 disabled:bg-slate-700 disabled:text-slate-500 text-white font-medium py-3 px-4 rounded-lg transition-colors flex justify-center items-center">
                        <span id="visionBtnText">Select an image first</span>
                    </button>
                </div>
                <!-- Results Card -->
                <div id="visionResultsView" class="hidden space-y-4">
                    <div class="bg-slate-800 p-6 rounded-xl border border-slate-700 shadow-xl">
                        <div class="flex justify-between items-start mb-4">
                            <div>
                                <p class="text-slate-400 text-sm font-medium">Detected Condition</p>
                                <h3 id="visionDisease" class="text-2xl font-bold text-white mt-1">--</h3>
                            </div>
                            <div class="text-right">
                                <div id="visionBadge" class="inline-block px-4 py-2 rounded-full text-lg font-bold border">--</div>
                                <p id="visionConf" class="text-slate-400 text-sm mt-2">Confidence: --</p>
                            </div>
                        </div>
                        <div id="expertAlert" class="hidden mt-4 p-4 bg-yellow-900/30 border border-yellow-500/50 rounded-lg">
                            <p class="text-yellow-300 font-semibold text-sm">&#9888; Low Confidence - Expert Review Recommended</p>
                            <p class="text-yellow-200 text-xs mt-1">The AI is not confident enough. Consider submitting a lab referral ticket.</p>
                            <button id="goToReferralBtn" class="mt-3 text-xs bg-purple-600 hover:bg-purple-500 text-white px-3 py-1.5 rounded-lg transition-colors">Open Referral Form &#8594;</button>
                        </div>
                    </div>
                    <div class="bg-slate-800 p-6 rounded-xl border border-slate-700 shadow-xl">
                        <h4 class="text-white font-semibold mb-3">Top-3 Predictions</h4>
                        <div id="top3Container" class="space-y-3"></div>
                    </div>
                    <div id="visionIpmCard" class="hidden bg-slate-800 p-6 rounded-xl border border-cyan-700/40 shadow-xl">
                        <h4 class="text-cyan-400 font-semibold mb-2">&#128202; Linked IPM Advisory</h4>
                        <p class="text-slate-300 text-sm" id="visionIpmText"></p>
                    </div>
                </div>
            </div>
        </div>
'''

# Insert before the closing </div>\n\n    <script> block
insert_before = '\n    <script>'
content = content.replace(insert_before, vision_html + insert_before, 1)

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'w', 'utf-8') as f:
    f.write(content)

print("Vision HTML section inserted.")
