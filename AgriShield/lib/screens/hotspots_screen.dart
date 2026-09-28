import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../localization/app_translations.dart';
import '../localization/language_notifier.dart';
import '../services/api_service.dart';
import '../widgets/accessible_audio_button.dart';

class HotspotsScreen extends StatefulWidget {
  const HotspotsScreen({super.key});
  @override
  State<HotspotsScreen> createState() => _HotspotsScreenState();
}

class _HotspotsScreenState extends State<HotspotsScreen> {
  final MapController _mapController = MapController();
  bool _loading = true;
  
  LatLng? _userLocation;
  int _riskLevel = 0;
  String _riskColorStr = 'GREEN';
  String _summary = 'All clear. No verified risks reported nearby.';
  List<Map<String, dynamic>> _hotspots = [];

  String _activeFilter = '5km';
  static const _filterOptions = ['5km', '15km', 'District'];

  @override
  void initState() {
    super.initState();
    _initRadar();
  }

  Future<void> _initRadar() async {
    setState(() => _loading = true);
    try {
      // Simulate network/GPS loading for the demo
      await Future.delayed(const Duration(seconds: 1));
      
      // Hardcode to a rural farming region (e.g., Punjab farmlands) for the satellite mockup
      // instead of using the physical device location which might be an urban city block.
      _userLocation = const LatLng(30.223, 74.948);

      int radius = _activeFilter == '5km' ? 5 : (_activeFilter == '15km' ? 15 : 50);

      // For demo purposes, we will mock the hotspots around the user's location
      _riskLevel = 2;
      _riskColorStr = 'ORANGE';
      _summary = 'Multiple pest threats detected in your immediate vicinity.';
      _hotspots = [
        {
          'lat': _userLocation!.latitude + 0.002,
          'lng': _userLocation!.longitude + 0.002,
          'level': 3,
          'title': 'Pink Bollworm Outbreak',
          'description': 'Severe infestation reported in Cotton Field North.',
        },
        {
          'lat': _userLocation!.latitude - 0.0015,
          'lng': _userLocation!.longitude - 0.003,
          'level': 2,
          'title': 'Aphid Cluster',
          'description': 'Moderate aphid presence in Wheat Sector B.',
        },
        {
          'lat': _userLocation!.latitude + 0.004,
          'lng': _userLocation!.longitude - 0.001,
          'level': 1,
          'title': 'Leaf Rust Risk',
          'description': 'Early signs of rust detected by neighboring farms.',
        }
      ];

    } catch (e) {
      debugPrint("Error in radar init: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _getColorFromStr(String c) {
    switch (c) {
      case 'RED': return const Color(0xFFC62828);
      case 'ORANGE': return const Color(0xFFE65100);
      case 'YELLOW': return Colors.amber.shade600;
      default: return const Color(0xFF1B5E20);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageNotifier.instance,
      builder: (context, _) {
        final lang = LanguageNotifier.instance.languageCode;
        String t(String key) => AppTranslations.t(key, lang);
        
        final riskColor = _getColorFromStr(_riskColorStr);

        return Scaffold(
          backgroundColor: const Color(0xFFFBF9F4),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B4D3E),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(t('Local Hotspot Radar'), style: GoogleFonts.epilogue(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
            actions: [
              IconButton(icon: const Icon(LucideIcons.refreshCcw, color: Colors.white), onPressed: _initRadar),
            ],
          ),
          body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _userLocation == null
              ? Center(child: Text(t('Could not detect location.'), style: GoogleFonts.notoSans(color: Colors.red)))
              : Column(
                  children: [
                    // --- Map Section ---
                    Expanded(
                      flex: 4,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _userLocation!,
                              initialZoom: 15.0, // Zoomed in for satellite mockup
                              minZoom: 9,
                              maxZoom: 18,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                userAgentPackageName: 'com.agrishield.app',
                              ),
                              CircleLayer(
                                circles: [
                                  // User Search Radius
                                  CircleMarker(
                                    point: _userLocation!,
                                    color: const Color(0xFF1B4D3E).withValues(alpha: 0.05),
                                    borderColor: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
                                    borderStrokeWidth: 2,
                                    useRadiusInMeter: true,
                                    radius: _activeFilter == '5km' ? 5000 : (_activeFilter == '15km' ? 15000 : 50000),
                                  ),
                                  // Highlighted Risk Areas
                                  ..._hotspots.map((h) {
                                    final lat = (h['lat'] as num?)?.toDouble() ?? 0;
                                    final lng = (h['lng'] as num?)?.toDouble() ?? 0;
                                    final typeColor = _getColorFromStr(h['level'] == 3 ? 'RED' : (h['level'] == 2 ? 'ORANGE' : 'YELLOW'));
                                    return CircleMarker(
                                      point: LatLng(lat, lng),
                                      color: typeColor.withValues(alpha: 0.25),
                                      borderColor: typeColor,
                                      borderStrokeWidth: 2,
                                      useRadiusInMeter: true,
                                      radius: h['level'] == 3 ? 150 : 100, // Zoomed in radius in meters
                                    );
                                  }),
                                ],
                              ),
                              MarkerLayer(
                                markers: _hotspots.map((h) {
                                  final lat = (h['lat'] as num?)?.toDouble() ?? 0;
                                  final lng = (h['lng'] as num?)?.toDouble() ?? 0;
                                  final typeColor = _getColorFromStr(h['level'] == 3 ? 'RED' : (h['level'] == 2 ? 'ORANGE' : 'YELLOW'));
                                  return Marker(
                                    point: LatLng(lat, lng),
                                    width: 140, height: 80,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(LucideIcons.alertTriangle, color: typeColor, size: 36),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: typeColor, width: 1),
                                          ),
                                          child: Text(
                                            h['title'] ?? '',
                                            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _userLocation!,
                                    width: 60, height: 60,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 24, height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3),
                                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                                          child: Text('My Farm', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF16221C))),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Top Filter Chips
                          Positioned(
                            top: 16, left: 16, right: 16,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _filterOptions.map((opt) {
                                  final isSelected = _activeFilter == opt;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(t(opt), style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF16221C))),
                                      selected: isSelected,
                                      onSelected: (val) {
                                        setState(() { _activeFilter = opt; _initRadar(); });
                                      },
                                      backgroundColor: Colors.white,
                                      selectedColor: const Color(0xFF1B4D3E),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999), side: const BorderSide(color: Color(0xFFE5DDD0))),
                                      showCheckmark: false,
                                      elevation: isSelected ? 4 : 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          // Recenter Button
                          Positioned(
                            bottom: 16, right: 16,
                            child: FloatingActionButton(
                              backgroundColor: Colors.white,
                              mini: true,
                              onPressed: () => _mapController.move(_userLocation!, 15.0),
                              child: const Icon(LucideIcons.target, color: Color(0xFF1B4D3E)),
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    // --- Bottom Alert Feed ---
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF9F4),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.white,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t('Community Hotspot Alerts'),
                                        style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF16221C)),
                                      ),
                                      Text(
                                        '${_hotspots.length} ${t("alerts in")} $_activeFilter',
                                        style: GoogleFonts.spaceGrotesk(fontSize: 13, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                  AccessibleAudioButton(textToSpeak: t('$_summary. You have ${_hotspots.length} alerts in $_activeFilter.')),
                                ],
                              ),
                            ),
                            // Alerts List
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _hotspots.isEmpty ? 1 : _hotspots.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  if (_hotspots.isEmpty) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(32),
                                        child: Text(t('No local alerts. All clear.'), style: GoogleFonts.notoSans(color: Colors.grey[600])),
                                      ),
                                    );
                                  }
                                  
                                  final h = _hotspots[index];
                                  final typeColor = _getColorFromStr(h['level'] == 3 ? 'RED' : (h['level'] == 2 ? 'ORANGE' : 'YELLOW'));
                                  
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE5DDD0)),
                                      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4, height: 48,
                                          decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(2)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                h['title'] ?? 'Alert',
                                                style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF16221C)),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                h['description'] ?? 'No details',
                                                style: GoogleFonts.notoSans(fontSize: 13, color: Colors.grey[700]),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Report New Outbreak CTA
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.white,
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed: () {}, // Report Outbreak Placeholder
                                  icon: const Icon(LucideIcons.alertCircle, color: Color(0xFF1B4D3E)),
                                  label: Text(t('Report Field Outbreak'), style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: const Color(0xFFFBF9F4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
