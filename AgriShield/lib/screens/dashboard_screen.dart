import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../localization/app_translations.dart';
import '../localization/language_notifier.dart';
import '../services/sync_service.dart';
import '../widgets/accessible_audio_button.dart';
import 'hotspots_screen.dart';
import 'expert_referral_screen.dart';

import '../services/api_service.dart';
import '../database/db_helper.dart';
import '../widgets/historical_soil_profile.dart';
import 'extreme_weather_alert_screen.dart';

class DashboardTabNotifier extends ChangeNotifier {
  DashboardTabNotifier._();
  static final instance = DashboardTabNotifier._();
  int _requestedTab = 2;
  int get requestedTab => _requestedTab;
  void switchTo(int index) {
    _requestedTab = index;
    notifyListeners();
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _pendingSync = 0;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _pendingSync = SyncService.instance.pendingCount;
    _isOnline = SyncService.instance.isOnline;
    SyncService.instance.addListener(_onSync);
  }

  @override
  void dispose() {
    SyncService.instance.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    if (mounted) {
      setState(() {
        _pendingSync = SyncService.instance.pendingCount;
        _isOnline = SyncService.instance.isOnline;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageNotifier.instance,
      builder: (context, _) {
        final lang = LanguageNotifier.instance.languageCode;
        String t(String key) => AppTranslations.t(key, lang);

        return Scaffold(
          backgroundColor: const Color(0xFFFEF9F0),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Oversized Scan Crop Hero Button
                GestureDetector(
                  onTap: () => DashboardTabNotifier.instance.switchTo(3), // Navigate to Vision AI Tab
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF1B4D3E).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.scanLine, size: 48, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          t('SCAN CROP NOW'),
                          style: GoogleFonts.epilogue(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('Instant AI leaf diagnosis'),
                          style: GoogleFonts.notoSans(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Navigation Grid (4 Pillars)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _PillarCard(
                      icon: LucideIcons.leaf,
                      title: t('Disease Risk'),
                      subtitle: t('Open 96h Vector Forecast'),
                      color: const Color(0xFFD97706),
                      onTap: () => DashboardTabNotifier.instance.switchTo(0),
                    ),
                    _PillarCard(
                      icon: LucideIcons.bug,
                      title: t('Pest ETL'),
                      subtitle: t('Log Trap Count'),
                      color: const Color(0xFFC62828),
                      onTap: () => DashboardTabNotifier.instance.switchTo(1),
                    ),
                    _PillarCard(
                      icon: LucideIcons.map,
                      title: t('Geospatial Hotspots'),
                      subtitle: t('View Cluster Map'),
                      color: const Color(0xFF1976D2),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HotspotsScreen())),
                    ),
                    _PillarCard(
                      icon: LucideIcons.stethoscope,
                      title: t('KVK Helpline'),
                      subtitle: t('Submit New Leaf Ticket'),
                      color: const Color(0xFF1B4D3E),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertReferralScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // 3. Universal Audio Bar
                AccessibleAudioButton(
                  textToSpeak: t('Tap to Listen to Full Field Summary'),
                  label: t('Tap to Listen to Full Field Summary'),
                  icon: LucideIcons.volume2,
                  color: const Color(0xFFD97706),
                  textColor: Colors.white,
                ),
                const SizedBox(height: 16),

                // Mockup trigger for Cyclone Alert
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.siren, color: Colors.white),
                  label: const Text(
                    "Simulate Extreme Weather Alert", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExtremeWeatherAlertScreen()));
                  },
                ),
                const SizedBox(height: 20),

                // 4. Field Health Overview Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5DDD0), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              t('Plot 4 • Nashik North (Cotton & Soybean)'),
                              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF555555)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t('HEALTHY'),
                              style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(LucideIcons.thermometer, size: 20, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Text(t('29°C / 65% Hum'), style: GoogleFonts.epilogue(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF16221C))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(t('Last checked 12m ago'), style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Historical Soil Profile
                const HistoricalSoilProfile(lat: 20.0, lng: 73.8),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PillarCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PillarCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5DDD0), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF16221C)),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.notoSans(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
