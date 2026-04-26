import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vendor_detail_screen.dart';

class VendorListScreen extends StatelessWidget {
  const VendorListScreen({super.key});

  static const Color _bg      = Color(0xFFe1cbb1);
  static const Color _cardBg  = Color(0xFFf5ede0);
  static const Color _derby   = Color(0xFF7b5836);
  static const Color _smoked  = Color(0xFF4b3828);
  static const Color _dark    = Color(0xFF422a14);
  static const Color _border  = Color(0x2E4b3828);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3a2510),
        title: const Text('Vendor List', style: TextStyle(color: Color(0xFFe1cbb1), fontWeight: FontWeight.w600, fontSize: 16)),
        iconTheme: const IconThemeData(color: Color(0xFFe1cbb1)),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7b5836)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 72, color: _smoked.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('No vendors yet!', style: TextStyle(fontSize: 17, color: _smoked)),
                  const Text('Add your first vendor', style: TextStyle(color: _smoked, fontSize: 13)),
                ],
              ),
            );
          }

          final vendors = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final data  = vendors[index].data() as Map<String, dynamic>;
              final score = (data['aiScore'] ?? 0).toDouble();

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VendorDetailScreen(vendorId: vendors[index].id, vendorData: data)),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFecddc8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.business_rounded, color: Color(0xFF7b5836), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['name'] ?? 'Unknown',   style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _dark)),
                            const SizedBox(height: 2),
                            Text(data['category'] ?? 'General', style: const TextStyle(color: _smoked, fontSize: 12)),
                            Text(data['location'] ?? '',         style: TextStyle(color: _smoked.withOpacity(0.7), fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _scoreBg(score),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${score.toInt()}%',
                              style: TextStyle(color: _scoreColor(score), fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('AI Score', style: TextStyle(color: _smoked, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}