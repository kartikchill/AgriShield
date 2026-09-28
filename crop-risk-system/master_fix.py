import codecs

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'r', 'utf-8') as f:
    content = f.read()

# 1. Fix the literal \n on line 603 that crashes JS
bad = r"document.getElementById('pestResultsView').classList.remove('hidden');\n                updateUILanguage(document.getElementById('langSelector').value);"
good = "document.getElementById('pestResultsView').classList.remove('hidden');\n                updateUILanguage(document.getElementById('langSelector').value);"
content = content.replace(bad, good)

# 2. Remove the duplicate/conflicting tab listener block (lines 370-386)
bad2 = """        tabModelA.addEventListener('click', () => {
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
        });"""
good2 = "        // Tab logic handled below in the unified hideAllSections() block"
content = content.replace(bad2, good2)

# 3. Fix geolocation to work on http by catching the PERMISSION_DENIED error with a note
old_geo = """        document.getElementById('geoBtn').addEventListener('click', () => {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    (position) => {
                        document.getElementById('latitude').value = position.coords.latitude.toFixed(4);
                        document.getElementById('longitude').value = position.coords.longitude.toFixed(4);
                    },
                    (error) => alert(\"Error getting location: \" + error.message)
                );
            }
        });"""
new_geo = """        document.getElementById('geoBtn').addEventListener('click', () => {
            if (!navigator.geolocation) {
                alert('Geolocation is not supported by your browser.');
                return;
            }
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    document.getElementById('latitude').value = position.coords.latitude.toFixed(4);
                    document.getElementById('longitude').value = position.coords.longitude.toFixed(4);
                },
                (err) => {
                    if (err.code === 1) {
                        // Permission denied – fill in defaults so user can still test
                        document.getElementById('latitude').value = '19.0760';
                        document.getElementById('longitude').value = '72.8777';
                        alert('Location permission denied. Using Mumbai coords as fallback. You can change them manually.');
                    } else {
                        alert('Location error: ' + err.message);
                    }
                },
                { timeout: 8000 }
            );
        });"""
content = content.replace(old_geo, new_geo)

# 4. Same fix for referral geo btn
old_ref_geo = """        document.getElementById('refGeoBtn').addEventListener('click', () => {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    (position) => {
                        document.getElementById('ref_lat').value = position.coords.latitude.toFixed(4);
                        document.getElementById('ref_lon').value = position.coords.longitude.toFixed(4);
                    },
                    (error) => alert(\"Error getting location: \" + error.message)
                );
            }
        });"""
new_ref_geo = """        document.getElementById('refGeoBtn').addEventListener('click', () => {
            if (!navigator.geolocation) {
                alert('Geolocation is not supported by your browser.');
                return;
            }
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    document.getElementById('ref_lat').value = position.coords.latitude.toFixed(4);
                    document.getElementById('ref_lon').value = position.coords.longitude.toFixed(4);
                },
                (err) => {
                    if (err.code === 1) {
                        document.getElementById('ref_lat').value = '19.0760';
                        document.getElementById('ref_lon').value = '72.8777';
                        alert('Location permission denied. Using Mumbai coords as fallback.');
                    } else {
                        alert('Location error: ' + err.message);
                    }
                },
                { timeout: 8000 }
            );
        });"""
content = content.replace(old_ref_geo, new_ref_geo)

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'w', 'utf-8') as f:
    f.write(content)

print("All fixes applied.")
