import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../database/db_helper.dart';
import '../services/api_service.dart';
import '../localization/app_translations.dart';
import '../localization/language_notifier.dart';
import '../widgets/accessible_audio_button.dart';
import '../widgets/insurance_recommendation_modal.dart';

class DiseaseRiskScreen extends StatefulWidget {
  const DiseaseRiskScreen({super.key});
  @override
  State<DiseaseRiskScreen> createState() => _DiseaseRiskScreenState();
}

class _DiseaseRiskScreenState extends State<DiseaseRiskScreen> {
  // Form state
  String _cropType    = 'Tomato';
  String _growthStage = 'Flowering';
  String _soilType    = 'Black Cotton';

  final TextEditingController _latController = TextEditingController(text: '19.9975');
  final TextEditingController _lonController = TextEditingController(text: '73.7898');
  bool _isDetectingLocation = false;
  final ScrollController _scrollController = ScrollController();

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

  static const _cropOptions  = ['Tomato', 'Potato', 'Apple', 'Soybean', 'Cotton', 'Wheat', 'Rice', 'Sugarcane', 'Maize'];
  
  String _getIcarProtocol(String cropType, String lang) {
    switch (cropType) {
      case 'Tomato': 
        if (lang == 'hi') return 'Trichoderma viride @ 5g/kg बीज उपचार करें। 60x45 सेमी दूरी बनाए रखें। अगेती झुलसा के लिए 5% पत्ती क्षेत्र संक्रमण के ETL का उपयोग करके निगरानी करें।';
        if (lang == 'mr') return 'Trichoderma viride @ 5g/kg बीज प्रक्रिया करा. 60x45 सेमी अंतर ठेवा. 5% पानांच्या संसर्गाच्या ETL चा वापर करून लवकर करपा साठी निरीक्षण करा.';
        return 'Apply Trichoderma viride @ 5g/kg seed. Maintain 60x45 cm spacing. Monitor for Early Blight using ETL of 5% leaf area infection.';
      case 'Potato':
        if (lang == 'hi') return 'प्रमाणित बीज कंद का प्रयोग करें। कैनोपी बंद होने पर पछेती झुलसा के खिलाफ 0.2% Mancozeb का छिड़काव करें।';
        if (lang == 'mr') return 'प्रमाणित बियाणे कंद वापरा. कॅनोपी बंद झाल्यावर उशिरा करपा विरूद्ध 0.2% Mancozeb ची फवारणी करा.';
        return 'Use certified seed tubers. Apply Mancozeb @ 0.2% as a prophylactic spray against Late Blight when canopy closes.';
      case 'Apple':
        if (lang == 'hi') return 'हवा के संचार में सुधार के लिए निष्क्रिय पेड़ों की छंटाई करें। सेब की पपड़ी के खिलाफ सिल्वर टिप चरण में 1% बोर्डो मिश्रण लगाएं।';
        if (lang == 'mr') return 'हवेचे परिसंचरण सुधारण्यासाठी सुप्त झाडांची छाटणी करा. सफरचंद खरुज विरूद्ध सिल्व्हर टिप टप्प्यावर 1% बोर्डो मिश्रण लावा.';
        return 'Prune dormant trees to improve air circulation. Apply 1% Bordeaux mixture at silver tip stage against Apple Scab.';
      case 'Soybean':
        if (lang == 'hi') return 'Thiram + Carbendazim (2:1) @ 3g/kg के साथ बीज उपचार। 45x5 सेमी दूरी का पालन करें। फूल आने के दौरान रस्ट के लिए निगरानी करें।';
        if (lang == 'mr') return 'Thiram + Carbendazim (2:1) @ 3g/kg सह बीज प्रक्रिया. 45x5 सेमी अंतराचे पालन करा. फुलांच्या काळात रस्टसाठी निरीक्षण करा.';
        return 'Seed treatment with Thiram + Carbendazim (2:1) @ 3g/kg. Follow 45x5 cm spacing. Monitor for Rust during flowering.';
      case 'Cotton':
        if (lang == 'hi') return 'प्यूपा को उजागर करने के लिए गहरी गर्मी की जुताई। गुलाबी सुंडी के लिए @ 5/ha फेरोमोन जाल स्थापित करें। नीम बीज कर्नेल अर्क (NSKE) 5% का छिड़काव करें।';
        if (lang == 'mr') return 'कोश उघडकीस आणण्यासाठी उन्हाळी खोल नांगरट. गुलाबी बोंडअळीसाठी @ 5/ha फेरोमोन सापळे लावा. निंबोळी अर्क (NSKE) 5% ची फवारणी करा.';
        return 'Deep summer ploughing to expose pupae. Install pheromone traps @ 5/ha for Pink Bollworm. Spray Neem Seed Kernel Extract (NSKE) 5%.';
      case 'Wheat':
        if (lang == 'hi') return 'प्रतिरोधी किस्में (उदा., HD 2967) बोएं। ढीले स्मट के खिलाफ Carboxin @ 2g/kg से बीजों का उपचार करें। शुरुआती वसंत में पीला रस्ट के लिए निगरानी करें।';
        if (lang == 'mr') return 'प्रतिरोधक वाण (उदा., HD 2967) पेरा. लूज स्मट विरूद्ध Carboxin @ 2g/kg ने बियाण्यांवर प्रक्रिया करा. लवकर वसंत ऋतू मध्ये पिवळ्या रस्टसाठी निरीक्षण करा.';
        return 'Sow resistant varieties (e.g., HD 2967). Treat seeds with Carboxin @ 2g/kg against loose smut. Monitor for yellow rust in early spring.';
      case 'Rice':
        if (lang == 'hi') return 'Carbendazim @ 2g/kg के साथ बीज उपचार। वैकल्पिक गीलापन और सूखापन बनाए रखें। बेसल इंटर्नोड्स पर ब्राउन प्लांट हॉपर (BPH) के लिए निगरानी करें।';
        if (lang == 'mr') return 'Carbendazim @ 2g/kg सह बीज प्रक्रिया. पर्यायी ओलावा आणि कोरडेपणा ठेवा. बेसल इंटरनोड्सवर ब्राउन प्लांट हॉपर (BPH) साठी निरीक्षण करा.';
        return 'Seed treatment with Carbendazim @ 2g/kg. Maintain alternate wetting and drying. Monitor for Brown Plant Hopper (BPH) at basal internodes.';
      case 'Sugarcane':
        if (lang == 'hi') return '15 मिनट के लिए 0.1% Carbendazim से उपचारित स्वस्थ सेट का उपयोग करें। लाल सड़न को रोकने के लिए पर्याप्त जल निकासी सुनिश्चित करें।';
        if (lang == 'mr') return '15 मिनिटांसाठी 0.1% Carbendazim ने उपचार केलेले निरोगी सेट्स वापरा. लाल सड टाळण्यासाठी पुरेशी निचरा व्यवस्था सुनिश्चित करा.';
        return 'Use healthy setts treated with Carbendazim @ 0.1% for 15 mins. Ensure adequate drainage to prevent red rot.';
      case 'Maize':
        if (lang == 'hi') return '150 kg N/ha को 3 भागों में लगाएं। Fall Armyworm भंवर क्षति के लिए निगरानी करें। जहर चारा (चावल का चोकर + गुड़ + emamectin benzoate) का प्रयोग करें।';
        if (lang == 'mr') return '150 kg N/ha 3 टप्प्यात द्या. Fall Armyworm नुकसानासाठी निरीक्षण करा. विषारी आमिष (तांदळाचा कोंडा + गूळ + emamectin benzoate) वापरा.';
        return 'Apply 150 kg N/ha in 3 splits. Monitor for Fall Armyworm whorl damage. Use poison bait (rice bran + jaggery + emamectin benzoate).';
      default:
        if (lang == 'hi') return 'अधिकतम उपज सुनिश्चित करने के लिए रिक्ति, बीज उपचार और एकीकृत कीट प्रबंधन (IPM) के लिए मानक ICAR दिशानिर्देशों का पालन करें।';
        if (lang == 'mr') return 'जास्तीत जास्त उत्पादन सुनिश्चित करण्यासाठी अंतर, बीज प्रक्रिया आणि एकात्मिक कीड व्यवस्थापन (IPM) साठी मानक ICAR मार्गदर्शक तत्त्वांचे पालन करा.';
        return 'Follow standard ICAR guidelines for spacing, seed treatment, and integrated pest management (IPM) to ensure maximum yield.';
    }
  }
  static const _stageOptions = ['Seedling', 'Vegetative', 'Flowering', 'Fruiting'];
  static const _soilOptions  = ['Black Cotton', 'Red Laterite', 'Alluvial', 'Loamy'];

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

      // Cache in SQLite
      await DatabaseHelper.instance.insertRiskAssessment({
        'crop_type':      _cropType,
        'growth_stage':   _growthStage,
        'diseases_json':  jsonEncode(data['diseases'] ?? []),
        'summary':        data['summary'] ?? '',
        'recommendation': data['recommendation'] ?? '',
        'forecast_json':  jsonEncode(data['forecast'] ?? []),
        'ipm_json':       data['ipm_advisory'] != null ? jsonEncode(data['ipm_advisory']) : null,
        'avg_temp':       (data['forecast'] as List?)?.isNotEmpty == true ? (data['forecast'][0]['temp'] ?? 0.0) : 0.0,
        'avg_humidity':   (data['forecast'] as List?)?.isNotEmpty == true ? (data['forecast'][0]['humidity'] ?? 0.0) : 0.0,
        'timestamp':      DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() { _result = data; _isLoading = false; });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
            
            final lang = LanguageNotifier.instance.languageCode;
            String popupTitle = "Check ICAR Protocol";
            String popupMsg = "Please also check the ICAR Crop Protocols below for preventative measures.";
            String btnText = "Okay";
            
            if (lang == 'hi') {
              popupTitle = "ICAR प्रोटोकॉल देखें";
              popupMsg = "कृपया निवारक उपायों के लिए नीचे ICAR फसल प्रोटोकॉल भी देखें।";
              btnText = "ठीक है";
            } else if (lang == 'mr') {
              popupTitle = "ICAR प्रोटोकॉल तपासा";
              popupMsg = "कृपया प्रतिबंधात्मक उपायांसाठी खालील ICAR पीक प्रोटोकॉल देखील तपासा.";
              btnText = "ठीक आहे";
            }

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    const Icon(LucideIcons.info, color: Color(0xFF1B4D3E)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(popupTitle, style: GoogleFonts.epilogue(fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E), fontSize: 18))),
                  ],
                ),
                content: Text(popupMsg, style: GoogleFonts.notoSans(fontSize: 14)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Optionally scroll to bottom when they dismiss
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    },
                    child: Text(btnText, style: const TextStyle(color: Color(0xFF1B4D3E), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMsg = 'Error: $e'; _isLoading = false; });
    }
  }

  Color _riskColor(String level) {
    if (level.toLowerCase().contains('high') || level.toLowerCase().contains('उच्च') || level.toLowerCase().contains('जास्त')) return const Color(0xFFC62828);
    if (level.toLowerCase().contains('medium') || level.toLowerCase().contains('मध्यम') || level.toLowerCase().contains('मध्य')) return const Color(0xFFE65100);
    return const Color(0xFF1B5E20);
  }

  @override
  Widget build(BuildContext context) {
    final forecast = (_result?['forecast'] as List?) ?? [];
    final diseases = (_result?['diseases'] as List?) ?? [];
    
    final temp     = (_result?['avg_temp'] as num?)?.toDouble() ?? (forecast.isNotEmpty ? (forecast[0]['temp'] as num?)?.toDouble() ?? 28.4 : 28.4);
    final humidity = (_result?['avg_humidity'] as num?)?.toDouble() ?? (forecast.isNotEmpty ? (forecast[0]['humidity'] as num?)?.toDouble() ?? 86.0 : 86.0);
    final rain     = forecast.isNotEmpty ? (forecast[0]['rain'] as num?)?.toDouble() ?? 16.0 : 16.0;

    double maxRiskScore = 0.0;
    String overallRiskLevel = 'LOW';
    if (diseases.isNotEmpty) {
      for (var d in diseases) {
        final score = (d['score'] as num?)?.toDouble() ?? 0.0;
        if (score > maxRiskScore) {
          maxRiskScore = score;
          overallRiskLevel = d['risk_level'] ?? 'LOW';
        }
      }
    }

    return ListenableBuilder(
      listenable: LanguageNotifier.instance,
      builder: (context, _) {
        final lang = LanguageNotifier.instance.languageCode;
        String t(String key) => AppTranslations.t(key, lang);

        String ttsString = t('There is no immediate risk to disease development. The overall epidemiological risk is low.');
        if (diseases.isNotEmpty && maxRiskScore > 50) {
           final highRisk = diseases.where((d) => d['risk_level'] != 'LOW').map((d) => d['disease_name'] as String).toList();
           if (highRisk.isNotEmpty) {
             ttsString = t('Attention. Based on the weather forecast, there is an elevated risk for ') + highRisk.join(t(' and ')) + t('. Please check the IPM advisory.');
           }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFEF9F0), // Canvas
          body: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(0),
            children: [
              // Custom Header replacing nested AppBar
              Container(
                color: const Color(0xFF1B4D3E),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(child: Text(t('Disease Risk Calculator'), style: GoogleFonts.epilogue(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))),
                    const Icon(Icons.satellite_alt, color: Colors.white70),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
              // 1. Overall Risk Outcome & Circular Gauge
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(t('Overall Risk Outcome'), style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
                         AccessibleAudioButton(textToSpeak: ttsString),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Stack(
                        alignment: Alignment.center,
                        children: [
                            SizedBox(
                                width: 140, height: 140,
                                child: CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 14,
                                    valueColor: AlwaysStoppedAnimation(Colors.grey[200]),
                                ),
                            ),
                            SizedBox(
                                width: 140, height: 140,
                                child: CircularProgressIndicator(
                                    value: maxRiskScore > 0 ? maxRiskScore / 100.0 : 0.05,
                                    strokeWidth: 14,
                                    valueColor: AlwaysStoppedAnimation(_riskColor(overallRiskLevel)),
                                    backgroundColor: Colors.transparent,
                                ),
                            ),
                            Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    Text('${maxRiskScore.toStringAsFixed(0)}%', style: GoogleFonts.epilogue(fontSize: 32, fontWeight: FontWeight.bold, color: _riskColor(overallRiskLevel))),
                                    if (maxRiskScore >= 50)
                                      Text(t('ETL BREACH'), style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]))
                                    else
                                      Text(t('SAFE'), style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                                ]
                            )
                        ]
                    ),
                    const SizedBox(height: 16),
                    Text(t('This percentage shows how likely your crop is to get sick in the next 4 days based on weather and soil. Over 50% means you should take action soon.'), textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey[600])),
                    if (forecast.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[200]),
                      const SizedBox(height: 12),
                      Text(t('4-Day Trajectory'), style: GoogleFonts.epilogue(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: forecast.take(4).map((dayData) {
                          final day = (dayData['day'] ?? '').toString();
                          final shortDay = day.length >= 3 ? day.substring(0, 3) : day;
                          final riskScore = (dayData['risk'] as num?)?.toDouble() ?? 0.0;
                          final level = dayData['level'] ?? 'LOW';
                          final c = _riskColor(level as String);
                          return Column(
                            children: [
                              Text(shortDay.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: c.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(riskScore.toStringAsFixed(0), style: GoogleFonts.epilogue(fontSize: 12, fontWeight: FontWeight.bold, color: c)),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Insurance Recommendation Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    side: const BorderSide(color: Color(0xFFC62828), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    InsuranceRecommendationModal.show(context, isDiseaseOrPest: false);
                  },
                  icon: const Icon(LucideIcons.shieldCheck),
                  label: Text(t('View Eligible Insurance Schemes'), style: GoogleFonts.epilogue(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Environmental & Canopy Microclimate Grid
              Text(t('Canopy Microclimate'), style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _MicroclimateCard(title: t('Canopy Temp'), val: '${temp.toStringAsFixed(1)}°C', icon: Icons.thermostat, color: Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _MicroclimateCard(title: t('RH'), val: '${humidity.toStringAsFixed(0)}%', icon: Icons.water_drop, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _MicroclimateCard(title: t('Leaf Wetness'), val: '7.8 hrs', icon: Icons.grass, color: Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _MicroclimateCard(title: t('48h Rain'), val: '${rain.toStringAsFixed(1)} mm', icon: Icons.cloudy_snowing, color: Colors.indigo)),
                ],
              ),
              
              const SizedBox(height: 24),

              // 3. Crop & Agronomic Parameters (Tactile Form)
              Text(t('Agronomic Parameters'), style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DropdownField(t('Crop Type'), _cropOptions, _cropType, lang, (v) => setState(() => _cropType = v!)),
                    const SizedBox(height: 16),
                    _DropdownField(t('Growth Stage'), _stageOptions, _growthStage, lang, (v) => setState(() => _growthStage = v!)),
                    const SizedBox(height: 16),
                    _DropdownField(t('Soil Type'), _soilOptions, _soilType, lang, (v) => setState(() => _soilType = v!)),
                    const SizedBox(height: 20),
                    Text(t('Soil Moisture Status'), style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: 0.34, minHeight: 12, backgroundColor: Colors.brown[100], valueColor: AlwaysStoppedAnimation(Colors.blue[400])),
                    ),
                    const SizedBox(height: 4),
                    Text('34% - ${t('Optimal')}', style: GoogleFonts.notoSans(fontSize: 10, color: Colors.grey[600])),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Field GPS Geolocation Section
              Text(t('Field Geolocation'), style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _LocationTextField(t('Lat (e.g. 28.61)'), _latController)),
                        const SizedBox(width: 12),
                        Expanded(child: _LocationTextField(t('Lon (e.g. 77.20)'), _lonController)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B4D3E),
                          side: const BorderSide(color: Color(0xFF1B4D3E), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isDetectingLocation ? null : _detectLocation,
                        icon: _isDetectingLocation
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B4D3E)))
                          : const Icon(Icons.my_location),
                        label: Text(t('Detect GPS Location'), style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_errorMsg != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMsg!, style: GoogleFonts.notoSans(fontSize: 13, color: Colors.orange[900]))),
                  ]),
                ),
              ],

              const SizedBox(height: 24),
              
              // 4.5 Action CTA (Moved above ICAR Protocol)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _submitRisk,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.analytics),
                  label: Text(_isLoading ? t('Analyzing...') : t('Predict the Disease Risk'),
                    style: GoogleFonts.epilogue(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),

              // 4.6 ICAR Protocol
              Text(t('ICAR Crop Protocols'), style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.bookOpen, color: Color(0xFF1B4D3E), size: 20),
                        const SizedBox(width: 8),
                        Text('$_cropType ${t('Standard Practices')}', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_getIcarProtocol(_cropType, lang), style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF4F7F6), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.info, size: 16, color: Color(0xFF1B4D3E)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t('Refer to the detailed manual for seed treatment and PHI (Pre-Harvest Interval) timelines.'), style: GoogleFonts.notoSans(fontSize: 11, fontStyle: FontStyle.italic, color: const Color(0xFF1B4D3E)))),
                        ]
                      )
                    )
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF235E4B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.save_alt),
                  label: Text(t('Save Calculation to Offline Log'), style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
                  const SizedBox(height: 40),
                ],
              ),
              ),
            ],
          ),
        );
      }
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _MicroclimateCard extends StatelessWidget {
  final String title, val;
  final IconData icon;
  final Color color;
  const _MicroclimateCard({required this.title, required this.val, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
            ]
          ),
          const SizedBox(height: 12),
          Text(val, style: GoogleFonts.epilogue(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
        ]
      )
    );
  }
}

Widget _DropdownField(String label, List<String> options, String value, String lang, ValueChanged<String?> onChanged) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F0), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DDD0), width: 1.5)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          isDense: true, isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFF1B4D3E)),
          style: GoogleFonts.notoSans(fontSize: 15, color: const Color(0xFF1B4D3E), fontWeight: FontWeight.w600),
          items: options.map((item) => DropdownMenuItem(
            value: item,
            child: Text(AppTranslations.t(item, lang)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    ),
  ]);
}

Widget _LocationTextField(String hint, TextEditingController controller) {
  return TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1B4D3E)),
    decoration: InputDecoration(
      labelText: hint,
      labelStyle: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.grey[600]),
      filled: true,
      fillColor: const Color(0xFFF9F6F0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5DDD0), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2)),
    ),
  );
}
