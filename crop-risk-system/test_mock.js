
const document = {
    getElementById: (id) => ({ addEventListener: ()=>{}, classList: {add: ()=>{}, remove: ()=>{}}, innerText: '', innerHTML: '' }),
    querySelectorAll: () => []
};
const navigator = {};
const fetch = () => {};
  1: 
  2:         // --- TAB LOGIC ---
  3:         const tabModelA = document.getElementById('tabModelA');
  4:         const tabPest = document.getElementById('tabPest');
  5:         const sectionModelA = document.getElementById('sectionModelA');
  6:         const sectionPest = document.getElementById('sectionPest');
  7: 
  8:         tabModelA.addEventListener('click', () => {
  9:             tabModelA.classList.add('text-emerald-400', 'border-emerald-400');
 10:             tabModelA.classList.remove('text-slate-400', 'border-transparent');
 11:             tabPest.classList.remove('text-blue-400', 'border-blue-400');
 12:             tabPest.classList.add('text-slate-400', 'border-transparent');
 13:             sectionModelA.classList.remove('hidden');
 14:             sectionPest.classList.add('hidden');
 15:         });
 16: 
 17:         tabPest.addEventListener('click', () => {
 18:             tabPest.classList.add('text-blue-400', 'border-blue-400');
 19:             tabPest.classList.remove('text-slate-400', 'border-transparent');
 20:             tabModelA.classList.remove('text-emerald-400', 'border-emerald-400');
 21:             tabModelA.classList.add('text-slate-400', 'border-transparent');
 22:             sectionPest.classList.remove('hidden');
 23:             sectionModelA.classList.add('hidden');
 24:         });
 25: 
 26:         // --- IPM RENDER FUNCTION ---
 27:         function renderIPM(ipm) {
 28:             if (!ipm) return '';
 29:             let html = '<div class="mt-4 space-y-3">';
 30:             if (ipm.cultural_advisory) {
 31:                 html += `<div class="p-3 bg-slate-800 rounded border border-slate-600"><span class="text-green-400 font-semibold block mb-1" data-i18n="Cultural Control">Cultural Control</span><span class="text-slate-300 text-sm">${ipm.cultural_advisory}</span></div>`;
 32:             }
 33:             if (ipm.biological_advisory) {
 34:                 html += `<div class="p-3 bg-slate-800 rounded border border-slate-600"><span class="text-blue-400 font-semibold block mb-1" data-i18n="Biological Control">Biological Control</span><span class="text-slate-300 text-sm">${ipm.biological_advisory}</span></div>`;
 35:             }
 36:             if (ipm.chemical_name) {
 37:                 html += `<div class="p-4 bg-red-900/20 rounded border border-red-500/50">
 38:                     <span class="text-red-400 font-semibold block mb-2">Chemical Control (Restricted Use)</span>
 39:                     <div class="grid grid-cols-2 gap-2 text-sm text-slate-300">
 40:                         <div><span class="text-slate-500">Agrochemical:</span> ${ipm.chemical_name}</div>
 41:                         <div><span class="text-slate-500">Dosage:</span> ${ipm.dosage_per_liter} g/ml per Liter</div>
 42:                         <div class="col-span-2"><span class="text-slate-500">Required PPE:</span> ${ipm.required_ppe}</div>
 43:                         <div class="text-red-300 font-semibold border border-red-500/30 bg-red-500/10 p-1 rounded text-center mt-2">PHI: ${ipm.phi_days} Days</div>
 44:                         <div class="text-orange-300 font-semibold border border-orange-500/30 bg-orange-500/10 p-1 rounded text-center mt-2">REI: ${ipm.re_entry_interval_hours} Hours</div>
 45:                     </div>
 46:                 </div>`;
 47:             }
 48:             html += '</div>';
 49:             return html;
 50:         }
 51: 
 52:         // --- MODEL A LOGIC ---
 53:         document.getElementById('geoBtn').addEventListener('click', () => {
 54:             if (navigator.geolocation) {
 55:                 navigator.geolocation.getCurrentPosition(
 56:                     (position) => {
 57:                         document.getElementById('latitude').value = position.coords.latitude.toFixed(4);
 58:                         document.getElementById('longitude').value = position.coords.longitude.toFixed(4);
 59:                     },
 60:                     (error) => alert("Error getting location: " + error.message)
 61:                 );
 62:             }
 63:         });
 64: 
 65:         document.getElementById('riskForm').addEventListener('submit', async (e) => {
 66:             e.preventDefault();
 67:             const btn = document.getElementById('submitBtn');
 68:             const btnText = document.getElementById('btnText');
 69:             
 70:             const lat = document.getElementById('latitude').value;
 71:             const lon = document.getElementById('longitude').value;
 72:             if(!lat || !lon) return alert("Please provide latitude and longitude.");
 73: 
 74:             btn.disabled = true;
 75:             btnText.innerText = "Analyzing...";
 76: 
 77:             const payload = {
 78:                 crop_type: document.getElementById('crop_type').value,
 79:                 crop_variety: document.getElementById('crop_variety').value,
 80:                 growth_stage: document.getElementById('growth_stage').value,
 81:                 soil_type: document.getElementById('soil_type').value,
 82:                 latitude: parseFloat(lat),
 83:                 longitude: parseFloat(lon)
 84:             };
 85: 
 86:             try {
 87:                 const lang = document.getElementById('langSelector').value;
 88:                 const response = await fetch('/api/assess-risk', {
 89:                     method: 'POST',
 90:                     headers: { 
 91:                         'Content-Type': 'application/json',
 92:                         'Accept-Language': lang
 93:                     },
 94:                     body: JSON.stringify(payload)
 95:                 });
 96:                 
 97:                 if (!response.ok) throw new Error("Server error");
 98:                 const data = await response.json();
 99:                 
100:                 document.getElementById('resDisease').innerText = data.disease;
101:                 document.getElementById('resScore').innerText = `${data.current_risk.toFixed(1)} % Risk Score`;
102:                 document.getElementById('resSummary').innerText = data.summary;
103:                 document.getElementById('resRec').innerText = data.recommendation;
104:                 
105:                 const badge = document.getElementById('resBadge');
106:                 badge.innerText = data.risk_level;
107:                 badge.className = 'inline-block px-4 py-2 rounded-full text-lg font-bold border shadow-[0_0_15px_rgba(0,0,0,0.5)] ';
108:                 
109:                 if (data.risk_level === 'HIGH') badge.className += 'bg-red-500/20 text-red-400 border-red-500/50';
110:                 else if (data.risk_level === 'MEDIUM') badge.className += 'bg-yellow-500/20 text-yellow-400 border-yellow-500/50';
111:                 else badge.className += 'bg-green-500/20 text-green-400 border-green-500/50';
112: 
113:                 const fg = document.getElementById('forecastGrid');
114:                 fg.innerHTML = '';
115:                 data.forecast.forEach(f => {
116:                     fg.innerHTML += `
117:                         <div class="bg-slate-800 border border-slate-700 p-4 rounded-lg flex flex-col justify-between">
118:                             <p class="text-slate-400 text-sm font-medium mb-2">${f.day}</p>
119:                             <h4 class="text-2xl font-bold ${f.level === 'HIGH' ? 'text-red-400' : f.level === 'MEDIUM' ? 'text-yellow-400' : 'text-green-400'} mb-3">${f.risk}%</h4>
120:                             <div class="space-y-1 text-xs text-slate-300">
121:                                 <div class="flex justify-between"><span>T:</span> <span class="font-medium">${f.temp}&deg;C</span></div>
122:                                 <div class="flex justify-between"><span>RH:</span> <span class="font-medium">${f.humidity}%</span></div>
123:                                 <div class="flex justify-between"><span>Rain:</span> <span class="font-medium">${f.rain}mm</span></div>
124:                             </div>
125:                         </div>
126:                     `;
127:                 });
128: 
129:                 const fl = document.getElementById('factorsList');
130:                 fl.innerHTML = '';
131:                 data.factors.forEach(factor => {
132:                     fl.innerHTML += `<li class="flex items-start text-slate-300 text-sm"><span class="mr-2">&bull;</span>${factor}</li>`;
133:                 });
134:                 
135:                 document.getElementById('modelAIpm').innerHTML = renderIPM(data.ipm_advisory);
136:                 document.getElementById('resultsView').classList.remove('hidden');
137:                 updateUILanguage(document.getElementById('langSelector').value);
138:             } catch (error) {
139:                 alert("Error analyzing risk.");
140:             } finally {
141:                 btn.disabled = false;
142:                 btnText.innerText = "Analyze Disease Risk";
143:             }
144:         });
145: 
146:         // --- DYNAMIC DROPDOWNS FOR PEST SURVEILLANCE ---
147:         const pestMapping = {
148:             "Cotton": [
149:                 { name: "Pink Bollworm", metric: "larvae_per_100_plants" }
150:             ],
151:             "Rice": [
152:                 { name: "Stem Borer", metric: "percent_dead_hearts" },
153:                 { name: "Brown Planthopper", metric: "insects_per_hill" }
154:             ],
155:             "Maize": [
156:                 { name: "Fall Armyworm", metric: "trap_count_per_week" }
157:             ],
158:             "Wheat": [
159:                 { name: "Aphids", metric: "aphids_per_tiller" }
160:             ]
161:         };
162: 
163:         const cropSelect = document.getElementById('pest_crop_name');
164:         const pestSelect = document.getElementById('pest_name');
165:         const metricSelect = document.getElementById('pest_metric');
166: 
167:         function updatePests() {
168:             const selectedCrop = cropSelect.value;
169:             const pests = pestMapping[selectedCrop] || [];
170:             
171:             pestSelect.innerHTML = '';
172:             pests.forEach(p => {
173:                 const opt = document.createElement('option');
174:                 opt.value = p.name;
175:                 opt.textContent = p.name;
176:                 pestSelect.appendChild(opt);
177:             });
178:             
179:             updateMetric();
180:         }
181: 
182:         function updateMetric() {
183:             const selectedCrop = cropSelect.value;
184:             const selectedPest = pestSelect.value;
185:             const pests = pestMapping[selectedCrop] || [];
186:             const pestObj = pests.find(p => p.name === selectedPest);
187:             
188:             if (pestObj) {
189:                 metricSelect.value = pestObj.metric;
190:             }
191:         }
192: 
193:         cropSelect.addEventListener('change', updatePests);
194:         pestSelect.addEventListener('change', updateMetric);
195:         
196:         // Initialize on load
197:         updatePests();
198: 
199:         // --- PEST SURVEILLANCE LOGIC ---
200:         document.getElementById('pestForm').addEventListener('submit', async (e) => {
201:             e.preventDefault();
202:             const btn = document.getElementById('pestSubmitBtn');
203:             btn.disabled = true;
204:             btn.innerText = "Evaluating...";
205: 
206:             const payload = {
207:                 field_id: document.getElementById('pest_field_id').value,
208:                 crop_name: document.getElementById('pest_crop_name').value,
209:                 pest_name: document.getElementById('pest_name').value,
210:                 metric_type: document.getElementById('pest_metric').value,
211:                 observed_value: parseFloat(document.getElementById('pest_obs_val').value)
212:             };
213: 
214:             const lang = document.getElementById('langSelector').value;
215:             try {
216:                 const response = await fetch('/api/v1/pest-surveillance/log', {
217:                     method: 'POST',
218:                     headers: { 
219:                         'Content-Type': 'application/json',
220:                         'Accept-Language': lang
221:                     },
222:                     body: JSON.stringify(payload)
223:                 });
224:                 if (!response.ok) throw new Error("Error evaluating ETL");
225:                 
226:                 const data = await response.json();
227: 
228:                 document.getElementById('pestObserved').innerText = `${data.observed_value}`;
229:                 document.getElementById('pestAdvisory').innerText = data.advisory;
230:                 
231:                 const badge = document.getElementById('pestBadge');
232:                 badge.innerText = data.status;
233:                 badge.className = 'px-4 py-2 rounded-full text-sm font-bold border ';
234:                 
235:                 if (data.status === 'ETL_BREACH') badge.className += 'bg-red-500/20 text-red-400 border-red-500/50';
236:                 else if (data.status === 'MONITOR') badge.className += 'bg-yellow-500/20 text-yellow-400 border-yellow-500/50';
237:                 else badge.className += 'bg-green-500/20 text-green-400 border-green-500/50';
238: 
239:                 document.getElementById('pestIpm').innerHTML = renderIPM(data.ipm_advisory);
240: 
241:                 document.getElementById('pestResultsView').classList.remove('hidden');
242:                 updateUILanguage(document.getElementById('langSelector').value);
243:                 
244:                 // Also refresh history if it's visible
245:                 if (!document.getElementById('pestHistoryView').classList.contains('hidden')) {
246:                     document.getElementById('viewHistoryBtn').click();
247:                 }
248: 
249:             } catch (error) {
250:                 alert(error.message);
251:             } finally {
252:                 btn.disabled = false;
253:                 btn.innerText = "Evaluate ETL Risk";
254:             }
255:         });
256: 
257:         document.getElementById('viewHistoryBtn').addEventListener('click', async () => {
258:             const field_id = document.getElementById('pest_field_id').value;
259:             if(!field_id) return alert("Enter a Field ID first.");
260: 
261:             try {
262:                 const response = await fetch(`/api/v1/pest-surveillance/history/${field_id}`);
263:                 if (!response.ok) throw new Error("Error fetching history");
264:                 
265:                 const data = await response.json();
266:                 
267:                 document.getElementById('historyFieldId').innerText = `ID: ${field_id}`;
268:                 const tbody = document.getElementById('pestHistoryTable');
269:                 tbody.innerHTML = '';
270:                 
271:                 if (data.length === 0) {
272:                     tbody.innerHTML = `<tr><td colspan="4" class="px-4 py-4 text-center text-slate-500">No logs found for this field.</td></tr>`;
273:                 } else {
274:                     data.forEach(log => {
275:                         const date = new Date(log.timestamp).toLocaleString();
276:                         let statusColor = 'text-green-400';
277:                         if(log.status === 'ETL_BREACH') statusColor = 'text-red-400';
278:                         if(log.status === 'MONITOR') statusColor = 'text-yellow-400';
279: 
280:                         tbody.innerHTML += `
281:                             <tr class="hover:bg-slate-800">
282:                                 <td class="px-4 py-3 whitespace-nowrap">${date}</td>
283:                                 <td class="px-4 py-3">${log.pest_name}</td>
284:                                 <td class="px-4 py-3 font-medium">${log.observed_value}</td>
285:                                 <td class="px-4 py-3 font-bold ${statusColor}">${log.status}</td>
286:                             </tr>
287:                         `;
288:                     });
289:                 }
290: 
291:                 document.getElementById('pestHistoryView').classList.remove('hidden');
292:             } catch (error) {
293:                 alert(error.message);
294:             }
295:         });
296:         
297:         // --- EXPERT REFERRAL JS LOGIC ---
298:         const tabReferral = document.getElementById('tabReferral');
299:         const sectionReferral = document.getElementById('sectionReferral');
300: 
301:         // Update tab listeners
302:         // --- GEOSPATIAL HOTSPOTS JS LOGIC ---
303:         const tabHotspots = document.getElementById('tabHotspots');
304:         const sectionHotspots = document.getElementById('sectionHotspots');
305:         let mapInitialized = false;
306:         let map = null;
307: 
308:         function initMap() {
309:             if (mapInitialized) return;
310:             map = L.map('hotspotMap').setView([19.7515, 75.7139], 7);
311:             
312:             // Standard OSM tiles with CSS inversion for dark theme (No API Key Required)
313:             L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
314:                 attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
315:                 maxZoom: 19
316:             }).addTo(map);
317: 
318:             loadMapData();
319:             loadDistrictSummary();
320:             mapInitialized = true;
321:         }
322: 
323:         async function loadMapData() {
324:             try {
325:                 // Load heatmap points
326:                 const heatRes = await fetch('/api/v1/hotspots/heatmap-points');
327:                 const heatPoints = await heatRes.json();
328:                 
329:                 // Add heatmap layer
330:                 L.heatLayer(heatPoints, {
331:                     radius: 25, 
332:                     blur: 15, 
333:                     maxZoom: 10,
334:                     gradient: {0.4: 'blue', 0.6: 'lime', 0.8: 'yellow', 1.0: 'red'}
335:                 }).addTo(map);
336: 
337:                 // Load geojson for markers
338:                 const geoRes = await fetch('/api/v1/hotspots/geojson');
339:                 const geoData = await geoRes.json();
340: 
341:                 L.geoJSON(geoData, {
342:                     pointToLayer: function (feature, latlng) {
343:                         let color = '#22c55e'; // green
344:                         if (feature.properties.severity === 'CRITICAL') color = '#ef4444'; // red
345:                         else if (feature.properties.severity === 'HIGH') color = '#f97316'; // orange
346: 
347:                         return L.circleMarker(latlng, {
348:                             radius: 6,
349:                             fillColor: color,
350:                             color: '#fff',
351:                             weight: 1,
352:                             opacity: 1,
353:                             fillOpacity: 0.8
354:                         });
355:                     },
356:                     onEachFeature: function (feature, layer) {
357:                         const p = feature.properties;
358:                         const popupContent = `
359:                             <div class="text-sm">
360:                                 <strong class="text-slate-800 text-base">${p.pathogen}</strong><br/>
361:                                 <span class="text-slate-600">Crop:</span> ${p.crop}<br/>
362:                                 <span class="text-slate-600">Severity:</span> 
363:                                 <span class="font-bold ${p.severity==='CRITICAL'?'text-red-600':p.severity==='HIGH'?'text-orange-500':'text-green-600'}">${p.severity}</span><br/>
364:                                 <span class="text-slate-600">Type:</span> ${p.incident_type}<br/>
365:                                 <span class="text-slate-600">District:</span> ${p.district}<br/>
366:                             </div>
367:                         `;
368:                         layer.bindPopup(popupContent);
369:                     }
370:                 }).addTo(map);
371: 
372:                 // Re-apply translations for dynamic popup content (if any have data-i18n, though popups are created on click)
373:                 updateUILanguage(document.getElementById('langSelector').value);
374: 
375:             } catch (e) {
376:                 console.error("Error loading map data", e);
377:             }
378:         }
379: 
380:         async function loadDistrictSummary() {
381:             try {
382:                 const res = await fetch('/api/v1/hotspots/district-summary');
383:                 const data = await res.json();
384:                 
385:                 const tbody = document.getElementById('districtSummaryTable');
386:                 tbody.innerHTML = '';
387:                 
388:                 data.forEach(d => {
389:                     let alertColor = 'text-green-400';
390:                     let alertBg = 'bg-green-500/20 border-green-500/50';
391:                     
392:                     if (d.alert_status === 'CRITICAL') {
393:                         alertColor = 'text-red-400';
394:                         alertBg = 'bg-red-500/20 border-red-500/50';
395:                     } else if (d.alert_status === 'WATCH') {
396:                         alertColor = 'text-yellow-400';
397:                         alertBg = 'bg-yellow-500/20 border-yellow-500/50';
398:                     }
399: 
400:                     tbody.innerHTML += `
401:                         <tr class="hover:bg-slate-800">
402:                             <td class="px-4 py-3 font-medium text-white">${d.district}</td>
403:                             <td class="px-4 py-3">${d.active_outbreaks}</td>
404:                             <td class="px-4 py-3">${d.dominant_pathogen}</td>
405:                             <td class="px-4 py-3">
406:                                 <span class="px-2 py-1 rounded text-xs font-bold border ${alertBg} ${alertColor}">
407:                                     ${d.alert_status}
408:                                 </span>
409:                             </td>
410:                         </tr>
411:                     `;
412:                 });
413:             } catch (e) {
414:                 console.error("Error loading district summary", e);
415:             }
416:         }
417: 
418:         // --- UPDATE ALL TABS LOGIC ---
419:         function hideAllSections() {
420:             sectionModelA.classList.add('hidden');
421:             sectionPest.classList.add('hidden');
422:             sectionVision.classList.add('hidden');
423:             sectionReferral.classList.add('hidden');
424:             sectionHotspots.classList.add('hidden');
425: 
426:             const allTabs = [tabModelA, tabPest, tabVision, tabReferral, tabHotspots];
427:             allTabs.forEach(t => {
428:                 t.classList.remove('text-emerald-400', 'border-emerald-400', 'text-blue-400', 'border-blue-400', 'text-cyan-400', 'border-cyan-400', 'text-purple-400', 'border-purple-400', 'text-orange-400', 'border-orange-400');
429:                 t.classList.add('text-slate-400', 'border-transparent');
430:             });
431:         }
432: 
433:         tabModelA.addEventListener('click', () => {
434:             hideAllSections();
435:             tabModelA.classList.remove('text-slate-400', 'border-transparent');
436:             tabModelA.classList.add('text-emerald-400', 'border-emerald-400');
437:             sectionModelA.classList.remove('hidden');
438:         });
439: 
440:         tabPest.addEventListener('click', () => {
441:             hideAllSections();
442:             tabPest.classList.remove('text-slate-400', 'border-transparent');
443:             tabPest.classList.add('text-blue-400', 'border-blue-400');
444:             sectionPest.classList.remove('hidden');
445:         });
446: 
447:         tabVision.addEventListener('click', () => {
448:             hideAllSections();
449:             tabVision.classList.remove('text-slate-400', 'border-transparent');
450:             tabVision.classList.add('text-cyan-400', 'border-cyan-400');
451:             sectionVision.classList.remove('hidden');
452:         });
453: 
454:         tabReferral.addEventListener('click', () => {
455:             hideAllSections();
456:             tabReferral.classList.remove('text-slate-400', 'border-transparent');
457:             tabReferral.classList.add('text-purple-400', 'border-purple-400');
458:             sectionReferral.classList.remove('hidden');
459:         });
460: 
461:         // Referral Geo Location
462:         document.getElementById('refGeoBtn').addEventListener('click', () => {
463:             if (navigator.geolocation) {
464:                 navigator.geolocation.getCurrentPosition(
465:                     (position) => {
466:                         document.getElementById('ref_lat').value = position.coords.latitude.toFixed(4);
467:                         document.getElementById('ref_lon').value = position.coords.longitude.toFixed(4);
468:                     },
469:                     (error) => alert("Error getting location: " + error.message)
470:                 );
471:             }
472:         });
473: 
474:         // Submit Referral Form
475:         document.getElementById('referralForm').addEventListener('submit', async (e) => {
476:             e.preventDefault();
477:             const btn = document.getElementById('refSubmitBtn');
478:             btn.disabled = true;
479:             btn.innerText = "Routing to lab...";
480: 
481:             const payload = {
482:                 farmer_name: document.getElementById('ref_farmer').value,
483:                 phone_number: document.getElementById('ref_phone').value,
484:                 field_id: 'Auto', // could be dynamically pulled
485:                 crop_name: document.getElementById('ref_crop').value,
486:                 reported_symptoms: document.getElementById('ref_symptoms').value,
487:                 ai_prediction: 'Suspected Late Blight (Model A)',
488:                 ai_confidence: 0.85,
489:                 latitude: parseFloat(document.getElementById('ref_lat').value),
490:                 longitude: parseFloat(document.getElementById('ref_lon').value)
491:             };
492: 
493:             try {
494:                 const response = await fetch('/api/v1/referral/create-ticket', {
495:                     method: 'POST',
496:                     headers: { 'Content-Type': 'application/json' },
497:                     body: JSON.stringify(payload)
498:                 });
499:                 if (!response.ok) throw new Error("Error creating ticket");
500:                 
501:                 const data = await response.json();
502: 
503:                 document.getElementById('refTicketId').innerText = data.ticket_code;
504:                 document.getElementById('refLab').innerText = data.assigned_lab;
505:                 document.getElementById('refDist').innerText = data.distance_km;
506:                 document.getElementById('refContact').innerText = data.lab_contact;
507:                 document.getElementById('refGuidelines').innerText = data.packaging_guidelines;
508:                 
509:                 document.getElementById('refResultsView').classList.remove('hidden');
510:                 updateUILanguage(document.getElementById('langSelector').value);
511: 
512:             } catch (error) {
513:                 alert(error.message);
514:             } finally {
515:                 btn.disabled = false;
516:                 btn.innerText = "Submit Referral Ticket";
517:             }
518:         });
519: 
520:         tabHotspots.addEventListener('click', () => {
521:             hideAllSections();
522:             tabHotspots.classList.remove('text-slate-400', 'border-transparent');
523:             tabHotspots.classList.add('text-orange-400', 'border-orange-400');
524:             sectionHotspots.classList.remove('hidden');
525:             // Leaflet requires invalidateSize if initialized while hidden
526:             if (!mapInitialized) {
527:                 initMap();
528:             } else {
529:                 setTimeout(() => map.invalidateSize(), 100);
530:             }
531:         });
532: 
533:     
534:         // ─── VISION AI (MODEL B) TAB ─────────────────────────────────────────────
535:         const tabVision = document.getElementById('tabVision');
536:         const sectionVision = document.getElementById('sectionVision');
537: 
538:         // Image preview
539:         const dropZone = document.getElementById('dropZone');
540:         const imageInput = document.getElementById('imageInput');
541:         const previewImage = document.getElementById('previewImage');
542:         const dropPlaceholder = document.getElementById('dropPlaceholder');
543:         const analyzeBtn = document.getElementById('analyzeImageBtn');
544:         const visionBtnText = document.getElementById('visionBtnText');
545:         let selectedFile = null;
546: 
547:         dropZone.addEventListener('click', () => imageInput.click());
548: 
549:         dropZone.addEventListener('dragover', (e) => {
550:             e.preventDefault();
551:             dropZone.classList.add('border-cyan-500');
552:         });
553:         dropZone.addEventListener('dragleave', () => {
554:             dropZone.classList.remove('border-cyan-500');
555:         });
556:         dropZone.addEventListener('drop', (e) => {
557:             e.preventDefault();
558:             dropZone.classList.remove('border-cyan-500');
559:             const file = e.dataTransfer.files[0];
560:             if (file) handleFileSelect(file);
561:         });
562: 
563:         imageInput.addEventListener('change', (e) => {
564:             if (e.target.files[0]) handleFileSelect(e.target.files[0]);
565:         });
566: 
567:         function handleFileSelect(file) {
568:             if (!['image/jpeg', 'image/jpg', 'image/png', 'image/webp'].includes(file.type)) {
569:                 alert('Please upload a JPEG or PNG image.');
570:                 return;
571:             }
572:             selectedFile = file;
573:             const url = URL.createObjectURL(file);
574:             previewImage.src = url;
575:             previewImage.classList.remove('hidden');
576:             dropPlaceholder.classList.add('hidden');
577:             analyzeBtn.disabled = false;
578:             visionBtnText.innerText = 'Analyze Leaf Image';
579:         }
580: 
581:         analyzeBtn.addEventListener('click', async () => {
582:             if (!selectedFile) return;
583:             analyzeBtn.disabled = true;
584:             visionBtnText.innerText = 'Analyzing...';
585: 
586:             const formData = new FormData();
587:             formData.append('file', selectedFile);
588: 
589:             try {
590:                 const resp = await fetch('/api/v1/vision/analyze-image', {
591:                     method: 'POST',
592:                     body: formData
593:                 });
594:                 if (!resp.ok) {
595:                     const err = await resp.json();
596:                     throw new Error(err.detail || 'Server error');
597:                 }
598:                 const data = await resp.json();
599: 
600:                 // Disease name + badge
601:                 document.getElementById('visionDisease').innerText = data.display_name;
602:                 document.getElementById('visionConf').innerText = 'Confidence: ' + data.confidence_pct;
603: 
604:                 const badge = document.getElementById('visionBadge');
605:                 if (data.is_healthy) {
606:                     badge.innerText = 'HEALTHY';
607:                     badge.className = 'inline-block px-4 py-2 rounded-full text-lg font-bold border bg-green-500/20 text-green-400 border-green-500/50';
608:                 } else {
609:                     badge.innerText = 'DISEASE DETECTED';
610:                     badge.className = 'inline-block px-4 py-2 rounded-full text-lg font-bold border bg-red-500/20 text-red-400 border-red-500/50';
611:                 }
612: 
613:                 // Expert review alert
614:                 const expertAlert = document.getElementById('expertAlert');
615:                 if (data.requires_expert_review) {
616:                     expertAlert.classList.remove('hidden');
617:                 } else {
618:                     expertAlert.classList.add('hidden');
619:                 }
620: 
621:                 // Top-3
622:                 const top3 = document.getElementById('top3Container');
623:                 top3.innerHTML = '';
624:                 data.top3.forEach(p => {
625:                     const pct = (p.confidence * 100).toFixed(1);
626:                     const barWidth = Math.round(p.confidence * 100);
627:                     top3.innerHTML += `
628:                         <div class="space-y-1">
629:                             <div class="flex justify-between text-sm">
630:                                 <span class="text-slate-300">${p.rank}. ${p.display_name}</span>
631:                                 <span class="font-bold text-white">${pct}%</span>
632:                             </div>
633:                             <div class="w-full bg-slate-700 rounded-full h-2">
634:                                 <div class="h-2 rounded-full ${p.rank === 1 ? 'bg-cyan-400' : 'bg-slate-500'}" style="width: ${barWidth}%"></div>
635:                             </div>
636:                         </div>`;
637:                 });
638: 
639:                 // IPM link
640:                 const ipmCard = document.getElementById('visionIpmCard');
641:                 const ipmText = document.getElementById('visionIpmText');
642:                 if (data.ipm_lookup) {
643:                     ipmText.innerText = 'Crop: ' + data.ipm_lookup.crop + '   |   Pest/Disease: ' + data.ipm_lookup.pest + '   — Use the Pest Surveillance tab to get the full ICAR IPM advisory for this condition.';
644:                     ipmCard.classList.remove('hidden');
645:                 } else {
646:                     ipmCard.classList.add('hidden');
647:                 }
648: 
649:                 document.getElementById('visionResultsView').classList.remove('hidden');
650: 
651:             } catch (err) {
652:                 alert('Vision AI Error: ' + err.message);
653:             } finally {
654:                 analyzeBtn.disabled = false;
655:                 visionBtnText.innerText = 'Analyze Leaf Image';
656:             }
657:         });
658: 
659:         // Go to referral form button
660:         document.getElementById('goToReferralBtn').addEventListener('click', () => {
661:             hideAllSections();
662:             tabReferral.classList.remove('text-slate-400', 'border-transparent');
663:             tabReferral.classList.add('text-purple-400', 'border-purple-400');
664:             sectionReferral.classList.remove('hidden');
665:         });
666: 
667:         const uiTranslations = {"Crop Health & Pest Surveillance System": {"mr": "पीक आरोग्य आणि कीड पाळत ठेवणे प्रणाली", "hi": "फसल स्वास्थ्य और कीट निगरानी प्रणाली"}, "Unified Dashboard: Disease Risk Forecasting & Pest ETL Rule Engine": {"mr": "एकात्मिक डॅशबोर्ड: रोग धोका अंदाज आणि कीड ETL नियम", "hi": "एकीकृत डैशबोर्ड: रोग जोखिम पूर्वानुमान और कीट ETL नियम"}, "Language:": {"mr": "भाषा:", "hi": "भाषा:"}, "Disease Risk (Model A)": {"mr": "रोग धोका (मॉडेल A)", "hi": "रोग जोखिम (मॉडल A)"}, "Pest Surveillance (ETL)": {"mr": "कीड पाळत ठेवणे (ETL)", "hi": "कीट निगरानी (ETL)"}, "Expert Referral (Lab Routing)": {"mr": "तज्ञ संदर्भ (लॅब)", "hi": "विशेषज्ञ संदर्भ (लैब)"}, "Geospatial Hotspots": {"mr": "भौगोलिक हॉटस्पॉट्स", "hi": "भू-स्थानिक हॉटस्पॉट"}, "Field Parameters": {"mr": "शेत परिमाण", "hi": "खेत पैरामीटर"}, "Crop Type": {"mr": "पिकाचा प्रकार", "hi": "फसल का प्रकार"}, "Crop Variety": {"mr": "पिकाची जात", "hi": "फसल की किस्म"}, "Growth Stage": {"mr": "वाढीचा टप्पा", "hi": "विकास चरण"}, "Soil Type": {"mr": "मातीचा प्रकार", "hi": "मिट्टी का प्रकार"}, "Location": {"mr": "स्थान", "hi": "स्थान"}, "Detect Location": {"mr": "स्थान शोधा", "hi": "स्थान का पता लगाएं"}, "Analyze Disease Risk": {"mr": "रोग धोक्याचे विश्लेषण करा", "hi": "रोग जोखिम का विश्लेषण करें"}, "Current Disease Risk": {"mr": "सध्याचा रोग धोका", "hi": "वर्तमान रोग जोखिम"}, "Executive Summary": {"mr": "कार्यकारी सारांश", "hi": "कार्यकारी सारांश"}, "Actionable Advisory": {"mr": "कृती करण्यायोग्य सल्ला", "hi": "कार्रवाई योग्य सलाह"}, "Cultural Control": {"mr": "सांस्कृतिक नियंत्रण", "hi": "सांस्कृतिक नियंत्रण"}, "Biological Control": {"mr": "जैविक नियंत्रण", "hi": "जैविक नियंत्रण"}, "Chemical Control": {"mr": "रासायनिक नियंत्रण", "hi": "रासायनिक नियंत्रण"}, "4-Day Trajectory (Weather features)": {"mr": "४-दिवसीय हवामान अंदाज", "hi": "४-दिवसीय मौसम प्रक्षेपवक्र"}, "Model Factors (XGBoost Inputs)": {"mr": "मॉडेल घटक (XGBoost)", "hi": "मॉडल कारक (XGBoost)"}, "Log Sensor/Trap Data": {"mr": "सेन्सर/ट्रॅप डेटा नोंदवा", "hi": "सेंसर/ट्रैप डेटा लॉग करें"}, "Field ID": {"mr": "शेत आयडी", "hi": "खेत आईडी"}, "Pest": {"mr": "कीड", "hi": "कीट"}, "Metric Type (Auto-mapped)": {"mr": "मेट्रिक प्रकार", "hi": "मीट्रिक प्रकार"}, "Observed Value": {"mr": "निरीक्षण केलेले मूल्य", "hi": "देखा गया मूल्य"}, "Evaluate ETL Risk": {"mr": "ETL धोक्याचे मूल्यांकन करा", "hi": "ETL जोखिम का मूल्यांकन करें"}, "View Field History": {"mr": "शेताचा इतिहास पहा", "hi": "खेत का इतिहास देखें"}, "ICAR ETL Evaluation Result": {"mr": "ICAR ETL मूल्यांकन निकाल", "hi": "ICAR ETL मूल्यांकन परिणाम"}, "Recommended Action": {"mr": "शिफारस केलेली कृती", "hi": "अनुशंसित कार्रवाई"}, "Escalate to Lab / Expert": {"mr": "लॅब / तज्ञाकडे पाठवा", "hi": "लैब / विशेषज्ञ को भेजें"}, "Farmer Name": {"mr": "शेतकऱ्याचे नाव", "hi": "किसान का नाम"}, "Phone Number": {"mr": "फोन नंबर", "hi": "फ़ोन नंबर"}, "Crop": {"mr": "पीक", "hi": "फसल"}, "Symptoms": {"mr": "लक्षणे", "hi": "लक्षण"}, "Farmer Location": {"mr": "शेतकऱ्याचे स्थान", "hi": "किसान का स्थान"}, "Submit Referral Ticket": {"mr": "संदर्भ तिकीट सबमिट करा", "hi": "रेफरल टिकट सबमिट करें"}, "Ticket Created Successfully": {"mr": "तिकीट यशस्वीरित्या तयार केले", "hi": "टिकट सफलतापूर्वक बनाया गया"}, "Ticket ID": {"mr": "तिकीट आयडी", "hi": "टिकट आईडी"}, "Routing Info": {"mr": "राउटिंग माहिती", "hi": "रूटिंग जानकारी"}, "Physical Sample Packaging Guidelines": {"mr": "नमुना पॅकेजिंग मार्गदर्शक तत्त्वे", "hi": "भौतिक नमूना पैकेजिंग दिशानिर्देश"}, "Live Epidemiological Map (Maharashtra)": {"mr": "थेट रोगराई नकाशा (महाराष्ट्र)", "hi": "लाइव महामारी विज्ञान मानचित्र (महाराष्ट्र)"}, "District Surveillance Summary": {"mr": "जिल्हा पाळत ठेवणे सारांश", "hi": "जिला निगरानी सारांश"}, "District": {"mr": "जिल्हा", "hi": "जिला"}, "Active Outbreaks": {"mr": "सक्रिय प्रादुर्भाव", "hi": "सक्रिय प्रकोप"}, "Dominant Threat": {"mr": "प्रमुख धोका", "hi": "प्रमुख खतरा"}, "Alert Status": {"mr": "अलर्ट स्थिती", "hi": "अलर्ट स्थिति"}};
668:         
669:         function updateUILanguage(lang) {
670:             document.querySelectorAll('[data-i18n]').forEach(el => {
671:                 const key = el.getAttribute('data-i18n');
672:                 if (lang === 'en') {
673:                     el.innerText = key;
674:                 } else if (uiTranslations[key] && uiTranslations[key][lang]) {
675:                     el.innerText = uiTranslations[key][lang];
676:                 }
677:             });
678:         }
679:         
680:         document.getElementById('langSelector').addEventListener('change', (e) => {
681:             updateUILanguage(e.target.value);
682:         });
683:         
684:         // Initial setup
685:         updateUILanguage(document.getElementById('langSelector').value);
686:     
687:     
