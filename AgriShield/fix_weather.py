import re

with open(r"D:\PDD2\AgriShield\lib\screens\disease_risk_screen.dart", "r", encoding="utf-8") as f:
    code = f.read()

# Fix temp/humidity extraction
old_build_vars = """    final temp       = (_result?['avg_temp'] as num?)?.toDouble() ?? 0.0;
    final humidity   = (_result?['avg_humidity'] as num?)?.toDouble() ?? 0.0;"""
new_build_vars = """    final temp       = (_result?['avg_temp'] as num?)?.toDouble() ?? (forecast.isNotEmpty ? (forecast[0]['temp'] as num?)?.toDouble() ?? 0.0 : 0.0);
    final humidity   = (_result?['avg_humidity'] as num?)?.toDouble() ?? (forecast.isNotEmpty ? (forecast[0]['humidity'] as num?)?.toDouble() ?? 0.0 : 0.0);
    final rain       = forecast.isNotEmpty ? (forecast[0]['rain'] as num?)?.toDouble() ?? 0.0 : 0.0;"""
code = code.replace(old_build_vars, new_build_vars)

# Fix VitalCards
new_vitals = """                  Row(children: [
                    _VitalCard(title: 'Temp', val: '${temp.toStringAsFixed(1)}\u00B0C', subtitle: temp > 25 ? 'Warm' : 'Cool', icon: Icons.device_thermostat),
                    const SizedBox(width: 8),
                    _VitalCard(title: 'Humidity', val: '${humidity.toStringAsFixed(0)}%', subtitle: humidity > 85 ? 'Critical' : 'Normal', icon: Icons.water_drop),
                    const SizedBox(width: 8),
                    _VitalCard(title: 'Rain', val: '${rain.toStringAsFixed(1)}mm', subtitle: rain > 2.0 ? 'High' : 'Low', icon: Icons.water),
                  ]),"""
# Note: since there's an encoding issue with the degree symbol, we will use a regex.
vital_regex = r"                  Row\(children: \[\s*\_VitalCard\(title: 'Temp'.*?\]\),"
code = re.sub(vital_regex, new_vitals, code, flags=re.DOTALL)

# Fix _ForecastChip risk math
old_chip = """final risk  = ((day['risk'] as num?)?.toDouble() ?? 0.0) * 100;"""
new_chip = """final risk  = ((day['risk'] as num?)?.toDouble() ?? 0.0);"""
code = code.replace(old_chip, new_chip)

old_chip_text = """Text('${risk.toStringAsFixed(0)}%', style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: color)),"""
new_chip_text = """Text('${risk.toStringAsFixed(1)}%', style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: color)),"""
code = code.replace(old_chip_text, new_chip_text)

with open(r"D:\PDD2\AgriShield\lib\screens\disease_risk_screen.dart", "w", encoding="utf-8") as f:
    f.write(code)

print("Weather and math patched!")
