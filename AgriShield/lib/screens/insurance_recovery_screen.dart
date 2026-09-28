import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class InsuranceRecoveryScreen extends StatefulWidget {
  const InsuranceRecoveryScreen({super.key});

  @override
  State<InsuranceRecoveryScreen> createState() => _InsuranceRecoveryScreenState();
}

class _InsuranceRecoveryScreenState extends State<InsuranceRecoveryScreen> {
  final TextEditingController _farmerNameController = TextEditingController(text: 'Rajesh Patil');
  final TextEditingController _cropController = TextEditingController();
  final TextEditingController _damageController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  bool _isSubmitting = false;

  Future<void> _submitClaim() async {
    if (_cropController.text.isEmpty || _damageController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      final url = '${ApiService.adminBaseUrl}/api/insurance/claims';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'farmer_name': _farmerNameController.text,
          'phone': '9876543210',
          'crop': _cropController.text,
          'damage_type': _damageController.text,
          'district': 'Nashik',
          'scheme': 'PMFBY',
          'claim_amount': double.tryParse(_amountController.text) ?? 0,
          'notes': 'Submitted via App',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Claim submitted successfully!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to connect to backend: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          'PMFBY Insurance Claim',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, color: Colors.blue, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Pradhan Mantri Fasal Bima Yojana (PMFBY) Direct Claim Portal',
                      style: GoogleFonts.inter(color: Colors.blue[100], fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Text('Farmer Name', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _farmerNameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('e.g. Rajesh Patil'),
            ),
            const SizedBox(height: 20),

            Text('Crop Affected', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _cropController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('e.g. Tomato'),
            ),
            const SizedBox(height: 20),

            Text('Damage Reason', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _damageController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('e.g. Heavy Rain / Pest Attack'),
            ),
            const SizedBox(height: 20),

            Text('Estimated Loss Amount (₹)', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('e.g. 25000'),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submitClaim,
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Submit Claim to KVK', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
