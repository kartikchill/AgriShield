import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../localization/app_translations.dart';
import '../localization/language_notifier.dart';
import 'accessible_audio_button.dart';

class InsuranceRecommendationModal extends StatelessWidget {
  final bool isDiseaseOrPest;

  const InsuranceRecommendationModal({
    super.key,
    required this.isDiseaseOrPest,
  });

  static void show(BuildContext context, {required bool isDiseaseOrPest}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InsuranceRecommendationModal(isDiseaseOrPest: isDiseaseOrPest),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageNotifier.instance,
      builder: (context, _) {
        final lang = LanguageNotifier.instance.languageCode;
        String t(String key) => AppTranslations.t(key, lang);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        t('Eligible Insurance Schemes'),
                        style: GoogleFonts.epilogue(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E)),
                      ),
                    ),
                    AccessibleAudioButton(textToSpeak: t('Eligible Insurance Schemes')),
                  ],
                ),
                const SizedBox(height: 16),

                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t('⚠️ Decision support only. AGRI-SHIELD does not determine eligibility, approve claims, or guarantee compensation.'),
                          style: GoogleFonts.notoSans(fontSize: 13, color: Colors.orange[900], fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dynamic Schemes
                if (isDiseaseOrPest)
                  _buildSchemeCard(
                    title: 'PMFBY (Pradhan Mantri Fasal Bima Yojana)',
                    description: t('Covers yield losses due to non-preventable risks, such as natural fire and lightning, storm, hailstorm, cyclone, typhoon, tempest, hurricane, tornado, flood, inundation, landslide, drought, dry spells, pests/diseases.'),
                    icon: LucideIcons.bug,
                    color: const Color(0xFF1976D2),
                  )
                else
                  _buildSchemeCard(
                    title: 'RWBCIS (Restructured Weather Based Crop Insurance)',
                    description: t('Aims to mitigate the hardship of the insured farmers against the likelihood of financial loss on account of anticipated crop loss resulting from adverse weather conditions relating to rainfall, temperature, wind, humidity etc.'),
                    icon: LucideIcons.cloudLightning,
                    color: const Color(0xFF00796B),
                  ),
                
                const SizedBox(height: 16),
                _buildSchemeCard(
                  title: 'SDRF / State Relief',
                  description: t('State Disaster Response Fund for extreme agricultural conditions and calamities.'),
                  icon: LucideIcons.alertTriangle,
                  color: const Color(0xFFC62828),
                ),

                const SizedBox(height: 24),
                // Document Checklist
                Text(
                  t('Document Checklist (Prepare before contacting KVK/Bank):'),
                  style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF16221C)),
                ),
                const SizedBox(height: 12),
                _buildChecklistItem(t('Aadhaar Card')),
                _buildChecklistItem(t('7/12 Land Record or Title Document')),
                _buildChecklistItem(t('Bank Passbook')),
                _buildChecklistItem(t('Sowing Certificate')),
                _buildChecklistItem(t('Clear photos of damaged crops')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSchemeCard({required String title, required String description, required IconData icon, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF16221C))),
                const SizedBox(height: 6),
                Text(description, style: GoogleFonts.notoSans(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(LucideIcons.checkCircle2, color: Color(0xFF1B4D3E), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.notoSans(fontSize: 14, color: Colors.grey[800]))),
        ],
      ),
    );
  }
}
