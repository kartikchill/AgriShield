import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../localization/language_notifier.dart';
import '../screens/insurance_recovery_screen.dart';
import '../screens/disease_risk_screen.dart';
import '../screens/pest_surveillance_screen.dart';
import '../screens/dashboard_screen.dart';

class FloatingVoiceAssistant extends StatefulWidget {
  const FloatingVoiceAssistant({super.key});

  @override
  State<FloatingVoiceAssistant> createState() => _FloatingVoiceAssistantState();
}

class _FloatingVoiceAssistantState extends State<FloatingVoiceAssistant> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the mic and start speaking...';
  String _botResponse = '';
  late FlutterTts _flutterTts;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _lastTopic = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _showBottomSheet() {
    setState(() {
      final lang = LanguageNotifier.instance.languageCode;
      _text = lang == 'hi' ? 'बोलने के लिए माइक दबाएं...' : 
              lang == 'mr' ? 'बोलण्यासाठी माइक दाबा...' : 
              'Press the mic and start speaking...';
      _botResponse = '';
    });
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ScaleTransition(
                    scale: _isListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                    child: GestureDetector(
                      onTap: () => _toggleListening(setModalState, context),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isListening ? Colors.green : const Color(0xFF1B4D3E),
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (_isListening)
                              BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)
                          ],
                        ),
                        child: Icon(
                          _isListening ? LucideIcons.mic : LucideIcons.micOff,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isListening
                        ? (LanguageNotifier.instance.languageCode == 'hi' ? 'सुन रहा हूँ...' : LanguageNotifier.instance.languageCode == 'mr' ? 'ऐकत आहे...' : 'Listening...')
                        : (LanguageNotifier.instance.languageCode == 'hi' ? 'बोलने के लिए माइक दबाएं' : LanguageNotifier.instance.languageCode == 'mr' ? 'बोलण्यासाठी माइक दाबा' : 'Tap mic to speak'),
                    style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _text,
                      style: GoogleFonts.notoSans(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_botResponse.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF81C784)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.bot, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _botResponse,
                              style: GoogleFonts.notoSans(fontSize: 15, color: const Color(0xFF1B4D3E), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      LanguageNotifier.instance.languageCode == 'hi' ? 'सुझाए गए प्रश्न:' : 
                      LanguageNotifier.instance.languageCode == 'mr' ? 'सुचवलेले प्रश्न:' : 'Suggested queries:',
                      style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: _buildQuickActions(setModalState, context),
                  ),
                ],
              ),
              ),
              ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _speech.stop();
      _flutterTts.stop();
      setState(() {
        _isListening = false;
      });
    });
  }

  void _toggleListening(StateSetter setModalState, BuildContext modalContext) async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done') {
            setModalState(() {
              _isListening = false;
            });
            setState(() {
              _isListening = false;
            });
            _processVoiceCommand(setModalState, modalContext);
          }
        },
        onError: (val) {
          setModalState(() {
            _isListening = false;
          });
          setState(() {
            _isListening = false;
          });
        },
      );

      if (available) {
        setModalState(() {
          _isListening = true;
          _botResponse = '';
        });
        setState(() {
          _isListening = true;
        });

        // Determine locale based on app language dynamically
        final lang = LanguageNotifier.instance.languageCode;
        String? localeId;
        try {
          var locales = await _speech.locales();
          if (lang == 'hi') {
            localeId = locales.firstWhere((l) => l.localeId.toLowerCase().startsWith('hi')).localeId;
          } else if (lang == 'mr') {
            localeId = locales.firstWhere((l) => l.localeId.toLowerCase().startsWith('mr')).localeId;
          } else {
            localeId = locales.firstWhere((l) => l.localeId.toLowerCase().startsWith('en')).localeId;
          }
        } catch (e) {
          // Fallbacks if locales can't be fetched
          localeId = lang == 'hi' ? 'hi-IN' : (lang == 'mr' ? 'mr-IN' : 'en-US');
        }

        _speech.listen(
          onResult: (val) {
            setModalState(() {
              _text = val.recognizedWords;
            });
            setState(() {
              _text = val.recognizedWords;
            });
          },
          localeId: localeId,
        );
      }
    } else {
      _speech.stop();
      setModalState(() {
        _isListening = false;
      });
      setState(() {
        _isListening = false;
      });
    }
  }

  List<Widget> _buildQuickActions(StateSetter setModalState, BuildContext modalContext) {
    final lang = LanguageNotifier.instance.languageCode;
    final List<Map<String, String>> actions = [
      {'en': 'Crop Disease?', 'hi': 'फसल रोग?', 'mr': 'पीक रोग?', 'trigger': 'disease'},
      {'en': 'Pest Risk?', 'hi': 'कीट जोखिम?', 'mr': 'कीटक धोका?', 'trigger': 'pest'},
      {'en': 'Cotton Bollworm?', 'hi': 'कपास में सुंडी?', 'mr': 'कापूस बोंडअळी?', 'trigger': 'cotton'},
      {'en': 'Wheat Water?', 'hi': 'गेहूं में पानी?', 'mr': 'गव्हाला पाणी?', 'trigger': 'wheat'},
      {'en': 'PM Kisan Date?', 'hi': 'पीएम किसान किस्त?', 'mr': 'पीएम किसान हप्ता?', 'trigger': 'kisan'},
      {'en': 'Urea for 1 Acre?', 'hi': '1 एकड़ यूरिया?', 'mr': '1 एकर युरिया?', 'trigger': 'urea'},
      {'en': 'Weather Report', 'hi': 'मौसम रिपोर्ट', 'mr': 'हवामान अहवाल', 'trigger': 'weather'},
      {'en': 'Crop Insurance', 'hi': 'फसल बीमा', 'mr': 'पीक विमा', 'trigger': 'insurance'},
      {'en': 'Market Prices', 'hi': 'मंडी भाव', 'mr': 'बाजारभाव', 'trigger': 'market'},
    ];

    return actions.map((action) {
      String display = action[lang] ?? action['en']!;
      return ActionChip(
        label: Text(display, style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1B4D3E))),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          setModalState(() {
            _text = action['trigger']!; 
          });
          setState(() {
            _text = action['trigger']!; 
          });
          _processVoiceCommand(setModalState, modalContext);
        },
      );
    }).toList();
  }

  void _processVoiceCommand(StateSetter setModalState, BuildContext modalContext) async {
    if (_text.isEmpty || _text.contains('Press the mic') || _text.contains('बोलने के लिए') || _text.contains('बोलण्यासाठी')) return;

    final lang = LanguageNotifier.instance.languageCode;
    final textLower = _text.toLowerCase();
    
    String responseText = "";
    
    if (textLower.contains("yes") || textLower.contains("haan") || textLower.contains("ho") || textLower.contains("sure") || textLower.contains("yep") || textLower.contains("हाँ") || textLower.contains("हो")) {
      if (_lastTopic == "insurance") {
        responseText = lang == 'hi' ? "बीमा पेज खोल रहा हूँ।" : (lang == 'mr' ? "विमा पेज उघडत आहे." : "Opening insurance page.");
        Navigator.of(modalContext).pop();
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InsuranceRecoveryScreen()));
        _lastTopic = "";
      } else if (_lastTopic == "scan") {
        responseText = lang == 'hi' ? "स्कैनर पेज खोल रहा हूँ।" : (lang == 'mr' ? "स्कॅनर पेज उघडत आहे." : "Opening image analysis.");
        Navigator.of(modalContext).pop();
        DashboardTabNotifier.instance.switchTo(3);
        _lastTopic = "";
      } else {
        responseText = lang == 'hi' ? "मुझे समझ नहीं आया।" : (lang == 'mr' ? "मला समजले नाही." : "I didn't understand.");
      }
    } else if (textLower.contains("no") || textLower.contains("nahi") || textLower.contains("nako") || textLower.contains("nope") || textLower.contains("नहीं") || textLower.contains("नाही")) {
      responseText = lang == 'hi' ? "ठीक है, मैं और क्या मदद कर सकता हूँ?" : (lang == 'mr' ? "ठीक आहे, मी आणखी काय मदत करू शकतो?" : "Okay, how else can I help?");
      _lastTopic = "";
    } else if (textLower.contains("scan") || textLower.contains("photo") || textLower.contains("image") || textLower.contains("chitra") || textLower.contains("फोटो") || textLower.contains("स्कैन") || textLower.contains("disease") || textLower.contains("सफेद धब्बे") || textLower.contains("safed dhabbe") || textLower.contains("white spots") || textLower.contains("पांढरे डाग") || textLower.contains("रोग") || textLower.contains("rog") || textLower.contains("धब्बे")) {
      _lastTopic = "scan";
      if (lang == 'hi') {
        responseText = "मैं आपके लिए फसल रोग स्कैनर खोल रहा हूँ। कृपया अपनी फसल की फोटो लें।";
      } else if (lang == 'mr') {
        responseText = "मी तुमच्यासाठी पीक रोग स्कॅनर उघडत आहे. कृपया तुमच्या पिकाचा फोटो घ्या.";
      } else {
        responseText = "I am opening the crop disease scanner for you. Please take a photo of your crop.";
      }
      Navigator.of(modalContext).pop();
      DashboardTabNotifier.instance.switchTo(3);
      _lastTopic = "";
    } else if (textLower.contains("kida") || textLower.contains("pest") || textLower.contains("ali") || textLower.contains("कीट") || textLower.contains("कीड") || textLower.contains("bug") || textLower.contains("अळी")) {
      if (lang == 'hi') {
        responseText = "कीट निगरानी पृष्ठ खोल रहा हूँ। यहाँ आप कीटों की संख्या दर्ज कर सकते हैं।";
      } else if (lang == 'mr') {
        responseText = "कीड पाळत ठेवणे पृष्ठ उघडत आहे. येथे तुम्ही कीटकांची संख्या नोंदवू शकता.";
      } else {
        responseText = "Opening the Pest Surveillance page. Here you can log pest counts.";
      }
      Navigator.of(modalContext).pop();
      DashboardTabNotifier.instance.switchTo(1);
      _lastTopic = "";
    } else if (textLower.contains("mausam") || textLower.contains("weather") || textLower.contains("paaus") || textLower.contains("मौसम") || textLower.contains("पाऊस") || textLower.contains("rain") || textLower.contains("barish") || textLower.contains("बारिश")) {
      if (lang == 'hi') {
        responseText = "आज मौसम साफ रहने की संभावना है। छिड़काव के लिए यह अच्छा समय है।";
      } else if (lang == 'mr') {
        responseText = "आज हवामान स्वच्छ राहण्याची शक्यता आहे. फवारणीसाठी ही चांगली वेळ आहे.";
      } else {
        responseText = "The weather is expected to be clear today. It is a good time for spraying.";
      }
    } else if (textLower.contains("bima") || textLower.contains("insurance") || textLower.contains("nuksan") || textLower.contains("बीमा") || textLower.contains("विमा") || textLower.contains("claim") || textLower.contains("क्लेम") || textLower.contains("subsidy") || textLower.contains("सब्सिडी") || textLower.contains("yojana") || textLower.contains("योजना") || textLower.contains("scheme")) {
      if (lang == 'hi') {
        responseText = "फसल बीमा, दावों और सब्सिडी के लिए मैं बीमा पृष्ठ खोल रहा हूँ।";
      } else if (lang == 'mr') {
        responseText = "पीक विमा, दावे आणि सबसिडीसाठी मी विमा पृष्ठ उघडत आहे.";
      } else {
        responseText = "Opening the Insurance page for crop insurance, claims, and subsidies.";
      }
      Navigator.of(modalContext).pop();
    } else if (textLower.contains("cotton") || textLower.contains("kapas") || textLower.contains("bollworm") || textLower.contains("कपास") || textLower.contains("सुंडी")) {
      if (lang == 'hi') {
        responseText = "कपास में गुलाबी सुंडी के बचाव के लिए फेरोमोन ट्रैप लगाएं और क्विनालफॉस का छिड़काव करें।";
      } else if (lang == 'mr') {
        responseText = "कापसातील गुलाबी बोंडअळीसाठी कामगंध सापळे लावा आणि क्विनालफॉसची फवारणी करा.";
      } else {
        responseText = "For pink bollworm in cotton, it is recommended to set up pheromone traps and spray Quinalphos.";
      }
    } else if (textLower.contains("wheat") || textLower.contains("gehu") || textLower.contains("गेहूं") || textLower.contains("water") || textLower.contains("pani") || textLower.contains("पानी") || textLower.contains("सिंचाई")) {
      if (lang == 'hi') {
        responseText = "गेहूं में पहली और सबसे जरूरी सिंचाई बुवाई के 21 दिन बाद करनी चाहिए।";
      } else if (lang == 'mr') {
        responseText = "गव्हामध्ये पहिले आणि सर्वात महत्वाचे पाणी पेरणीनंतर २१ दिवसांनी द्यावे.";
      } else {
        responseText = "For wheat, the most critical irrigation stage is exactly 21 days after sowing.";
      }
    } else if (textLower.contains("kisan") || textLower.contains("installment") || textLower.contains("kist") || textLower.contains("किस्त") || textLower.contains("pm kisan") || textLower.contains("पीएम किसान")) {
      if (lang == 'hi') {
        responseText = "पीएम किसान सम्मान निधि की अगली ₹2,000 की किस्त अगले महीने के अंत तक आने की उम्मीद है।";
      } else if (lang == 'mr') {
        responseText = "पीएम किसान सन्मान निधीचा पुढील ₹2,000 चा हप्ता पुढच्या महिन्याच्या अखेरीस येण्याची अपेक्षा आहे.";
      } else {
        responseText = "The next PM Kisan installment of ₹2,000 is expected to be released into your linked account by the end of next month.";
      }
    } else if (textLower.contains("urea") || textLower.contains("यूरिया") || textLower.contains("acre") || textLower.contains("एकड़")) {
      if (lang == 'hi') {
        responseText = "आमतौर पर 1-2 बोरी यूरिया प्रति एकड़ अनुशंसित है। कृपया सटीक मात्रा के लिए डैशबोर्ड पर अपनी मृदा रिपोर्ट देखें।";
      } else if (lang == 'mr') {
        responseText = "साधारणपणे एकरी 1-2 गोण्या युरियाची शिफारस केली जाते. कृपया अचूक प्रमाणासाठी डॅशबोर्डवरील तुमचा मातीचा अहवाल तपासा.";
      } else {
        responseText = "Generally, 1 to 2 bags of urea per acre is recommended. Please check your soil card on the dashboard for precise amounts.";
      }
    } else if (textLower.contains("market") || textLower.contains("mandi") || textLower.contains("मंडी") || textLower.contains("bhav") || textLower.contains("भाव") || textLower.contains("price") || textLower.contains("rate") || textLower.contains("रेट")) {
      if (lang == 'hi') {
        responseText = "आज आपकी निकटतम मंडी में सोयाबीन का भाव ₹4,200 प्रति क्विंटल है।";
      } else if (lang == 'mr') {
        responseText = "आज तुमच्या जवळच्या मंडईत सोयाबीनचा भाव ₹4,200 प्रति क्विंटल आहे.";
      } else {
        responseText = "Today's soybean price in your nearest Mandi is ₹4,200 per quintal.";
      }
    } else if (textLower.contains("mitti") || textLower.contains("soil") || textLower.contains("mati") || textLower.contains("मिट्टी") || textLower.contains("माती") || textLower.contains("khad") || textLower.contains("खाद") || textLower.contains("खत") || textLower.contains("fertilizer")) {
      if (lang == 'hi') {
        responseText = "आपकी मिट्टी के अनुसार, आपको यूरिया की सही मात्रा का उपयोग करना चाहिए। विस्तृत रिपोर्ट डैशबोर्ड पर उपलब्ध है।";
      } else if (lang == 'mr') {
        responseText = "तुमच्या मातीनुसार, तुम्ही युरियाचा योग्य प्रमाणात वापर केला पाहिजे. सविस्तर अहवाल डॅशबोर्डवर उपलब्ध आहे.";
      } else {
        responseText = "Based on your soil, you should use the correct amount of urea. Detailed report is on the dashboard.";
      }
    } else if (textLower.contains("help") || textLower.contains("मदद") || textLower.contains("madad") || textLower.contains("sahayata") || textLower.contains("मदत") || textLower.contains("namaste") || textLower.contains("hello") || textLower.contains("namaskar") || textLower.contains("नमस्ते") || textLower.contains("नमस्कार") || textLower.contains("hi")) {
      if (lang == 'hi') {
        responseText = "नमस्ते! मैं आपका एग्रीशील्ड सहायक हूँ। आप मुझसे मौसम, बीमा, मंडी भाव या फसल रोगों के बारे में पूछ सकते हैं।";
      } else if (lang == 'mr') {
        responseText = "नमस्कार! मी तुमचा अ‍ॅग्रीशील्ड सहाय्यक অফিসে आहे. तुम्ही मला हवामान, विमा, बाजारभाव किंवा पीक रोगांबद्दल विचारू शकता.";
      } else {
        responseText = "Hello! I am your AgriShield assistant. You can ask me about weather, insurance, market prices, or crop diseases.";
      }
    } else {
      if (lang == 'hi') {
        responseText = "मैं इस प्रश्न का उत्तर नहीं दे पा रहा हूँ। कृपया फसल, मौसम, या मंडी से जुड़ा कुछ पूछें।";
      } else if (lang == 'mr') {
        responseText = "मी या प्रश्नाचे उत्तर देऊ शकत नाही. कृपया पीक, हवामान, किंवा बाजारभावाशी संबंधित काहीतरी विचारा.";
      } else {
        responseText = "I am still learning. I will connect your query to the nearest KVK agricultural expert.";
      }
    }

    setModalState(() {
      _botResponse = responseText;
    });
    setState(() {
      _botResponse = responseText;
    });

    String ttsLang = 'en-IN';
    if (lang == 'hi') ttsLang = 'hi-IN';
    if (lang == 'mr') ttsLang = 'mr-IN';
    
    await _flutterTts.setLanguage(ttsLang);
    await _flutterTts.speak(responseText);
  }

  double _x = 0.8;
  double _y = 0.8;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageNotifier.instance,
      builder: (context, child) {
        final lang = LanguageNotifier.instance.languageCode;
        String helperText = "Ask me for help";
        if (lang == 'hi') helperText = "मदद के लिए पूछें";
        if (lang == 'mr') helperText = "मदतीसाठी विचारा";

        return Align(
          alignment: Alignment(_x, _y),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                final size = MediaQuery.of(context).size;
                // Convert pixel delta to alignment delta (-1.0 to 1.0)
                _x += details.delta.dx / (size.width / 2);
                _y += details.delta.dy / (size.height / 2);
                
                // Clamp strictly to screen bounds
                if (_x < -1) _x = -1;
                if (_y < -1) _y = -1;
                if (_x > 1) _x = 1;
                if (_y > 1) _y = 1;
              });
            },
            child: FloatingActionButton.extended(
              onPressed: _showBottomSheet,
              backgroundColor: const Color(0xFFE65100),
              icon: const Icon(LucideIcons.bot, color: Colors.white),
              label: Text(
                helperText,
                style: GoogleFonts.epilogue(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
