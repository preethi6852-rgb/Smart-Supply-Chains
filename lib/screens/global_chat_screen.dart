import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'dart:convert';

class GlobalChatScreen extends StatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController  = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading     = false;
  bool _vendorsLoaded = false;
  List<Map<String, dynamic>> _allVendors = [];

  static const Color _bg      = Color(0xFFe1cbb1);
  static const Color _cardBg  = Color(0xFFf5ede0);
  static const Color _derby   = Color(0xFF7b5836);
  static const Color _smoked  = Color(0xFF4b3828);
  static const Color _dark    = Color(0xFF422a14);
  static const Color _inputBg = Color(0xFFecddc8);

  final String _geminiApiKey = '';

  // ── All logic unchanged ───────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': 'Hi! I am your Smart Supply Chain Assistant!\n\n'
          'I know all your vendors and their data. You can ask me:\n'
          '• "Which vendor has the highest score?"\n'
          '• "Compare naren vs Sri Murugan Electronics"\n'
          '• "Who is high risk?"\n'
          '• "Which vendor should I order electronics from?"\n\n'
          'Loading vendor data...',
    });
    _loadAllVendors();
  }

  Future<void> _loadAllVendors() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .where('uid', isEqualTo: user?.uid ?? '')
          .get();
      setState(() {
        _allVendors = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _vendorsLoaded = true;
      });
      setState(() {
        _messages[0] = {
          'role': 'ai',
          'text': 'Hi! I am your Smart Supply Chain Assistant!\n\n'
              'I have loaded ${_allVendors.length} vendors. You can ask me:\n'
              '• "Which vendor has the highest score?"\n'
              '• "Compare naren vs Sri Murugan Electronics"\n'
              '• "Who is high risk?"\n'
              '• "Which vendor should I order from?"\n'
              '• "Summarize all vendors"',
        };
      });
    } catch (e) {
      setState(() {
        _vendorsLoaded = true;
        _messages[0] = {
          'role': 'ai',
          'text': 'Could not load vendor data. Please check your connection.',
        };
      });
    }
  }

  String _buildVendorContext() {
    if (_allVendors.isEmpty) return 'No vendors found in database.';
    final buffer = StringBuffer();
    buffer.writeln('Current vendor database has ${_allVendors.length} vendors:\n');
    for (final vendor in _allVendors) {
      final checklist  = vendor['checklist'] as Map<String, dynamic>? ?? {};
      final completed  = checklist.values.where((v) => v == true).length;
      final total      = checklist.length > 0 ? checklist.length : 20;
      buffer.writeln('---');
      buffer.writeln('Vendor: ${vendor['name'] ?? 'Unknown'}');
      buffer.writeln('Category: ${vendor['category'] ?? 'N/A'}');
      buffer.writeln('Location: ${vendor['city'] ?? vendor['location'] ?? 'N/A'}');
      buffer.writeln('AI Score: ${vendor['aiScore'] ?? 0}/100');
      buffer.writeln('Risk Level: ${vendor['riskLevel'] ?? 'unknown'}');
      buffer.writeln('Delivery Score: ${vendor['deliveryScore'] ?? 0}/100');
      buffer.writeln('Total Orders: ${vendor['totalOrders'] ?? 0}');
      buffer.writeln('On-time Deliveries: ${vendor['onTimeDeliveries'] ?? 0}');
      buffer.writeln('Late Deliveries: ${vendor['lateDeliveries'] ?? 0}');
      buffer.writeln('Checklist: $completed/$total completed');
      buffer.writeln('Checklist Score: ${vendor['checklistScore'] ?? 0}/100');
      buffer.writeln('Status: ${vendor['status'] ?? 'active'}');
      buffer.writeln('Blacklisted: ${vendor['isBlacklisted'] ?? false}');
    }
    return buffer.toString();
  }

  String _localAnswer(String question) {
    final q = question.toLowerCase();
    if (_allVendors.isEmpty) return 'No vendor data found. Please add vendors first.';
    final sorted = List<Map<String, dynamic>>.from(_allVendors)
      ..sort((a, b) => ((b['aiScore'] ?? 0) as num).compareTo((a['aiScore'] ?? 0) as num));

    if (q.contains('highest') || q.contains('best') || q.contains('top')) {
      final best = sorted.first;
      return '${best['name']} has the highest AI score of ${best['aiScore'] ?? 0}/100 with risk level: ${best['riskLevel'] ?? 'unknown'}. They have completed ${_getChecklistCount(best)} qualification documents.';
    }
    if (q.contains('high risk') || q.contains('risky') || q.contains('dangerous')) {
      final highRisk = _allVendors.where((v) => v['riskLevel'] == 'high').toList();
      if (highRisk.isEmpty) return 'No high risk vendors currently!';
      final names = highRisk.map((v) => v['name']).join(', ');
      return 'High risk vendors: $names\n\nThese vendors have incomplete qualification documents and should not receive large orders.';
    }
    if (q.contains('compare') || q.contains('vs') || q.contains('versus')) {
      if (sorted.length < 2) return 'Need at least 2 vendors to compare.';
      final a = sorted[0]; final b = sorted[1];
      return 'Comparison:\n\n${a['name']}:\n• Score: ${a['aiScore'] ?? 0}/100\n• Risk: ${a['riskLevel'] ?? 'unknown'}\n• Checklist: ${_getChecklistCount(a)}\n\n${b['name']}:\n• Score: ${b['aiScore'] ?? 0}/100\n• Risk: ${b['riskLevel'] ?? 'unknown'}\n• Checklist: ${_getChecklistCount(b)}\n\nRecommendation: ${a['name']} is safer based on AI score.';
    }
    if (q.contains('order') || q.contains('recommend') || q.contains('choose') || q.contains('which vendor') || q.contains('should i')) {
      final best = sorted.first; final worst = sorted.last;
      return 'Recommendation:\n\nBest choice: ${best['name']} (Score: ${best['aiScore'] ?? 0}/100)\nAvoid: ${worst['name']} (Score: ${worst['aiScore'] ?? 0}/100)\n\n${best['name']} has better compliance and lower risk for your orders.';
    }
    if (q.contains('summar') || q.contains('all vendor') || q.contains('list')) {
      final buffer = StringBuffer('All Vendors Summary:\n\n');
      for (final v in sorted) {
        final risk = v['riskLevel'] ?? 'unknown';
        buffer.writeln('${v['name']} — Score: ${v['aiScore'] ?? 0}/100 ($risk risk)');
      }
      return buffer.toString();
    }
    return 'I can answer questions like:\n• "Which vendor has the highest score?"\n• "Who is high risk?"\n• "Compare vendors"\n• "Which vendor should I order from?"\n• "Summarize all vendors"';
  }

  String _getChecklistCount(Map<String, dynamic> vendor) {
    final checklist = vendor['checklist'] as Map<String, dynamic>? ?? {};
    final completed = checklist.values.where((v) => v == true).length;
    final total     = checklist.length > 0 ? checklist.length : 20;
    return '$completed/$total docs';
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final vendorContext = _buildVendorContext();
      final prompt =
          'You are a Smart Supply Chain AI Assistant for a manufacturing company in India. '
          'You have access to the following vendor database:\n\n'
          '$vendorContext\n\n'
          'Answer the user question clearly in 3-4 sentences. '
          'Use emojis to make it readable. '
          'Give specific vendor names and scores in your answer.\n\n'
          'User question: $text';

      final requestBody = jsonEncode({
        'contents': [{'parts': [{'text': prompt}]}],
        'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 400},
      });

      final xhr = html.HttpRequest();
      xhr.open('POST', 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey');
      xhr.setRequestHeader('Content-Type', 'application/json');
      bool responded = false;

      xhr.onLoad.listen((event) {
        if (responded) return;
        responded = true;
        if (xhr.status == 200) {
          try {
            final data  = jsonDecode(xhr.responseText!);
            final reply = data['candidates'][0]['content']['parts'][0]['text'] as String;
            if (mounted) {
              setState(() { _messages.add({'role': 'ai', 'text': reply.trim()}); _isLoading = false; });
              _scrollToBottom();
            }
          } catch (e) { _showLocalAnswer(text); }
        } else { _showLocalAnswer(text); }
      });

      xhr.onError.listen((event) { if (responded) return; responded = true; _showLocalAnswer(text); });

      Future.delayed(const Duration(seconds: 8), () {
        if (responded) return;
        responded = true;
        _showLocalAnswer(text);
      });

      xhr.send(requestBody);
    } catch (e) { _showLocalAnswer(text); }
  }

  void _showLocalAnswer(String question) {
    if (!mounted) return;
    setState(() { _messages.add({'role': 'ai', 'text': _localAnswer(question)}); _isLoading = false; });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3a2510),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supply Chain AI Assistant', style: TextStyle(color: Color(0xFFe1cbb1), fontWeight: FontWeight.w600, fontSize: 15)),
            Text('Knows all your vendors',    style: TextStyle(color: Color(0x99e1cbb1), fontSize: 11)),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFFe1cbb1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFe1cbb1)),
            onPressed: _loadAllVendors,
            tooltip: 'Refresh vendor data',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Vendor status banner ──────────────────────────────
          Container(
            width: double.infinity,
            color: _vendorsLoaded ? const Color(0xFFd6e8d0) : const Color(0xFFf5e4c8),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  _vendorsLoaded ? Icons.check_circle_outline : Icons.hourglass_empty_rounded,
                  size: 14,
                  color: _vendorsLoaded ? const Color(0xFF2e5e22) : const Color(0xFF7a4a0a),
                ),
                const SizedBox(width: 6),
                Text(
                  _vendorsLoaded ? '${_allVendors.length} vendors loaded — AI ready!' : 'Loading vendor data...',
                  style: TextStyle(fontSize: 12, color: _vendorsLoaded ? const Color(0xFF2e5e22) : const Color(0xFF7a4a0a), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // ── Quick chips ───────────────────────────────────────
          if (_vendorsLoaded)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _QuickChip(label: 'Best vendor?',           onTap: () { _messageController.text = 'Best vendor?'; _sendMessage(); }),
                  _QuickChip(label: 'Who is high risk?',      onTap: () { _messageController.text = 'Who is high risk?'; _sendMessage(); }),
                  _QuickChip(label: 'Compare vendors',        onTap: () { _messageController.text = 'Compare vendors'; _sendMessage(); }),
                  _QuickChip(label: 'Summarize all',          onTap: () { _messageController.text = 'Summarize all'; _sendMessage(); }),
                  _QuickChip(label: 'Who should I order from?', onTap: () { _messageController.text = 'Who should I order from?'; _sendMessage(); }),
                ],
              ),
            ),

          // ── Messages ──────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller:  _scrollController,
              padding:     const EdgeInsets.all(14),
              itemCount:   _messages.length,
              itemBuilder: (context, index) {
                final msg    = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF7b5836) : _cardBg,
                      borderRadius: BorderRadius.only(
                        topLeft:     const Radius.circular(16),
                        topRight:    const Radius.circular(16),
                        bottomLeft:  Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser ? null : Border.all(color: const Color(0x2E4b3828)),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color:  isUser ? const Color(0xFFf5ede0) : _dark,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Typing indicator ─────────────────────────────────
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _derby)),
                  const SizedBox(width: 8),
                  const Text('AI is thinking...', style: TextStyle(color: _smoked, fontSize: 12)),
                ],
              ),
            ),

          // ── Input bar ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border(top: BorderSide(color: const Color(0x2E4b3828))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: _dark, fontSize: 14),
                    decoration: InputDecoration(
                      hintText:  'Ask about your vendors...',
                      hintStyle: const TextStyle(color: _smoked, fontSize: 13),
                      filled:    true,
                      fillColor: const Color(0xFFecddc8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:   BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _isLoading ? _derby.withOpacity(0.4) : _derby,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Color(0xFFf5ede0), size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFecddc8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF976f47).withOpacity(0.4)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF7b5836), fontWeight: FontWeight.w500)),
      ),
    );
  }
}
