import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'main_shell_screen.dart';
import '../app_state.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  
  String _countryCode = '+972';
  bool _codeSent = false;
  bool _isLoading = false;
  String? _verificationId;
  ConfirmationResult? _confirmationResult;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      
      setState(() {
        _isLoading = true;
      });

      try {
        final fullPhoneNumber = _countryCode.trim() + _phoneController.text.trim();
        
        if (kIsWeb) {
          final result = await FirebaseAuth.instance.signInWithPhoneNumber(fullPhoneNumber);
          setState(() {
            _confirmationResult = result;
            _codeSent = true;
            _isLoading = false;
          });
          
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _codeFocusNode.requestFocus();
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SMS Code sent! ✉️'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          await FirebaseAuth.instance.verifyPhoneNumber(
            phoneNumber: fullPhoneNumber,
            verificationCompleted: (PhoneAuthCredential credential) async {
              await FirebaseAuth.instance.signInWithCredential(credential);
              final isComplete = await AppState().isCurrentProfileComplete();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => MainShellScreen(initialIndex: isComplete ? 0 : 2)),
                );
              }
            },
            verificationFailed: (FirebaseAuthException e) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verification failed: ${e.message}'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            codeSent: (String verificationId, int? resendToken) {
              setState(() {
                _verificationId = verificationId;
                _codeSent = true;
                _isLoading = false;
              });

              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _codeFocusNode.requestFocus();
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SMS Code sent! ✉️'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            codeAutoRetrievalTimeout: (String verificationId) {
              _verificationId = verificationId;
            },
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to verify phone number: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _signInWithCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (kIsWeb && _confirmationResult != null) {
          await _confirmationResult!.confirm(_codeController.text.trim());
        } else if (!kIsWeb && _verificationId != null) {
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: _codeController.text.trim(),
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
        } else {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        final isComplete = await AppState().isCurrentProfileComplete();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MainShellScreen(initialIndex: isComplete ? 0 : 2)),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${e.message}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Phone Login',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFB74D), // Soft warm pastel orange
                Color(0xFFE1BEE7), // Soft pastel purple
                Color(0xFF81C784), // Soft pastel green
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Pastel background gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD), Color(0xFFFFF3E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    elevation: 12,
                    shadowColor: Colors.black.withOpacity(0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    color: Colors.white.withOpacity(0.95),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 44.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Phone Login 📱',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF3F3D56),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _codeSent ? 'Enter the SMS code sent to your phone' : 'Enter your phone number (with country code)',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 36),
                            // Country Code & Phone Number row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                    initialValue: _countryCode,
                                    enabled: !_codeSent,
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    decoration: InputDecoration(
                                      labelText: 'Code',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onChanged: (value) => _countryCode = value,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Req';
                                      if (!value.startsWith('+')) return 'Use +';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    enabled: !_codeSent,
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    decoration: InputDecoration(
                                      labelText: 'Phone Number',
                                      prefixIcon: const Icon(Icons.phone_outlined),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Please enter phone number';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (_codeSent) ...[
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _codeController,
                                focusNode: _codeFocusNode,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  labelText: '6-digit SMS Code',
                                  prefixIcon: const Icon(Icons.lock_clock_outlined),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter code';
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 36),
                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : (_codeSent ? _signInWithCode : _verifyPhone),
                                icon: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Icon(_codeSent ? Icons.check_circle_outline_rounded : Icons.send_rounded),
                                label: Text(_codeSent ? 'VERIFY & LOGIN' : 'SEND SMS', style: const TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  elevation: 4,
                                  shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
                                ),
                              ),
                            ),
                            if (_codeSent) ...[
                              const SizedBox(height: 18),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _codeSent = false;
                                    _codeController.clear();
                                  });
                                },
                                child: const Text(
                                  'Change Phone Number',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
