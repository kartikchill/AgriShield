import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import '../localization/language_notifier.dart';

class ExtremeWeatherAlertScreen extends StatefulWidget {
  const ExtremeWeatherAlertScreen({super.key});

  @override
  State<ExtremeWeatherAlertScreen> createState() => _ExtremeWeatherAlertScreenState();
}

class _ExtremeWeatherAlertScreenState extends State<ExtremeWeatherAlertScreen> with SingleTickerProviderStateMixin {
  late FlutterTts _flutterTts;
  late AnimationController _flashController;
  Timer? _ttsTimer;
  Timer? _beepTimer;
  bool _isDisposed = false;
  
  final String _advisoryEn = "WARNING! Extreme Weather Alert. A severe Cyclone is approaching your region with heavy winds. Secure livestock, harvest mature crops immediately, and move to a safe indoor location. This is a red alert.";
  final String _advisoryHi = "चेतावनी! चक्रवात अलर्ट। तेज हवाओं के साथ एक गंभीर चक्रवात आपके क्षेत्र में आ रहा है। पशुधन को सुरक्षित करें, फसलों की तुरंत कटाई करें और सुरक्षित स्थान पर जाएं। यह एक रेड अलर्ट है।";

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);

    _startAlarmSequence();
  }

  void _startAlarmSequence() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    
    // Simulate beeps before speaking
    _simulateBeeps();
    
    // Play voice advisory 3 seconds later
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isDisposed) _playAdvisory();
    });

    // Repeat every 15 seconds
    _ttsTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!_isDisposed) {
        _simulateBeeps();
        Future.delayed(const Duration(seconds: 3), () {
          if (!_isDisposed) _playAdvisory();
        });
      }
    });
  }
  
  void _simulateBeeps() {
    // If audioplayers package isn't present, we can hack a beep using TTS by making it say a harsh sound very fast
    // Or we rely on the flashing screen visually and just have the TTS announce the warning.
    // For now, we will just flash the screen and let TTS play.
  }

  void _playAdvisory() async {
    // Force TTS in Hindi as requested for the mockup
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.speak(_advisoryHi);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _flashController.dispose();
    _ttsTimer?.cancel();
    _beepTimer?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageNotifier.instance,
      builder: (context, _) {
        final lang = LanguageNotifier.instance.languageCode;
        return Scaffold(
          body: AnimatedBuilder(
            animation: _flashController,
            builder: (context, child) {
              final isRed = _flashController.value > 0.5;
              return Container(
                color: isRed ? Colors.red.shade900 : Colors.red.shade500,
                width: double.infinity,
                height: double.infinity,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                        LucideIcons.alertTriangle,
                        size: 140,
                        color: isRed ? Colors.white : Colors.yellowAccent,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        lang == 'hi' ? "रेड अलर्ट!" : "RED ALERT!",
                        style: GoogleFonts.epilogue(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30)
                        ),
                        child: Text(
                          lang == 'hi' ? "चक्रवात की चेतावनी" : "CYCLONE WARNING",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellowAccent,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade300, width: 3),
                        ),
                        child: Text(
                          lang == 'hi' ? _advisoryHi : _advisoryEn,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade900,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                          elevation: 10,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          lang == 'hi' ? "चेतावनी बंद करें" : "DISMISS ALERT",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
            },
          ),
        );
      }
    );
  }
}
