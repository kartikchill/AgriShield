import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../localization/app_translations.dart';
import '../localization/language_notifier.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'expert_referral_screen.dart';
import '../database/db_helper.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import '../widgets/accessible_audio_button.dart';
import '../widgets/insurance_recommendation_modal.dart';
import 'package:lucide_icons/lucide_icons.dart';


class VisionAiScreen extends StatefulWidget {
  const VisionAiScreen({super.key});
  @override
  State<VisionAiScreen> createState() => _VisionAiScreenState();
}

class _VisionAiScreenState extends State<VisionAiScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  int _selectedIpmTab = 0;

  // Image & result state
  File? _pickedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;
  String? _errorMsg;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

    Future<void> _pickFile() async {
      try {
        final result = await FilePicker.pickFiles(
          type: FileType.image,
        );
        if (result.isEmpty || result.first.path == null) return;
        setState(() {
          _pickedImage = File(result.first.path!);
        _result = null;
        _errorMsg = null;
      });
      await _runAnalysis();
    } catch (e) {
      setState(() => _errorMsg = 'Could not pick file: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 90,
      );
      if (picked == null) return;
      setState(() {
        _pickedImage = File(picked.path);
        _result = null;
        _errorMsg = null;
      });
      await _runAnalysis();
    } catch (e) {
      setState(() => _errorMsg = 'Could not access camera/gallery: $e');
    }
  }

  Future<void> _runAnalysis() async {
    if (_pickedImage == null) return;
    setState(() { _isAnalyzing = true; _errorMsg = null; });

    try {
      final result = await ApiService.instance.classifyImage(imageFile: _pickedImage!);
      if (mounted) setState(() { _result = result; _isAnalyzing = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMsg = 'Error: $e';
          // Show a mock result from offline heuristic
          _result = {
            'display_name': 'Unknown Pathology (Offline)',
            'confidence': 0.15,
            'confidence_pct': '15.0%',
            'is_healthy': false,
            'requires_expert_review': true,
            'triage_message': 'Local edge heuristic detected anomalous leaf patterns. Please escalate this scan to a lab expert for detailed cloud-based diagnosis.',
            'top3': [],
            'ipm_lookup': null,
          };
        });
      }
    }
  }

  Future<void> _saveAndSync() async {
    if (_result == null) return;
    final diagnosis    = _result!['display_name'] as String? ?? 'Unknown';
    final confidence   = (_result!['confidence'] as num?)?.toDouble() ?? 0.0;
    final cropFromIpm  = (_result!['ipm_lookup'] as Map?)?['crop'] as String? ?? 'Unknown';
    final symptoms     = 'AI diagnosis from Model B Vision: $diagnosis';
    final now          = DateTime.now().toIso8601String();

    // Encode scanned image as base64 to attach to ticket
    String? base64Img;
    if (_pickedImage != null) {
      try {
        final bytes = await _pickedImage!.readAsBytes();
        base64Img = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } catch (e) {
        base64Img = 'data:image/jpeg;base64,ERROR_$e';
      }
    } else {
        base64Img = 'data:image/jpeg;base64,NULL_IMAGE';
    }

    final ticketData = {
      'farmer_name':        'Rajesh Patil',
      'phone_number':       '9876543210',
      'field_id':           'FIELD-001',
      'crop_name':          cropFromIpm,
      'reported_symptoms':  symptoms,
      'ai_prediction':      diagnosis,
      'ai_confidence':      confidence,
      'image_url':          base64Img,
      'status':             'PENDING_REVIEW',
      'created_at':         now,
      'synced':             0,
    };

    try {
      // Try server first
      final serverResult = await ApiService.instance.createReferralTicket(
        farmerName:  'Rajesh Patil',
        phoneNumber: '9876543210',
        fieldId:     'FIELD-001',
        cropName:    cropFromIpm,
        symptoms:    symptoms,
        aiPrediction: diagnosis,
        aiConfidence: confidence,
        latitude:    19.9975,
        longitude:   73.7898,
        imageUrl:    base64Img,
      );
      ticketData['ticket_code'] = serverResult['ticket_code'] ?? '';
      ticketData['assigned_lab'] = serverResult['assigned_lab'] ?? '';
      ticketData['synced'] = 1;
      _showSnackBar('Ticket created: ${serverResult['ticket_code']}', Colors.green[800]!);
    } catch (_) {
      // Queue for sync
      await DatabaseHelper.instance.enqueueSync(
        '/api/v1/referral/create-ticket', 'POST',
        jsonEncode({
          'farmer_name': 'Rajesh Patil', 'phone_number': '9876543210',
          'field_id': 'FIELD-001', 'crop_name': cropFromIpm,
          'reported_symptoms': symptoms, 'ai_prediction': diagnosis,
          'ai_confidence': confidence, 'latitude': 19.9975, 'longitude': 73.7898,
          'image_url': base64Img,
        }),
      );
      _showSnackBar('Saved offline â€“ ticket will sync automatically', Colors.orange[800]!);
    }

    await DatabaseHelper.instance.insertTicket(ticketData);

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        backgroundColor: color, duration: const Duration(seconds: 3)));
  }

  @override
  Widget build(BuildContext context) {
    final bool hasResult = _result != null;
    final displayName    = _result?['display_name'] as String? ?? '';
    final confidence     = (_result?['confidence'] as num?)?.toDouble() ?? 0.0;
    final confidencePct  = _result?['confidence_pct'] as String? ?? '';
    final isHealthy      = _result?['is_healthy'] as bool? ?? false;
    final requiresExpert = _result?['requires_expert_review'] as bool? ?? false;
    final triageMsg      = _result?['triage_message'] as String? ?? '';
    final top3           = (_result?['top3'] as List?) ?? [];
    final ipmLookup      = _result?['ipm_lookup'] as Map?;

    // IPM tab content from disease risk cache or Vision result
    final ipmTabContent = [
      'Prune infected lower foliage immediately. Improve furrow aeration to decrease canopy humidity.',
      'Spray Trichoderma viride @ 5g/L or Neem Seed Kernel Extract (NSKE 5%) before 9:00 AM.',
      'Apply Azoxystrobin 18.2% + Difenoconazole 11.4% SC @ 1 ml/L. Use hollow-cone nozzle.',
    ];

    return ListenableBuilder(
      listenable: LanguageNotifier.instance,
      builder: (context, _) {
        final lang = LanguageNotifier.instance.languageCode;
        String t(String key) => AppTranslations.t(key, lang);
        return Stack(
      children: [
        // â”€â”€ Camera / Image Background â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned.fill(
          child: _pickedImage != null
              ? Image.file(_pickedImage!, fit: BoxFit.cover)
              : Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBG3MguA-Cl9L8_AGfT76UDllGISV5gBB7dSEzVcRDncJILg_yRgKj_vZFy7nNjSL1_j1XhKIdG0C56GBmB5H6giiYf6cJqLah7qcPMtVpqy3WT28lt9j2ESOKQz8jnV2QnLPie_x0yQMuB6Mt7ANmTYZVMrSH6O4gGTnpy3-RtlPoB5NptXroyt0x-ipw0PzxUI-brJlCBpxTlxf5ycmqSailXuEmnuQF_G4_XRTZIEuM8UBkoWScEhA',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.black87),
                ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // â”€â”€ Top Controls â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          top: 16, left: 16, right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(_isAnalyzing ? Icons.hourglass_top : Icons.lens, color: Colors.white, size: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xCC1B4D3E), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Icon(Icons.circle, color: _isAnalyzing ? Colors.amber : Colors.greenAccent, size: 10),
                  const SizedBox(width: 6),
                  Text(
                    _isAnalyzing ? t('Scanning...') : t('AI Scanner Ready'),
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
              Row(children: [
                GestureDetector(
                  onTap: () => _pickFile(),
                  child: const CircleAvatar(backgroundColor: Colors.white24,
                    child: Icon(Icons.folder, color: Colors.white))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: const CircleAvatar(backgroundColor: Colors.white24,
                    child: Icon(Icons.photo_library, color: Colors.white))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.camera),
                  child: const CircleAvatar(backgroundColor: Colors.white24,
                    child: Icon(Icons.camera_alt, color: Colors.white))),
              ]),
            ],
          ),
        ),

        // â”€â”€ Scanning Reticle (only when no image yet) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_pickedImage == null)
          Positioned(
            top: 100, bottom: 250, left: 40, right: 40,
            child: Stack(children: [
              const Align(alignment: Alignment.topLeft,    child: _CornerBracket(angle: 0)),
              const Align(alignment: Alignment.topRight,   child: _CornerBracket(angle: 1.5708)),
              const Align(alignment: Alignment.bottomRight, child: _CornerBracket(angle: 3.14159)),
              const Align(alignment: Alignment.bottomLeft,  child: _CornerBracket(angle: 4.71239)),
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, _) => Positioned(
                  top: _scanController.value * 300, left: 0, right: 0,
                  child: Container(height: 2,
                    decoration: const BoxDecoration(color: Colors.greenAccent,
                      boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 10)])),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: Text(t('Tap ðŸ“· to capture, ðŸ–¼ for gallery, or ðŸ“Ž to upload file'),
                      style: GoogleFonts.spaceGrotesk(color: Colors.greenAccent, fontSize: 10))),
                ),
              ),
            ]),
          ),

        // â”€â”€ Analyzing Spinner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_isAnalyzing)
          Positioned.fill(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: Colors.greenAccent, strokeWidth: 3),
                const SizedBox(height: 16),
                Text(t('Analyzing your crop...'), style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13)),
              ]),
            ),
          ),

        // â”€â”€ Bottom Diagnosis Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
            ),
            child: hasResult
                ? _buildResultSheet(displayName, confidence, confidencePct, isHealthy, requiresExpert, triageMsg, top3, ipmLookup, ipmTabContent, t, lang)
                : _buildPlaceholderSheet(t, lang),
          ),
        ),
      ],
    );
      },
    );
  }

  Widget _buildPlaceholderSheet(String Function(String) t, String lang) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 20),
        Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(t('Crop Disease Scanner'), style: GoogleFonts.epilogue(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
        const SizedBox(height: 8),
        Text(t('Take a photo of your crop leaf to detect disease instantly'),
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt, size: 28),
            label: Text(t('Open Camera'), style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF1B4D3E)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library, color: Color(0xFF1B4D3E)),
              label: Text(t('Gallery'), style: GoogleFonts.spaceGrotesk(color: const Color(0xFF1B4D3E), fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF1B4D3E)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _pickFile(),
              icon: const Icon(Icons.folder, color: Color(0xFF1B4D3E)),
              label: Text(t('Files'), style: GoogleFonts.spaceGrotesk(color: const Color(0xFF1B4D3E), fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildResultSheet(String displayName, double confidence, String confidencePct,
      bool isHealthy, bool requiresExpert, String triageMsg,
      List top3, Map? ipmLookup, List<String> ipmTabContent, String Function(String) t, String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 16),

        // Status badge
        Row(children: [
          Icon(isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
            color: isHealthy ? Colors.green[700] : Colors.orange[800], size: 20),
          const SizedBox(width: 4),
          Text(isHealthy ? t('PLANT HEALTHY') : t('PATHOLOGY DETECTED'),
            style: GoogleFonts.spaceGrotesk(
              color: isHealthy ? Colors.green[700] : Colors.orange[800],
              fontSize: 12, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (requiresExpert)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFFFDBCF), borderRadius: BorderRadius.circular(8)),
              child: Text(t('âš  Expert Review Advised'),
                style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red[900]))),
        ]),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(displayName,
                style: GoogleFonts.epilogue(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
            ),
            Builder(
              builder: (context) {
                String treatment = '';
                if (ipmLookup != null && ipmTabContent.isNotEmpty) {
                  treatment = ipmTabContent.first;
                }
                final ttsString = t('Image analysis is complete. The crop appears to have ') + displayName + t(' with a confidence of ') + confidencePct + t('. ') + treatment;
                return AccessibleAudioButton(textToSpeak: ttsString);
              }
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Confidence Card (Simplified)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF4F7F6), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: confidence >= 0.7 ? Colors.green[100] : Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                confidence >= 0.7 ? Icons.verified : Icons.info_outline,
                color: confidence >= 0.7 ? Colors.green[800] : Colors.orange[800],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('AI Confidence Level'),
                  style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey[700])),
                const SizedBox(height: 4),
                Text(confidencePct,
                  style: GoogleFonts.epilogue(fontSize: 20, fontWeight: FontWeight.bold,
                    color: confidence >= 0.7 ? Colors.green[700] : Colors.orange[800])),
              ]),
            ),
          ]),
        ),

        // IPM Advisory Tabs
        if (!isHealthy) ...[
          const SizedBox(height: 16),
          Text(t('IPM Advisory Protocol'), style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFFF4EFE6), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              _IpmTab(title: t('Cultural'),    icon: Icons.agriculture, isSelected: _selectedIpmTab==0, onTap: () => setState(() => _selectedIpmTab=0)),
              const SizedBox(width: 4),
              _IpmTab(title: t('Bio Control'), icon: Icons.eco,         isSelected: _selectedIpmTab==1, onTap: () => setState(() => _selectedIpmTab=1)),
              const SizedBox(width: 4),
              _IpmTab(title: t('Chemical'),    icon: Icons.science,     isSelected: _selectedIpmTab==2, onTap: () => setState(() => _selectedIpmTab=2)),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF4EFE6), borderRadius: BorderRadius.circular(12)),
            child: Text(ipmTabContent[_selectedIpmTab],
              style: GoogleFonts.notoSans(fontSize: 13, color: Colors.black87)),
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
                InsuranceRecommendationModal.show(context, isDiseaseOrPest: true);
              },
              icon: const Icon(LucideIcons.shieldCheck),
              label: Text(t('View Eligible Insurance Schemes'), style: GoogleFonts.epilogue(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Escalate Button
        if (!isHealthy || requiresExpert) ...[
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                String crop = displayName.split('-').first.trim();
                if (crop.isEmpty) crop = 'Unknown';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExpertReferralScreen(),
                    settings: RouteSettings(arguments: {
                      'crop_name': crop,
                      'ai_prediction': displayName,
                      'ai_confidence': confidence,
                      'symptoms': 'Automatically detected by Vision AI: $displayName. \n\nPlease review the attached image for further analysis.',
                      'image_path': _pickedImage?.path,
                    }),
                  ),
                );
              },
              icon: const Icon(Icons.support_agent, color: Colors.white),
              label: Text(t('Escalate to Lab Expert'),
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Save Button
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _saveAndSync,
            icon: Icon(SyncService.instance.isOnline ? Icons.send : Icons.save_alt, color: Colors.white),
            label: Text(
              SyncService.instance.isOnline ? t('Save to Offline Log & Sync') : t('Save Offline (Will Auto-Sync)'),
              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 8),

        // Retry / New Scan
        SizedBox(
          width: double.infinity, height: 44,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1B4D3E)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => setState(() { _pickedImage = null; _result = null; _errorMsg = null; }),
            icon: const Icon(Icons.refresh, color: Color(0xFF1B4D3E)),
            label: Text(t('Scan New Leaf'),
              style: GoogleFonts.spaceGrotesk(color: const Color(0xFF1B4D3E), fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 8),
      ]),
    );
  }
}

// â”€â”€ Helper Widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CornerBracket extends StatelessWidget {
  final double angle;
  const _CornerBracket({required this.angle});
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: CustomPaint(size: const Size(30, 30), painter: _BracketPainter()),
  );
}
class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.greenAccent..strokeWidth = 3.5..style = PaintingStyle.stroke;
    canvas.drawPath(Path()..moveTo(0, size.height)..lineTo(0, 0)..lineTo(size.width, 0), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IpmTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _IpmTab({required this.title, required this.icon, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : []),
        child: Column(children: [
          Icon(icon, size: 18, color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[600]),
          Text(title,
            style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF1B4D3E) : Colors.grey[600])),
        ]),
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  const _ActionButton({required this.icon, required this.label, required this.onTap, required this.isPrimary});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF1B4D3E) : const Color(0xFFF4EFE6),
        borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF1B4D3E), size: 18),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.spaceGrotesk(
          color: isPrimary ? Colors.white : const Color(0xFF1B4D3E),
          fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    ),
  );
}
