import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _vendorController   = TextEditingController();
  final _materialController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedStatus = 'Processing';
  bool _isAdding = false;

  static const Color _bg     = Color(0xFFe1cbb1);
  static const Color _cardBg = Color(0xFFf5ede0);
  static const Color _derby  = Color(0xFF7b5836);
  static const Color _smoked = Color(0xFF4b3828);
  static const Color _dark   = Color(0xFF422a14);
  static const Color _border = Color(0x2E4b3828);
  static const Color _inputBg= Color(0xFFecddc8);

  final List<String> _statuses = [
    'Processing', 'Dispatched', 'In Transit',
    'Out for Delivery', 'Delivered', 'Delayed',
  ];

  // ── Logic unchanged ───────────────────────────────────────────
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':       return const Color(0xFF2e5e22);
      case 'Delayed':         return const Color(0xFF7a1f1a);
      case 'In Transit':      return const Color(0xFF1a4a7a);
      case 'Out for Delivery':return const Color(0xFF7a4a0a);
      case 'Dispatched':      return const Color(0xFF4a1a6a);
      default:                return const Color(0xFF4b3828);
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'Delivered':       return const Color(0xFFd6e8d0);
      case 'Delayed':         return const Color(0xFFf0d5d0);
      case 'In Transit':      return const Color(0xFFdce8f5);
      case 'Out for Delivery':return const Color(0xFFf5e4c8);
      case 'Dispatched':      return const Color(0xFFe8d5f0);
      default:                return const Color(0xFFe0dbc4);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Delivered':        return Icons.check_circle_outline;
      case 'Delayed':          return Icons.warning_amber_rounded;
      case 'In Transit':       return Icons.local_shipping_outlined;
      case 'Out for Delivery': return Icons.delivery_dining_outlined;
      case 'Dispatched':       return Icons.inventory_2_outlined;
      default:                 return Icons.pending_outlined;
    }
  }

  Future<void> _addOrder() async {
    if (_vendorController.text.isEmpty || _materialController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill vendor and material!'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _isAdding = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      // ── Check vendor exists in this user's vendor list ──────
      final vendorQuery = await FirebaseFirestore.instance
          .collection('vendors')
          .where('uid', isEqualTo: user!.uid)
          .where('name', isEqualTo: _vendorController.text.trim())
          .limit(1)
          .get();

      if (vendorQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vendor not found! Please add the vendor first.'),
              backgroundColor: Color(0xFF7a1f1a),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isAdding = false);
        return;
      }
      // ────────────────────────────────────────────────────────

      await FirebaseFirestore.instance.collection('orders').add({
        'uid':       user!.uid,
        'orderId':   'ORD-${DateTime.now().millisecondsSinceEpoch}',
        'vendor':    _vendorController.text.trim(),
        'material':  _materialController.text.trim(),
        'quantity':  _quantityController.text.trim().isEmpty ? '1' : _quantityController.text.trim(),
        'status':    _selectedStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _vendorController.clear();
      _materialController.clear();
      _quantityController.clear();
      setState(() => _selectedStatus = 'Processing');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order added!'), backgroundColor: Color(0xFF2e5e22), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFF7a1f1a), behavior: SnackBarBehavior.floating),
      );
    } finally {
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3a2510),
        title: const Text('Order Tracking', style: TextStyle(color: Color(0xFFe1cbb1), fontWeight: FontWeight.w600, fontSize: 16)),
        iconTheme: const IconThemeData(color: Color(0xFFe1cbb1)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Add Order Card ─────────────────────────────────────
            Container(
              decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Order', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _derby)),
                  const SizedBox(height: 14),
                  _BrownField(controller: _vendorController,   label: 'Vendor Name',    icon: Icons.business_rounded),
                  const SizedBox(height: 10),
                  _BrownField(controller: _materialController, label: 'Material Name',   icon: Icons.inventory_2_outlined),
                  const SizedBox(height: 10),
                  _BrownField(controller: _quantityController, label: 'Quantity',         icon: Icons.numbers_rounded, keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    dropdownColor: _cardBg,
                    style: const TextStyle(color: _dark, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Status',
                      labelStyle: const TextStyle(color: _smoked),
                      prefixIcon: const Icon(Icons.timeline_outlined, color: _derby),
                      filled: true,
                      fillColor: _inputBg,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF976f47).withOpacity(0.3))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _derby, width: 2)),
                    ),
                    items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAdding ? null : _addOrder,
                      icon: _isAdding
                          ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFf5ede0)))
                          : const Icon(Icons.add_rounded, color: Color(0xFFf5ede0), size: 18),
                      label: Text(
                        _isAdding ? 'Adding...' : 'Add Order',
                        style: const TextStyle(color: Color(0xFFf5ede0), fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _derby,
                        disabledBackgroundColor: _derby.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text('LIVE ORDERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _smoked, letterSpacing: 0.6)),
            const SizedBox(height: 10),

            // ── Orders List ────────────────────────────────────────
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Color(0xFF7a1f1a))));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF7b5836)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 44, color: _smoked.withOpacity(0.3)),
                          const SizedBox(height: 10),
                          const Text('No orders yet!', style: TextStyle(color: _smoked, fontSize: 15)),
                          const Text('Add your first order above', style: TextStyle(color: _smoked, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final aTime = (a.data() as Map)['createdAt'];
                  final bTime = (b.data() as Map)['createdAt'];
                  if (aTime == null || bTime == null) return 0;
                  return (bTime as Timestamp).compareTo(aTime as Timestamp);
                });

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data   = docs[index].data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Processing';
                    final docId  = docs[index].id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  data['material'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _dark),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusBg(status),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getStatusIcon(status), size: 13, color: _getStatusColor(status)),
                                    const SizedBox(width: 4),
                                    Text(status, style: TextStyle(color: _getStatusColor(status), fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.business_rounded, size: 13, color: _smoked.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text('Vendor: ${data['vendor'] ?? 'Unknown'}', style: const TextStyle(color: _smoked, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.numbers_rounded, size: 13, color: _smoked.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text('Qty: ${data['quantity'] ?? 'N/A'}', style: const TextStyle(color: _smoked, fontSize: 12)),
                              const SizedBox(width: 14),
                              Icon(Icons.tag_rounded, size: 13, color: _smoked.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(data['orderId'] ?? '', style: const TextStyle(color: _smoked, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _statuses.contains(status) ? status : 'Processing',
                            dropdownColor: _cardBg,
                            style: const TextStyle(color: _dark, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Update status',
                              labelStyle: const TextStyle(color: _smoked, fontSize: 12),
                              prefixIcon: const Icon(Icons.update_rounded, size: 17, color: _derby),
                              filled: true,
                              fillColor: _inputBg,
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: const Color(0xFF976f47).withOpacity(0.25))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _derby)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) async {
                              await FirebaseFirestore.instance.collection('orders').doc(docId).update({
                                'status':    val,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Status updated to $val'), backgroundColor: const Color(0xFF2e5e22), behavior: SnackBarBehavior.floating),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared brown text field ──────────────────────────────────────────────────
class _BrownField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  const _BrownField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:   controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF422a14), fontSize: 14),
      decoration: InputDecoration(
        labelText:   label,
        labelStyle:  const TextStyle(color: Color(0xFF4b3828)),
        prefixIcon:  Icon(icon, color: const Color(0xFF7b5836), size: 20),
        filled:      true,
        fillColor:   const Color(0xFFecddc8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF976f47).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF7b5836), width: 2),
        ),
      ),
    );
  }
}