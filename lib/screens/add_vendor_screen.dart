import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'dart:convert';

class AddVendorScreen extends StatefulWidget {
  const AddVendorScreen({super.key});

  @override
  State<AddVendorScreen> createState() => _AddVendorScreenState();
}

class _AddVendorScreenState extends State<AddVendorScreen> {
  final _nameController       = TextEditingController();
  final _categoryController   = TextEditingController();
  final _locationController   = TextEditingController();
  final _experienceController = TextEditingController();
  final _capacityController   = TextEditingController();
  final _contactController    = TextEditingController();

  bool _isLoading        = false;
  bool _isScoringLoading = false;
  double _aiScore        = 0;
  String _aiAnalysis     = '';
  String _selectedCategory = 'Raw Materials';

  // ── Warm Brown Palette ──────────────────────────────────────────
  static const _bgPrimary   = Color(0xFFE1CBB1); // Grain Brown     – canvas
  static const _bgCard      = Color(0xFF976F47); // Cape Palliser   – card surface
  static const _bgAccent    = Color(0xFF7B5836); // Brown Derby     – hover / accent
  static const _textSecond  = Color(0xFF4B3828); // Smoked Brown    – icons / secondary
  static const _textPrimary = Color(0xFF422A14); // Dark Brown      – headings / body
  static const _inputFill   = Color(0xFFD4B897); // lighter grain for input bg

  final List<String> _categories = [
    'Raw Materials', 'Electronics', 'Packaging', 'Logistics',
    'Chemical', 'Textile', 'Machinery', 'Food & Beverage',
  ];

  final String _geminiApiKey = 'AIzaSyBFcVeZTlXGuVaajNwiGIea_9ZevmKqNRQ';

  Future<void> _getAIScore() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
      _showSnack('Please fill name and location first!', isError: true);
      return;
    }

    setState(() => _isScoringLoading = true);

    try {
      final prompt = '''
You are a vendor qualification expert for manufacturing supply chains.
Analyze this vendor and give a score from 0-100.

Vendor Details:
- Name: ${_nameController.text}
- Category: $_selectedCategory
- Location: ${_locationController.text}
- Years of Experience: ${_experienceController.text} years
- Production Capacity: ${_capacityController.text}
- Contact: ${_contactController.text}

Respond ONLY with JSON:
{
  "score": 75,
  "analysis": "Brief analysis here",
  "strengths": "Key strengths here",
  "improvements": "Areas to improve here"
}''';

      final requestBody = jsonEncode({
        'contents': [{'parts': [{'text': prompt}]}]
      });

      final xhr = html.HttpRequest();
      xhr.open('POST', 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey');
      xhr.setRequestHeader('Content-Type', 'application/json');

      xhr.onLoad.listen((event) {
        if (xhr.status == 200) {
          final data      = jsonDecode(xhr.responseText!);
          final text      = data['candidates'][0]['content']['parts'][0]['text'] as String;
          final cleanText = text.replaceAll('```json', '').replaceAll('```', '').trim();
          final result    = jsonDecode(cleanText);
          setState(() {
            _aiScore    = (result['score'] as num).toDouble();
            _aiAnalysis = 'Analysis: ${result['analysis']}\n\nStrengths: ${result['strengths']}\n\nImprovements: ${result['improvements']}';
            _isScoringLoading = false;
          });
        } else {
          setState(() => _isScoringLoading = false);
          _showSnack('AI scoring failed: ${xhr.status}', isError: true);
        }
      });

      xhr.onError.listen((event) {
        setState(() => _isScoringLoading = false);
        _showSnack('Network error. Try again!', isError: true);
      });

      xhr.send(requestBody);
    } catch (e) {
      setState(() => _isScoringLoading = false);
      _showSnack('AI scoring failed: $e', isError: true);
    }
  }

  Future<void> _saveVendor() async {
    if (_nameController.text.isEmpty) {
      _showSnack('Please fill vendor name!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('vendors').add({
        'uid':        user!.uid,
        'name':       _nameController.text.trim(),
        'category':   _selectedCategory,
        'location':   _locationController.text.trim(),
        'experience': _experienceController.text.trim(),
        'capacity':   _capacityController.text.trim(),
        'contact':    _contactController.text.trim(),
        'aiScore':    _aiScore,
        'aiAnalysis': _aiAnalysis,
        'status':     'Active',
        'createdAt':  FieldValue.serverTimestamp(),
      });

      _showSnack('Vendor added successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Error saving vendor: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: _bgPrimary)),
        backgroundColor: isError ? const Color(0xFF8B3A3A) : _bgAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF5B7B52);  // earthy green
    if (score >= 60) return const Color(0xFFA0722A);  // warm amber
    return const Color(0xFF8B3A3A);                    // muted red
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        backgroundColor: _textPrimary,
        title: const Text(
          'Add Vendor',
          style: TextStyle(
            color: Color(0xFFE1CBB1),
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE1CBB1)),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Section Label ──────────────────────────────────────
            _sectionLabel('Vendor Information'),
            const SizedBox(height: 12),

            // ── Info Card ──────────────────────────────────────────
            _card(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Vendor Name',
                    icon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildDropdown(),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location (City, State)',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _experienceController,
                    label: 'Years of Experience',
                    icon: Icons.work_outline,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _capacityController,
                    label: 'Production Capacity',
                    icon: Icons.factory_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _contactController,
                    label: 'Contact Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── AI Score Button ────────────────────────────────────
            _sectionLabel('AI Qualification'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScoringLoading ? null : _getAIScore,
                icon: _isScoringLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE1CBB1)),
                      )
                    : const Icon(Icons.auto_awesome_outlined, color: Color(0xFFE1CBB1), size: 20),
                label: Text(
                  _isScoringLoading ? 'Analyzing…' : 'Get AI Score',
                  style: const TextStyle(
                    color: Color(0xFFE1CBB1),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bgAccent,
                  disabledBackgroundColor: _textSecond.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),

            // ── AI Result Card ─────────────────────────────────────
            if (_aiScore > 0) ...[
              const SizedBox(height: 18),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_outlined,
                            color: _bgPrimary.withOpacity(0.8), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'AI Score Result',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _bgPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 96,
                            height: 96,
                            child: CircularProgressIndicator(
                              value: _aiScore / 100,
                              strokeWidth: 8,
                              backgroundColor: _bgPrimary.withOpacity(0.2),
                              color: _getScoreColor(_aiScore),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            '${_aiScore.toInt()}',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(_aiScore),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _aiAnalysis,
                      style: TextStyle(
                        fontSize: 13,
                        color: _bgPrimary.withOpacity(0.85),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),

            // ── Save Button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveVendor,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE1CBB1)),
                      )
                    : const Icon(Icons.save_outlined, color: Color(0xFFE1CBB1), size: 20),
                label: Text(
                  _isLoading ? 'Saving…' : 'Save Vendor',
                  style: const TextStyle(
                    color: Color(0xFFE1CBB1),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _textPrimary,
                  disabledBackgroundColor: _textSecond.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: _textSecond,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _textPrimary.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      dropdownColor: _bgAccent,
      iconEnabledColor: _bgPrimary.withOpacity(0.7),
      style: const TextStyle(color: Color(0xFFE1CBB1), fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: TextStyle(color: _bgPrimary.withOpacity(0.7), fontSize: 13),
        prefixIcon: Icon(Icons.category_outlined, color: _bgPrimary.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: _bgAccent.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _bgPrimary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _bgPrimary.withOpacity(0.6), width: 1.5),
        ),
      ),
      items: _categories
          .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat, style: const TextStyle(color: Color(0xFFE1CBB1))),
              ))
          .toList(),
      onChanged: (val) => setState(() => _selectedCategory = val!),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFFE1CBB1), fontSize: 14),
      cursorColor: _bgPrimary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _bgPrimary.withOpacity(0.65), fontSize: 13),
        prefixIcon: Icon(icon, color: _bgPrimary.withOpacity(0.65), size: 20),
        filled: true,
        fillColor: _bgAccent.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _bgPrimary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _bgPrimary.withOpacity(0.6), width: 1.5),
        ),
      ),
    );
  }
}