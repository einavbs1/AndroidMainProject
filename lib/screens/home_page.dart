import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'signup_screen.dart';
import 'login_screen.dart';
import 'main_shell_screen.dart';
import '../app_state.dart';
import '../utils/google_logo_painter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    
    // Subscribe to Google Sign-In account changes to intercept Web native logins
    GoogleSignIn.instance.authenticationEvents.listen((event) async {
      if (event is GoogleSignInAuthenticationEventSignIn && mounted) {
        final GoogleSignInAccount googleUser = event.user;
        setState(() {
          _isLoggingIn = true;
        });
        try {
          final GoogleSignInAuthentication googleAuth = googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
          );

          final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          final User? user = userCredential.user;

          if (user != null) {
            await _handlePostLoginRedirect(user);
          }
        } catch (e) {
          debugPrint('Web Google Sign-In Event Error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Google Sign-In failed: $e'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoggingIn = false;
            });
          }
        }
      }
    });

    // Initialize Web Identity Services on start
    if (kIsWeb) {
      GoogleSignIn.instance.initialize(
        clientId: '180824327760-p7h8a65bjk829qustjuui0t104rlild2.apps.googleusercontent.com',
      );
    }
  }

  Future<void> _handlePostLoginRedirect(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final isComplete = await AppState().isCurrentProfileComplete();

    if (mounted) {
      if (!isComplete) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainShellScreen(initialIndex: 2)),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your phone number to complete your profile.'),
            backgroundColor: Color(0xFF6C63FF),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainShellScreen(initialIndex: 0)),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoggingIn) return;

    setState(() {
      _isLoggingIn = true;
    });

    try {
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? '180824327760-p7h8a65bjk829qustjuui0t104rlild2.apps.googleusercontent.com' : null,
        serverClientId: '180824327760-p7h8a65bjk829qustjuui0t104rlild2.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        setState(() {
          _isLoggingIn = false;
        });
        return; // Cancelled
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _handlePostLoginRedirect(user);
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }



  void _goBackToDashboard() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainShellScreen(initialIndex: 0)),
      );
    }
  }

  void _navigateToDashboardHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainShellScreen(initialIndex: 0)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF3F3D56), size: 28),
          onPressed: _goBackToDashboard,
        ),
      ),
      body: Stack(
        children: [
          // Playful pastel gradient background
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
          SafeArea(
            child: Center(
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
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Story-Land 📖',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF3F3D56),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Share magical reading adventures together!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 36),
                            // Styled Unsplash Image (Unique Child-Reading Book image)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28.0),
                                child: Image.network(
                                  'https://images.unsplash.com/photo-1532012197267-da84d127e765?auto=format&fit=crop&q=80&w=400',
                                  width: 260,
                                  height: 170,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Google Sign-In Integration
                            if (kIsWeb)
                              Container(
                                height: 48,
                                alignment: Alignment.center,
                                child: (GoogleSignInPlatform.instance as dynamic).renderButton(),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: GoogleSignInButton(
                                  onPressed: _signInWithGoogle,
                                  isLoading: _isLoggingIn,
                                ),
                              ),
                            const SizedBox(height: 18),

                            // Email Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.mail_outline_rounded),
                                label: const Text('LOGIN WITH EMAIL'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const Login(title: 'Login')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  elevation: 4,
                                  shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Create Account Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.person_add_outlined),
                                label: const Text('CREATE ACCOUNT'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SignupPage()),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6C63FF),
                                  side: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Continue as Guest Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.person_outline_rounded),
                                label: const Text('CONTINUE AS A GUEST'),
                                onPressed: _navigateToDashboardHome,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  elevation: 4,
                                  shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoggingIn)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '🎨 Authenticating...',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
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