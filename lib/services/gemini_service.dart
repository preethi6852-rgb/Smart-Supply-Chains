import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyAQNUeIRxGYzX9er21r0ardtRrkCC5awE8';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> scoreVendor(String vendorId) async {
    final doc = await _db.collection('vendors').doc(vendorId).get();
    final data = doc.data() ?? {};

    // ✅ Calculate score locally first
    final localResult = _calculateLocalScore(data);

    // Try Gemini for explanation only — if fails, use local explanation
    try {
      final geminiResult = await _callGemini(data)
          .timeout(const Duration(seconds: 8));
      return {
        'score': geminiResult['score'] ?? localResult['score'],
        'riskLevel': geminiResult['riskLevel'] ?? localResult['riskLevel'],
        'explanation': geminiResult['explanation'] ?? localResult['explanation'],
      };
    } catch (e) {
      // Gemini failed — return local calculation (always works!)
      return localResult;
    }
  }

  // ✅ FIXED LOCAL SCORE CALCULATION
  Map<String, dynamic> _calculateLocalScore(Map<String, dynamic> vendor) {
    final checklist = vendor['checklist'] as Map<String, dynamic>? ?? {};
    final completedDocs = checklist.values.where((v) => v == true).length;
    final totalDocs = checklist.length > 0 ? checklist.length : 20;
    final checklistPercent = (completedDocs / totalDocs) * 100;

    final deliveryScore = (vendor['deliveryScore'] ?? 0) as num;
    final totalOrders = (vendor['totalOrders'] ?? 0) as num;
    final isBlacklisted = vendor['isBlacklisted'] ?? false;
    final status = vendor['status'] ?? 'active';

    double score = 0;

    if (totalOrders == 0) {
      // New vendor — judge only by checklist
      score = checklistPercent * 0.9;  // 90% weight on checklist
      score += 5;                       // 5 point base bonus for being active
    } else {
      // Existing vendor — checklist + delivery both matter
      score += checklistPercent * 0.6;  // 60% checklist
      score += deliveryScore * 0.4;     // 40% delivery
    }

    if (isBlacklisted) score = score * 0.3;
    if (status == 'probation') score = score * 0.7;

    final finalScore = score.clamp(0, 100).toInt();

    String riskLevel;
    String explanation;

    if (finalScore >= 70) {
      riskLevel = 'low';
      explanation =
          'This vendor has completed ${completedDocs} out of ${totalDocs} '
          'qualification documents (${checklistPercent.toInt()}%) — '
          'demonstrating strong compliance. '
          '${totalOrders > 0 ? 'Delivery score of ${deliveryScore}/100 confirms reliability.' : 'No orders placed yet, but high document compliance makes this a low-risk supplier.'}';
    } else if (finalScore >= 40) {
      riskLevel = 'medium';
      explanation =
          'This vendor has completed ${completedDocs} out of ${totalDocs} '
          'qualification documents (${checklistPercent.toInt()}%). '
          'Some compliance gaps remain. Regular monitoring is recommended '
          'before placing large orders.';
    } else {
      riskLevel = 'high';
      explanation =
          'This vendor has only completed ${completedDocs} out of ${totalDocs} '
          'qualification documents (${checklistPercent.toInt()}%). '
          'Critical compliance documents are missing. Do not place orders '
          'until qualification is improved.';
    }

    return {
      'score': finalScore,
      'riskLevel': riskLevel,
      'explanation': explanation,
    };
  }

  Future<Map<String, dynamic>> _callGemini(
      Map<String, dynamic> vendor) async {
    final prompt = _buildPrompt(vendor);
    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 300,
      }
    });

    final completer = Completer<Map<String, dynamic>>();
    final xhr = html.HttpRequest();
    xhr.open('POST', _endpoint);
    xhr.setRequestHeader('Content-Type', 'application/json');

    xhr.onLoad.listen((event) {
      if (xhr.status == 200) {
        try {
          final json = jsonDecode(xhr.responseText!);
          final text =
              json['candidates'][0]['content']['parts'][0]['text'] as String;
          completer.complete(_parseGeminiResponse(text));
        } catch (e) {
          completer.completeError('Parse error');
        }
      } else {
        completer.completeError('API Error ${xhr.status}');
      }
    });

    xhr.onError.listen((event) {
      completer.completeError('Network error');
    });

    xhr.send(requestBody);
    return completer.future;
  }

  Future<void> scoreAndSaveVendor(String vendorId) async {
    final result = await scoreVendor(vendorId);
    await _db.collection('vendors').doc(vendorId).update({
      'aiScore': result['score'],
      'riskLevel': result['riskLevel'],
      'riskExplanation': result['explanation'],
      'lastScoredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _buildPrompt(Map<String, dynamic> vendor) {
    final checklist = vendor['checklist'] as Map<String, dynamic>? ?? {};
    final completedDocs = checklist.values.where((v) => v == true).length;
    final totalDocs = checklist.length;

    return 'You are a supply chain risk analyst. Evaluate this vendor and respond ONLY in this exact JSON format:\n'
        '{\n'
        '  "score": <number 0-100>,\n'
        '  "riskLevel": "<low|medium|high>",\n'
        '  "explanation": "<2-3 sentences explaining the score>"\n'
        '}\n\n'
        'Vendor: ${vendor['name']}, Category: ${vendor['category']}, '
        'Docs: $completedDocs/$totalDocs, '
        'Delivery: ${vendor['deliveryScore'] ?? 0}/100, '
        'Orders: ${vendor['totalOrders'] ?? 0}, '
        'Status: ${vendor['status'] ?? 'active'}\n\n'
        'Respond ONLY with JSON.';
  }

  Map<String, dynamic> _parseGeminiResponse(String text) {
    try {
      final cleaned =
          text.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(cleaned);
      return {
        'score': (parsed['score'] as num).toInt().clamp(0, 100),
        'riskLevel': parsed['riskLevel'] ?? 'medium',
        'explanation': parsed['explanation'] ?? 'No explanation provided.',
      };
    } catch (e) {
      return {
        'score': 50,
        'riskLevel': 'medium',
        'explanation': 'Could not parse response.',
      };
    }
  }
}