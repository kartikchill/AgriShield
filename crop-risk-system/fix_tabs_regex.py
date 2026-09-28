import codecs
import re

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'r', 'utf-8') as f:
    html = f.read()

# Replace sectionHotspots.classList.add('hidden'); with both
html = re.sub(
    r"sectionHotspots\.classList\.add\('hidden'\);",
    r"sectionHotspots.classList.add('hidden');\n            sectionLearning.classList.add('hidden');",
    html
)

# Replace the array
html = re.sub(
    r"const allTabs = \[tabModelA, tabPest, tabVision, tabReferral, tabHotspots\];",
    r"const allTabs = [tabModelA, tabPest, tabVision, tabReferral, tabHotspots, tabLearning];",
    html
)

# Replace the class removal list
html = re.sub(
    r"t\.classList\.remove\('text-emerald-400', 'border-emerald-400', 'text-blue-400', 'border-blue-400', 'text-cyan-400', 'border-cyan-400', 'text-purple-400', 'border-purple-400', 'text-orange-400', 'border-orange-400'\);",
    r"t.classList.remove('text-emerald-400', 'border-emerald-400', 'text-blue-400', 'border-blue-400', 'text-cyan-400', 'border-cyan-400', 'text-purple-400', 'border-purple-400', 'text-orange-400', 'border-orange-400', 'text-pink-400', 'border-pink-400');",
    html
)

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'w', 'utf-8') as f:
    f.write(html)
