import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;


  // --- GETTERS ---
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- USER DATA INITIALIZATION ---
  // --- USER DATA INITIALIZATION ---
  Future<void> _initializeUserData(User user) async {
    final userRef = _db.collection('users').doc(user.uid);

    // 1. Get the current document snapshot
    final docSnapshot = await userRef.get();

    if (!docSnapshot.exists) {
      // 2. NEW USER: Set everything for the first time
      await userRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': user.displayName ?? '',
        'phoneNumber':  '',
        'isAdmin' : false,
        'createdAt': FieldValue.serverTimestamp(),

      });
    } else {
      // 3. RETURNING USER: Only update non-financial info (email/phone/timestamp)
      // This ensures 'balance' and 'investedAmount' stay exactly as they were.
      await userRef.update({
        'email': user.email ?? docSnapshot.get('email'),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }
  // --- GOOGLE SIGN IN ---
// --- GOOGLE SIGN IN ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Attempt silent (lightweight) login first
      GoogleSignInAccount? googleUser = await _googleSignIn.attemptLightweightAuthentication();

      // 2. If silent failed, trigger the interactive picker
      googleUser ??= await _googleSignIn.authenticate();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // v7.2.0 requires requesting scopes explicitly for the access token
        final authClient = await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);

        final credential = GoogleAuthProvider.credential(
          accessToken: authClient.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          await _initializeUserData(userCredential.user!);
        }
        return userCredential;
      }
    } catch (e) {
      debugPrint("Google Auth Error: $e");
    }
    return null;
  }
  // --- EMAIL & PASSWORD ---



  // --- UTILS ---
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password': return 'The password provided is too weak.';
      case 'email-already-in-use': return 'An account already exists for that email.';
      case 'user-not-found': return 'No user found for that email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'invalid-email': return 'The email address is badly formatted.';
      default: return e.message ?? 'An unknown error occurred.';
    }
  }
}