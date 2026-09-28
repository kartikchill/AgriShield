import codecs

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'r', 'utf-8') as f:
    html = f.read()

old_hide = """function hideAllSections() {
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
        }"""

new_hide = """function hideAllSections() {
            sectionModelA.classList.add('hidden');
            sectionPest.classList.add('hidden');
            sectionVision.classList.add('hidden');
            sectionReferral.classList.add('hidden');
            sectionHotspots.classList.add('hidden');
            sectionLearning.classList.add('hidden');

            const allTabs = [tabModelA, tabPest, tabVision, tabReferral, tabHotspots, tabLearning];
            allTabs.forEach(t => {
                t.classList.remove('text-emerald-400', 'border-emerald-400', 'text-blue-400', 'border-blue-400', 'text-cyan-400', 'border-cyan-400', 'text-purple-400', 'border-purple-400', 'text-orange-400', 'border-orange-400', 'text-pink-400', 'border-pink-400');
                t.classList.add('text-slate-400', 'border-transparent');
            });
        }"""

html = html.replace(old_hide, new_hide)

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'w', 'utf-8') as f:
    f.write(html)
