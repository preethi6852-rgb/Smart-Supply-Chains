import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static const Color _bg     = Color(0xFFe1cbb1);
  static const Color _cardBg = Color(0xFFf5ede0);
  static const Color _derby  = Color(0xFF7b5836);
  static const Color _cape   = Color(0xFF976f47);
  static const Color _smoked = Color(0xFF4b3828);
  static const Color _dark   = Color(0xFF422a14);
  static const Color _border = Color(0x2E4b3828);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3a2510),
        title: const Text('Analytics', style: TextStyle(color: Color(0xFFe1cbb1), fontWeight: FontWeight.w600, fontSize: 16)),
        iconTheme: const IconThemeData(color: Color(0xFFe1cbb1)),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Vendor Stats ─────────────────────────────────────────
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('vendors').where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '').snapshots(),
              builder: (context, vendorSnapshot) {
                final vendors    = vendorSnapshot.data?.docs ?? [];
                final total      = vendors.length;
                int highScore    = 0;
                int lowScore     = 0;

                for (var v in vendors) {
                  final data  = v.data() as Map<String, dynamic>;
                  final score = (data['aiScore'] ?? 0).toDouble();
                  if (score >= 80) highScore++;
                  if (score < 60) lowScore++;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VENDOR OVERVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _smoked, letterSpacing: 0.6)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatCard(label: 'Total Vendors', value: '$total', icon: Icons.people_outline_rounded, iconColor: _derby),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatCard(label: 'High Performer', value: '$highScore', icon: Icons.thumb_up_outlined,     iconColor: const Color(0xFF2e5e22)),
                        const SizedBox(width: 10),
                        _StatCard(label: 'Low Performer',  value: '$lowScore',  icon: Icons.warning_amber_rounded, iconColor: const Color(0xFF7a1f1a)),
                      ],
                    ),

                    if (vendors.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('VENDOR COMPARISON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _smoked, letterSpacing: 0.6)),
                      const SizedBox(height: 4),
                      const Text('AI Score vs Delivery Score vs Checklist Score', style: TextStyle(fontSize: 12, color: _smoked)),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LegendDot(color: _derby, label: 'AI Score'),
                                const SizedBox(width: 16),
                                _LegendDot(color: const Color(0xFF2e5e22), label: 'Delivery'),
                                const SizedBox(width: 16),
                                _LegendDot(color: _cape, label: 'Checklist'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 220,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 100,
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (_) => const Color(0xFF3a2510),
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        final labels = ['AI Score', 'Delivery', 'Checklist'];
                                        return BarTooltipItem(
                                          '${labels[rodIndex]}\n${rod.toY.toInt()}%',
                                          const TextStyle(color: Color(0xFFe1cbb1), fontSize: 12),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 || index >= vendors.length) return const SizedBox();
                                          final data  = vendors[index].data() as Map<String, dynamic>;
                                          final name  = (data['name'] ?? 'V${index + 1}').toString();
                                          final short = name.length > 6 ? name.substring(0, 6) : name;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(short, style: const TextStyle(fontSize: 10, color: _smoked)),
                                          );
                                        },
                                        reservedSize: 30,
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 25,
                                        getTitlesWidget: (value, meta) =>
                                            Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: _smoked)),
                                        reservedSize: 28,
                                      ),
                                    ),
                                    topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    horizontalInterval: 25,
                                    getDrawingHorizontalLine: (_) => FlLine(color: _smoked.withOpacity(0.1), strokeWidth: 1),
                                    drawVerticalLine: false,
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: vendors.asMap().entries.map((entry) {
                                    final data = entry.value.data() as Map<String, dynamic>;
                                    return BarChartGroupData(
                                      x: entry.key,
                                      barRods: [
                                        BarChartRodData(toY: (data['aiScore']       ?? 0).toDouble(), color: _derby,                     width: 8, borderRadius: BorderRadius.circular(4)),
                                        BarChartRodData(toY: (data['deliveryScore'] ?? 0).toDouble(), color: const Color(0xFF2e5e22),    width: 8, borderRadius: BorderRadius.circular(4)),
                                        BarChartRodData(toY: (data['checklistScore']?? 0).toDouble(), color: _cape,                      width: 8, borderRadius: BorderRadius.circular(4)),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Order Stats ──────────────────────────────────────────
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '').snapshots(),
              builder: (context, orderSnapshot) {
                final orders = orderSnapshot.data?.docs ?? [];
                int delivered = 0, delayed = 0, inTransit = 0;
                for (var o in orders) {
                  final status = (o.data() as Map<String, dynamic>)['status'] ?? '';
                  if (status == 'Delivered')  delivered++;
                  if (status == 'Delayed')    delayed++;
                  if (status == 'In Transit') inTransit++;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ORDER ANALYTICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _smoked, letterSpacing: 0.6)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatCard(label: 'Total Orders', value: '${orders.length}', icon: Icons.shopping_cart_outlined,  iconColor: _derby),
                        const SizedBox(width: 10),
                        _StatCard(label: 'Delivered',    value: '$delivered',        icon: Icons.check_circle_outline,    iconColor: const Color(0xFF2e5e22)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatCard(label: 'In Transit', value: '$inTransit', icon: Icons.local_shipping_outlined, iconColor: _cape),
                        const SizedBox(width: 10),
                        _StatCard(label: 'Delayed',    value: '$delayed',   icon: Icons.warning_amber_rounded,   iconColor: const Color(0xFF7a1f1a)),
                      ],
                    ),
                    if (delayed > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFf0d5d0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFd4a099)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFF7a1f1a), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$delayed order(s) are delayed — contact vendors immediately.',
                                style: const TextStyle(color: Color(0xFF7a1f1a), fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ── AI Tips ──────────────────────────────────────────────
            const Text('AI RECOMMENDATIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _smoked, letterSpacing: 0.6)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _TipItem(tip: 'Vendors with score below 60% need immediate review',  icon: Icons.warning_amber_rounded,  color: const Color(0xFF7a4a0a)),
                  _TipItem(tip: 'Schedule virtual visits for unverified vendors',       icon: Icons.video_call_outlined,    color: _derby),
                  _TipItem(tip: 'Update qualification checklist every 6 months',        icon: Icons.checklist_rounded,      color: const Color(0xFF2e5e22)),
                  _TipItem(tip: 'Maintain at least 2 backup vendors per category',     icon: Icons.people_outline_rounded, color: _cape),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4b3828))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({required this.label, required this.value, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFf5ede0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x2E4b3828)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: iconColor)),
            Text(label, style: const TextStyle(color: Color(0xFF4b3828), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String tip;
  final IconData icon;
  final Color color;

  const _TipItem({required this.tip, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, color: Color(0xFF422a14)))),
        ],
      ),
    );
  }
}