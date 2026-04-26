import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'checklist_screen.dart';
import 'vendor_score_screen.dart';
import 'map_screen.dart';
import 'chat_screen.dart';

class VendorDetailScreen extends StatelessWidget {
  final String vendorId;
  final Map<String, dynamic> vendorData;

  const VendorDetailScreen({super.key, required this.vendorId, required this.vendorData});

  static const Color _bg     = Color(0xFFe1cbb1);
  static const Color _cardBg = Color(0xFFf5ede0);
  static const Color _derby  = Color(0xFF7b5836);
  static const Color _cape   = Color(0xFF976f47);
  static const Color _smoked = Color(0xFF4b3828);
  static const Color _dark   = Color(0xFF422a14);
  static const Color _border = Color(0x2E4b3828);

  Color _scoreColor(double score) {
    if (score >= 80) return const Color(0xFF2e5e22);
    if (score >= 60) return const Color(0xFF7a4a0a);
    return const Color(0xFF7a1f1a);
  }

  Color _scoreBg(double score) {
    if (score >= 80) return const Color(0xFFd6e8d0);
    if (score >= 60) return const Color(0xFFf5e4c8);
    return const Color(0xFFf0d5d0);
  }

  PdfColor _pdfScoreColor(double score) {
    if (score >= 80) return PdfColors.green700;
    if (score >= 60) return PdfColors.orange700;
    return PdfColors.red700;
  }

  double _getLat() {
    final loc = vendorData['locationGeo'];
    if (loc != null && loc.runtimeType.toString().contains('GeoPoint')) {
      return loc.latitude as double;
    }
    return (vendorData['lat'] ?? vendorData['latitude'] ?? 13.0827).toDouble();
  }

  double _getLng() {
    final loc = vendorData['locationGeo'];
    if (loc != null && loc.runtimeType.toString().contains('GeoPoint')) {
      return loc.longitude as double;
    }
    return (vendorData['lng'] ?? vendorData['longitude'] ?? 80.2707).toDouble();
  }

  String _cleanLabel(String key) {
    const labels = {
      'hasCreditScore'      : 'Credit Score',
      'hasNoPendingCases'   : 'No Pending Cases',
      'hasGSTCertificate'   : 'GST Certificate',
      'hasEnvCompliance'    : 'Environmental Compliance',
      'hasSignedContract'   : 'Signed Contract',
      'hasReturnPolicy'     : 'Return Policy',
      'hasFactoryVisit'     : 'Factory Visit',
      'hasQualitySystem'    : 'Quality System',
      'hasDeliveryTimeline' : 'Delivery Timeline',
      'hasWarehouse'        : 'Warehouse',
      'hasSafetyClearance'  : 'Safety Clearance',
      'hasDefectRate'       : 'Defect Rate',
      'hasTestingReports'   : 'Testing Reports',
      'hasFactoryLicense'   : 'Factory License',
      'hasFireSafety'       : 'Fire Safety',
      'hasISOCertification' : 'ISO Certification',
      'hasCapacityVerified' : 'Capacity Verified',
      'hasWorkerSafety'     : 'Worker Safety',
      'hasWastePolicy'      : 'Waste Policy',
      'hasBankDetails'      : 'Bank Details',
    };
    if (labels.containsKey(key)) return labels[key]!;
    final spaced = key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}');
    return spaced.trim();
  }

  // ── Risk badge color ──────────────────────────────────────────────
  PdfColor _riskBadgeColor(dynamic level) {
    switch ((level ?? '').toString().toLowerCase()) {
      case 'low':    return PdfColors.green700;
      case 'medium': return PdfColors.orange700;
      case 'high':   return PdfColors.red700;
      default:       return PdfColors.grey600;
    }
  }

  // ── Checklist cell ────────────────────────────────────────────────
  pw.Widget _checklistCell(String key, bool done) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      child: pw.Row(children: [
        pw.Container(
          width: 14, height: 14,
          decoration: pw.BoxDecoration(
            color: done ? PdfColors.green600 : PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(3),
            border: pw.Border.all(color: done ? PdfColors.green700 : PdfColors.grey400, width: 0.5),
          ),
          child: done
              ? pw.Center(child: pw.Text('v', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)))
              : pw.SizedBox(),
        ),
        pw.SizedBox(width: 7),
        pw.Expanded(
          child: pw.Text(
            _cleanLabel(key),
            style: pw.TextStyle(fontSize: 10, color: done ? PdfColors.grey800 : PdfColors.grey500),
          ),
        ),
      ]),
    );
  }

  // ── Section title bar ─────────────────────────────────────────────
  pw.Widget _pdfSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: pw.BoxDecoration(
        color: PdfColors.brown800,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }

  // ── Detail table ──────────────────────────────────────────────────
  pw.Widget _pdfDetailTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(110),
        1: const pw.FlexColumnWidth(1),
      },
      children: rows.asMap().entries.map((e) {
        final i = e.key; final row = e.value;
        return pw.TableRow(
          decoration: pw.BoxDecoration(color: i.isEven ? PdfColors.grey50 : PdfColors.white),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: pw.Text(row[0], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.brown800)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  GENERATE PDF  (matches the image layout)
  // ════════════════════════════════════════════════════════════════
  Future<void> _generatePDF(BuildContext context) async {
    final pdf            = pw.Document();
    final score          = (vendorData['aiScore']        ?? 0).toDouble();
    final deliveryScore  = (vendorData['deliveryScore']  ?? 0).toDouble();
    final checklistScore = (vendorData['checklistScore'] ?? 0).toDouble();
    final riskLevel      = (vendorData['riskLevel']      ?? 'unknown').toString().toLowerCase();
    final riskText       = riskLevel == 'high'   ? 'HIGH RISK'
                         : riskLevel == 'medium' ? 'MEDIUM RISK'
                         :                         'LOW RISK';
    final riskSubtitle   = riskLevel == 'high'   ? 'Potential Compliance Issues'
                         : riskLevel == 'medium' ? 'Moderate Concerns'
                         :                         'All Clear';
    final riskBgColor    = riskLevel == 'high'   ? PdfColors.red700
                         : riskLevel == 'medium' ? PdfColors.orange600
                         :                         PdfColors.green700;

    final checklist      = vendorData['checklist'] as Map<String, dynamic>? ?? {};
    final completedCount = checklist.values.where((v) => v == true).length;
    final totalCount     = checklist.length;
    final checklistPct   = totalCount > 0 ? (completedCount / totalCount * 100).round() : 0;

    final entries  = checklist.entries.toList();
    final half     = (entries.length / 2).ceil();
    final leftCol  = entries.sublist(0, half);
    final rightCol = entries.sublist(half);

    // Parse risk explanation into bullet points
    final riskRaw   = (vendorData['riskExplanation'] ?? '').toString();
    final riskLines = riskRaw.isNotEmpty
        ? riskRaw.split(RegExp(r'[.\n]+')).where((s) => s.trim().length > 6).take(3).toList()
        : <String>['No specific risk notes available.'];

    // AI recommendations (from aiAnalysis or generic)
    final analysisRaw = (vendorData['aiAnalysis'] ?? '').toString();
    final recLines    = analysisRaw.isNotEmpty
        ? analysisRaw.split(RegExp(r'[.\n]+')).where((s) => s.trim().length > 6).take(3).toList()
        : <String>['Conduct regular vendor audits.', 'Review delivery performance quarterly.', 'Ensure compliance documentation is up to date.'];

    // On-time delivery (use deliveryScore as proxy if no direct field)
    final onTime = vendorData['onTimeDelivery'] != null
        ? '${vendorData['onTimeDelivery']}%'
        : '${deliveryScore.toInt()}%';
    final rating = vendorData['rating'] != null ? '${vendorData['rating']} / 5' : '4.5 / 5';
    final auditPassed = vendorData['auditPassed'] ?? (checklistScore >= 70);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (ctx) => [

          // ── TITLE BLOCK ────────────────────────────────────────────
          pw.Text(
            vendorData['name'] ?? 'Vendor Name',
            style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900),
          ),
          pw.SizedBox(height: 4),
          pw.Text('AI Vendor Evaluation Report',
              style: const pw.TextStyle(fontSize: 13, color: PdfColors.brown600)),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.brown300, thickness: 1.2),
          pw.SizedBox(height: 18),

          // ── TOP SCORE ROW: AI Score | Risk Level | Compliance | Final ─
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // AI Score box
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('AI Score',
                          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        width: 56, height: 56,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: _pdfScoreColor(score) == PdfColors.green700
                              ? PdfColors.green100 : _pdfScoreColor(score) == PdfColors.orange700
                              ? PdfColors.orange100 : PdfColors.red100,
                          border: pw.Border.all(color: _pdfScoreColor(score), width: 2),
                        ),
                        child: pw.Center(
                          child: pw.Text('${score.toInt()}',
                              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _pdfScoreColor(score))),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        score >= 80 ? 'Strong Performance' : score >= 60 ? 'Moderate' : 'Needs Improvement',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _pdfScoreColor(score)),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),

              // Risk Level box
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: riskBgColor,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('Risk Level',
                          style: const pw.TextStyle(fontSize: 11, color: PdfColors.white)),
                      pw.SizedBox(height: 10),
                      pw.Text(riskText,
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                          textAlign: pw.TextAlign.center),
                      pw.SizedBox(height: 6),
                      pw.Text(riskSubtitle,
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                          textAlign: pw.TextAlign.center),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),

              // Compliance Score box
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('Compliance Score',
                          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        width: 56, height: 56,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColors.green100,
                          border: pw.Border.all(color: PdfColors.green700, width: 2),
                        ),
                        child: pw.Center(
                          child: pw.Text('${checklistScore.toInt()}%',
                              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        checklistScore >= 80 ? 'Fully Compliant' : checklistScore >= 60 ? 'Partial' : 'Non-Compliant',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),

              // Final Score badge
              pw.Container(
                width: 80,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColors.brown800,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('FINAL\nSCORE',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                        textAlign: pw.TextAlign.center),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      '${((score + deliveryScore + checklistScore) / 3).round()}',
                      style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── VENDOR DETAILS ─────────────────────────────────────────
          _pdfSectionTitle('Vendor Details'),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey200),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left column
                pw.Expanded(
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    _detailItem('Location', vendorData['location']   ?? 'N/A'),
                    pw.SizedBox(height: 8),
                    _detailItem('Category', vendorData['category']   ?? 'N/A'),
                    pw.SizedBox(height: 8),
                    _detailItem('Experience', '${vendorData['experience'] ?? 'N/A'} Years in Business'),
                  ]),
                ),
                pw.SizedBox(width: 16),
                // Middle column
                pw.Expanded(
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    _detailItem('Rating', 'Rating: $rating'),
                    pw.SizedBox(height: 8),
                    _detailItem('On-Time Delivery', 'On-Time Delivery: $onTime'),
                  ]),
                ),
                pw.SizedBox(width: 16),
                // Right column
                pw.Expanded(
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    _detailItem('Rating', 'Rating: $rating'),
                    pw.SizedBox(height: 8),
                    _detailItem('On-Time Delivery', 'On-Time Delivery: $onTime'),
                    pw.SizedBox(height: 8),
                    _detailItem('Audit', 'Audit Passed: ${auditPassed == true ? 'Yes' : 'No'}'),
                  ]),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── QUALIFICATION CHECKLIST ────────────────────────────────
          _pdfSectionTitle('Qualification Checklist'),
          pw.SizedBox(height: 10),

          // Progress bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: PdfColors.grey200),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('$completedCount of $totalCount items completed',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.Text('$checklistPct% Complete',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold,
                          color: checklistPct >= 80 ? PdfColors.green700 : PdfColors.orange700)),
                ],
              ),
              pw.SizedBox(height: 8),
              // Progress bar track
              pw.Stack(children: [
                pw.Container(
                  height: 10,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                ),
                pw.Container(
                  height: 10,
                  width: (PdfPageFormat.a4.availableWidth - 64) * (checklistPct / 100),
                  decoration: pw.BoxDecoration(
                    gradient: const pw.LinearGradient(colors: [PdfColors.green600, PdfColors.yellow600]),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                ),
              ]),
            ]),
          ),
          pw.SizedBox(height: 10),

          // Two-column checklist
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: PdfColors.grey200),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
              },
              children: List.generate(half, (i) {
                final left  = leftCol[i];
                final right = i < rightCol.length ? rightCol[i] : null;
                return pw.TableRow(children: [
                  _checklistCell(left.key, left.value == true),
                  right != null ? _checklistCell(right.key, right.value == true) : pw.SizedBox(),
                ]);
              }),
            ),
          ),
          pw.SizedBox(height: 20),

          // ── RISK ANALYSIS ──────────────────────────────────────────
          _pdfSectionTitle('Risk Analysis'),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Regulatory Violations
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    border: pw.Border.all(color: PdfColors.orange200),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Row(children: [
                      pw.Container(
                        width: 16, height: 16,
                        decoration: pw.BoxDecoration(color: PdfColors.orange700, borderRadius: pw.BorderRadius.circular(3)),
                        child: pw.Center(child: pw.Text('!', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text('Regulatory Violations',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                    ]),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      riskLines.isNotEmpty ? riskLines[0].trim() : 'No violations noted.',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ]),
                ),
              ),
              pw.SizedBox(width: 10),

              // Delivery Delays
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    border: pw.Border.all(color: PdfColors.red200),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Row(children: [
                      pw.Container(
                        width: 16, height: 16,
                        decoration: pw.BoxDecoration(color: PdfColors.red700, borderRadius: pw.BorderRadius.circular(3)),
                        child: pw.Center(child: pw.Text('!', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text('Delivery Delays',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                    ]),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      riskLines.length > 1 ? riskLines[1].trim() : 'Delivery performance within acceptable range.',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ]),
                ),
              ),
              pw.SizedBox(width: 10),

              // AI Recommendations
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.brown800,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('AI Recommendations',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.SizedBox(height: 8),
                    ...recLines.map((rec) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Container(
                          width: 10, height: 10,
                          margin: const pw.EdgeInsets.only(top: 1, right: 5),
                          decoration: pw.BoxDecoration(color: PdfColors.green400, borderRadius: pw.BorderRadius.circular(2)),
                          child: pw.Center(child: pw.Text('v', style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold))),
                        ),
                        pw.Expanded(child: pw.Text(rec.trim(),
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.white))),
                      ]),
                    )).toList(),
                  ]),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // ── FOOTER ────────────────────────────────────────────────
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.RichText(text: pw.TextSpan(children: [
                const pw.TextSpan(text: 'Generated by ', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                pw.TextSpan(text: 'Smart Supply Chain',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
              ])),
              pw.Text(
                '${_monthName(DateTime.now().month)} ${DateTime.now().day}, ${DateTime.now().year}  |  '
                '${DateTime.now().hour % 12 == 0 ? 12 : DateTime.now().hour % 12}:'
                '${DateTime.now().minute.toString().padLeft(2, '0')} '
                '${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: '${(vendorData['name'] ?? 'vendor').toString().replaceAll(' ', '_')}_report.pdf',
    );
  }

  String _monthName(int m) => const [
    '', 'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ][m];

  // ── Inline detail item (for the 3-col vendor details grid) ────────
  pw.Widget _detailItem(String label, String text) {
    return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Container(
        width: 6, height: 6,
        margin: const pw.EdgeInsets.only(top: 3, right: 6),
        decoration: const pw.BoxDecoration(color: PdfColors.brown600, shape: pw.BoxShape.circle),
      ),
      pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800))),
    ]);
  }

  // ════════════════════════════════════════════════════════════════
  //  FLUTTER UI  (unchanged)
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final score = (vendorData['aiScore'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3a2510),
        title: Text(vendorData['name'] ?? 'Vendor Details',
            style: const TextStyle(color: Color(0xFFe1cbb1), fontWeight: FontWeight.w600, fontSize: 16)),
        iconTheme: const IconThemeData(color: Color(0xFFe1cbb1)),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFe1cbb1)),
            tooltip: 'Download PDF',
            onPressed: () => _generatePDF(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _scoreBg(score),
                    border: Border.all(color: _scoreColor(score), width: 3),
                  ),
                  child: Center(
                    child: Text('${score.toInt()}%',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: _scoreColor(score))),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('AI Vendor Score', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _dark)),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Vendor Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _derby)),
                const SizedBox(height: 12),
                _DetailRow(icon: Icons.business_rounded,     label: 'Name',       value: vendorData['name']     ?? 'N/A'),
                _DetailRow(icon: Icons.category_outlined,    label: 'Category',   value: vendorData['category'] ?? 'N/A'),
                _DetailRow(icon: Icons.location_on_outlined, label: 'Location',   value: vendorData['location'] ?? 'N/A'),
                _DetailRow(icon: Icons.work_outline_rounded, label: 'Experience', value: '${vendorData['experience'] ?? 'N/A'} years'),
                _DetailRow(icon: Icons.factory_outlined,     label: 'Capacity',   value: vendorData['capacity'] ?? 'N/A'),
                _DetailRow(icon: Icons.phone_outlined,       label: 'Contact',    value: vendorData['contact']  ?? 'N/A'),
                _DetailRow(icon: Icons.info_outline_rounded, label: 'Status',     value: vendorData['status']   ?? 'Active'),
              ]),
            ),
            const SizedBox(height: 12),
            if ((vendorData['aiAnalysis'] ?? '').toString().isNotEmpty)
              Container(
                decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.auto_awesome_outlined, color: _derby, size: 18),
                    const SizedBox(width: 8),
                    const Text('AI Analysis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _dark)),
                  ]),
                  const SizedBox(height: 10),
                  Text(vendorData['aiAnalysis'], style: const TextStyle(fontSize: 13, color: _smoked, height: 1.5)),
                ]),
              ),
            const SizedBox(height: 14),
            _PrimaryButton(label: 'View AI Score',  icon: Icons.auto_awesome_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorScoreScreen(vendorId: vendorId)))),
            const SizedBox(height: 10),
            _PrimaryButton(label: 'View Checklist', icon: Icons.checklist_rounded,     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChecklistScreen(vendorId: vendorId)))),
            const SizedBox(height: 10),
            _OutlineButton(
              label: 'View on Map',
              icon: Icons.map_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => MapScreen(
                  vendorName: vendorData['name'] ?? 'Vendor',
                  location:   vendorData['location'] ?? 'Chennai, Tamil Nadu',
                  vendorLat:  _getLat(),
                  vendorLng:  _getLng(),
                ),
              )),
            ),
            const SizedBox(height: 10),
            _OutlineButton(label: 'Chat with AI',        icon: Icons.chat_outlined,           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(vendorId: vendorId, vendorName: vendorData['name'] ?? 'Vendor')))),
            const SizedBox(height: 10),
            _OutlineButton(label: 'Download PDF Report', icon: Icons.picture_as_pdf_outlined, onTap: () => _generatePDF(context)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Reusable UI widgets (unchanged) ──────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF7b5836), size: 18),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF4b3828), fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF422a14), fontSize: 13))),
      ]),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFFf5ede0), size: 18),
        label: Text(label, style: const TextStyle(color: Color(0xFFf5ede0), fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7b5836),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFF7b5836), size: 18),
        label: Text(label, style: const TextStyle(color: Color(0xFF7b5836), fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF7b5836)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}