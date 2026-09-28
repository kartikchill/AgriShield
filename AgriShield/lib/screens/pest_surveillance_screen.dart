import 'dart:convert';
import '../localization/app_translations.dart';
import '../localization/language_notifier.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../services/api_service.dart';
import '../widgets/accessible_audio_button.dart';

class PestSurveillanceScreen extends StatefulWidget {
  const PestSurveillanceScreen({super.key});
  @override
  State<PestSurveillanceScreen> createState() => _PestSurveillanceScreenState();
}

class _PestSurveillanceScreenState extends State<PestSurveillanceScreen> {
  final TextEditingController _notesController = TextEditingController();
  
  final TextEditingController _countController = TextEditingController();
  
  String _cropName = 'Cotton';
  String _pestName = 'Pink Bollworm';
  
  static const _cropOptions = ['Cotton', 'Soybean', 'Maize', 'Rice', 'Wheat', 'Tomato'];
  static const _pestOptions = ['Fall Armyworm', 'Pink Bollworm', 'Whitefly', 'Thrips', 'Stem Borer', 'Aphids'];
  
  final ScrollController _scrollController = ScrollController();

  String _getOfflineAdvisory(String pestName, String status) {
    final lang = LanguageNotifier.instance.languageCode;
    
    if (status == 'SAFE') {
      if (lang == 'hi') return 'कीट संख्या सुरक्षित सीमा से नीचे है। नियमित निगरानी जारी रखें।';
      if (lang == 'mr') return 'कीटकांची संख्या सुरक्षित मर्यादेखाली आहे. नियमित निरीक्षण सुरू ठेवा.';
      return 'Pest population is below economic threshold. Continue regular monitoring and field sanitation.';
    }
    
    switch (pestName) {
      case 'Fall Armyworm':
        if (lang == 'hi') return 'गंभीर स्थिति! मक्के में Spinetoram 11.7 SC @ 0.5 ml/L या Emamectin Benzoate 5 SG @ 0.4 g/L का तुरंत छिड़काव करें। फेरोमोन जाल लगाएं।';
        if (lang == 'mr') return 'गंभीर स्थिती! मक्यावर Spinetoram 11.7 SC @ 0.5 ml/L किंवा Emamectin Benzoate 5 SG @ 0.4 g/L ची तातडीने फवारणी करा. फेरोमोन सापळे लावा.';
        return 'Critical ETL breached! Immediate application of Spinetoram 11.7 SC @ 0.5 ml/L or Emamectin Benzoate 5 SG @ 0.4 g/L into maize whorls. Install pheromone traps.';
      case 'Pink Bollworm':
        if (lang == 'hi') return 'अधिक जोखिम! Quinalphos 25 EC @ 2 ml/L का छिड़काव करें। सुनिश्चित करें कि कपास के गोलों पर पूरा छिड़काव हो। गिरे हुए फूल और गोलों को नष्ट करें।';
        if (lang == 'mr') return 'जास्त धोका! Quinalphos 25 EC @ 2 ml/L ची फवारणी करा. बोंडांवर पूर्ण कव्हरेजची खात्री करा. पडलेली फुले आणि बोंडे नष्ट करा.';
        return 'High risk! Spray Quinalphos 25 EC @ 2 ml/L. Ensure complete coverage of bolls. Destroy shed squares and bolls.';
      case 'Whitefly':
        if (lang == 'hi') return 'गंभीर संक्रमण! Diafenthiuron 50 WP @ 1.25 g/L या Flonicamid 50 WG @ 0.3 g/L का उपयोग करें। वैकल्पिक खरपतवार हटा दें।';
        if (lang == 'mr') return 'तीव्र प्रादुर्भाव! Diafenthiuron 50 WP @ 1.25 g/L किंवा Flonicamid 50 WG @ 0.3 g/L वापरा. पर्यायी तण काढून टाका.';
        return 'Severe infestation! Use Diafenthiuron 50 WP @ 1.25 g/L or Flonicamid 50 WG @ 0.3 g/L. Remove alternative weed hosts.';
      case 'Thrips':
        if (lang == 'hi') return 'सीमा पार! Spinosad 45 SC @ 0.3 ml/L या Fipronil 5 SC @ 1.5 ml/L का छिड़काव करें। तनाव कम करने के लिए मिट्टी में नमी बनाए रखें।';
        if (lang == 'mr') return 'मर्यादा ओलांडली! Spinosad 45 SC @ 0.3 ml/L किंवा Fipronil 5 SC @ 1.5 ml/L ची फवारणी करा. मातीत पुरेसा ओलावा ठेवा.';
        return 'ETL crossed! Spray Spinosad 45 SC @ 0.3 ml/L or Fipronil 5 SC @ 1.5 ml/L. Maintain adequate soil moisture to reduce stress.';
      case 'Stem Borer':
        if (lang == 'hi') return 'कार्रवाई आवश्यक! खड़े पानी में Cartap Hydrochloride 4G @ 10 kg/ha डालें या Chlorantraniliprole 18.5 SC @ 0.3 ml/L का छिड़काव करें।';
        if (lang == 'mr') return 'कारवाई आवश्यक! साचलेल्या पाण्यात Cartap Hydrochloride 4G @ 10 kg/ha टाका किंवा Chlorantraniliprole 18.5 SC @ 0.3 ml/L ची फवारणी करा.';
        return 'Action required! Apply Cartap Hydrochloride 4G @ 10 kg/ha in standing water or spray Chlorantraniliprole 18.5 SC @ 0.3 ml/L.';
      case 'Aphids':
        if (lang == 'hi') return 'संक्रमण सक्रिय! Imidacloprid 17.8 SL @ 0.5 ml/L या Dimethoate 30 EC @ 2 ml/L का छिड़काव करें। लेडीबर्ड बीटल जैसे प्राकृतिक शत्रुओं का संरक्षण करें।';
        if (lang == 'mr') return 'प्रादुर्भाव सक्रिय! Imidacloprid 17.8 SL @ 0.5 ml/L किंवा Dimethoate 30 EC @ 2 ml/L ची फवारणी करा. लेडीबर्ड बीटल सारख्या नैसर्गिक शत्रूंचे संरक्षण करा.';
        return 'Infestation active! Spray Imidacloprid 17.8 SL @ 0.5 ml/L or Dimethoate 30 EC @ 2 ml/L. Conserve natural enemies like ladybird beetles.';
      default:
        if (lang == 'hi') return 'सीमा पार। तुरंत रासायनिक छिड़काव की आवश्यकता है। विशिष्ट कीटनाशक के लिए स्थानीय केवीके से परामर्श लें।';
        if (lang == 'mr') return 'मर्यादा ओलांडली. तातडीने रासायनिक फवारणीची आवश्यकता आहे. विशिष्ट कीटकनाशकासाठी स्थानिक केव्हीकेचा सल्ला घ्या.';
        return 'ETL breached. Immediate chemical intervention required. Consult local KVK or extension officer for specific pesticide recommendations.';
    }
  }

  bool _isSaving = false;
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>? _evaluationResult;

  @override
  void initState() {
    super.initState();
    _countController.text = '0';
    _loadHistory();
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final rows = await DatabaseHelper.instance.getPestLogs(limit: 5);
    if (mounted) setState(() => _history = rows);
  }

  Future<void> _saveLog() async {
    double observedVal = double.tryParse(_countController.text) ?? 0.0;
    
    setState(() { _isSaving = true; _evaluationResult = null; });
    
    final fieldId = 'FIELD_001';

    final payload = {
      'field_id':       fieldId,
      'crop_name':      _cropName,
      'pest_name':      _pestName,
      'metric_type':    'count',
      'observed_value': observedVal,
      'notes':          _notesController.text,
    };

    try {
      final result = await ApiService.instance.logPestTrap(
        fieldId:       fieldId,
        cropName:      _cropName,
        pestName:      _pestName,
        metricType:    'count',
        observedValue: observedVal,
      );

      final status = result['status'] as String? ?? 'SAFE';
      final localizedAdvisory = _getOfflineAdvisory(_pestName, status);
      result['advisory'] = localizedAdvisory;

      await DatabaseHelper.instance.insertPestLog({
        'field_id':       fieldId,
        'crop_name':      _cropName,
        'pest_name':      _pestName,
        'metric_type':    'count',
        'observed_value': observedVal,
        'status':         status,
        'advisory':       localizedAdvisory,
        'timestamp':      DateTime.now().toIso8601String(),
        'synced':         1,
      });

      setState(() => _evaluationResult = result);
      _showSnackBar('Surveillance logged successfully!', Colors.green[800]!);
    } catch (_) {
      await DatabaseHelper.instance.enqueueSync('/api/v1/pest-surveillance/log', 'POST', jsonEncode(payload));
      
      // Basic offline fallback ETL check (assumes 10 as average threshold if offline)
      String offlineStatus = observedVal >= 10.0 ? 'ETL_BREACH' : 'SAFE';
      
      await DatabaseHelper.instance.insertPestLog({
        'field_id':       fieldId,
        'crop_name':      _cropName,
        'pest_name':      _pestName,
        'metric_type':    'count',
        'observed_value': observedVal,
        'status':         offlineStatus,
        'advisory':       _getOfflineAdvisory(_pestName, offlineStatus),
        'timestamp':      DateTime.now().toIso8601String(),
        'synced':         0,
      });
      
      setState(() {
        _evaluationResult = {
          'status': offlineStatus,
          'observed_value': observedVal,
          'advisory': _getOfflineAdvisory(_pestName, offlineStatus),
        };
      });
      _showSnackBar('Saved offline - will sync when connected', Colors.orange[800]!);
    }

    _notesController.clear();
    _countController.text = '0';
    await _loadHistory();
    if (mounted) {
      setState(() => _isSaving = false);
      _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.spaceGrotesk(color: Colors.white)),
      backgroundColor: color, duration: const Duration(seconds: 3)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageNotifier.instance,
      builder: (context, _) {
        final lang = LanguageNotifier.instance.languageCode;
        String t(String key) => AppTranslations.t(key, lang);
        
        return Scaffold(
          backgroundColor: const Color(0xFFFEF9F0), // Canvas
          body: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header replacing nested AppBar
                Container(
                  color: const Color(0xFF1B4D3E),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  width: double.infinity,
                  child: Text(t('Pest Surveillance & Log'), style: GoogleFonts.epilogue(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                ),
                if (_evaluationResult != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: _evaluationResult!['status'] == 'ETL_BREACH' ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _evaluationResult!['status'] == 'ETL_BREACH' ? Colors.red[200]! : Colors.green[200]!),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _evaluationResult!['status'] == 'ETL_BREACH' ? Icons.warning_amber_rounded : Icons.check_circle,
                              color: _evaluationResult!['status'] == 'ETL_BREACH' ? Colors.red[800] : Colors.green[800],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _evaluationResult!['status'] == 'ETL_BREACH' ? t('CRITICAL: ETL BREACHED!') : t('SAFE: BELOW THRESHOLD'),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _evaluationResult!['status'] == 'ETL_BREACH' ? Colors.red[800] : Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _evaluationResult!['advisory'] ?? '',
                          style: GoogleFonts.notoSans(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // 3. Manual Entry & Pest Intensity Input
                Row(
                  children: [
                    Expanded(child: Text(t('Manual Parameters'), style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E)))),
                    AccessibleAudioButton(textToSpeak: t('Manual Parameters')),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
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
                          Expanded(child: _buildDropdown(t('Crop'), _cropOptions, _cropName, (v) => setState(() => _cropName = v!), t)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDropdown(t('Pest'), _pestOptions, _pestName, (v) => setState(() => _pestName = v!), t)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(t('Observed Pest Count'), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: _countController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: t('Enter number of pests (e.g., 12)'),
                          hintStyle: GoogleFonts.notoSans(color: Colors.grey[400]),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
                          ),
                          prefixIcon: const Icon(Icons.bug_report, color: Color(0xFF1B4D3E)),
                        ),
                        style: GoogleFonts.notoSans(fontSize: 16, color: const Color(0xFF1B4D3E), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4D3E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isSaving ? null : _saveLog,
                    icon: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? t('Saving...') : t('Save Surveillance Log'),
                      style: GoogleFonts.epilogue(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 32),

                // 4. Verified Model B Diagnostic Feeds (History)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t('Recent Diagnostic Feeds'), style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
                    AccessibleAudioButton(textToSpeak: t('Reading recent diagnostic feeds. ${_history.isNotEmpty ? 'Latest feed is ${_history.first['pest_name']} on ${_history.first['crop_name']}' : 'No recent feeds'}')),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (_history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Text(t('No recent logs found'), style: GoogleFonts.notoSans(color: Colors.grey)),
                  )
                else
                  ..._history.map((log) => _buildHistoryItem(log, t)),
                  
                const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown(String label, List<String> options, String value, ValueChanged<String?> onChanged, String Function(String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F6F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5DDD0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFF1B4D3E), size: 20),
              style: GoogleFonts.notoSans(fontSize: 14, color: const Color(0xFF1B4D3E), fontWeight: FontWeight.w600),
              onChanged: onChanged,
              items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(t(opt)))).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> log, String Function(String) t) {
    final status = log['status'] as String? ?? 'UNKNOWN';
    final isBreach = status == 'ETL_BREACH';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBreach ? Colors.red[200]! : Colors.green[200]!),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isBreach ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isBreach ? t('ETL BREACH') : t('SAFE'),
                  style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: isBreach ? Colors.red[800] : Colors.green[800]),
                ),
              ),
              Icon(log['synced'] == 1 ? Icons.cloud_done : Icons.cloud_off, size: 16, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 12),
          Text('${log['pest_name']} - ${log['crop_name']}', style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (log['advisory'] != null && log['advisory'].toString().isNotEmpty)
             Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Expanded(child: Text(log['advisory'], style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey[700]))),
                 const SizedBox(width: 8),
                 AccessibleAudioButton(textToSpeak: log['advisory']),
               ],
             ),
        ],
      ),
    );
  }
}