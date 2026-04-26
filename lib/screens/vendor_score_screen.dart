import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/vendor_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorScoreScreen extends StatefulWidget {
  final String vendorId;
  const VendorScoreScreen({super.key, required this.vendorId});

  @override
  State<VendorScoreScreen> createState() => _VendorScoreScreenState();
}

class _VendorScoreScreenState extends State<VendorScoreScreen> {
  final GeminiService _gemini = GeminiService();
  final VendorService _vendorService = VendorService();
  bool _loading = false;

  // ── Warm Brown Palette ──────────────────────────────────────────
  static const _bgPrimary    = Color(0xFFE1CBB1); // Grain Brown     – canvas
  static const _bgCard       = Color(0xFF976F47); // Cape Palliser   – card surface
  static const _bgAccent     = Color(0xFF7B5836); // Brown Derby     – hover / accent
  static const _textSecond   = Color(0xFF4B3828); // Smoked Brown    – icons / secondary text
  static const _textPrimary  = Color(0xFF422A14); // Dark Brown      – headings / body

  // ── Semantic colours (muted to match warm palette) ──────────────
  static const _lowRisk    = Color(0xFF5B7B52);  // earthy green
  static const _medRisk    = Color(0xFFA0722A);  // warm amber
  static const _highRisk   = Color(0xFF8B3A3A);  // muted red

  // ─── TRIGGER SCORING ──────────────────────────────────────────
  Future<void> _runScore() async {
    setState(() => _loading = true);
    try {
      await _gemini.scoreAndSaveVendor(widget.vendorId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('AI Score updated!'),
            backgroundColor: _bgAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: _highRisk,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── RISK COLOR ───────────────────────────────────────────────
  Color _riskColor(String risk) {
    switch (risk) {
      case 'low':    return _lowRisk;
      case 'medium': return _medRisk;
      case 'high':   return _highRisk;
      default:       return _textSecond;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        backgroundColor: _textPrimary,
        title: const Text(
          'Vendor Score',
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(widget.vendorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _bgAccent),
            );
          }

          final vendor      = snapshot.data!.data() as Map<String, dynamic>;
          final score       = vendor['aiScore'] ?? 0;
          final riskLevel   = vendor['riskLevel'] ?? 'unknown';
          final explanation = vendor['riskExplanation'] ?? 'Not yet scored.';
          final lastScored  = vendor['lastScoredAt'];
          final ringColor   = _riskColor(riskLevel);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Vendor Name ──────────────────────────────────
                Text(
                  vendor['name'] ?? 'Vendor',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  vendor['category'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textSecond,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Score Ring ───────────────────────────────────
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _bgCard,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _textPrimary.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 10,
                            backgroundColor: _bgPrimary.withOpacity(0.3),
                            color: ringColor,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE1CBB1),
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'out of 100',
                              style: TextStyle(
                                color: Color(0xFFD0B898),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Risk Badge ───────────────────────────────────
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                    decoration: BoxDecoration(
                      color: ringColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ringColor.withOpacity(0.5), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(color: ringColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '${riskLevel.toUpperCase()} RISK',
                          style: TextStyle(
                            color: ringColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Explanation Card ─────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _textPrimary.withOpacity(0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_outlined, color: _bgPrimary.withOpacity(0.8), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'AI Analysis',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _bgPrimary,
                              fontSize: 14,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        explanation,
                        style: TextStyle(
                          color: _bgPrimary.withOpacity(0.85),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                if (lastScored != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 14, color: _textSecond),
                      const SizedBox(width: 5),
                      Text(
                        'Last scored: ${(lastScored as Timestamp).toDate().toString().substring(0, 16)}',
                        style: const TextStyle(fontSize: 12, color: _textSecond),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 36),

                // ── Score Button ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _runScore,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE1CBB1)),
                          )
                        : const Icon(Icons.auto_awesome, color: Color(0xFFE1CBB1), size: 20),
                    label: Text(
                      _loading ? 'Scoring…' : 'Run AI Score',
                      style: const TextStyle(
                        color: Color(0xFFE1CBB1),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _textPrimary,
                      disabledBackgroundColor: _textSecond.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}