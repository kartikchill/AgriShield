import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'screens/tickets_screen.dart';
import 'screens/disease_risk_screen.dart';
import 'screens/pest_surveillance_screen.dart';
import 'screens/vision_ai_screen.dart';
import 'screens/expert_referral_screen.dart';
import 'screens/hotspots_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_tutorial_screen.dart';
import 'services/sync_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'localization/app_translations.dart';
import 'localization/language_notifier.dart';
import 'widgets/floating_voice_assistant.dart';
import 'database/db_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Init DB (creates tables on first run)
  await DatabaseHelper.instance.database;
  
  await ApiService.loadLanguage();
  
  // Init Notifications
  await NotificationService().init();
  
  // Start background sync (5s timer → drains sync_queue to FastAPI)
  SyncService.instance.start();
  runApp(const AgriShieldApp());
}

class AgriShieldApp extends StatelessWidget {
  const AgriShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGRI-SHIELD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFEF9F0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4D3E),
          primary: const Color(0xFF1B4D3E),
          secondary: const Color(0xFF2E7D32),
          tertiary: const Color(0xFFE65100),
          surface: Colors.white,
          surfaceContainerLow: const Color(0xFFF8F3EA),
        ),
        textTheme: GoogleFonts.notoSansTextTheme().copyWith(
          headlineLarge: GoogleFonts.epilogue(fontWeight: FontWeight.bold, color: const Color(0xFF16221C)),
          titleLarge: GoogleFonts.epilogue(fontWeight: FontWeight.bold, color: const Color(0xFF16221C)),
          labelSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFEF9F0),
          foregroundColor: Color(0xFF1B4D3E),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE5DDD0), width: 1.5),
          ),
        ),
      ),
      home: const OnboardingTutorialScreen(),
    );
  }
}

class TourStep {
  final int tabIndex;
  final String textEn;
  final String textHi;
  
  TourStep({
    required this.tabIndex, 
    required this.textEn, 
    required this.textHi,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // Default to Dashboard
  bool _isOnline    = SyncService.instance.isOnline;
  int  _pendingSync = SyncService.instance.pendingCount;

  // Tour properties
  bool _isTourActive = true;
  final FlutterTts _tts = FlutterTts();

  final List<TourStep> _tourSteps = [
    // 0. Dashboard
    TourStep(
      tabIndex: 2,
      textEn: "Welcome to Agri-Shield. This is your main dashboard.",
      textHi: "यहाँ आप अपनी फसलों और मौसम का सारांश देख सकते हैं।", // Here you can see crop and weather summary
    ),
    // 1. Disease Risk
    TourStep(
      tabIndex: 0,
      textEn: "This is the Disease Risk tab. It shows the current risk levels.",
      textHi: "निचे दिए गए कार्ड्स में आपको बीमारी का नाम और उपाय मिलेगा।", // In the cards below you will find the disease name and remedies
    ),
    // 2. Pest ETL (Part 1 - Form Top)
    TourStep(
      tabIndex: 1,
      textEn: "Here in Pest Surveillance, you can report pest counts.",
      textHi: "सबसे पहले, इस जगह पर अपनी फसल चुनें।", // First, select your crop in this place.
    ),
    // 3. Pest ETL (Part 2 - Form Input)
    TourStep(
      tabIndex: 1,
      textEn: "Then, carefully enter the exact number of pests observed in your field.",
      textHi: "और यहाँ, कीटों की सही संख्या डालें।", // And here, enter the exact pest count.
    ),
    // 4. Vision AI (Part 1 - Info)
    TourStep(
      tabIndex: 3,
      textEn: "Use Vision AI to diagnose plant diseases instantly.",
      textHi: "यह AI आपके पौधों की बीमारियों को पहचानता है।", // This AI identifies your plant diseases.
    ),
    // 5. Vision AI (Part 2 - Buttons)
    TourStep(
      tabIndex: 3,
      textEn: "Tap the camera button to take a photo of an infected leaf.",
      textHi: "फोटो लेने के लिए इस कैमरा बटन पर क्लिक करें।", // Click on this camera button to take a photo.
    ),
    // 6. Tickets
    TourStep(
      tabIndex: 4,
      textEn: "Track your expert consultations here in the Tickets screen.",
      textHi: "यहाँ आप अपने पुराने सवालों के जवाब पढ़ सकते हैं।", // Here you can read answers to your old questions.
    ),
    // 7. Hotspot
    TourStep(
      tabIndex: 5, // We use index 5 to show HotspotsScreen temporarily
      textEn: "Finally, the Geospatial Hotspot map shows regional disease outbreaks.",
      textHi: "लाल रंग के क्षेत्र खतरे को दर्शाते हैं। हमेशा सावधान रहें!", // Red areas show danger. Always be careful!
    ),
  ];

  List<Widget> get _screens => [
    DiseaseRiskScreen(key: ValueKey(ApiService.currentLanguageCode)),
    const PestSurveillanceScreen(),
    const DashboardScreen(),
    const VisionAiScreen(),
    const TicketsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SyncService.instance.addListener(_onSyncUpdate);
    DashboardTabNotifier.instance.addListener(_onDashboardTabRequest);
    
    // Start automated tour
    Future.delayed(const Duration(milliseconds: 500), _startTour);
  }

  Future<void> _startTour() async {
    if (!mounted) return;
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.45); // Speak slowly as requested

    for (var step in _tourSteps) {
      if (!mounted || !_isTourActive) break;

      // Switch tab
      setState(() {
        _currentIndex = step.tabIndex;
      });
      
      // Wait for UI to settle and highlight to animate
      await Future.delayed(const Duration(milliseconds: 800));

      // Speak English
      if (!mounted || !_isTourActive) break;
      await _tts.setLanguage("en-IN");
      await _tts.speak(step.textEn);
      
      // Short pause
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Speak Hindi
      if (!mounted || !_isTourActive) break;
      await _tts.setLanguage("hi-IN");
      await _tts.speak(step.textHi);
      
      // Generous delay before moving to next feature
      await Future.delayed(const Duration(milliseconds: 1500)); 
    }

    if (mounted) {
      setState(() {
        _isTourActive = false;
        _currentIndex = 2; // Return to dashboard
      });
    }
  }

  void _skipTour() {
    _tts.stop();
    setState(() {
      _isTourActive = false;
      _currentIndex = 2;
    });
  }

  void _onDashboardTabRequest() {
    if (!_isTourActive) {
      setState(() => _currentIndex = DashboardTabNotifier.instance.requestedTab);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    SyncService.instance.removeListener(_onSyncUpdate);
    DashboardTabNotifier.instance.removeListener(_onDashboardTabRequest);
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) {
      setState(() {
        _isOnline    = SyncService.instance.isOnline;
        _pendingSync = SyncService.instance.pendingCount;
      });
    }
  }

  Future<void> _callHelpline() async {
    await SystemChannels.platform.invokeMethod('url/launch', 'tel:18001801551');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.t('AGRI-SHIELD', ApiService.currentLanguageCode),
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1B4D3E)),
            ),
            Text(
              AppTranslations.t('MASTER FIELD HUB', ApiService.currentLanguageCode),
              style: GoogleFonts.epilogue(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFF16221C), letterSpacing: -0.5),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.circle,
                  size: 8,
                  color: _isOnline ? const Color(0xFF2E7D32) : Colors.orange),
                const SizedBox(width: 6),
                Text(
                  _isOnline
                      ? (_pendingSync > 0 ? 'Syncing $_pendingSync items...' : 'Live • Synced')
                      : 'Offline • $_pendingSync queued',
                  style: GoogleFonts.spaceGrotesk(fontSize: 10, color: const Color(0xFF555555), fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
        actions: [
          // Language selector
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F3EA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: PopupMenuButton<String>(
              initialValue: ApiService.currentLanguageCode,
              onSelected: (String langCode) {
                setState(() {
                  ApiService.currentLanguageCode = langCode;
                LanguageNotifier.instance.setLanguage(langCode);
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'en', child: Text('English (EN)')),
                const PopupMenuItem<String>(value: 'hi', child: Text('Hindi (हि)')),
                const PopupMenuItem<String>(value: 'mr', child: Text('Marathi (म)')),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(LucideIcons.globe, size: 14, color: Color(0xFF1B4D3E)),
                    const SizedBox(width: 4),
                    Text(
                      ApiService.currentLanguageCode == 'en' ? 'EN' : 
                      ApiService.currentLanguageCode == 'hi' ? 'हि' : 'म',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            onBackgroundImageError: (_, __) {},
            backgroundImage: const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuC3XxdycCHyPoUsza3EUhwIwP5IKH7DXlgoJaGmknS1BNxbfgHJ0PXgafmjVpkNYx2slmUrUf7PNStVPWjeNPImGOjYleE54DD-Et_ybWAW-p7NotDG-TenYtBvrpjelGdttXqtBPGyXpIwk1n5Rz4vYFqhWsFaYVxQmqbXbkg2-ggkKXEMT9WOT7VJ5wI0b3URfl1uh3zAZlf60GsQ1rJ9XfymesVcgcc36_TNsLuHXp45vA02qrMS2g'),
          ),
          const SizedBox(width: 16),
        ],
      ),

      // ── Drawer ───────────────────────────────────────────────────────
      drawer: Drawer(
        backgroundColor: const Color(0xFFFEF9F0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              color: const Color(0xFFF8F3EA),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    onBackgroundImageError: (_, __) {},
                    backgroundImage: const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuC3XxdycCHyPoUsza3EUhwIwP5IKH7DXlgoJaGmknS1BNxbfgHJ0PXgafmjVpkNYx2slmUrUf7PNStVPWjeNPImGOjYleE54DD-Et_ybWAW-p7NotDG-TenYtBvrpjelGdttXqtBPGyXpIwk1n5Rz4vYFqhWsFaYVxQmqbXbkg2-ggkKXEMT9WOT7VJ5wI0b3URfl1uh3zAZlf60GsQ1rJ9XfymesVcgcc36_TNsLuHXp45vA02qrMS2g'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rajesh Patil', style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF16221C))),
                        Text('KHANDESH SECTOR #4', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: const Color(0xFF555555), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Sync Status Card ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5DDD0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(LucideIcons.database, size: 14, color: _isOnline ? const Color(0xFF2E7D32) : Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(child: Text('Offline SQLite DB', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Icon(Icons.circle, size: 8,
                              color: _isOnline ? const Color(0xFF2E7D32) : Colors.orange),
                            const SizedBox(width: 4),
                            Text(_isOnline ? 'Online' : 'Offline',
                              style: GoogleFonts.spaceGrotesk(fontSize: 10,
                                color: _isOnline ? const Color(0xFF1B5E20) : Colors.orange[900],
                                fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(LucideIcons.cloudCog, size: 14, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 4),
                              Expanded(child: Text('Offline Queue', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Flexible(
                          child: GestureDetector(
                            onTap: () => SyncService.instance.forceSyncNow(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _pendingSync > 0 ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12)),
                              child: Text('$_pendingSync Queued${_pendingSync > 0 ? " (tap to sync)" : ""}',
                                style: GoogleFonts.spaceGrotesk(fontSize: 10,
                                  color: _pendingSync > 0 ? Colors.orange[900] : const Color(0xFF1B5E20),
                                  fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.stethoscope, color: Color(0xFF1B4D3E)),
                    title: Text('Expert Referral', style: GoogleFonts.notoSans()),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertReferralScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.map, color: Color(0xFF1B4D3E)),
                    title: Text('Geospatial Hotspots', style: GoogleFonts.notoSans()),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HotspotsScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.refreshCcw, color: Color(0xFF1B4D3E)),
                    title: Text('Active Learning Loop', style: GoogleFonts.notoSans()),
                    subtitle: Text('Submit treatment feedback', style: GoogleFonts.notoSans(fontSize: 11, color: Colors.grey[600])),
                    onTap: () {
                      Navigator.pop(context);
                      _showFeedbackSheet(context);
                    },
                  ),
                ],
              ),
            ),

            // ── KVK Helpline Button ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                onPressed: _callHelpline,
                icon: const Icon(LucideIcons.phoneCall),
                label: const Text('KVK Kisan Helpline\n1800-180-1551', textAlign: TextAlign.center),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      body: SafeArea(
        child: Stack(
          children: [
            _currentIndex == 5 ? const HotspotsScreen() : _screens[_currentIndex],
            const FloatingVoiceAssistant(),
            
            // App Tour Overlay Widget
            if (_isTourActive)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF1B4D3E),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.map, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Guided Tour in Progress...',
                            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: _skipTour,
                          child: Text('SKIP', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFFFB74D), fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      bottomNavigationBar: ListenableBuilder(
        listenable: LanguageNotifier.instance,
        builder: (context, _) => BottomNavigationBar(
          currentIndex: _currentIndex < 5 ? _currentIndex : 2,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          iconSize: 28,
          selectedItemColor: const Color(0xFF1B4D3E),
          unselectedItemColor: const Color(0xFF94A3B8),
          backgroundColor: Colors.white,
          selectedLabelStyle: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
          items: [
            BottomNavigationBarItem(icon: const Icon(LucideIcons.leaf),         label: AppTranslations.t('Disease Risk', LanguageNotifier.instance.languageCode)),
            BottomNavigationBarItem(icon: const Icon(LucideIcons.bug),          label: AppTranslations.t('Pest ETL', LanguageNotifier.instance.languageCode)),
            BottomNavigationBarItem(icon: const Icon(Icons.dashboard_outlined), label: AppTranslations.t('Dashboard', LanguageNotifier.instance.languageCode)),
            BottomNavigationBarItem(icon: const Icon(LucideIcons.camera),       label: AppTranslations.t('Vision AI', LanguageNotifier.instance.languageCode)),
            BottomNavigationBarItem(icon: const Icon(LucideIcons.ticket),       label: AppTranslations.t('My Tickets', LanguageNotifier.instance.languageCode)),
          ],        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    final ticketCtrl      = TextEditingController();
    final treatmentCtrl   = TextEditingController();
    String efficacy = 'SUCCESS';
    String batchSize = '1 Ticket (Single)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: StatefulBuilder(builder: (ctx, setLocal) => Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Text('Submit Treatment Feedback', style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Helps retrain the AI model for better accuracy', style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          
          // Batch Training Selection Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: batchSize,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1B4D3E)),
                items: ['1 Ticket (Single)', '5 Tickets (Batch)', '10 Tickets (Batch)', 'All Pending (Bulk)']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text('Tickets for Model Training: $value', style: GoogleFonts.notoSans(fontSize: 13, color: Colors.black87)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setLocal(() => batchSize = newValue);
                    if (newValue != '1 Ticket (Single)') {
                      ticketCtrl.text = 'BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                    } else {
                      ticketCtrl.text = '';
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          TextField(controller: ticketCtrl,
            decoration: InputDecoration(labelText: 'Ticket ID(s)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
          const SizedBox(height: 10),
          TextField(controller: treatmentCtrl,
            decoration: InputDecoration(labelText: 'Treatment Applied',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
          const SizedBox(height: 10),
          Row(children: ['SUCCESS', 'PARTIAL', 'FAILED'].map((e) => Expanded(
            child: GestureDetector(
              onTap: () => setLocal(() => efficacy = e),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: efficacy == e
                      ? (e == 'SUCCESS' ? Colors.green : e == 'PARTIAL' ? Colors.orange : Colors.red)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8)),
                child: Text(e, textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold,
                    color: efficacy == e ? Colors.white : Colors.black87)),
              ),
            ),
          )).toList()),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (ticketCtrl.text.isEmpty || treatmentCtrl.text.isEmpty) return;
                Navigator.pop(context);
                try {
                  await ApiService.instance.submitFeedback(
                    originalTicketId: ticketCtrl.text,
                    farmerId: 'FARMER-001',
                    treatmentApplied: treatmentCtrl.text,
                    treatmentEfficacy: efficacy,
                    currentStatus: efficacy == 'SUCCESS' ? 'RESOLVED' : 'ESCALATED',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Feedback submitted! AI model updated.', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                        backgroundColor: Colors.green[800]));
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Feedback saved – will sync when online.', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                        backgroundColor: Colors.orange[800]));
                  }
                }
              },
              child: Text('Submit Feedback', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }
}
