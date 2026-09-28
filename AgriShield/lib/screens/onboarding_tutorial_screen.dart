import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'login_screen.dart';

class OnboardingTutorialScreen extends StatefulWidget {
  const OnboardingTutorialScreen({super.key});

  @override
  State<OnboardingTutorialScreen> createState() => _OnboardingTutorialScreenState();
}

class _OnboardingTutorialScreenState extends State<OnboardingTutorialScreen> {
  final PageController _pageController = PageController();
  final FlutterTts _flutterTts = FlutterTts();
  int _currentIndex = 0;
  String _selectedLanguage = 'en';

  List<Map<String, dynamic>> _getTutorialSteps(String lang) {
    if (lang == 'hi') {
      return [
        {
          'title': 'भाषा चयन',
          'text': 'कृपया अपनी पसंदीदा भाषा चुनें।',
          'icon': LucideIcons.languages,
        },
        {
          'title': 'एग्री-शील्ड में आपका स्वागत है',
          'text': 'एग्री-शील्ड, आपके व्यक्तिगत खेती सहायक में आपका स्वागत है। अधिक जानने के लिए बाईं ओर स्वाइप करें।',
          'icon': LucideIcons.leaf,
        },
        {
          'title': 'फसल स्वास्थ्य निगरानी',
          'text': 'एआई विजन का उपयोग करके फसल के स्वास्थ्य की निगरानी करें। बस एक फोटो लें और तुरंत परिणाम प्राप्त करें।',
          'icon': LucideIcons.camera,
        },
        {
          'title': 'रोग हॉटस्पॉट',
          'text': 'अपनी फसलों की सुरक्षा के लिए अपने गांव में बीमारी के हॉटस्पॉट के लिए प्रारंभिक अलर्ट प्राप्त करें।',
          'icon': LucideIcons.map,
        },
        {
          'title': 'विशेषज्ञ से जुड़ें',
          'text': 'विशेषज्ञ रेफ़रल आसानी से प्राप्त करें। अपनी यात्रा शुरू करने के लिए गेट स्टार्टेड पर टैप करें।',
          'icon': LucideIcons.stethoscope,
        },
      ];
    }
    
    // Default English
    return [
      {
        'title': 'Language Selection',
        'text': 'Please select your preferred guide language.',
        'icon': LucideIcons.languages,
      },
      {
        'title': 'Welcome to Agri-Shield',
        'text': 'Welcome to Agri-Shield, your personal farming assistant. Swipe left to learn more.',
        'icon': LucideIcons.leaf,
      },
      {
        'title': 'Crop Health Monitoring',
        'text': 'Monitor crop health using AI Vision. Just take a photo and get instant results.',
        'icon': LucideIcons.camera,
      },
      {
        'title': 'Disease Hotspots',
        'text': 'Get early alerts for disease hotspots in your village to protect your crops.',
        'icon': LucideIcons.map,
      },
      {
        'title': 'Expert Connect',
        'text': 'Access expert referrals easily. Tap Get Started to begin your journey.',
        'icon': LucideIcons.stethoscope,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    // Speak first slide (language selection)
    _speak(_getTutorialSteps(_selectedLanguage)[0]['text']);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage(_selectedLanguage == 'hi' ? 'hi-IN' : 'en-US');
    await _flutterTts.setSpeechRate(_selectedLanguage == 'hi' ? 0.35 : 0.5);
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _speak(_getTutorialSteps(_selectedLanguage)[index]['text']);
  }
  
  void _selectLanguage(String lang) {
    setState(() {
      _selectedLanguage = lang;
    });
    _speak(_getTutorialSteps(lang)[_currentIndex]['text']);
    
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getTutorialSteps(_selectedLanguage);
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9F0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildLanguageSelectionSlide();
                  }
                  return _buildTutorialSlide(steps[index]);
                },
              ),
            ),
            
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                steps.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? const Color(0xFF1B4D3E) : const Color(0xFFE5DDD0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Next / Get Started button
            if (_currentIndex > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (_currentIndex == steps.length - 1) {
                      _flutterTts.stop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _currentIndex == steps.length - 1 ? 'GET STARTED' : 'NEXT',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 104), // Empty space for first slide
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelectionSlide() {
    final steps = _getTutorialSteps(_selectedLanguage);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.languages, size: 80, color: Color(0xFF1B4D3E)),
          const SizedBox(height: 32),
          Text(
            steps[0]['title'],
            textAlign: TextAlign.center,
            style: GoogleFonts.epilogue(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF16221C),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            steps[0]['text'],
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: const Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 48),
          
          _buildLanguageButton('English', 'en', true),
          const SizedBox(height: 16),
          _buildLanguageButton('हिंदी (Hindi)', 'hi', false),
          const SizedBox(height: 16),
          _buildLanguageButton('मराठी (Marathi)', 'mr', false),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String title, String code, bool isRecommended) {
    return InkWell(
      onTap: () => _selectLanguage(code),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _selectedLanguage == code ? const Color(0xFF1B4D3E) : const Color(0xFFE5DDD0),
            width: _selectedLanguage == code ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF16221C),
              ),
            ),
            if (isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Selected',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              )
            else
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialSlide(Map<String, dynamic> step) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: Icon(
              step['icon'],
              size: 80,
              color: const Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            step['title'],
            textAlign: TextAlign.center,
            style: GoogleFonts.epilogue(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF16221C),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step['text'],
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: const Color(0xFF555555),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
