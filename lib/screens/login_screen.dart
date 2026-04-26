import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  static const Color _bg       = Color(0xFFe1cbb1); // grain brown
  static const Color _cardBg   = Color(0xFFf5ede0); // card surface
  static const Color _derby    = Color(0xFF7b5836); // brown derby  (buttons)
  static const Color _cape     = Color(0xFF976f47); // cape palliser
  static const Color _smoked   = Color(0xFF4b3828); // smoked brown (labels)
  static const Color _dark     = Color(0xFF422a14); // dark brown   (text)
  static const Color _inputBg  = Color(0xFFecddc8); // input fill
  static const Color _border   = Color(0x2E4b3828);

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } catch (e) {
      _showError('$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      _showError('$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithEmail() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      _showError('$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF7a1f1a), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFecddc8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _cape.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.local_shipping_rounded, size: 56, color: Color(0xFF7b5836)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Smart Supply Chain',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _dark, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 6),
                  const Text('AI-Powered Vendor Management', style: TextStyle(fontSize: 13, color: _smoked)),
                  const SizedBox(height: 36),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        // Email
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: _dark),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: _smoked),
                            prefixIcon: const Icon(Icons.email_outlined, color: _derby),
                            filled: true,
                            fillColor: _inputBg,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _cape.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _derby, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: _dark),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: _smoked),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: _derby),
                            filled: true,
                            fillColor: _inputBg,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _cape.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _derby, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        if (_isLoading)
                          const CircularProgressIndicator(color: Color(0xFF7b5836))
                        else ...[
                          // Login
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _signInWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _derby,
                                foregroundColor: const Color(0xFFf5ede0),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              child: const Text('Login'),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Register
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _registerWithEmail,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _derby,
                                side: const BorderSide(color: Color(0xFF7b5836)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                              child: const Text('Register'),
                            ),
                          ),
                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(child: Divider(color: _smoked.withOpacity(0.2))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Text('OR', style: TextStyle(color: _smoked, fontSize: 12)),
                              ),
                              Expanded(child: Divider(color: Color(0x334b3828))),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Google
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _signInWithGoogle,
                              icon: const Icon(Icons.g_mobiledata_rounded, color: _derby, size: 22),
                              label: const Text('Sign in with Google', style: TextStyle(fontSize: 14, color: _derby, fontWeight: FontWeight.w500)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFF7b5836)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}