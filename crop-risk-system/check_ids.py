html = open('d:/PDD2/crop-risk-system/static/index.html', encoding='utf-8').read()
try:
    js = html.split('<script>')[1].split('</script>')[0]
except IndexError:
    js = html.split('<script>')[2].split('</script>')[0] # Because leafjs is first

import re
for i, line in enumerate(js.split('\n')):
    ids = re.findall(r"document\.getElementById\(['\"]([^'\"]+)['\"]\)", line)
    for id_val in ids:
        if f'id="{id_val}"' not in html and f"id='{id_val}'" not in html:
            print(f"Line {i+1}: missing ID in DOM: {id_val}")
