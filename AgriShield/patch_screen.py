import re

with open(r"D:\PDD2\AgriShield\lib\screens\disease_risk_screen.dart", "r", encoding="utf-8") as f:
    code = f.read()

# 1. Add geolocator import
if 'geolocator.dart' not in code:
    code = code.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:geolocator/geolocator.dart';")

# 2. Add controllers and _detectLocation to _DiseaseRiskScreenState
state_block = """
  // Form state
  String _cropType    = 'Tomato';
  String _cropVariety = 'N/A';
  String _growthStage = 'Flowering';
  String _soilType    = 'Loamy';

  final TextEditingController _latController = TextEditingController(text: '19.9975');
  final TextEditingController _lonController = TextEditingController(text: '73.7898');
  bool _isDetectingLocation = false;

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location disabled';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permission denied';
      }
      if (permission == LocationPermission.deniedForever) throw 'Permission permanently denied';

      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(4);
        _lonController.text = pos.longitude.toStringAsFixed(4);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not detect location: $e')));
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }
"""
code = re.sub(r'  // Form state.*?String _soilType[^;]+;', state_block.strip(), code, flags=re.DOTALL)

# 3. Update Crop options
code = code.replace("['Soybean', 'Cotton', 'Tomato', 'Wheat', 'Rice', 'Maize']", "['Tomato', 'Potato', 'Soybean', 'Cotton', 'Wheat', 'Rice', 'Maize']")

# 4. Update assessRisk call
old_assess = """      final data = await ApiService.instance.assessRisk(
        cropType:    _cropType,
        cropVariety: _cropVariety,
        growthStage: _growthStage,
        soilType:    _soilType,
        latitude:    19.9975,   // Nashik District â€“ TODO: replace with GPS
        longitude:   73.7898,
      );"""
new_assess = """      final lat = double.tryParse(_latController.text) ?? 19.9975;
      final lon = double.tryParse(_lonController.text) ?? 73.7898;
      
      final data = await ApiService.instance.assessRisk(
        cropType:    _cropType,
        cropVariety: 'N/A',
        growthStage: _growthStage,
        soilType:    _soilType,
        latitude:    lat,
        longitude:   lon,
      );"""
# Note: Since there might be some encoding differences for 'â€“', we will use regex to replace assessRisk block
assess_regex = r"final data = await ApiService\.instance\.assessRisk\([^;]+;"
code = re.sub(assess_regex, new_assess, code, flags=re.DOTALL)


# 5. Replace the UI block for Field Parameters
old_ui = """              Row(children: [
                Expanded(child: _DropdownField('Crop', _cropOptions, _cropType, (v) => setState(() => _cropType = v!))),
                const SizedBox(width: 8),
                Expanded(child: _DropdownField('Growth Stage', _stageOptions, _growthStage, (v) => setState(() => _growthStage = v!))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _DropdownField('Soil Type', _soilOptions, _soilType, (v) => setState(() => _soilType = v!))),
                const SizedBox(width: 8),
                Expanded(child: _TextInputField('Variety', _cropVariety, (v) => _cropVariety = v)),
              ]),
              const SizedBox(height: 12),"""
new_ui = """              _DropdownField('Crop Type', _cropOptions, _cropType, (v) => setState(() => _cropType = v!)),
              const SizedBox(height: 12),
              _DropdownField('Growth Stage', _stageOptions, _growthStage, (v) => setState(() => _growthStage = v!)),
              const SizedBox(height: 12),
              _DropdownField('Soil Type', _soilOptions, _soilType, (v) => setState(() => _soilType = v!)),
              const SizedBox(height: 16),
              
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Location', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                GestureDetector(
                  onTap: _isDetectingLocation ? null : _detectLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFC7EBD1), borderRadius: BorderRadius.circular(4)),
                    child: _isDetectingLocation 
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B4D3E)))
                      : Text('Detect Location', style: GoogleFonts.notoSans(fontSize: 12, color: const Color(0xFF1B4D3E))),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _LocationTextField('Lat (e.g. 28.61)', _latController)),
                const SizedBox(width: 8),
                Expanded(child: _LocationTextField('Lon (e.g. 77.20)', _lonController)),
              ]),
              const SizedBox(height: 12),"""
code = code.replace(old_ui, new_ui)

# 6. Replace 9610% Risk Score bug
code = code.replace("(risk * 100).toStringAsFixed(0)", "risk.toStringAsFixed(1)")

# 7. Add _LocationTextField to bottom
location_textfield = """Widget _LocationTextField(String hint, TextEditingController controller) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC7EBD1)),
        borderRadius: BorderRadius.circular(8)),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.notoSans(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }"""
if "_LocationTextField(" not in code:
    code = code.replace("Widget _TextInputField", location_textfield + "\n\n  Widget _TextInputField")

with open(r"D:\PDD2\AgriShield\lib\screens\disease_risk_screen.dart", "w", encoding="utf-8") as f:
    f.write(code)

print("Patch applied successfully.")
