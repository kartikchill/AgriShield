import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../database/db_helper.dart';
import '../localization/app_translations.dart';
import '../localization/language_notifier.dart';
import '../services/api_service.dart';

class ExpertReferralScreen extends StatefulWidget {
  const ExpertReferralScreen({super.key});

  @override
  State<ExpertReferralScreen> createState() => _ExpertReferralScreenState();
}

class _ExpertReferralScreenState extends State<ExpertReferralScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Rajesh Patil');
  final _phoneCtrl = TextEditingController(text: '9876543210');
  final _symptomsCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController(text: 'FIELD-001');

  String _cropName = 'Tomato';
  String _aiPrediction = 'Unknown';
  double _aiConfidence = 0.0;
  String? _imagePath;

  bool _isSubmitting = false;
  Map<String, dynamic>? _submitResult;
  final List<String> _selectedChips = [];

  static const _chipOptions = ['Yellow Halos', 'Wilting Stems', 'Spreading Fast', 'Recent Heavy Rain'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _cropName = args['crop_name'] as String? ?? _cropName;
      _aiPrediction = args['ai_prediction'] as String? ?? _aiPrediction;
      _aiConfidence = (args['ai_confidence'] as num?)?.toDouble() ?? _aiConfidence;
      final syms = args['symptoms'] as String?;
      if (syms != null && _symptomsCtrl.text.isEmpty) _symptomsCtrl.text = syms;
      _imagePath = args['image_path'] as String?;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _symptomsCtrl.dispose();
    _fieldCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final farmerName = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final symptoms = '${_selectedChips.join(', ')} - ${_symptomsCtrl.text.trim()}';
    final fieldId = _fieldCtrl.text.trim();
    final now = DateTime.now().toIso8601String();

    String? base64Img;
    if (_imagePath != null) {
      try {
        final bytes = await File(_imagePath!).readAsBytes();
        base64Img = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } catch (e) {
        base64Img = 'data:image/jpeg;base64,ERROR_$e';
      }
    }

    final ticketRow = {
      'farmer_name': farmerName,
      'phone_number': phone,
      'field_id': fieldId,
      'crop_name': _cropName,
      'reported_symptoms': symptoms,
      'ai_prediction': _aiPrediction,
      'ai_confidence': _aiConfidence,
      'image_url': base64Img,
      'status': 'PENDING_REVIEW',
      'created_at': now,
      'synced': 0,
    };

    try {
      final result = await ApiService.instance.createReferralTicket(
        farmerName: farmerName,
        phoneNumber: phone,
        fieldId: fieldId,
        cropName: _cropName,
        symptoms: symptoms,
        aiPrediction: _aiPrediction,
        aiConfidence: _aiConfidence,
        latitude: 19.9975,
        longitude: 73.7898,
        imageUrl: base64Img,
      );
      ticketRow['ticket_code'] = result['ticket_code'] ?? '';
      ticketRow['assigned_lab'] = result['assigned_lab'] ?? '';
      ticketRow['synced'] = 1;
      await DatabaseHelper.instance.insertTicket(ticketRow);
      if (mounted) setState(() { _submitResult = result; _isSubmitting = false; });
    } catch (_) {
      await DatabaseHelper.instance.enqueueSync(
        '/api/v1/referral/create-ticket',
        'POST',
        jsonEncode({
          'farmer_name': farmerName, 'phone_number': phone, 'field_id': fieldId,
          'crop_name': _cropName, 'reported_symptoms': symptoms,
          'ai_prediction': _aiPrediction, 'ai_confidence': _aiConfidence,
          'latitude': 19.9975, 'longitude': 73.7898,
          'image_url': base64Img,
        }),
      );
      await DatabaseHelper.instance.insertTicket(ticketRow);
      if (mounted) {
        setState(() {
          _submitResult = {
            'ticket_code': 'OFFLINE-${now.substring(0, 10)}',
            'assigned_lab': 'Will be assigned when synced',
            'offline': true,
          };
          _isSubmitting = false;
        });
      }
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
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B4D3E),
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(t('Expert Lab Referral'), style: GoogleFonts.epilogue(fontWeight: FontWeight.bold)),
          ),
          body: _submitResult != null ? _buildSuccessView(t) : _buildForm(t),
        );
      },
    );
  }

  Widget _buildForm(String Function(String) t) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI Diagnosis Summary Card
        if (_aiPrediction != 'Unknown')
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5DDD0)),
              boxShadow: const [BoxShadow(color: Color(0x141B4D3E), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Row(
              children: [
                if (_imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(_imagePath!), width: 60, height: 60, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: const Color(0xFFF4EFE6), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(LucideIcons.leaf, color: Color(0xFF1B4D3E)),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('AI Diagnosis'), style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                      Text(
                        _aiPrediction,
                        style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF16221C)),
                      ),
                      Text(
                        '${(_aiConfidence * 100).toStringAsFixed(1)}% ${t("edge confidence")}',
                        style: GoogleFonts.notoSans(fontSize: 13, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 24),

        // Nearest KVK Lab
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5DDD0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFFF4EFE6), shape: BoxShape.circle),
                child: const Icon(LucideIcons.building, color: Color(0xFF1B4D3E)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('KVK Baramati / Nashik Node', style: GoogleFonts.epilogue(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF16221C))),
                    Text('Dr. R. K. Sharma (Agronomist)', style: GoogleFonts.notoSans(fontSize: 13, color: Colors.grey[700])),
                    const SizedBox(height: 4),
                    Text('12.4 km away • Open till 5:30 PM', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1B4D3E))),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(LucideIcons.phoneCall, color: Color(0xFF1B4D3E)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text(t('Farmer Field Observations'), style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF16221C))),
        const SizedBox(height: 16),

        // Quick-Tap Indicator Chips
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _chipOptions.map((chip) {
            final isSelected = _selectedChips.contains(chip);
            return FilterChip(
              label: Text(t(chip), style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF16221C))),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedChips.add(chip);
                  } else {
                    _selectedChips.remove(chip);
                  }
                });
              },
              backgroundColor: const Color(0xFFEAE3D5),
              selectedColor: const Color(0xFF1B4D3E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _symptomsCtrl,
                maxLines: 3,
                style: GoogleFonts.notoSans(fontSize: 15),
                decoration: InputDecoration(
                  hintText: t('Add specific observations...'),
                  hintStyle: GoogleFonts.notoSans(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD7CCC8), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        // Tactile Voice Recorder
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.mic, color: Color(0xFF1B4D3E)),
            label: Text(t('Hold to Record Voice Note'), style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, color: const Color(0xFF1B4D3E))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFFFBF9F4),
            ),
          ),
        ),

        const SizedBox(height: 32),
        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSubmitting 
                ? const CircularProgressIndicator(color: Colors.white) 
                : Text(t('Submit to Lab Expert'), style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSuccessView(String Function(String) t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.checkCircle, color: Color(0xFF1B5E20), size: 64),
            const SizedBox(height: 24),
            Text(
              t('Ticket Submitted!'),
              style: GoogleFonts.epilogue(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF16221C)),
            ),
            const SizedBox(height: 12),
            Text(
              '${t("Ticket ID")}: ${_submitResult!['ticket_code']}',
              style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E)),
            ),
            const SizedBox(height: 8),
            Text(
              _submitResult!['offline'] == true 
                  ? t('Saved offline. Will sync automatically.')
                  : t('An expert from the KVK lab will review this shortly.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(fontSize: 15, color: Colors.grey[700]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(t('Return to Dashboard'), style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
