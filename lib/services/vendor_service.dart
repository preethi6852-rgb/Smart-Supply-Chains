import 'package:cloud_firestore/cloud_firestore.dart';

class VendorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── CREATE VENDOR ───────────────────────────────────────────
  Future<String> addVendor({
    required String name,
    required String contactEmail,
    required String phone,
    required String address,
    required String city,
    required String state,
    required double latitude,
    required double longitude,
    required String category,      // e.g. "Raw Materials", "Electronics"
    required String meetLink,      // Google Meet URL for virtual visit
  }) async {
    final docRef = _db.collection('vendors').doc();

    await docRef.set({
      'id':            docRef.id,
      'name':          name,
      'contactEmail':  contactEmail,
      'phone':         phone,
      'address':       address,
      'city':          city,
      'state':         state,
      'latitude':      latitude,
      'longitude':     longitude,
      'category':      category,
      'meetLink':      meetLink,

      // AI Scoring fields (Step 2 will fill these)
      'aiScore':           0,
      'riskLevel':         'unknown',   // 'low' | 'medium' | 'high'
      'riskExplanation':   '',
      'lastScoredAt':      null,

      // Checklist fields
      'checklist': {
        'hasGSTCertificate':     false,
        'hasISOCertification':   false,
        'hasFactoryLicense':     false,
        'hasSafetyClearance':    false,
        'hasBankDetails':        false,
        'hasSignedContract':     false,
      },
      'checklistScore': 0,   // 0–100, auto-calculated

      // Performance tracking
      'totalOrders':       0,
      'onTimeDeliveries':  0,
      'lateDeliveries':    0,
      'deliveryScore':     0,   // 0–100

      // Status
      'status':      'active',   // 'active' | 'probation' | 'blacklisted'
      'isBlacklisted': false,

      // Timestamps
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // ─── READ ALL VENDORS ─────────────────────────────────────────
  Stream<QuerySnapshot> getAllVendors() {
    return _db
        .collection('vendors')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ─── READ SINGLE VENDOR ───────────────────────────────────────
  Future<DocumentSnapshot> getVendor(String vendorId) {
    return _db.collection('vendors').doc(vendorId).get();
  }

  // ─── UPDATE VENDOR ────────────────────────────────────────────
  Future<void> updateVendor(String vendorId, Map<String, dynamic> data) {
    return _db.collection('vendors').doc(vendorId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── UPDATE CHECKLIST ─────────────────────────────────────────
  Future<void> updateChecklist(
      String vendorId, String field, bool value) async {
    // Update the specific checklist field
    await _db.collection('vendors').doc(vendorId).update({
      'checklist.$field': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Recalculate checklist score
    final doc = await _db.collection('vendors').doc(vendorId).get();
    final checklist =
        Map<String, dynamic>.from(doc['checklist'] as Map);
    final total = checklist.length;
    final completed = checklist.values.where((v) => v == true).length;
    final score = ((completed / total) * 100).round();

    await _db.collection('vendors').doc(vendorId).update({
      'checklistScore': score,
    });
  }

  // ─── DELETE VENDOR ────────────────────────────────────────────
  Future<void> deleteVendor(String vendorId) {
    return _db.collection('vendors').doc(vendorId).delete();
  }
}