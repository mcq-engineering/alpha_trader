import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'adminside.dart';
import 'firebase_options.dart';
import 'splashscreen.dart';
import 'userside1.dart'; // Your home screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize(

    clientId: '147207286648-m9ushsdknksc99ugtl65hvgf1o3gu85b.apps.googleusercontent.com',

  );
  if (kIsWeb) {

    await GoogleSignIn.instance.initialize(

      clientId: '147207286648-m9ushsdknksc99ugtl65hvgf1o3gu85b.apps.googleusercontent.com',



    );

  }

  runApp(const AlphaTraderApp());
}

class AlphaTraderApp extends StatelessWidget {
  const AlphaTraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alpha Trader',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),

      home: const SplashScreen(),
     // home: const AlphaTraderAdminApp(), // ✅ FIX


    );
  }
}