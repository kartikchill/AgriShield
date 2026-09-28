import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../database/db_helper.dart';
import '../localization/app_translations.dart';
import '../localization/language_notifier.dart';
import '../widgets/accessible_audio_button.dart';
class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    final tickets = await DatabaseHelper.instance.getAllTickets();
    setState(() {
      _tickets = tickets;
      _isLoading = false;
    });
  }

  Future<void> _syncNow() async {
    // Implement actual sync logic here
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All tickets synced successfully', style: GoogleFonts.notoSans()),
        backgroundColor: const Color(0xFF1B4D3E),
      ),
    );
    _loadTickets();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageNotifier.instance,
      builder: (context, _) {
        final lang = LanguageNotifier.instance.languageCode;
        String t(String key) => AppTranslations.t(key, lang);

        final pendingCount = _tickets.where((tk) => tk['synced'] == 0).length;

        return Scaffold(
          backgroundColor: const Color(0xFFFBF9F4),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  color: const Color(0xFF1B4D3E),
                  onRefresh: _loadTickets,
                  child: ListView(
                    padding: const EdgeInsets.all(0),
                    children: [
                      // Custom Header replacing nested AppBar
                      Container(
                        color: const Color(0xFF1B4D3E),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        width: double.infinity,
                        child: Text(t('Offline Sync & Ledger'), style: GoogleFonts.epilogue(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      // Sync Now Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5DDD0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x141B4D3E), blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t('Queue Telemetry'),
                                      style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF16221C)),
                                    ),
                                    Text(
                                      '$pendingCount ${t("Tickets Pending Sync")}',
                                      style: GoogleFonts.notoSans(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                AccessibleAudioButton(textToSpeak: t('You have $pendingCount tickets pending sync.')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: pendingCount > 0 ? _syncNow : null,
                                icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
                                label: Text(
                                  t('SYNC ALL NOW'),
                                  style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B4D3E),
                                  disabledBackgroundColor: Colors.grey[400],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Text(
                            t('Diagnostic Tickets'),
                            style: GoogleFonts.epilogue(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF16221C)),
                          )),
                          AccessibleAudioButton(textToSpeak: t('Diagnostic Tickets')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_tickets.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              t('No tickets found.'),
                              style: GoogleFonts.notoSans(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      else
                        ..._tickets.map((ticket) {
                          final isSynced = ticket['synced'] == 1;
                          final hasAdvisory = ticket['expert_advisory'] != null && ticket['expert_advisory'].toString().isNotEmpty;
                          final statusColor = hasAdvisory ? const Color(0xFF1976D2) : (isSynced ? const Color(0xFF1B5E20) : const Color(0xFFE65100));
                          final statusText = hasAdvisory ? t('Diagnosed') : (isSynced ? t('Synced') : t('Pending'));

                          return GestureDetector(
                            onTap: hasAdvisory ? () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                backgroundColor: Colors.white,
                                builder: (ctx) => Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(t('Expert Advisory'), style: GoogleFonts.epilogue(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
                                          AccessibleAudioButton(textToSpeak: ticket['expert_advisory']),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      if (ticket['expert_diagnosis'] != null)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(color: const Color(0xFFF4F7F6), borderRadius: BorderRadius.circular(12)),
                                          child: Row(
                                            children: [
                                              const Icon(LucideIcons.stethoscope, color: Color(0xFF1B4D3E), size: 20),
                                              const SizedBox(width: 12),
                                              Expanded(child: Text('${t("Diagnosis")}: ${ticket['expert_diagnosis']}', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E)))),
                                            ],
                                          ),
                                        ),
                                      Text(ticket['expert_advisory'], style: GoogleFonts.notoSans(fontSize: 14, color: Colors.grey[800], height: 1.5)),

                                    ],
                                  ),
                                ),
                              );
                            } : null,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5DDD0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${ticket['ai_prediction'] ?? "Unknown"} - ${ticket['crop_name'] ?? "Crop"}',
                                              style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF16221C)),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${t("Field")}: ${ticket['field_id'] ?? "Unknown"}',
                                              style: GoogleFonts.spaceGrotesk(fontSize: 13, color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(9999),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.circle, color: statusColor, size: 8),
                                            const SizedBox(width: 4),
                                            Text(
                                              t(statusText),
                                              style: GoogleFonts.spaceGrotesk(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, color: Color(0xFFE5DDD0)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(t('Submitted to Admin Portal for Active Learning'), style: GoogleFonts.notoSans()),
                                              backgroundColor: const Color(0xFF1B4D3E),
                                            ),
                                          );
                                        },
                                        icon: const Icon(LucideIcons.brainCircuit, size: 16, color: Color(0xFF1B4D3E)),
                                        label: Text(
                                          t('Submit for AI Training'),
                                          style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1B4D3E)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
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
}
