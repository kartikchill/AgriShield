import codecs

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'r', 'utf-8') as f:
    lines = f.readlines()

new_lines = []
skip = False
for line in lines:
    if "const tabVision = document.getElementById('tabVision');" in line:
        continue
    if "const sectionVision = document.getElementById('sectionVision');" in line:
        continue
    
    new_lines.append(line)
    
    if "const sectionPest = document.getElementById('sectionPest');" in line:
        new_lines.append("        const tabVision = document.getElementById('tabVision');\n")
        new_lines.append("        const sectionVision = document.getElementById('sectionVision');\n")

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'w', 'utf-8') as f:
    f.writelines(new_lines)
