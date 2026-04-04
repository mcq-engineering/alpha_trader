import 'package:alpha_trader/userside1.dart'; // Your main user screen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'adminside.dart';
import 'loginscreen.dart';

// ====================== SPLASH SCREEN ======================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
      super.initState();

      Future.delayed(const Duration(seconds: 3), () async {
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
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
        else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen2()),
          );
        }
      });
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Dark background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.candlestick_chart,
                size: 100,
                color: Color(0xFFFFD700),
              ),
            ),

            const SizedBox(height: 40),

            // App Name
            const Text(
              "ALPHA TRADER",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Gold Signals • Premium Trading",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 60),

            // Loading Indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
                strokeWidth: 3,
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "Loading Signals...",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

