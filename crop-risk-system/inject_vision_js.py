import codecs

VISION_JS = '''
        // ─── VISION AI (MODEL B) TAB ─────────────────────────────────────────────
        const tabVision = document.getElementById('tabVision');
        const sectionVision = document.getElementById('sectionVision');

        // Image preview
        const dropZone = document.getElementById('dropZone');
        const imageInput = document.getElementById('imageInput');
        const previewImage = document.getElementById('previewImage');
        const dropPlaceholder = document.getElementById('dropPlaceholder');
        const analyzeBtn = document.getElementById('analyzeImageBtn');
        const visionBtnText = document.getElementById('visionBtnText');
        let selectedFile = null;

        dropZone.addEventListener('click', () => imageInput.click());

        dropZone.addEventListener('dragover', (e) => {
            e.preventDefault();
            dropZone.classList.add('border-cyan-500');
        });
        dropZone.addEventListener('dragleave', () => {
            dropZone.classList.remove('border-cyan-500');
        });
        dropZone.addEventListener('drop', (e) => {
            e.preventDefault();
            dropZone.classList.remove('border-cyan-500');
            const file = e.dataTransfer.files[0];
            if (file) handleFileSelect(file);
        });

        imageInput.addEventListener('change', (e) => {
            if (e.target.files[0]) handleFileSelect(e.target.files[0]);
        });

        function handleFileSelect(file) {
            if (!['image/jpeg', 'image/jpg', 'image/png', 'image/webp'].includes(file.type)) {
                alert('Please upload a JPEG or PNG image.');
                return;
            }
            selectedFile = file;
            const url = URL.createObjectURL(file);
            previewImage.src = url;
            previewImage.classList.remove('hidden');
            dropPlaceholder.classList.add('hidden');
            analyzeBtn.disabled = false;
            visionBtnText.innerText = 'Analyze Leaf Image';
        }

        analyzeBtn.addEventListener('click', async () => {
            if (!selectedFile) return;
            analyzeBtn.disabled = true;
            visionBtnText.innerText = 'Analyzing...';

            const formData = new FormData();
            formData.append('file', selectedFile);

            try {
                const resp = await fetch('/api/v1/vision/analyze-image', {
                    method: 'POST',
                    body: formData
                });
                if (!resp.ok) {
                    const err = await resp.json();
                    throw new Error(err.detail || 'Server error');
                }
                const data = await resp.json();

                // Disease name + badge
                document.getElementById('visionDisease').innerText = data.display_name;
                document.getElementById('visionConf').innerText = 'Confidence: ' + data.confidence_pct;

                const badge = document.getElementById('visionBadge');
                if (data.is_healthy) {
                    badge.innerText = 'HEALTHY';
                    badge.className = 'inline-block px-4 py-2 rounded-full text-lg font-bold border bg-green-500/20 text-green-400 border-green-500/50';
                } else {
                    badge.innerText = 'DISEASE DETECTED';
                    badge.className = 'inline-block px-4 py-2 rounded-full text-lg font-bold border bg-red-500/20 text-red-400 border-red-500/50';
                }

                // Expert review alert
                const expertAlert = document.getElementById('expertAlert');
                if (data.requires_expert_review) {
                    expertAlert.classList.remove('hidden');
                } else {
                    expertAlert.classList.add('hidden');
                }

                // Top-3
                const top3 = document.getElementById('top3Container');
                top3.innerHTML = '';
                data.top3.forEach(p => {
                    const pct = (p.confidence * 100).toFixed(1);
                    const barWidth = Math.round(p.confidence * 100);
                    top3.innerHTML += `
                        <div class="space-y-1">
                            <div class="flex justify-between text-sm">
                                <span class="text-slate-300">${p.rank}. ${p.display_name}</span>
                                <span class="font-bold text-white">${pct}%</span>
                            </div>
                            <div class="w-full bg-slate-700 rounded-full h-2">
                                <div class="h-2 rounded-full ${p.rank === 1 ? 'bg-cyan-400' : 'bg-slate-500'}" style="width: ${barWidth}%"></div>
                            </div>
                        </div>`;
                });

                // IPM link
                const ipmCard = document.getElementById('visionIpmCard');
                const ipmText = document.getElementById('visionIpmText');
                if (data.ipm_lookup) {
                    ipmText.innerText = 'Crop: ' + data.ipm_lookup.crop + '   |   Pest/Disease: ' + data.ipm_lookup.pest + '   — Use the Pest Surveillance tab to get the full ICAR IPM advisory for this condition.';
                    ipmCard.classList.remove('hidden');
                } else {
                    ipmCard.classList.add('hidden');
                }

                document.getElementById('visionResultsView').classList.remove('hidden');

            } catch (err) {
                alert('Vision AI Error: ' + err.message);
            } finally {
                analyzeBtn.disabled = false;
                visionBtnText.innerText = 'Analyze Leaf Image';
            }
        });

        // Go to referral form button
        document.getElementById('goToReferralBtn').addEventListener('click', () => {
            hideAllSections();
            tabReferral.classList.remove('text-slate-400', 'border-transparent');
            tabReferral.classList.add('text-purple-400', 'border-purple-400');
            sectionReferral.classList.remove('hidden');
        });
'''

with open('d:/PDD2/crop-risk-system/static/index.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Inject Vision JS right before the i18n translation block
insert_before = '\n        const uiTranslations'
content = content.replace(insert_before, VISION_JS + insert_before, 1)

# Also update hideAllSections to include sectionVision
old_hide = '''        function hideAllSections() {
            sectionModelA.classList.add('hidden');
            sectionPest.classList.add('hidden');
            sectionReferral.classList.add('hidden');
            sectionHotspots.classList.add('hidden');

            const allTabs = [tabModelA, tabPest, tabReferral, tabHotspots];
            allTabs.forEach(t => {
                t.classList.remove('text-emerald-400', 'border-emerald-400', 'text-blue-400', 'border-blue-400', 'text-purple-400', 'border-purple-400', 'text-orange-400', 'border-orange-400');
                t.classList.add('text-slate-400', 'border-transparent');
            });
        }'''

new_hide = '''        function hideAllSections() {
            sectionModelA.classList.add('hidden');
            sectionPest.classList.add('hidden');
            sectionVision.classList.add('hidden');
            sectionReferral.classList.add('hidden');
            sectionHotspots.classList.add('hidden');

            const allTabs = [tabModelA, tabPest, tabVision, tabReferral, tabHotspots];
            allTabs.forEach(t => {
                t.classList.remove('text-emerald-400', 'border-emerald-400', 'text-blue-400', 'border-blue-400', 'text-cyan-400', 'border-cyan-400', 'text-purple-400', 'border-purple-400', 'text-orange-400', 'border-orange-400');
                t.classList.add('text-slate-400', 'border-transparent');
            });
        }'''

content = content.replace(old_hide, new_hide)

# Add tabVision click handler after tabPest click handler
old_tabpest_end = '''        tabPest.addEventListener('click', () => {
            hideAllSections();
            tabPest.classList.remove('text-slate-400', 'border-transparent');
            tabPest.classList.add('text-blue-400', 'border-blue-400');
            sectionPest.classList.remove('hidden');
        });

        tabReferral'''

new_tabpest_end = '''        tabPest.addEventListener('click', () => {
            hideAllSections();
            tabPest.classList.remove('text-slate-400', 'border-transparent');
            tabPest.classList.add('text-blue-400', 'border-blue-400');
            sectionPest.classList.remove('hidden');
        });

        tabVision.addEventListener('click', () => {
            hideAllSections();
            tabVision.classList.remove('text-slate-400', 'border-transparent');
            tabVision.classList.add('text-cyan-400', 'border-cyan-400');
            sectionVision.classList.remove('hidden');
        });

        tabReferral'''

content = content.replace(old_tabpest_end, new_tabpest_end)

with open('d:/PDD2/crop-risk-system/static/index.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("Vision JS injected successfully.")
