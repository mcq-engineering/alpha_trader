import 'dart:ui';
import 'package:alpha_trader/userside1.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'adminside.dart';
import 'auth_provider.dart'; // Make sure this file exists and has what's needed


class LoginScreen2 extends StatefulWidget {
  const LoginScreen2({super.key});

  @override
  State<LoginScreen2> createState() => _LoginScreen2State();
}

class _LoginScreen2State extends State<LoginScreen2> {
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final UserCredential? userCredential =
      await _auth.signInWithGoogle();

      if (userCredential != null && mounted) {
        final user = userCredential.user;

        if (user != null) {
          // 🔥 Get user data from Firestore
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          final isAdmin = doc.data()?['isAdmin'] ?? false;

          if (isAdmin == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AlphaTraderAdminApp()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AlphaTraderApp10()),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
      _showSnackBar(context, "Login failed");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // Future<void> _handleGoogleSignIn() async {
  //   if (_isLoading) return;
  //
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     final UserCredential? userCredential =
  //     await _auth.signInWithGoogle();
  //
  //     if (userCredential != null && mounted) {
  //       // ✅ Navigate to Home
  //       Navigator.pushReplacementNamed(context, '/home');
  //     }
  //   } catch (e) {
  //     debugPrint("Auth Error: $e");
  //
  //     String errorMessage = "Login failed. Try again.";
  //
  //     if (e is FirebaseAuthException) {
  //       switch (e.code) {
  //         case 'network-request-failed':
  //           errorMessage = "Check your internet connection";
  //           break;
  //         case 'account-exists-with-different-credential':
  //           errorMessage = "Account already exists with another method";
  //           break;
  //         case 'invalid-credential':
  //           errorMessage = "Invalid login credentials";
  //           break;
  //       }
  //     }
  //
  //     if (mounted) {
  //       _showSnackBar(context, errorMessage);
  //     }
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0D0D), // Deep Obsidian
              Color(0xFF000000), // Pure Black
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const Spacer(flex: 3),
                _buildBranding(),
                const SizedBox(height: 60),

                // Toggle between button and loading indicator
                _isLoading ? _buildLoadingState() : _buildModernButton(
                  label: "Continue with Google",
                  onPressed: _handleGoogleSignIn,
                ),

                const Spacer(flex: 4),
                const SizedBox(height: 20),
                _buildFooter(),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildBranding() {
    return Column(
      children: [
        // Updated Image to be Circular
        ClipOval(
          child: Image.asset(
            'assets/icon1.png',
            height: 220, // Slightly adjusted for balance
            width: 220,  // Height and Width must be equal for a perfect circle
            fit: BoxFit.fitHeight, // Ensures the image fills the circle
          ),
        ),
        const SizedBox(height: 20),
        // 2. Main Brand Name
        const Text(
          "ALPHA TRADER",
          style: TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37), // Metallic Gold
            letterSpacing: 2.0,
          ),
        ),
        // 3. Sub-title
        const Text(
          "GOLD SIGNAL",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: 4.0,
          ),
        ),
      ],
    );
  }

  Widget _buildModernButton({required String label, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white, // Pure white background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Subtle shadow for depth
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Local asset image (Placeholder, make sure 'assets/google.png' exists)
            // If you don't have this, comment it out or provide a real path
            Image.asset(
              'assets/google.png',
              height: 24, // Standard logo size
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black, // Black text contrast
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 3),
        const SizedBox(height: 15),
        Text(
          "Authenticating with Google...",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        )
      ],
    );
  }

  Widget _buildFooter() {
    return Opacity(
      opacity: 0.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock_outline_rounded, size: 12, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "Secured by Google Identity",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}