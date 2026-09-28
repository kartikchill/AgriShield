import re
html = open('d:/PDD2/crop-risk-system/static/index.html', encoding='utf-8').read()

print('Checking section display states in HTML:')
for sec in ['sectionModelA', 'sectionPest', 'sectionVision', 'sectionReferral', 'sectionHotspots']:
    match = re.search(f'<div id="{sec}".*?class="([^"]*)"', html)
    if match:
        print(f'{sec}: {match.group(1)}')
    else:
        print(f'{sec}: NOT FOUND')

scripts = re.findall(r'<script>(.*?)</script>', html, re.DOTALL)
if len(scripts) > 1:
    js = scripts[1]
    
    # check if variables are defined
    print('\nVariables check:')
    for v in ['tabModelA', 'tabPest', 'tabVision', 'tabReferral', 'tabHotspots']:
        if v in js:
            print(f'{v}: Found')
        else:
            print(f'{v}: Missing')
    
    for v in ['sectionModelA', 'sectionPest', 'sectionVision', 'sectionReferral', 'sectionHotspots']:
        if v in js:
            print(f'{v}: Found')
        else:
            print(f'{v}: Missing')
