import re
import codecs

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'r', 'utf-8') as f:
    html = f.read()

# 1. Remove the old duplicate tab listeners
old_tabs_regex = r"        tabModelA\.addEventListener\('click', \(\) => \{[\s\S]*?sectionModelA\.classList\.add\('hidden'\);\n        \}\);\n\n"
html = re.sub(old_tabs_regex, "", html)

# 2. Move tabVision declaration up
html = html.replace("        const tabVision = document.getElementById('tabVision');\n        const sectionVision = document.getElementById('sectionVision');\n", "")

insert_point = "        const sectionPest = document.getElementById('sectionPest');\n"
html = html.replace(insert_point, insert_point + "        const tabVision = document.getElementById('tabVision');\n        const sectionVision = document.getElementById('sectionVision');\n")

# 3. Save
with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'w', 'utf-8') as f:
    f.write(html)

print("Fixed tab initialization.")
