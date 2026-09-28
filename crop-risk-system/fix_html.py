import codecs
import re

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'r', 'utf-8') as f:
    html = f.read()

# 1. Fix Tailwind URL
html = html.replace('https://cdn.tailwindcss.com?v=3.4.5', 'https://cdn.tailwindcss.com')

# 2. Extract sectionVision from <head>
# Find the start of sectionVision
vision_start = html.find('<!-- ==================== VISION AI SECTION (MODEL B) ==================== -->')
if vision_start != -1 and vision_start < html.find('</head>'):
    print("Found sectionVision in head! Extracting...")
    # Find the end of it (it ends before the tailwind config script)
    vision_end = html.find('    <script>', vision_start)
    vision_html = html[vision_start:vision_end]
    
    # Remove it from head
    html = html[:vision_start] + html[vision_end:]
    
    # Insert it after sectionPest
    # Find the end of sectionPest
    pest_start = html.find('<div id="sectionPest"')
    # We need to find the matching closing div for sectionPest.
    # It's followed by <!-- ==================== EXPERT REFERRAL SECTION ==================== -->
    referral_start = html.find('<!-- ==================== EXPERT REFERRAL SECTION ==================== -->')
    if referral_start != -1:
        html = html[:referral_start] + vision_html + '\n        ' + html[referral_start:]
        print("Moved sectionVision to body.")

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'w', 'utf-8') as f:
    f.write(html)
