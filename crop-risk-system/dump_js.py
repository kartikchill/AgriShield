import re
import codecs
html = codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'r', 'utf-8').read()
js = re.findall(r'<script>(.*?)</script>', html, re.DOTALL)[1]
with codecs.open('d:/PDD2/crop-risk-system/debug_full.js', 'w', 'utf-8') as f:
    for i, line in enumerate(js.split('\n')):
        f.write(f'{i+1:3d}: {line}\n')
