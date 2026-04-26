import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'vendor_list_screen.dart';
import 'add_vendor_screen.dart';
import 'tracking_screen.dart';
import 'analytics_screen.dart';
import 'global_chat_screen.dart';
import 'vendor_score_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
// Grain Brown   #e1cbb1  → page background
// Cape Palliser #976f47  → accents, muted
// Brown Derby   #7b5836  → primary buttons, active
// Dark Brown    #422a14  → primary text
// Smoked Brown  #4b3828  → secondary text

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const _bg      = Color(0xFFe1cbb1);
  static const _card    = Color(0xFFf5ede0);
  static const _sidebar = Color(0xFF2b1a0b);
  static const _cape    = Color(0xFF976f47);
  static const _derby   = Color(0xFF7b5836);
  static const _smoked  = Color(0xFF4b3828);
  static const _dark    = Color(0xFF422a14);
  static const _accent  = Color(0xFFecddc8);
  static const _border  = Color(0x254b3828);

  // ── Sidebar nav — 5 unique screens only ──────────────────────────────────
  static const _navItems = [
    (icon: Icons.grid_view_rounded,       label: 'Dashboard'),
    (icon: Icons.people_outline_rounded,  label: 'Vendors'),
    (icon: Icons.local_shipping_outlined, label: 'Tracking'),
    (icon: Icons.bar_chart_rounded,       label: 'Analytics'),
    (icon: Icons.smart_toy_outlined,      label: 'AI Assistant'),
  ];

  void _onNavTap(BuildContext context, int i) {
    setState(() => _selectedIndex = i);
    if (i == 0) return;
    final routes = [
      null,
      const VendorListScreen(),
      const TrackingScreen(),
      const AnalyticsScreen(),
      const GlobalChatScreen(),
    ];
    Navigator.push(context, MaterialPageRoute(builder: (_) => routes[i]!));
  }

  @override
  Widget build(BuildContext context) {
    final user   = FirebaseAuth.instance.currentUser;
    final uid    = user?.uid ?? '';
    final isWide = MediaQuery.of(context).size.width > 750;

    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [

          // ══════════════════════════════════════════════
          //  SIDEBAR  — navigation only, no feature cards
          // ══════════════════════════════════════════════
          if (isWide)
            Container(
              width: 215,
              color: _sidebar,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Brand
                  Container(
                    height: 68,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: _derby, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.local_shipping_rounded, size: 20, color: Color(0xFFe1cbb1)),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Smart Supply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFe1cbb1))),
                            Text('Vendor Management', style: TextStyle(fontSize: 10, color: Color(0x70e1cbb1))),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _label('MENU'),
                  const SizedBox(height: 8),

                  // Nav items
                  ..._navItems.asMap().entries.map((e) => _NavTile(
                    icon: e.value.icon,
                    label: e.value.label,
                    selected: _selectedIndex == e.key,
                    onTap: () => _onNavTap(context, e.key),
                  )),

                  const SizedBox(height: 24),
                  _label('EXTERNAL'),
                  const SizedBox(height: 8),

                  // Virtual Visit — only here, not repeated in main content
                  _NavTile(
                    icon: Icons.video_call_outlined,
                    label: 'Virtual Visit',
                    selected: false,
                    onTap: () => html.window.open('https://meet.google.com/new', '_blank'),
                    isExternal: true,
                  ),

                  const Spacer(),

                  // User row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06)))),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: _derby,
                          child: Text((user?.email ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFe1cbb1))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.displayName ?? user?.email?.split('@').first ?? 'User',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFe1cbb1)),
                                  overflow: TextOverflow.ellipsis),
                              Text(user?.email ?? '', style: const TextStyle(fontSize: 10, color: Color(0x70e1cbb1)), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => FirebaseAuth.instance.signOut(),
                          child: Icon(Icons.logout_rounded, size: 17, color: Colors.white.withOpacity(0.3)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ══════════════════════════════════════════════
          //  MAIN CONTENT
          // ══════════════════════════════════════════════
          Expanded(
            child: Column(
              children: [

                // ── Topbar ──────────────────────────────
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: _bg,
                    border: Border(bottom: BorderSide(color: _border)),
                  ),
                  child: Row(
                    children: [
                      if (!isWide) ...[
                        const Icon(Icons.local_shipping_rounded, color: _derby, size: 22),
                        const SizedBox(width: 8),
                        const Text('Smart Supply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                        const Spacer(),
                      ] else ...[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Good ${_greeting()}, ${user?.displayName ?? user?.email?.split('@').first ?? 'there'}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _dark)),
                            Text(_formattedDate(), style: const TextStyle(fontSize: 11, color: _smoked)),
                          ],
                        ),
                        const Spacer(),
                      ],
                      // Add vendor CTA
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVendorScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(color: _derby, borderRadius: BorderRadius.circular(9)),
                          child: const Row(
                            children: [
                              Icon(Icons.add, size: 16, color: Color(0xFFf5ede0)),
                              SizedBox(width: 6),
                              Text('Add vendor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFf5ede0))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: _cape.withOpacity(0.22),
                        child: Text((user?.email ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _derby)),
                      ),
                    ],
                  ),
                ),

                // ── Body ────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Row 1: 6 stat cards ─────────
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('vendors')
                              .where('uid', isEqualTo: uid)
                              .snapshots(),
                          builder: (ctx, vs) {
                            int total = 0, low = 0, high = 0;
                            if (vs.hasData) {
                              final d = vs.data!.docs;
                              total = d.length;
                              low   = d.where((x) => (x.data() as Map)['riskLevel'] == 'low').length;
                              high  = d.where((x) => (x.data() as Map)['riskLevel'] == 'high').length;
                            }
                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('orders')
                                  .where('uid', isEqualTo: uid)
                                  .snapshots(),
                              builder: (ctx2, os) {
                                int orders = 0, done = 0, late = 0;
                                if (os.hasData) {
                                  final d = os.data!.docs;
                                  orders = d.length;
                                  done   = d.where((x) => (x.data() as Map)['status'] == 'Delivered').length;
                                  late   = d.where((x) => (x.data() as Map)['status'] == 'Delayed').length;
                                }
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _KpiCard(label: 'Total Vendors', value: '$total', icon: Icons.people_outline_rounded,  iconBg: _derby,                    sub: 'registered suppliers'),
                                    _KpiCard(label: 'Low Risk',      value: '$low',   icon: Icons.verified_outlined,        iconBg: const Color(0xFF3a7a2a),   sub: 'safe to order'),
                                    _KpiCard(label: 'High Risk',     value: '$high',  icon: Icons.warning_amber_rounded,    iconBg: const Color(0xFF9a2a20),   sub: 'needs attention'),
                                    _KpiCard(label: 'Total Orders',  value: '$orders',icon: Icons.inventory_2_outlined,     iconBg: _cape,                     sub: 'all time'),
                                    _KpiCard(label: 'Delivered',     value: '$done',  icon: Icons.check_circle_outline,     iconBg: const Color(0xFF3a7a2a),   sub: 'on time'),
                                    _KpiCard(label: 'Delayed',       value: '$late',  icon: Icons.access_time_rounded,      iconBg: const Color(0xFF9a2a20),   sub: 'overdue'),
                                  ],
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 28),

                        // ── Row 2: AI banner + mini vendor list side by side ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // AI banner (left, 40%)
                            Expanded(
                              flex: 4,
                              child: GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalChatScreen())),
                                child: Container(
                                  height: 160,
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: _derby,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                        child: const Icon(Icons.smart_toy_outlined, color: Color(0xFFe1cbb1), size: 22),
                                      ),
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('AI Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFf5ede0))),
                                          SizedBox(height: 4),
                                          Text('Analyse vendors, flag risks\nand suggest actions →', style: TextStyle(fontSize: 12, color: Color(0xCCf5ede0), height: 1.4)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 14),

                            // Top vendors (right, 60%)
                            Expanded(
                              flex: 6,
                              child: Container(
                                height: 160,
                                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Top Vendors', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
                                          GestureDetector(
                                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorListScreen())),
                                            child: const Text('See all ›', style: TextStyle(fontSize: 11, color: _cape)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('vendors')
                                            .where('uid', isEqualTo: uid)
                                            .orderBy('aiScore', descending: true)
                                            .limit(3)
                                            .snapshots(),
                                        builder: (ctx, snap) {
                                          if (!snap.hasData || snap.data!.docs.isEmpty) {
                                            return const Center(child: Text('No vendors yet', style: TextStyle(color: _smoked, fontSize: 12)));
                                          }
                                          return ListView(
                                            padding: EdgeInsets.zero,
                                            children: snap.data!.docs.map((doc) {
                                              final d     = doc.data() as Map<String, dynamic>;
                                              final score = (d['aiScore'] ?? 0).toDouble();
                                              return _MiniVendorTile(
                                                name: d['name'] ?? 'Unknown',
                                                category: d['category'] ?? '',
                                                score: score,
                                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorScoreScreen(vendorId: doc.id))),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ── Row 3: Recent orders + Recent vendors ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Recent orders
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(title: 'Recent Orders', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingScreen()))),
                                  const SizedBox(height: 10),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('orders')
                                        .where('uid', isEqualTo: uid)
                                        .snapshots(),
                                    builder: (ctx, snap) {
                                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                                        return _Empty('No orders yet');
                                      }
                                      final docs = snap.data!.docs.take(5).toList();
                                      return Container(
                                        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                                        child: Column(
                                          children: docs.asMap().entries.map((e) {
                                            final d      = e.value.data() as Map<String, dynamic>;
                                            final isLast = e.key == docs.length - 1;
                                            return _OrderTile(data: d, isLast: isLast);
                                          }).toList(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 18),

                            // Recent vendors
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(title: 'Recent Vendors', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorListScreen()))),
                                  const SizedBox(height: 10),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('vendors')
                                        .where('uid', isEqualTo: uid)
                                        .orderBy('createdAt', descending: true)
                                        .limit(5)
                                        .snapshots(),
                                    builder: (ctx, snap) {
                                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                                        return _Empty('No vendors yet');
                                      }
                                      final docs = snap.data!.docs;
                                      return Container(
                                        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                                        child: Column(
                                          children: docs.asMap().entries.map((e) {
                                            final d     = e.value.data() as Map<String, dynamic>;
                                            final score = (d['aiScore'] ?? 0).toDouble();
                                            final isLast = e.key == docs.length - 1;
                                            return _VendorTile(
                                              name: d['name'] ?? 'Unknown',
                                              category: d['category'] ?? '',
                                              location: d['location'] ?? '',
                                              score: score,
                                              isLast: isLast,
                                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorScoreScreen(vendorId: e.value.id))),
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Mobile bottom nav
      bottomNavigationBar: isWide ? null : Container(
        color: _sidebar,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => _onNavTap(context, i),
          selectedItemColor:    const Color(0xFFe1cbb1),
          unselectedItemColor:  const Color(0x55e1cbb1),
          backgroundColor:      Colors.transparent,
          elevation:            0,
          type:                 BottomNavigationBarType.fixed,
          selectedLabelStyle:   const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded,      size: 22), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded,  size: 22), label: 'Vendors'),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined, size: 22), label: 'Tracking'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded,       size: 22), label: 'Analytics'),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  String _formattedDate() {
    final now = DateTime.now();
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const d = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${d[now.weekday - 1]}, ${now.day} ${m[now.month - 1]} ${now.year}';
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Text(t, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.25), letterSpacing: 1.4)),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isExternal;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.label, required this.selected, required this.onTap, this.isExternal = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7b5836).withOpacity(0.30) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? const Color(0xFFe1cbb1) : const Color(0x65e1cbb1)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? const Color(0xFFe1cbb1) : const Color(0x65e1cbb1)))),
            if (isExternal) Icon(Icons.open_in_new_rounded, size: 12, color: const Color(0x50e1cbb1)),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color iconBg;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.iconBg, required this.sub});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 215 - 56 - 60) / 3;
    return Container(
      width: w,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFf5ede0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x254b3828)),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 24, color: const Color(0xFFf5ede0)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF422a14))),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4b3828))),
              Text(sub,   style: const TextStyle(fontSize: 10, color: Color(0xFF976f47))),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniVendorTile extends StatelessWidget {
  final String name, category;
  final double score;
  final VoidCallback onTap;
  const _MiniVendorTile({required this.name, required this.category, required this.score, required this.onTap});

  Color get _sc => score >= 80 ? const Color(0xFF2e5e22) : score >= 60 ? const Color(0xFF7a4a0a) : const Color(0xFF7a1f1a);
  Color get _bg => score >= 80 ? const Color(0xFFd6e8d0) : score >= 60 ? const Color(0xFFf5e4c8) : const Color(0xFFf0d5d0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            Container(width: 30, height: 30, decoration: BoxDecoration(color: const Color(0xFFecddc8), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.business_rounded, size: 15, color: Color(0xFF7b5836))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF422a14)), overflow: TextOverflow.ellipsis),
              Text(category, style: const TextStyle(fontSize: 10, color: Color(0xFF4b3828))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
              child: Text('${score.toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _sc)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF422a14))),
      GestureDetector(onTap: onTap, child: const Text('View all ›', style: TextStyle(fontSize: 12, color: Color(0xFF976f47)))),
    ],
  );
}

class _VendorTile extends StatelessWidget {
  final String name, category, location;
  final double score;
  final bool isLast;
  final VoidCallback onTap;
  const _VendorTile({required this.name, required this.category, required this.location, required this.score, required this.isLast, required this.onTap});

  Color get _sc => score >= 80 ? const Color(0xFF2e5e22) : score >= 60 ? const Color(0xFF7a4a0a) : const Color(0xFF7a1f1a);
  Color get _bg => score >= 80 ? const Color(0xFFd6e8d0) : score >= 60 ? const Color(0xFFf5e4c8) : const Color(0xFFf0d5d0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: const Color(0x254b3828)))),
        child: Row(
          children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFecddc8), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.business_rounded, size: 17, color: Color(0xFF7b5836))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF422a14))),
              Text('$category · $location', style: const TextStyle(fontSize: 11, color: Color(0xFF4b3828))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
                child: Text('${score.toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _sc)),
              ),
              const SizedBox(height: 2),
              const Text('AI Score', style: TextStyle(fontSize: 10, color: Color(0xFF4b3828))),
            ]),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLast;
  const _OrderTile({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Processing';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: const Color(0x254b3828)))),
      child: Row(
        children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFecddc8), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.inventory_2_outlined, size: 17, color: Color(0xFF7b5836))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['material'] ?? 'Unknown', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF422a14))),
            Text('${data['vendor'] ?? ''}  ·  Qty: ${data['quantity'] ?? 'N/A'}', style: const TextStyle(fontSize: 11, color: Color(0xFF4b3828))),
          ])),
          _Pill(status: status),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String status;
  const _Pill({required this.status});

  Color get _bg => switch (status) {
    'Delivered'        => const Color(0xFFd6e8d0),
    'Delayed'          => const Color(0xFFf0d5d0),
    'In Transit'       => const Color(0xFFd0e4f5),
    'Out for Delivery' => const Color(0xFFf5e4c8),
    _                  => const Color(0xFFddd0bb),
  };
  Color get _fg => switch (status) {
    'Delivered'        => const Color(0xFF2e5e22),
    'Delayed'          => const Color(0xFF7a1f1a),
    'In Transit'       => const Color(0xFF1a3a6a),
    'Out for Delivery' => const Color(0xFF7a4a0a),
    _                  => const Color(0xFF4b3828),
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
    child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _fg)),
  );
}

class _Empty extends StatelessWidget {
  final String msg;
  const _Empty(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: const Color(0xFFf5ede0), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x254b3828))),
    child: Center(child: Text(msg, style: const TextStyle(color: Color(0xFF4b3828), fontSize: 13))),
  );
}