import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../database/db_helper.dart';
import '../localization/app_translations.dart';
import '../localization/language_notifier.dart';
import 'accessible_audio_button.dart';

class HistoricalSoilProfile extends StatefulWidget {
  final double lat;
  final double lng;
  const HistoricalSoilProfile({super.key, required this.lat, required this.lng});

  @override
  State<HistoricalSoilProfile> createState() => _HistoricalSoilProfileState();
}

class _HistoricalSoilProfileState extends State<HistoricalSoilProfile> {
  bool _isLoading = true;
  Map<String, dynamic>? _soilData;

  @override
  void initState() {
    super.initState();
    _fetchSoilData();
  }

  Future<void> _fetchSoilData() async {
    try {
      final data = await ApiService.instance.getSoilHealth(widget.lat, widget.lng);
      if (data != null) {
        await DatabaseHelper.instance.cacheSoilHealth(widget.lat, widget.lng, data);
        if (mounted) {
          setState(() {
            _soilData = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _soilData = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      final cached = await DatabaseHelper.instance.getCachedSoilHealth();
      if (mounted) {
        setState(() {
          _soilData = cached;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageNotifier.instance,
      builder: (context, _) {
        if (_isLoading) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final lang = LanguageNotifier.instance.languageCode;
        String t(String key) => AppTranslations.t(key, lang);

        if (_soilData == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Color(0xFFE65100)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t('Unlock Your Soil\'s Potential'),
                        style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                      ),
                    ),
                    AccessibleAudioButton(
                      textToSpeak: t('We couldn\'t find official soil records for your location. Knowing your soil health prevents crop failure and saves money on fertilizers. Register for a free test via the official Ministry of Agriculture app.'),
                      label: t('Listen'),
                      icon: LucideIcons.volume2,
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  t('We couldn\'t find official soil records for your location. Knowing your soil health prevents crop failure and saves money on fertilizers. Register for a free test via the official Ministry of Agriculture app.'),
                  style: GoogleFonts.notoSans(fontSize: 14, color: const Color(0xFF5D4037)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.kt_goi_shc');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(LucideIcons.download),
                  label: Text(t('Download Official SHC App')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        }

        List<String> crops = [];
        if (_soilData!['recommended_crops'] is List) {
          crops = List<String>.from(_soilData!['recommended_crops']);
        } else if (_soilData!['recommended_crops'] is String) {
          crops = (_soilData!['recommended_crops'] as String).split(',');
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5DDD0), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      t('Historical Soil Profile'),
                      style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF16221C)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AccessibleAudioButton(
                    textToSpeak: t('Based on your location\'s soil profile, these crops will yield the highest results with minimal fertilizer.'),
                    label: t('Listen'),
                    icon: LucideIcons.volume2,
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBadge('pH', _soilData!['ph_level'].toString(), Colors.blue),
                  _buildBadge('N', '${_soilData!['nitrogen_N']} kg/ha', Colors.green),
                  _buildBadge('P', '${_soilData!['phosphorus_P']} kg/ha', Colors.orange),
                  _buildBadge('K', '${_soilData!['potassium_K']} kg/ha', Colors.red),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                t('Best Suited Crops for Your Soil'),
                style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E)),
              ),
              const SizedBox(height: 8),
              Text(
                t('Based on your location\'s soil profile, these crops will yield the highest results with minimal fertilizer.'),
                style: GoogleFonts.notoSans(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: crops.map((crop) => Chip(
                  label: Text(t(crop.trim()), style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
                  backgroundColor: const Color(0xFFE8F5E9),
                  side: const BorderSide(color: Color(0xFF81C784)),
                  avatar: const Icon(LucideIcons.leaf, size: 16, color: Color(0xFF2E7D32)),
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(String label, String value, MaterialColor color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: color.shade200),
          ),
          child: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: color.shade700)),
        ),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
      ],
    );
  }
}
