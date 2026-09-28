import urllib.request, json, io
from PIL import Image

# Create a 300x300 green image
img = Image.new('RGB', (300, 300), (80, 140, 60))
buf = io.BytesIO()
img.save(buf, format='JPEG')
img_bytes = buf.getvalue()

boundary = b'----TestBoundary'
body = (
    b'--' + boundary + b'\r\n'
    b'Content-Disposition: form-data; name="file"; filename="test_leaf.jpg"\r\n'
    b'Content-Type: image/jpeg\r\n\r\n'
    + img_bytes +
    b'\r\n--' + boundary + b'--\r\n'
)

req = urllib.request.Request(
    'http://127.0.0.1:8000/api/v1/vision/analyze-image',
    data=body,
    headers={'Content-Type': 'multipart/form-data; boundary=----TestBoundary'}
)
try:
    r = urllib.request.urlopen(req)
    data = json.loads(r.read().decode())
    print('Disease:', data['display_name'])
    print('Confidence:', data['confidence_pct'])
    print('Requires expert review:', data['requires_expert_review'])
    print('Top-3:', [(p['display_name'], p['confidence']) for p in data['top3']])
except urllib.error.HTTPError as e:
    print('Error:', e.code, e.read().decode())
