import re

with open(r"D:\PDD2\AgriShield\lib\screens\disease_risk_screen.dart", "r", encoding="utf-8") as f:
    code = f.read()

# Replace the "Leaf Wet" _VitalCard with the "Rain" one.
code = re.sub(
    r"_VitalCard\(title: 'Leaf Wet', val: humidity > 85 \? '8\.2 hrs' : '3\.1 hrs', subtitle: humidity > 85 \? 'High Sat' : 'Low Sat', icon: Icons\.opacity\)",
    r"_VitalCard(title: 'Rain', val: '${rain.toStringAsFixed(1)}mm', subtitle: rain > 2.0 ? 'High' : 'Low', icon: Icons.water)",
    code
)

with open(r"D:\PDD2\AgriShield\lib\screens\disease_risk_screen.dart", "w", encoding="utf-8") as f:
    f.write(code)

print("Leaf Wet patched!")
