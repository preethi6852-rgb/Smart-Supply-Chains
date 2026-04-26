import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const ChatScreen({super.key, required this.vendorId, required this.vendorName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _vendorLoaded = false;
  Map<String, dynamic> _vendorData = {};

  static const _gold = Color(0xFFD4AF37);
  static const _darkBg = Color(0xFF121212);
  static const _cardBg = Color(0xFF1E1E1E);
  static const _inputBg = Color(0xFF2A2A2A);

  final String _geminiApiKey = '';

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': '👋 Hi! I am your AI assistant for ${widget.vendorName}!\n\n'
          'You can ask me:\n'
          '• "What is this vendor\'s score?"\n'
          '• "Is this vendor risky?"\n'
          '• "What documents are missing?"\n'
          '• "Should I place an order?"',
    });
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('vendors').doc(widget.vendorId).get();
      setState(() {
        _vendorData = doc.exists ? doc.data()! : {'name': widget.vendorName};
        _vendorLoaded = true;
      });
    } catch (e) {
      setState(() {
        _vendorData = {'name': widget.vendorName};
        _vendorLoaded = true;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _localVendorAnswer(String question) {
    if (!mounted) return;
    final q = question.toLowerCase();
    final name = _vendorData['name'] ?? widget.vendorName;
    final score = _vendorData['aiScore'] ?? 0;
    final risk = _vendorData['riskLevel'] ?? 'unknown';
    final delivery = _vendorData['deliveryScore'] ?? 0;
    final checklist = _vendorData['checklist'] as Map<String, dynamic>? ?? {};
    final completed = checklist.values.where((v) => v == true).length;
    final total = checklist.length > 0 ? checklist.length : 20;
    final totalOrders = _vendorData['totalOrders'] ?? 0;
    final onTime = _vendorData['onTimeDeliveries'] ?? 0;
    final late = _vendorData['lateDeliveries'] ?? 0;

    String answer;

    if (q.contains('score') || q.contains('rating') || q.contains('points')) {
      answer = '📊 $name has an AI score of $score/100 with $risk risk level.\n\n'
          'Based on:\n• Checklist: $completed/$total docs\n• Delivery: $delivery/100\n• Orders: $totalOrders\n\n'
          '${score >= 70 ? '✅ Reliable vendor.' : score >= 40 ? '⚠️ Needs monitoring.' : '❌ Low score — improve compliance.'}';
    } else if (q.contains('risk')) {
      answer = '⚠️ $name is rated as $risk risk.\n\n'
          '${risk == 'high' ? '❌ Not recommended for large orders.' : risk == 'low' ? '✅ Safe to place orders.' : '🟡 Suitable for small orders only.'}\n\nChecklist: $completed/$total docs.';
    } else if (q.contains('checklist') || q.contains('document') || q.contains('missing')) {
      final missing = total - completed;
      answer = '📋 $name checklist:\n\n✅ Completed: $completed/$total\n❌ Missing: $missing\n\n'
          '${missing == 0 ? 'All docs complete! ✅' : missing <= 5 ? 'Almost done — complete $missing more.' : '$missing critical docs pending.'}';
    } else if (q.contains('deliver')) {
      answer = '🚚 $name delivery:\n\n• Score: $delivery/100\n• Total: $totalOrders\n• On-time: $onTime\n• Late: $late\n\n'
          '${delivery >= 70 ? '✅ Good track record.' : delivery >= 40 ? '⚠️ Average.' : '❌ Poor history.'}';
    } else if (q.contains('recommend') || q.contains('safe') || q.contains('order') || q.contains('should')) {
      if (score >= 70) {
        answer = '✅ $name is recommended!\n\nScore: $score/100 ($risk risk)\nDelivery: $delivery/100\nChecklist: $completed/$total';
      } else if (score >= 40) {
        answer = '⚠️ Okay for small orders only.\n\nScore: $score/100 ($risk risk)\nComplete ${total - completed} more docs first.';
      } else {
        answer = '❌ Not recommended right now.\n\nScore: $score/100\nOnly $completed/$total docs done.';
      }
    } else {
      answer = '📌 $name summary:\n\n• AI Score: $score/100\n• Risk: $risk\n• Category: ${_vendorData['category'] ?? 'N/A'}\n'
          '• Checklist: $completed/$total\n• Delivery: $delivery/100\n• Orders: $totalOrders\n\nAsk me about score, risk, or delivery!';
    }

    setState(() {
      _messages.add({'role': 'ai', 'text': answer});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (!_vendorLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loading vendor data...')));
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final checklist = _vendorData['checklist'] as Map<String, dynamic>? ?? {};
      final completedDocs = checklist.values.where((v) => v == true).length;
      final totalDocs = checklist.length;

      final prompt = 'You are an AI assistant for a Smart Supply Chain platform. Answer in 2-3 sentences using emojis.\n\n'
          'Vendor: ${_vendorData['name'] ?? widget.vendorName}, '
          'AI Score: ${_vendorData['aiScore'] ?? 0}/100, '
          'Risk: ${_vendorData['riskLevel'] ?? 'unknown'}, '
          'Delivery: ${_vendorData['deliveryScore'] ?? 0}/100, '
          'Checklist: $completedDocs/$totalDocs docs completed.\n\nUser: $text';

      final requestBody = jsonEncode({
        'contents': [{'parts': [{'text': prompt}]}]
      });

      final xhr = html.HttpRequest();
      xhr.open('POST', 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey');
      xhr.setRequestHeader('Content-Type', 'application/json');

      bool responded = false;

      xhr.onLoad.listen((event) {
        if (responded || !mounted) return;
        responded = true;
        if (xhr.status == 200) {
          final data = jsonDecode(xhr.responseText!);
          final reply = data['candidates'][0]['content']['parts'][0]['text'] as String;
          setState(() {
            _messages.add({'role': 'ai', 'text': reply});
            _isLoading = false;
          });
          _scrollToBottom();
        } else {
          _localVendorAnswer(text);
        }
      });

      xhr.onError.listen((event) {
        if (responded || !mounted) return;
        responded = true;
        _localVendorAnswer(text);
      });

      xhr.send(requestBody);
    } catch (e) {
      _localVendorAnswer(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Chat Assistant', style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.vendorName, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: _gold),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            color: _vendorLoaded ? const Color(0xFF1A3A2A) : const Color(0xFF3A2A0A),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  _vendorLoaded ? Icons.check_circle : Icons.hourglass_empty,
                  size: 14,
                  color: _vendorLoaded ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                ),
                const SizedBox(width: 6),
                Text(
                  _vendorLoaded ? 'Vendor data loaded — AI ready!' : 'Loading vendor data...',
                  style: TextStyle(
                    fontSize: 12,
                    color: _vendorLoaded ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
          ),

          // Quick chips
          if (_vendorLoaded)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _quickChip('What is the score?'),
                  _quickChip('Is this vendor risky?'),
                  _quickChip('Checklist status'),
                  _quickChip('Should I order?'),
                  _quickChip('Delivery performance'),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? _gold : _cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: isUser ? null : Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.black : Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37))),
                  SizedBox(width: 8),
                  Text('AI is thinking...', style: TextStyle(color: Color(0xFF9E9E9E))),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0A0A0A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask about this vendor...',
                      hintStyle: const TextStyle(color: Color(0xFF757575)),
                      filled: true,
                      fillColor: _inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF424242)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: _gold, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _gold,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black, size: 20),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label) {
    return GestureDetector(
      onTap: () {
        _messageController.text = label;
        _sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFD4AF37), fontWeight: FontWeight.w500)),
      ),
    );
  }
}
