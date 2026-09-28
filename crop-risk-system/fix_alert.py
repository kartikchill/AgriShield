import codecs

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'r', 'utf-8') as f:
    content = f.read()

content = content.replace('alert("Error analyzing risk.");', 'alert("Error analyzing risk: " + error.message);')

with codecs.open('d:/PDD2/crop-risk-system/static/index.html', 'w', 'utf-8') as f:
    f.write(content)
