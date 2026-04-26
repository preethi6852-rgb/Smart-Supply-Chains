import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/vendor_service.dart';

class ChecklistScreen extends StatefulWidget {
  final String vendorId;
  const ChecklistScreen({super.key, required this.vendorId});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final VendorService _vendorService = VendorService();
  bool _saving = false;

  static const Color _bg     = Color(0xFFe1cbb1);
  static const Color _cardBg = Color(0xFFf5ede0);
  static const Color _derby  = Color(0xFF7b5836);
  static const Color _smoked = Color(0xFF4b3828);
  static const Color _dark   = Color(0xFF422a14);
  static const Color _border = Color(0x2E4b3828);

  final Map<String, List<Map<String, dynamic>>> _checklistItems = {
    'Legal & Compliance': [
      {'title': 'GST Registration',          'key': 'hasGSTCertificate',   'checked': false},
      {'title': 'Business License',          'key': 'hasFactoryLicense',   'checked': false},
      {'title': 'ISO Certification',         'key': 'hasISOCertification', 'checked': false},
      {'title': 'Factory Licence',               'key': 'hasSafetyClearance',  'checked': false},
    ],
    'Quality Standards': [
      {'title': 'Quality Management System', 'key': 'hasQualitySystem',   'checked': false},
      {'title': 'Product Testing Reports',   'key': 'hasTestingReports',  'checked': false},
      {'title': 'Defect Rate < 10%',         'key': 'hasDefectRate',      'checked': false},
      {'title': 'Return Policy Defined',     'key': 'hasReturnPolicy',    'checked': false},
    ],
    'Financial Health': [
      {'title': 'Account Health',            'key': 'hasBankDetails',     'checked': false},
      {'title': 'Credit Score Verified',     'key': 'hasCreditScore',     'checked': false},
      {'title': 'No Pending Litigations',    'key': 'hasNoPendingCases',  'checked': false},
      {'title': 'Payment Terms Agreed',      'key': 'hasSignedContract',  'checked': false},
    ],
    'Operational Capacity': [
      {'title': 'Factory/Facility Visit Done',  'key': 'hasFactoryVisit',     'checked': false},
      {'title': 'Production Capacity Verified', 'key': 'hasCapacityVerified', 'checked': false},
      {'title': 'Delivery Timeline Confirmed',  'key': 'hasDeliveryTimeline', 'checked': false},
      {'title': 'Warehouse Storage Adequate',   'key': 'hasWarehouse',        'checked': false},
    ],
    'Environmental & Safety': [
      {'title': 'Environmental Compliance', 'key': 'hasEnvCompliance', 'checked': false},
      {'title': 'Worker Safety Standards',  'key': 'hasWorkerSafety',  'checked': false},
      {'title': 'Waste Management Policy',  'key': 'hasWastePolicy',   'checked': false},
      {'title': 'Fire Safety Certified',    'key': 'hasFireSafety',    'checked': false},
    ],
  };

  int get _totalItems   => _checklistItems.values.fold(0, (s, l) => s + l.length);
  int get _checkedItems => _checklistItems.values.fold(0, (s, l) => s + l.where((i) => i['checked']).length);
  double get _progress  => _totalItems > 0 ? _checkedItems / _totalItems : 0;

  String get _qualificationStatus {
    if (_progress >= 0.9) return 'Fully Qualified';
    if (_progress >= 0.7) return 'Conditionally Qualified';
    if (_progress >= 0.5) return 'Under Review';
    return 'Not Qualified';
  }

  Color get _statusBg {
    if (_progress >= 0.9) return const Color(0xFFd6e8d0);
    if (_progress >= 0.7) return const Color(0xFFf5e4c8);
    if (_progress >= 0.5) return const Color(0xFFdce8f5);
    return const Color(0xFFf0d5d0);
  }

  Color get _statusFg {
    if (_progress >= 0.9) return const Color(0xFF2e5e22);
    if (_progress >= 0.7) return const Color(0xFF7a4a0a);
    if (_progress >= 0.5) return const Color(0xFF1a4a7a);
    return const Color(0xFF7a1f1a);
  }

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    final doc = await FirebaseFirestore.instance.collection('vendors').doc(widget.vendorId).get();
    if (!doc.exists) return;
    final saved = (doc.data()!['checklist'] as Map<String, dynamic>?) ?? {};
    setState(() {
      for (final category in _checklistItems.values) {
        for (final item in category) {
          final key = item['key'] as String;
          if (saved.containsKey(key)) item['checked'] = saved[key] ?? false;
        }
      }
    });
  }

  Future<void> _saveChecklist() async {
    setState(() => _saving = true);
    try {
      final Map<String, bool> checklistMap = {};
      for (final category in _checklistItems.values) {
        for (final item in category) {
          checklistMap[item['key'] as String] = item['checked'] as bool;
        }
      }
      final score = ((_checkedItems / _totalItems) * 100).round();
      await FirebaseFirestore.instance.collection('vendors').doc(widget.vendorId).update({
        'checklist':      checklistMap,
        'checklistScore': score,
        'updatedAt':      FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Checklist saved!'), backgroundColor: const Color(0xFF2e5e22), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFF7a1f1a), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3a2510),
        title: const Text('Vendor Qualification Checklist', style: TextStyle(color: Color(0xFFe1cbb1), fontWeight: FontWeight.w600, fontSize: 15)),
        iconTheme: const IconThemeData(color: Color(0xFFe1cbb1)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_checkedItems / $_totalItems completed', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _dark)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(20)),
                        child: Text(_qualificationStatus, style: TextStyle(color: _statusFg, fontWeight: FontWeight.w600, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: _smoked.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(_statusFg),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${(_progress * 100).toInt()}% complete', style: TextStyle(color: _statusFg, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Checklist Categories
            ..._checklistItems.entries.map((entry) {
              final doneCount = entry.value.where((i) => i['checked']).length;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _dark)),
                    subtitle: Text('$doneCount/${entry.value.length} done', style: const TextStyle(color: _smoked, fontSize: 12)),
                    iconColor: _derby,
                    collapsedIconColor: _smoked,
                    initiallyExpanded: true,
                    children: entry.value.map((item) {
                      return CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(item['title'], style: const TextStyle(fontSize: 13, color: _dark)),
                        value: item['checked'],
                        activeColor: _derby,
                        checkColor: const Color(0xFFf5ede0),
                        side: BorderSide(color: _smoked.withOpacity(0.4)),
                        onChanged: (val) => setState(() => item['checked'] = val ?? false),
                      );
                    }).toList(),
                  ),
                ),
              );
            }),

            const SizedBox(height: 14),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveChecklist,
                icon: _saving
                    ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFf5ede0)))
                    : const Icon(Icons.save_rounded, color: Color(0xFFf5ede0)),
                label: Text(
                  _saving ? 'Saving...' : 'Save Checklist',
                  style: const TextStyle(color: Color(0xFFf5ede0), fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _derby,
                  disabledBackgroundColor: _derby.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}