import re

new_file_content = """import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class DiseaseRiskScreen extends StatefulWidget {
  const DiseaseRiskScreen({super.key});
  @override
  State<DiseaseRiskScreen> createState() => _DiseaseRiskScreenState();
}

class _DiseaseRiskScreenState extends State<DiseaseRiskScreen> {
  // Form state
  String _cropType    = 'Tomato';
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

      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      setState(() {
        _latController.text = pos!.latitude.toStringAsFixed(4);
        _lonController.text = pos.longitude.toStringAsFixed(4);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not detect location: $e')));
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  // Result state
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _errorMsg;

  static const _cropOptions       = ['Tomato', 'Potato', 'Apple', 'Soybean', 'Cotton', 'Wheat', 'Rice', 'Sugarcane', 'Maize'];
  static const _stageOptions      = ['Seedling', 'Vegetative', 'Flowering', 'Pod Fill', 'Maturity'];
  static const _soilOptions       = ['Black Cotton', 'Red Laterite', 'Sandy Loam', 'Clay Loam', 'Alluvial'];

  @override
  void initState() {
    super.initState();
    _loadCachedResult();
  }

  Future<void> _loadCachedResult() async {
    final cached = await DatabaseHelper.instance.getLatestAssessment();
    if (cached != null && mounted) {
      setState(() {
        _result = {
          'diseases':       cached['diseases_json'] != null ? jsonDecode(cached['diseases_json'] as String) : [],
          'summary':        cached['summary'] ?? '',
          'recommendation': cached['recommendation'] ?? '',
          'forecast':       cached['forecast_json'] != null ? jsonDecode(cached['forecast_json'] as String) : [],
          'ipm_advisory':   cached['ipm_json'] != null ? jsonDecode(cached['ipm_json'] as String) : null,
          'avg_temp':       cached['avg_temp'] ?? 27.0,
          'avg_humidity':   cached['avg_humidity'] ?? 78.0,
        };
        _cropType    = cached['crop_type'] ?? _cropType;
        _growthStage = cached['growth_stage'] ?? _growthStage;
      });
    }
  }

  Future<void> _submitRisk() async {
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final lat = double.tryParse(_latController.text) ?? 19.9975;
      final lon = double.tryParse(_lonController.text) ?? 73.7898;

      final data = await ApiService.instance.assessRisk(
        cropType:    _cropType,
        cropVariety: 'N/A',
        growthStage: _growthStage,
        soilType:    _soilType,
        latitude:    lat,
        longitude:   lon,
      );

      await DatabaseHelper.instance.insertRiskAssessment({
        'field_id':       data['field_id'],
        'crop_type':      _cropType,
        'crop_variety':   'N/A',
        'growth_stage':   _growthStage,
        'diseases_json':  jsonEncode(data['diseases'] ?? []),
        'summary':        data['summary'],
        'recommendation': data['recommendation'],
        'forecast_json':  jsonEncode(data['forecast'] ?? []),
        'ipm_json':       data['ipm_advisory'] != null ? jsonEncode(data['ipm_advisory']) : null,
        'avg_temp':       (data['forecast'] as List?)?.isNotEmpty == true ? (data['forecast'][0]['temp'] ?? 0.0) : 0.0,
        'avg_humidity':   (data['forecast'] as List?)?.isNotEmpty == true ? (data['forecast'][0]['humidity'] ?? 0.0) : 0.0,
        'timestamp':      DateTime.now().toIso8601String(),
      });

      if (mounted) setState(() { _result = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg  = 'Offline: showing cached data. Will sync when online.';
        });
      }
    }
  }

  Color _riskColor(String? level) {
    switch (level?.toUpperCase()) {
      case 'HIGH':
      case 'SEVERE':
        return Colors.red[700]!;
      case 'MEDIUM':
      case 'MODERATE':
        return Colors.orange[700]!;
      default:
        return Colors.green[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final forecast = (_result?['forecast'] as List?) ?? [];
    final diseases = (_result?['diseases'] as List?) ?? [];
    final ipm      = _result?['ipm_advisory'] as Map<String, dynamic>?;
    
    final temp     = (_result?['avg_temp'] as num?)?.toDouble() ?? (forecast.isNotEmpty ? (forecast[0]['temp'] as num?)?.toDouble() ?? 0.0 : 0.0);
    final humidity = (_result?['avg_humidity'] as num?)?.toDouble() ?? (forecast.isNotEmpty ? (forecast[0]['humidity'] as num?)?.toDouble() ?? 0.0 : 0.0);
    final rain     = forecast.isNotEmpty ? (forecast[0]['rain'] as num?)?.toDouble() ?? 0.0 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Location Banner ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF4EFE6), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.location_on, color: Color(0xFF1B4D3E)),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Nashik District, MH', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                    Text('Sector 4 • KVK Station Link', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: Colors.grey[600])),
                  ]),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.circle, size: 8, color: SyncService.instance.isOnline ? Colors.green : Colors.red),
                    const SizedBox(width: 4),
                    Text('Model A (v4.2)', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 10, color: const Color(0xFF1B4D3E))),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Crop Form ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Field Parameters', style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _DropdownField('Crop Type', _cropOptions, _cropType, (v) => setState(() => _cropType = v!)),
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : _submitRisk,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.analytics, color: Colors.white),
                  label: Text(_isLoading ? 'Analyzing...' : 'Run 96h Risk Analysis',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),

          if (_errorMsg != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_errorMsg!, style: GoogleFonts.notoSans(fontSize: 12, color: Colors.orange[900]))),
              ]),
            ),
          ],

          if (_result != null) ...[
            const SizedBox(height: 16),

            // ── Weather Context (Moved to top) ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Current Weather Features', style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(children: [
                  _VitalCard(title: 'Temp', val: '${temp.toStringAsFixed(1)}\u00B0C', subtitle: temp > 25 ? 'Warm' : 'Cool', icon: Icons.device_thermostat),
                  const SizedBox(width: 8),
                  _VitalCard(title: 'Humidity', val: '${humidity.toStringAsFixed(0)}%', subtitle: humidity > 85 ? 'Critical' : 'Normal', icon: Icons.water_drop),
                  const SizedBox(width: 8),
                  _VitalCard(title: 'Rain', val: '${rain.toStringAsFixed(1)}mm', subtitle: rain > 2.0 ? 'High' : 'Low', icon: Icons.water),
                ]),
                if (forecast.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: forecast.map<Widget>((day) => _ForecastChip(day: day)).toList(),
                    ),
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 16),

            // ── Disease Cards List ────────────────────────────────────────────────
            Text('Epidemiological Risk Alerts', style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...diseases.map<Widget>((disease) => _buildDiseaseCard(disease)).toList(),

            // ── IPM Advisory ───────────────────────────────────────────────────
            if (ipm != null) ...[
              const SizedBox(height: 16),
              _IpmAdvisoryCard(ipm: ipm),
            ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(dynamic disease) {
    final name = disease['disease_name'] ?? 'Unknown';
    final riskLevel = disease['risk_level'] ?? 'LOW';
    final score = (disease['score'] as num?)?.toDouble() ?? 0.0;
    final breakdown = disease['explanation_breakdown'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.warning_amber, color: _riskColor(riskLevel)),
            const SizedBox(width: 4),
            Text(riskLevel == 'HIGH' ? 'HIGH RISK' : riskLevel == 'MEDIUM' ? 'MODERATE RISK' : 'LOW RISK',
              style: GoogleFonts.spaceGrotesk(color: _riskColor(riskLevel), fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _riskColor(riskLevel).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12)),
              child: Text('${score.toStringAsFixed(1)}% Score',
                style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: _riskColor(riskLevel))),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showTransparencyModal(name, breakdown),
              child: const Icon(Icons.info_outline, color: Color(0xFF1B4D3E), size: 22),
            ),
          ]),
        ]),
        const SizedBox(height: 8),
        Text(name, style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  void _showTransparencyModal(String name, dynamic breakdown) {
    final fieldMetrics = breakdown['field_metrics'] ?? 'N/A';
    final thresholds = breakdown['required_thresholds'] ?? 'N/A';
    final citation = breakdown['citation'] ?? 'N/A';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFF4EFE6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why is $name at this risk?', style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  _ModalRow('Your Field Weather', fieldMetrics, isBold: true, color: Colors.blue[800]),
                  const Divider(height: 1),
                  _ModalRow('Required Thresholds', thresholds, isBold: true, color: Colors.red[800]),
                ]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.library_books, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(citation, style: GoogleFonts.notoSans(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[700]))),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4D3E)),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Understood', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ModalRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.grey[600]))),
          Expanded(flex: 3, child: Text(value, style: GoogleFonts.notoSans(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black87))),
        ],
      ),
    );
  }

  Widget _DropdownField(String label, List<String> options, String value, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EFE6),
          borderRadius: BorderRadius.circular(8)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: options.contains(value) ? value : options.first,
            isDense: true,
            isExpanded: true,
            items: options.map((o) => DropdownMenuItem(value: o,
              child: Text(o, style: GoogleFonts.notoSans(fontSize: 12)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  Widget _LocationTextField(String hint, TextEditingController controller) {
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
  }
}

class _ForecastChip extends StatelessWidget {
  final dynamic day;
  const _ForecastChip({required this.day});
  @override
  Widget build(BuildContext context) {
    final level = day['level'] as String? ?? 'LOW';
    final risk  = ((day['risk'] as num?)?.toDouble() ?? 0.0);
    final color = level == 'HIGH' ? Colors.red[700]! : level == 'MEDIUM' ? Colors.orange[700]! : Colors.green[700]!;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(day['day'] ?? '', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 4),
        Text('${risk.toStringAsFixed(1)}%', style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(level, style: GoogleFonts.spaceGrotesk(fontSize: 9, color: color)),
      ]),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final String title, val, subtitle;
  final IconData icon;
  const _VitalCard({required this.title, required this.val, required this.subtitle, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF4EFE6), borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: const Color(0xFF1B4D3E)),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold)),
          Text(val, style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(subtitle, style: GoogleFonts.spaceGrotesk(fontSize: 10, color: Colors.red[700])),
        ]),
      ),
    );
  }
}

class _IpmAdvisoryCard extends StatefulWidget {
  final Map<String, dynamic> ipm;
  const _IpmAdvisoryCard({required this.ipm});
  @override
  State<_IpmAdvisoryCard> createState() => _IpmAdvisoryCardState();
}

class _IpmAdvisoryCardState extends State<_IpmAdvisoryCard> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final tabs = <String>['Cultural', 'Biological', 'Chemical'];
    final content = [
      widget.ipm['cultural_advisory'] ?? 'No cultural advisory available.',
      widget.ipm['biological_advisory'] ?? 'Not required at current risk level.',
      widget.ipm['chemical_name'] != null
          ? '${widget.ipm['chemical_name']} @ ${widget.ipm['dosage_per_liter']} ml/L\\nPHI: ${widget.ipm['phi_days']} days | Re-entry: ${widget.ipm['re_entry_interval_hours']}h\\nPPE: ${widget.ipm['required_ppe']}'
          : 'Chemical intervention not required at current risk level.',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('IPM Advisory Protocol', style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFF4EFE6), borderRadius: BorderRadius.circular(10)),
          child: Row(children: tabs.asMap().entries.map((e) {
            final selected = e.key == _tab;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _tab = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : []),
                child: Text(e.value, textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold,
                    color: selected ? const Color(0xFF1B4D3E) : Colors.grey[600])),
              ),
            ));
          }).toList()),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF4EFE6), borderRadius: BorderRadius.circular(12)),
          child: Text(content[_tab], style: GoogleFonts.notoSans(fontSize: 13, color: Colors.black87)),
        ),
      ]),
    );
  }
}
"""

with open(r"D:\PDD2\AgriShield\lib\screens\disease_risk_screen.dart", "w", encoding="utf-8") as f:
    f.write(new_file_content)

print("DiseaseRiskScreen rebuilt with multi-disease support!")
