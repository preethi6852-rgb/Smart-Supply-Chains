import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── ADD ORDER ────────────────────────────────────────────────
  Future<void> addOrder({
    required String vendorId,
    required String materialName,
    required int quantity,
    required String unit,           // "kg", "units", "tonnes"
    required DateTime expectedDate,
  }) async {
    final orderRef = _db
        .collection('vendors')
        .doc(vendorId)
        .collection('orders')
        .doc();

    await orderRef.set({
      'id':           orderRef.id,
      'vendorId':     vendorId,
      'materialName': materialName,
      'quantity':     quantity,
      'unit':         unit,
      'status':       'pending',   // pending|dispatched|delivered|delayed
      'expectedDate': Timestamp.fromDate(expectedDate),
      'deliveredDate': null,
      'isOnTime':     null,
      'createdAt':    FieldValue.serverTimestamp(),
    });
  }

  // ─── GET ALL ORDERS FOR VENDOR (real-time) ────────────────────
  Stream<QuerySnapshot> getOrdersForVendor(String vendorId) {
    return _db
        .collection('vendors')
        .doc(vendorId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ─── UPDATE ORDER STATUS ──────────────────────────────────────
  Future<void> updateOrderStatus({
    required String vendorId,
    required String orderId,
    required String newStatus,
    DateTime? deliveredDate,
  }) async {
    final data = <String, dynamic>{'status': newStatus};

    if (newStatus == 'delivered' && deliveredDate != null) {
      // Get order to check if delivery was on time
      final orderDoc = await _db
          .collection('vendors')
          .doc(vendorId)
          .collection('orders')
          .doc(orderId)
          .get();

      final expectedDate =
          (orderDoc['expectedDate'] as Timestamp).toDate();
      final isOnTime =
          deliveredDate.isBefore(expectedDate) ||
          deliveredDate.isAtSameMomentAs(expectedDate);

      data['deliveredDate'] = Timestamp.fromDate(deliveredDate);
      data['isOnTime'] = isOnTime;

      // Update vendor delivery score
      await _updateDeliveryScore(vendorId, isOnTime);
    }

    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('orders')
        .doc(orderId)
        .update(data);
  }

  // ─── AUTO UPDATE DELIVERY SCORE ───────────────────────────────
  Future<void> _updateDeliveryScore(
      String vendorId, bool isOnTime) async {
    final vendorRef = _db.collection('vendors').doc(vendorId);
    final vendor = await vendorRef.get();

    int total = vendor['totalOrders'] + 1;
    int onTime = vendor['onTimeDeliveries'] + (isOnTime ? 1 : 0);
    int late = vendor['lateDeliveries'] + (isOnTime ? 0 : 1);
    int score = ((onTime / total) * 100).round();

    await vendorRef.update({
      'totalOrders':      total,
      'onTimeDeliveries': onTime,
      'lateDeliveries':   late,
      'deliveryScore':    score,
      'updatedAt':        FieldValue.serverTimestamp(),
    });
  }
}