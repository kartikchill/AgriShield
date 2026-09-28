import re

with open(r"D:\PDD2\AgriShield\lib\screens\disease_risk_screen.dart", "r", encoding="utf-8") as f:
    code = f.read()

# Replace the VitalCard row directly using a simpler substring
# Find the start of the row and the end of the row
start_str = "                  Row(children: [\n                    _VitalCard(title: 'Temp'"
end_str = "icon: Icons.opacity),\n                  ]),"

start_idx = code.find(start_str)
end_idx = code.find(end_str) + len(end_str)

if start_idx != -1 and end_idx != -1:
    new_row = """                  Row(children: [
                    _VitalCard(title: 'Temp', val: '${temp.toStringAsFixed(1)}\u00B0C', subtitle: temp > 25 ? 'Warm' : 'Cool', icon: Icons.device_thermostat),
                    const SizedBox(width: 8),
                    _VitalCard(title: 'Humidity', val: '${humidity.toStringAsFixed(0)}%', subtitle: humidity > 85 ? 'Critical' : 'Normal', icon: Icons.water_drop),
                    const SizedBox(width: 8),
                    _VitalCard(title: 'Rain', val: '${rain.toStringAsFixed(1)}mm', subtitle: rain > 2.0 ? 'High' : 'Low', icon: Icons.water),
                  ]),"""
    code = code[:start_idx] + new_row + code[end_idx:]

with open(r"D:\PDD2\AgriShield\lib\screens\disease_risk_screen.dart", "w", encoding="utf-8") as f:
    f.write(code)

print("VitalCard patched!")
