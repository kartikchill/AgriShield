
        // --- TAB LOGIC ---
        const tabModelA = document.getElementById('tabModelA');
        const tabPest = document.getElementById('tabPest');
        const sectionModelA = document.getElementById('sectionModelA');
        const sectionPest = document.getElementById('sectionPest');
        const tabVision = document.getElementById('tabVision');
        const sectionVision = document.getElementById('sectionVision');

        tabModelA.addEventListener('click', () => {
            tabModelA.classList.add('text-emerald-400', 'border-emerald-400');
            tabModelA.classList.remove('text-slate-400', 'border-transparent');
            tabPest.classList.remove('text-blue-400', 'border-blue-400');
            tabPest.classList.add('text-slate-400', 'border-transparent');
            sectionModelA.classList.remove('hidden');
            sectionPest.classList.add('hidden');
        });

        tabPest.addEventListener('click', () => {
            tabPest.classList.add('text-blue-400', 'border-blue-400');
            tabPest.classList.remove('text-slate-400', 'border-transparent');
            tabModelA.classList.remove('text-emerald-400', 'border-emerald-400');
            tabModelA.classList.add('text-slate-400', 'border-transparent');
            sectionPest.classList.remove('hidden');
            sectionModelA.classList.add('hidden');
        });

        // --- IPM RENDER FUNCTION ---
        function renderIPM(ipm) {
            if (!ipm) return '';
            let html = '<div class="mt-4 space-y-3">';
            if (ipm.cultural_advisory) {
                html += `<div class="p-3 bg-slate-800 rounded border border-slate-600"><span class="text-green-400 font-semibold block mb-1" data-i18n="Cultural Control">Cultural Control</span><span class="text-slate-300 text-sm">${ipm.cultural_advisory}</span></div>`;
            }
            if (ipm.biological_advisory) {
                html += `<div class="p-3 bg-slate-800 rounded border border-slate-600"><span class="text-blue-400 font-semibold block mb-1" data-i18n="Biological Control">Biological Control</span><span class="text-slate-300 text-sm">${ipm.biological_advisory}</span></div>`;
            }
            if (ipm.chemical_name) {
                html += `<div class="p-4 bg-red-900/20 rounded border border-red-500/50">
                    <span class="text-red-400 font-semibold block mb-2">Chemical Control (Restricted Use)</span>
                    <div class="grid grid-cols-2 gap-2 text-sm text-slate-300">
                        <div><span class="text-slate-500">Agrochemical:</span> ${ipm.chemical_name}</div>
                        <div><span class="text-slate-500">Dosage:</span> ${ipm.dosage_per_liter} g/ml per Liter</div>
                        <div class="col-span-2"><span class="text-slate-500">Required PPE:</span> ${ipm.required_ppe}</div>
                        <div class="text-red-300 font-semibold border border-red-500/30 bg-red-500/10 p-1 rounded text-center mt-2">PHI: ${ipm.phi_days} Days</div>
                        <div class="text-orange-300 font-semibold border border-orange-500/30 bg-orange-500/10 p-1 rounded text-center mt-2">REI: ${ipm.re_entry_interval_hours} Hours</div>
                    </div>
                </div>`;
            }
            html += '</div>';
            return html;
        }

        // --- MODEL A LOGIC ---
        document.getElementById('geoBtn').addEventListener('click', () => {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    (position) => {
                        document.getElementById('latitude').value = position.coords.latitude.toFixed(4);
                        document.getElementById('longitude').value = position.coords.longitude.toFixed(4);
                    },
                    (error) => alert("Error getting location: " + error.message)
                );
            }
        });

        document.getElementById('riskForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = document.getElementById('submitBtn');
            const btnText = document.getElementById('btnText');
            
            const lat = document.getElementById('latitude').value;
            const lon = document.getElementById('longitude').value;
            if(!lat || !lon) return alert("Please provide latitude and longitude.");

            btn.disabled = true;
            btnText.innerText = "Analyzing...";

            const payload = {
                crop_type: document.getElementById('crop_type').value,
                crop_variety: document.getElementById('crop_variety').value,
                growth_stage: document.getElementById('growth_stage').value,
                soil_type: document.getElementById('soil_type').value,
                latitude: parseFloat(lat),
                longitude: parseFloat(lon)
            };

            try {
                const lang = document.getElementById('langSelector').value;
                const response = await fetch('/api/assess-risk', {
                    method: 'POST',
                    headers: { 
                        'Content-Type': 'application/json',
                        'Accept-Language': lang
                    },
                    body: JSON.stringify(payload)
                });
                
                if (!response.ok) throw new Error("Server error");
                const data = await response.json();
                
                document.getElementById('resDisease').innerText = data.disease;
                document.getElementById('resScore').innerText = `${data.current_risk.toFixed(1)} % Risk Score`;
                document.getElementById('resSummary').innerText = data.summary;
                document.getElementById('resRec').innerText = data.recommendation;
                
                const badge = document.getElementById('resBadge');
                badge.innerText = data.risk_level;
                badge.className = 'inline-block px-4 py-2 rounded-full text-lg font-bold border shadow-[0_0_15px_rgba(0,0,0,0.5)] ';
                
                if (data.risk_level === 'HIGH') badge.className += 'bg-red-500/20 text-red-400 border-red-500/50';
                else if (data.risk_level === 'MEDIUM') badge.className += 'bg-yellow-500/20 text-yellow-400 border-yellow-500/50';
                else badge.className += 'bg-green-500/20 text-green-400 border-green-500/50';

                const fg = document.getElementById('forecastGrid');
                fg.innerHTML = '';
                data.forecast.forEach(f => {
                    fg.innerHTML += `
                        <div class="bg-slate-800 border border-slate-700 p-4 rounded-lg flex flex-col justify-between">
                            <p class="text-slate-400 text-sm font-medium mb-2">${f.day}</p>
                            <h4 class="text-2xl font-bold ${f.level === 'HIGH' ? 'text-red-400' : f.level === 'MEDIUM' ? 'text-yellow-400' : 'text-green-400'} mb-3">${f.risk}%</h4>
                            <div class="space-y-1 text-xs text-slate-300">
                                <div class="flex justify-between"><span>T:</span> <span class="font-medium">${f.temp}&deg;C</span></div>
                                <div class="flex justify-between"><span>RH:</span> <span class="font-medium">${f.humidity}%</span></div>
                                <div class="flex justify-between"><span>Rain:</span> <span class="font-medium">${f.rain}mm</span></div>
                            </div>
                        </div>
                    `;
                });

                const fl = document.getElementById('factorsList');
                fl.innerHTML = '';
                data.factors.forEach(factor => {
                    fl.innerHTML += `<li class="flex items-start text-slate-300 text-sm"><span class="mr-2">&bull;</span>${factor}</li>`;
                });
                
                document.getElementById('modelAIpm').innerHTML = renderIPM(data.ipm_advisory);
                document.getElementById('resultsView').classList.remove('hidden');
                updateUILanguage(document.getElementById('langSelector').value);
            } catch (error) {
                alert("Error analyzing risk.");
            } finally {
                btn.disabled = false;
                btnText.innerText = "Analyze Disease Risk";
            }
        });

        // --- DYNAMIC DROPDOWNS FOR PEST SURVEILLANCE ---
        const pestMapping = {
            "Cotton": [
                { name: "Pink Bollworm", metric: "larvae_per_100_plants" }
            ],
            "Rice": [
                { name: "Stem Borer", metric: "percent_dead_hearts" },
                { name: "Brown Planthopper", metric: "insects_per_hill" }
            ],
            "Maize": [
                { name: "Fall Armyworm", metric: "trap_count_per_week" }
            ],
            "Wheat": [
                { name: "Aphids", metric: "aphids_per_tiller" }
            ]
        };

        const cropSelect = document.getElementById('pest_crop_name');
        const pestSelect = document.getElementById('pest_name');
        const metricSelect = document.getElementById('pest_metric');

        function updatePests() {
            const selectedCrop = cropSelect.value;
            const pests = pestMapping[selectedCrop] || [];
            
            pestSelect.innerHTML = '';
            pests.forEach(p => {
                const opt = document.createElement('option');
                opt.value = p.name;
                opt.textContent = p.name;
                pestSelect.appendChild(opt);
            });
            
            updateMetric();
        }

        function updateMetric() {
            const selectedCrop = cropSelect.value;
            const selectedPest = pestSelect.value;
            const pests = pestMapping[selectedCrop] || [];
            const pestObj = pests.find(p => p.name === selectedPest);
            
            if (pestObj) {
                metricSelect.value = pestObj.metric;
            }
        }

        cropSelect.addEventListener('change', updatePests);
        pestSelect.addEventListener('change', updateMetric);
        
        // Initialize on load
        updatePests();

        // --- PEST SURVEILLANCE LOGIC ---
        document.getElementById('pestForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = document.getElementById('pestSubmitBtn');
            btn.disabled = true;
            btn.innerText = "Evaluating...";

            const payload = {
                field_id: document.getElementById('pest_field_id').value,
                crop_name: document.getElementById('pest_crop_name').value,
                pest_name: document.getElementById('pest_name').value,
                metric_type: document.getElementById('pest_metric').value,
                observed_value: parseFloat(document.getElementById('pest_obs_val').value)
            };

            const lang = document.getElementById('langSelector').value;
            try {
                const response = await fetch('/api/v1/pest-surveillance/log', {
                    method: 'POST',
                    headers: { 
                        'Content-Type': 'application/json',
                        'Accept-Language': lang
                    },
                    body: JSON.stringify(payload)
                });
                if (!response.ok) throw new Error("Error evaluating ETL");
                
                const data = await response.json();

                document.getElementById('pestObserved').innerText = `${data.observed_value}`;
                document.getElementById('pestAdvisory').innerText = data.advisory;
                
                const badge = document.getElementById('pestBadge');
                badge.innerText = data.status;
                badge.className = 'px-4 py-2 rounded-full text-sm font-bold border ';
                
                if (data.status === 'ETL_BREACH') badge.className += 'bg-red-500/20 text-red-400 border-red-500/50';
                else if (data.status === 'MONITOR') badge.className += 'bg-yellow-500/20 text-yellow-400 border-yellow-500/50';
                else badge.className += 'bg-green-500/20 text-green-400 border-green-500/50';

                document.getElementById('pestIpm').innerHTML = renderIPM(data.ipm_advisory);

                document.getElementById('pestResultsView').classList.remove('hidden');
                updateUILanguage(document.getElementById('langSelector').value);
                
                // Also refresh history if it's visible
                if (!document.getElementById('pestHistoryView').classList.contains('hidden')) {
                    document.getElementById('viewHistoryBtn').click();
                }

            } catch (error) {
                alert(error.message);
            } finally {
                btn.disabled = false;
                btn.innerText = "Evaluate ETL Risk";
            }
        });

        document.getElementById('viewHistoryBtn').addEventListener('click', async () => {
            const field_id = document.getElementById('pest_field_id').value;
            if(!field_id) return alert("Enter a Field ID first.");

            try {
                const response = await fetch(`/api/v1/pest-surveillance/history/${field_id}`);
                if (!response.ok) throw new Error("Error fetching history");
                
                const data = await response.json();
                
                document.getElementById('historyFieldId').innerText = `ID: ${field_id}`;
                const tbody = document.getElementById('pestHistoryTable');
                tbody.innerHTML = '';
                
                if (data.length === 0) {
                    tbody.innerHTML = `<tr><td colspan="4" class="px-4 py-4 text-center text-slate-500">No logs found for this field.</td></tr>`;
                } else {
                    data.forEach(log => {
                        const date = new Date(log.timestamp).toLocaleString();
                        let statusColor = 'text-green-400';
                        if(log.status === 'ETL_BREACH') statusColor = 'text-red-400';
                        if(log.status === 'MONITOR') statusColor = 'text-yellow-400';

                        tbody.innerHTML += `
                            <tr class="hover:bg-slate-800">
                                <td class="px-4 py-3 whitespace-nowrap">${date}</td>
                                <td class="px-4 py-3">${log.pest_name}</td>
                                <td class="px-4 py-3 font-medium">${log.observed_value}</td>
                                <td class="px-4 py-3 font-bold ${statusColor}">${log.status}</td>
                            </tr>
                        `;
                    });
                }

                document.getElementById('pestHistoryView').classList.remove('hidden');
            } catch (error) {
                alert(error.message);
            }
        });
        
        // --- EXPERT REFERRAL JS LOGIC ---
        const tabReferral = document.getElementById('tabReferral');
        const sectionReferral = document.getElementById('sectionReferral');

        // Update tab listeners
        // --- GEOSPATIAL HOTSPOTS JS LOGIC ---
        const tabHotspots = document.getElementById('tabHotspots');
        const sectionHotspots = document.getElementById('sectionHotspots');
        let mapInitialized = false;
        let map = null;

        function initMap() {
            if (mapInitialized) return;
            map = L.map('hotspotMap').setView([19.7515, 75.7139], 7);
            
            // Standard OSM tiles with CSS inversion for dark theme (No API Key Required)
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
                maxZoom: 19
            }).addTo(map);

            loadMapData();
            loadDistrictSummary();
            mapInitialized = true;
        }

        async function loadMapData() {
            try {
                // Load heatmap points
                const heatRes = await fetch('/api/v1/hotspots/heatmap-points');
                const heatPoints = await heatRes.json();
                
                // Add heatmap layer
                L.heatLayer(heatPoints, {
                    radius: 25, 
                    blur: 15, 
                    maxZoom: 10,
                    gradient: {0.4: 'blue', 0.6: 'lime', 0.8: 'yellow', 1.0: 'red'}
                }).addTo(map);

                // Load geojson for markers
                const geoRes = await fetch('/api/v1/hotspots/geojson');
                const geoData = await geoRes.json();

                L.geoJSON(geoData, {
                    pointToLayer: function (feature, latlng) {
                        let color = '#22c55e'; // green
                        if (feature.properties.severity === 'CRITICAL') color = '#ef4444'; // red
                        else if (feature.properties.severity === 'HIGH') color = '#f97316'; // orange

                        return L.circleMarker(latlng, {
                            radius: 6,
                            fillColor: color,
                            color: '#fff',
                            weight: 1,
                            opacity: 1,
                            fillOpacity: 0.8
                        });
                    },
                    onEachFeature: function (feature, layer) {
                        const p = feature.properties;
                        const popupContent = `
                            <div class="text-sm">
                                <strong class="text-slate-800 text-base">${p.pathogen}</strong><br/>
                                <span class="text-slate-600">Crop:</span> ${p.crop}<br/>
                                <span class="text-slate-600">Severity:</span> 
                                <span class="font-bold ${p.severity==='CRITICAL'?'text-red-600':p.severity==='HIGH'?'text-orange-500':'text-green-600'}">${p.severity}</span><br/>
                                <span class="text-slate-600">Type:</span> ${p.incident_type}<br/>
                                <span class="text-slate-600">District:</span> ${p.district}<br/>
                            </div>
                        `;
                        layer.bindPopup(popupContent);
                    }
                }).addTo(map);

                // Re-apply translations for dynamic popup content (if any have data-i18n, though popups are created on click)
                updateUILanguage(document.getElementById('langSelector').value);

            } catch (e) {
                console.error("Error loading map data", e);
            }
        }

        async function loadDistrictSummary() {
            try {
                const res = await fetch('/api/v1/hotspots/district-summary');
                const data = await res.json();
                
                const tbody = document.getElementById('districtSummaryTable');
                tbody.innerHTML = '';
                
                data.forEach(d => {
                    let alertColor = 'text-green-400';
                    let alertBg = 'bg-green-500/20 border-green-500/50';
                    
                    if (d.alert_status === 'CRITICAL') {
                        alertColor = 'text-red-400';
                        alertBg = 'bg-red-500/20 border-red-500/50';
                    } else if (d.alert_status === 'WATCH') {
                        alertColor = 'text-yellow-400';
                        alertBg = 'bg-yellow-500/20 border-yellow-500/50';
                    }

                    tbody.innerHTML += `
                        <tr class="hover:bg-slate-800">
                            <td class="px-4 py-3 font-medium text-white">${d.district}</td>
                            <td class="px-4 py-3">${d.active_outbreaks}</td>
                            <td class="px-4 py-3">${d.dominant_pathogen}</td>
                            <td class="px-4 py-3">
                                <span class="px-2 py-1 rounded text-xs font-bold border ${alertBg} ${alertColor}">
                                    ${d.alert_status}
                                </span>
                            </td>
                        </tr>
                    `;
                });
            } catch (e) {
                console.error("Error loading district summary", e);
            }
        }

        // --- UPDATE ALL TABS LOGIC ---
        function hideAllSections() {
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
        }

        tabModelA.addEventListener('click', () => {
            hideAllSections();
            tabModelA.classList.remove('text-slate-400', 'border-transparent');
            tabModelA.classList.add('text-emerald-400', 'border-emerald-400');
            sectionModelA.classList.remove('hidden');
        });

        tabPest.addEventListener('click', () => {
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

        tabReferral.addEventListener('click', () => {
            hideAllSections();
            tabReferral.classList.remove('text-slate-400', 'border-transparent');
            tabReferral.classList.add('text-purple-400', 'border-purple-400');
            sectionReferral.classList.remove('hidden');
        });

        // Referral Geo Location
        document.getElementById('refGeoBtn').addEventListener('click', () => {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    (position) => {
                        document.getElementById('ref_lat').value = position.coords.latitude.toFixed(4);
                        document.getElementById('ref_lon').value = position.coords.longitude.toFixed(4);
                    },
                    (error) => alert("Error getting location: " + error.message)
                );
            }
        });

        // Submit Referral Form
        document.getElementById('referralForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = document.getElementById('refSubmitBtn');
            btn.disabled = true;
            btn.innerText = "Routing to lab...";

            const payload = {
                farmer_name: document.getElementById('ref_farmer').value,
                phone_number: document.getElementById('ref_phone').value,
                field_id: 'Auto', // could be dynamically pulled
                crop_name: document.getElementById('ref_crop').value,
                reported_symptoms: document.getElementById('ref_symptoms').value,
                ai_prediction: 'Suspected Late Blight (Model A)',
                ai_confidence: 0.85,
                latitude: parseFloat(document.getElementById('ref_lat').value),
                longitude: parseFloat(document.getElementById('ref_lon').value)
            };

            try {
                const response = await fetch('/api/v1/referral/create-ticket', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
                if (!response.ok) throw new Error("Error creating ticket");
                
                const data = await response.json();

                document.getElementById('refTicketId').innerText = data.ticket_code;
                document.getElementById('refLab').innerText = data.assigned_lab;
                document.getElementById('refDist').innerText = data.distance_km;
                document.getElementById('refContact').innerText = data.lab_contact;
                document.getElementById('refGuidelines').innerText = data.packaging_guidelines;
                
                document.getElementById('refResultsView').classList.remove('hidden');
                updateUILanguage(document.getElementById('langSelector').value);

            } catch (error) {
                alert(error.message);
            } finally {
                btn.disabled = false;
                btn.innerText = "Submit Referral Ticket";
            }
        });

        tabHotspots.addEventListener('click', () => {
            hideAllSections();
            tabHotspots.classList.remove('text-slate-400', 'border-transparent');
            tabHotspots.classList.add('text-orange-400', 'border-orange-400');
            sectionHotspots.classList.remove('hidden');
            // Leaflet requires invalidateSize if initialized while hidden
            if (!mapInitialized) {
                initMap();
            } else {
                setTimeout(() => map.invalidateSize(), 100);
            }
        });

    
        // ─── VISION AI (MODEL B) TAB ─────────────────────────────────────────────

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

        const uiTranslations = {"Crop Health & Pest Surveillance System": {"mr": "पीक आरोग्य आणि कीड पाळत ठेवणे प्रणाली", "hi": "फसल स्वास्थ्य और कीट निगरानी प्रणाली"}, "Unified Dashboard: Disease Risk Forecasting & Pest ETL Rule Engine": {"mr": "एकात्मिक डॅशबोर्ड: रोग धोका अंदाज आणि कीड ETL नियम", "hi": "एकीकृत डैशबोर्ड: रोग जोखिम पूर्वानुमान और कीट ETL नियम"}, "Language:": {"mr": "भाषा:", "hi": "भाषा:"}, "Disease Risk (Model A)": {"mr": "रोग धोका (मॉडेल A)", "hi": "रोग जोखिम (मॉडल A)"}, "Pest Surveillance (ETL)": {"mr": "कीड पाळत ठेवणे (ETL)", "hi": "कीट निगरानी (ETL)"}, "Expert Referral (Lab Routing)": {"mr": "तज्ञ संदर्भ (लॅब)", "hi": "विशेषज्ञ संदर्भ (लैब)"}, "Geospatial Hotspots": {"mr": "भौगोलिक हॉटस्पॉट्स", "hi": "भू-स्थानिक हॉटस्पॉट"}, "Field Parameters": {"mr": "शेत परिमाण", "hi": "खेत पैरामीटर"}, "Crop Type": {"mr": "पिकाचा प्रकार", "hi": "फसल का प्रकार"}, "Crop Variety": {"mr": "पिकाची जात", "hi": "फसल की किस्म"}, "Growth Stage": {"mr": "वाढीचा टप्पा", "hi": "विकास चरण"}, "Soil Type": {"mr": "मातीचा प्रकार", "hi": "मिट्टी का प्रकार"}, "Location": {"mr": "स्थान", "hi": "स्थान"}, "Detect Location": {"mr": "स्थान शोधा", "hi": "स्थान का पता लगाएं"}, "Analyze Disease Risk": {"mr": "रोग धोक्याचे विश्लेषण करा", "hi": "रोग जोखिम का विश्लेषण करें"}, "Current Disease Risk": {"mr": "सध्याचा रोग धोका", "hi": "वर्तमान रोग जोखिम"}, "Executive Summary": {"mr": "कार्यकारी सारांश", "hi": "कार्यकारी सारांश"}, "Actionable Advisory": {"mr": "कृती करण्यायोग्य सल्ला", "hi": "कार्रवाई योग्य सलाह"}, "Cultural Control": {"mr": "सांस्कृतिक नियंत्रण", "hi": "सांस्कृतिक नियंत्रण"}, "Biological Control": {"mr": "जैविक नियंत्रण", "hi": "जैविक नियंत्रण"}, "Chemical Control": {"mr": "रासायनिक नियंत्रण", "hi": "रासायनिक नियंत्रण"}, "4-Day Trajectory (Weather features)": {"mr": "४-दिवसीय हवामान अंदाज", "hi": "४-दिवसीय मौसम प्रक्षेपवक्र"}, "Model Factors (XGBoost Inputs)": {"mr": "मॉडेल घटक (XGBoost)", "hi": "मॉडल कारक (XGBoost)"}, "Log Sensor/Trap Data": {"mr": "सेन्सर/ट्रॅप डेटा नोंदवा", "hi": "सेंसर/ट्रैप डेटा लॉग करें"}, "Field ID": {"mr": "शेत आयडी", "hi": "खेत आईडी"}, "Pest": {"mr": "कीड", "hi": "कीट"}, "Metric Type (Auto-mapped)": {"mr": "मेट्रिक प्रकार", "hi": "मीट्रिक प्रकार"}, "Observed Value": {"mr": "निरीक्षण केलेले मूल्य", "hi": "देखा गया मूल्य"}, "Evaluate ETL Risk": {"mr": "ETL धोक्याचे मूल्यांकन करा", "hi": "ETL जोखिम का मूल्यांकन करें"}, "View Field History": {"mr": "शेताचा इतिहास पहा", "hi": "खेत का इतिहास देखें"}, "ICAR ETL Evaluation Result": {"mr": "ICAR ETL मूल्यांकन निकाल", "hi": "ICAR ETL मूल्यांकन परिणाम"}, "Recommended Action": {"mr": "शिफारस केलेली कृती", "hi": "अनुशंसित कार्रवाई"}, "Escalate to Lab / Expert": {"mr": "लॅब / तज्ञाकडे पाठवा", "hi": "लैब / विशेषज्ञ को भेजें"}, "Farmer Name": {"mr": "शेतकऱ्याचे नाव", "hi": "किसान का नाम"}, "Phone Number": {"mr": "फोन नंबर", "hi": "फ़ोन नंबर"}, "Crop": {"mr": "पीक", "hi": "फसल"}, "Symptoms": {"mr": "लक्षणे", "hi": "लक्षण"}, "Farmer Location": {"mr": "शेतकऱ्याचे स्थान", "hi": "किसान का स्थान"}, "Submit Referral Ticket": {"mr": "संदर्भ तिकीट सबमिट करा", "hi": "रेफरल टिकट सबमिट करें"}, "Ticket Created Successfully": {"mr": "तिकीट यशस्वीरित्या तयार केले", "hi": "टिकट सफलतापूर्वक बनाया गया"}, "Ticket ID": {"mr": "तिकीट आयडी", "hi": "टिकट आईडी"}, "Routing Info": {"mr": "राउटिंग माहिती", "hi": "रूटिंग जानकारी"}, "Physical Sample Packaging Guidelines": {"mr": "नमुना पॅकेजिंग मार्गदर्शक तत्त्वे", "hi": "भौतिक नमूना पैकेजिंग दिशानिर्देश"}, "Live Epidemiological Map (Maharashtra)": {"mr": "थेट रोगराई नकाशा (महाराष्ट्र)", "hi": "लाइव महामारी विज्ञान मानचित्र (महाराष्ट्र)"}, "District Surveillance Summary": {"mr": "जिल्हा पाळत ठेवणे सारांश", "hi": "जिला निगरानी सारांश"}, "District": {"mr": "जिल्हा", "hi": "जिला"}, "Active Outbreaks": {"mr": "सक्रिय प्रादुर्भाव", "hi": "सक्रिय प्रकोप"}, "Dominant Threat": {"mr": "प्रमुख धोका", "hi": "प्रमुख खतरा"}, "Alert Status": {"mr": "अलर्ट स्थिती", "hi": "अलर्ट स्थिति"}};
        
        function updateUILanguage(lang) {
            document.querySelectorAll('[data-i18n]').forEach(el => {
                const key = el.getAttribute('data-i18n');
                if (lang === 'en') {
                    el.innerText = key;
                } else if (uiTranslations[key] && uiTranslations[key][lang]) {
                    el.innerText = uiTranslations[key][lang];
                }
            });
        }
        
        document.getElementById('langSelector').addEventListener('change', (e) => {
            updateUILanguage(e.target.value);
        });
        
        // Initial setup
        updateUILanguage(document.getElementById('langSelector').value);
    
    