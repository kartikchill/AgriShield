from bs4 import BeautifulSoup

with open('index.html', 'r', encoding='utf-8') as f:
    html = f.read()

soup = BeautifulSoup(html, 'html.parser')

print("Body classes:", soup.body.get('class'))
nav = soup.find('nav')
if nav:
    print("Nav classes:", nav.get('class'))
    
tabs_container = soup.find(id='tabModelA').parent if soup.find(id='tabModelA') else None
if tabs_container:
    print("Tabs container classes:", tabs_container.get('class'))
