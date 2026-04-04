import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'loginscreen.dart';

class AlphaTraderApp10 extends StatelessWidget {
  const AlphaTraderApp10({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alpha Trader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: const Color(0xFFFFD700),
        cardColor: const Color(0xFF1A1A1A),
      ),
      home: const AlphaTraderHome(),
    );
  }
}

class Signal {
  final String id;
  final String symbol;
  final String type;
  final double entry;
  final List<double> tp;
  final double sl;
  final Timestamp? createdAt;
  final String status;
  final bool isPremium;

  Signal({
    required this.id,
    required this.symbol,
    required this.type,
    required this.entry,
    required this.tp,
    required this.sl,
    this.createdAt,
    required this.status,
    this.isPremium = false,
  });

  factory Signal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Signal(
      id: doc.id,
      symbol: data['symbol'] ?? 'XAU/USD',
      type: data['type'] ?? 'BUY',
      entry: (data['entry'] ?? 0.0).toDouble(),
      tp: List<double>.from((data['tp'] ?? []).map((e) => (e ?? 0.0).toDouble())),
      sl: (data['sl'] ?? 0.0).toDouble(),
      createdAt: data['createdAt'] as Timestamp?,
      status: data['status'] ?? 'LIVE',
      isPremium: data['isPremium'] ?? false,
    );
  }
}

class AlphaTraderHome extends StatefulWidget {
  const AlphaTraderHome({super.key});

  @override
  State<AlphaTraderHome> createState() => _AlphaTraderHomeState();
}

class _AlphaTraderHomeState extends State<AlphaTraderHome> {
  final CollectionReference signalsCollection = FirebaseFirestore.instance.collection('alphatrader');
  final CollectionReference subscriptionsCollection = FirebaseFirestore.instance.collection('alphatrader_subscriptions');

  bool isSubscribed = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  void _checkSubscriptionStatus() {
    // 1. Get the current logged-in user
    final User? user = FirebaseAuth.instance.currentUser;

    // 2. If no user is logged in, they cannot be subscribed
    if (user == null) {
      if (mounted) setState(() => isSubscribed = false);
      return;
    }

    // 3. Listen ONLY to documents belonging to this specific UID
    subscriptionsCollection
        .where('uid', isEqualTo: user.uid) // Filter by User ID
        .where('status', isEqualTo: 'approved') // Filter by Approval status
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          // isSubscribed is true only if a matching approved doc exists for THIS user
          isSubscribed = snapshot.docs.isNotEmpty;
        });
      }
    }, onError: (error) {
      debugPrint("Subscription listener error: $error");
    });
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "Just now • LIVE";
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago • LIVE";
    return DateFormat('HH:mm').format(date) + " • LIVE";
  }

  // ==================== SUBSCRIPTION BOTTOM SHEET ====================
  void _showSubscribeBottomSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final txHashController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text("Premium Subscription - \$10/month", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                const SizedBox(height: 8),
                const Center(child: Text("Unlock All Gold Signals", style: TextStyle(color: Colors.amber))),

                const SizedBox(height: 24),

                const Text("Send exactly 10 USDT (TRC20)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Expanded(
                        child: SelectableText(
                          "YOUR_REAL_USDT_TRC20_ADDRESS_HERE", // ← CHANGE THIS
                          style: TextStyle(fontFamily: 'monospace', fontSize: 15),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Color(0xFFFFD700)),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: "YOUR_REAL_USDT_TRC20_ADDRESS_HERE"));
                          ScaffoldMessenger.of(bottomSheetContext).showSnackBar(const SnackBar(content: Text("Address Copied!")));
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                TextFormField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                const SizedBox(height: 16),

                TextFormField(
                  controller: txHashController,
                  decoration: const InputDecoration(
                    labelText: "Transaction Hash (TXID)",
                    hintText: "Paste TX Hash after sending USDT",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;

                      if (user == null) {
                        ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                          const SnackBar(content: Text("Please login first!")),
                        );
                        return;
                      }
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      final txHash = txHashController.text.trim().toUpperCase();

                      if (name.isEmpty || phone.isEmpty || txHash.isEmpty) {
                        ScaffoldMessenger.of(bottomSheetContext).showSnackBar(const SnackBar(content: Text("All fields are required")));
                        return;
                      }

                      final existing = await subscriptionsCollection.where('txHash', isEqualTo: txHash).limit(1).get();
                      if (existing.docs.isNotEmpty) {
                        ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                          const SnackBar(content: Text("❌ This transaction has already been submitted!"), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      await subscriptionsCollection.add({
                        'name': name,
                        'uid': FirebaseAuth.instance.currentUser?.uid,
                        'phone': phone,
                        'txHash': txHash,
                        'amount': 10,
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      Navigator.pop(bottomSheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Request submitted! Admin will verify soon."), backgroundColor: Colors.green),
                      );
                    },
                    child: const Text("Submit Payment Proof"),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> signOutFromGoogle(BuildContext context) async {
    try {
      // 1. Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // 2. Sign out from Google (Clears the cached account)
      // This ensures the "Choose an account" dialog appears next time
      await _googleSignIn.signOut();
      await _auth.signOut();
      // 3. Navigate the user back to the Login Screen
      // We use pushAndRemoveUntil to clear the navigation stack
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen2()),
              (route) => false,
        );
      }

    } catch (e) {
      // Handle errors (e.g., show a SnackBar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error signing out: $e")),
      );
    }
  }
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E), // Slightly lighter dark background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Slightly less rounded corners
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32), // More vertical padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Icon Header ---
              Container(
                padding: const EdgeInsets.all(12), // Slightly smaller padding for icon
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15), // Slightly more opacity
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 30), // Slightly darker red, slightly smaller icon
              ),
              const SizedBox(height: 24), // Increased spacing

              // --- Text Content ---
              const Text(
                "Sign Out",
                style: TextStyle(
                  fontSize: 22, // Slightly larger title
                  fontWeight: FontWeight.w700, // Bolder font weight
                  color: Colors.white,
                  letterSpacing: 0.5, // Add subtle letter spacing
                ),
              ),
              const SizedBox(height: 10), // Reduced spacing for subtitle
              const Text(
                "Are you sure you want to sign out? You will need to log back in to access premium signals.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70, // Slightly more visible white
                  fontSize: 15, // Slightly larger subtitle font
                  height: 1.4, // Adjusted line height
                ),
              ),
              const SizedBox(height: 36), // Increased spacing before buttons

              // --- Action Buttons ---
              Row(
                children: [
                  // Cancel Button (Outlined style)
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        // Removed explicit padding for TextButton, it often looks better with default/content-based padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Slightly less rounded for buttons
                          side: const BorderSide(color: Colors.white12, width: 1), // Subtle border
                        ),
                        overlayColor: Colors.white.withOpacity(0.08), // Hover/splash effect
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12), // Explicit padding for text inside button
                        child: const Text(
                          "Stay Logged In",
                          style: TextStyle(
                            color: Colors.white60, // Better contrast for text
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Increased spacing between buttons
                  // Confirm Logout (Tonal/Modern style)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700], // Deeper, richer red
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14), // Retained vertical padding
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        shadowColor: Colors.red.withOpacity(0.4), // Subtle shadow for depth
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        signOutFromGoogle(context);
                      },
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.candlestick_chart, color: Colors.amber[400], size: 28),
            const SizedBox(width: 8),
            const Text('ALPHA TRADER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        actions: [
          // Premium/Free Status Chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(isSubscribed ? "PREMIUM" : "FREE"),
              backgroundColor: isSubscribed ? Colors.green.withOpacity(0.2) : Colors.white10,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: isSubscribed ? Colors.greenAccent : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.power_settings_new_sharp, color: Colors.red),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // appBar: AppBar(
      //   title: Row(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [
      //       Icon(Icons.candlestick_chart, color: Colors.amber[400], size: 28),
      //       const SizedBox(width: 8),
      //       const Text('ALPHA TRADER'),
      //     ],
      //   ),
      //   actions: [
      //     Padding(
      //       padding: const EdgeInsets.only(right: 16),
      //       child: Chip(
      //         label: Text(isSubscribed ? "Premium ✓" : "Free"),
      //         backgroundColor: isSubscribed ? Colors.green : Colors.grey[800],
      //         labelStyle: const TextStyle(color: Colors.white),
      //       ),
      //     ),
      //   ],
      // ),
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(milliseconds: 800)),
        child: StreamBuilder<QuerySnapshot>(
          stream: signalsCollection.orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text("Error loading signals"));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
            }

            final signals = snapshot.data!.docs.map((doc) => Signal.fromFirestore(doc)).toList();

            if (signals.isEmpty) return _buildNoSignalsYetScreen();

            // Separate free and premium signals
            final freeSignals = signals.where((s) => !s.isPremium).toList();
            final premiumSignals = signals.where((s) => s.isPremium).toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if (freeSignals.isNotEmpty) ...[
                    const Text("Free Signals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: freeSignals.length,
                      itemBuilder: (context, index) {
                        final signal = freeSignals[index];
                        return _buildSignalCard(signal, signal.type == "BUY", signal.status == "NEXT");
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Premium Signals
                  if (premiumSignals.isNotEmpty) ...[
                    Text(
                      isSubscribed ? "Premium Signals" : "Premium Signals (Locked)",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: premiumSignals.length,
                      itemBuilder: (context, index) {
                        final signal = premiumSignals[index];
                        if (!isSubscribed) {
                          return _buildLockedSignalCard(signal);
                        }
                        return _buildSignalCard(signal, signal.type == "BUY", signal.status == "NEXT");
                      },
                    ),
                  ],

                  const SizedBox(height: 40),
                  const Center(
                    child: Text("Signals are updated in real-time by admin", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: const Color(0xFF0F0F0F),
      //   selectedItemColor: const Color(0xFFFFD700),
      //   unselectedItemColor: Colors.white54,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      //     BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Signals"),
      //     BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
      //     BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      //   ],
      // ),
    );
  }

  // Locked Card for Free Users
  Widget _buildLockedSignalCard(Signal signal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1A1A1A),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(signal.symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
                      child: const Text("PREMIUM", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.lock, size: 70, color: Color(0xFFFFD700)),
                      SizedBox(height: 16),
                      Text("Premium Signal", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text("\$10 / Month - Unlock Now", style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open),
                  label: const Text("Subscribe Now - \$10/month"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: _showSubscribeBottomSheet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Normal Signal Card
  // Widget _buildSignalCard(Signal signal, bool isBuy, bool isNext) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 20),
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(24),
  //       color: const Color(0xFF1A1A1A),
  //       border: isNext ? Border.all(color: Colors.amber.withOpacity(0.6), width: 2) : null,
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(20),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(signal.symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
  //               Container(
  //                 padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
  //                 decoration: BoxDecoration(
  //                   color: isBuy ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
  //                   borderRadius: BorderRadius.circular(50),
  //                 ),
  //                 child: Text(signal.type, style: TextStyle(fontWeight: FontWeight.bold, color: isBuy ? Colors.green[400] : Colors.red[400])),
  //               ),
  //               Column(
  //                 crossAxisAlignment: CrossAxisAlignment.end,
  //                 children: [
  //                   if (isNext)
  //                     Text("NEXT TRADE", style: TextStyle(color: Colors.amber[300], fontSize: 10, fontWeight: FontWeight.bold)),
  //                   Text(
  //                       formatTime(signal.createdAt), // New helper function
  //                       style: TextStyle(
  //                         color: isNext ? Colors.amber[300] : Colors.white54,
  //                         fontSize: 12,
  //                       )
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //
  //           const SizedBox(height: 20),
  //
  //           Row(
  //             children: [
  //               const Text("ENTRY", style: TextStyle(color: Colors.white54)),
  //               const Spacer(),
  //               Text(signal.entry.toStringAsFixed(2), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
  //             ],
  //           ),
  //
  //           const Divider(height: 24, color: Colors.white12),
  //
  //           Row(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Expanded(child: _buildTpColumn(signal)),
  //               Expanded(child: _buildSlColumn(signal)),
  //             ],
  //           ),
  //
  //           const SizedBox(height: 24),
  //
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: OutlinedButton.icon(
  //                   icon: const Icon(Icons.copy),
  //                   label: const Text("COPY"),
  //                   onPressed: () {
  //                     final text = "${signal.type} ${signal.symbol} @ ${signal.entry}\nTP: ${signal.tp.join(" | ")}\nSL: ${signal.sl}";
  //                     Clipboard.setData(ClipboardData(text: text));
  //                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Signal copied!")));
  //                   },
  //                 ),
  //               ),
  //
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //
  //
  // Widget _buildTpColumn(Signal signal) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text("TAKE PROFIT", style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
  //       const SizedBox(height: 8),
  //       ...signal.tp.asMap().entries.map((e) => Padding(
  //         padding: const EdgeInsets.only(bottom: 4),
  //         child: Row(children: [Text("TP${e.key + 1}"), const Spacer(), Text(e.value.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF22C55E)))]),
  //       )),
  //     ],
  //   );
  // }
  //
  // Widget _buildSlColumn(Signal signal) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text("STOP LOSS", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
  //       const SizedBox(height: 8),
  //       Container(
  //         width: double.infinity,
  //         padding: const EdgeInsets.symmetric(vertical: 12),
  //         decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
  //         child: Text(signal.sl.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSignalCard(Signal signal, bool isBuy, bool isNext) {
    final Color actionColor = isBuy ? const Color(0xFF00C805) : const Color(0xFFFF3B30);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A1A1A),
        border: Border.all(
          color: isNext ? Colors.amber.withOpacity(0.4) : Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ROW 1: SYMBOL & TYPE ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Symbol Name
                Text(
                  signal.symbol,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                // Buy/Sell Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: actionColor.withOpacity(0.5), width: 1),
                  ),
                  child: Text(
                    signal.type.toUpperCase(),
                    style: TextStyle(
                      color: actionColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- ROW 2: TECHNICAL DETAILS (ENTRY, TP, SL) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
            ),
            child: Column(
              children: [
                // Entry Price Highlight
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ENTRY", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      signal.entry.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                // TP and SL Grid
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: _buildTpColumn(signal)),
                      const VerticalDivider(color: Colors.white10, thickness: 1, indent: 4, endIndent: 4),
                      Expanded(child: _buildSlColumn(signal)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- ROW 3: FOOTER (TIME AGO) ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: isNext ? Colors.amber : Colors.white30),
                const SizedBox(width: 6),
                Text(
                  formatTime(signal.createdAt),
                  style: TextStyle(
                    color: isNext ? Colors.amber.withOpacity(0.8) : Colors.white30,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Mini Copy Button
                GestureDetector(
                onTap: () {
                        final text = "${signal.type} ${signal.symbol} @ ${signal.entry}\nTP: ${signal.tp.join(" | ")}\nSL: ${signal.sl}";
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Signal copied!")));
                      },
                  child: const Text("COPY", style: TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTpColumn(Signal signal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("TAKE PROFIT", style: TextStyle(color: Color(0xFF00C805), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...signal.tp.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text("TP${e.key + 1}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const Spacer(),
              Text(e.value.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSlColumn(Signal signal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Icon
        Row(
          children: [
           // const Icon(Icons.gpp_maybe_rounded, color: Color(0xFFFF3B30), size: 14),
            //const SizedBox(width: 4),
            const Text(
                "STOP LOSS",
                style: TextStyle(
                  color: Color(0xFFFF3B30),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                )
            ),
          ],
        ),
        const SizedBox(height: 10),

        // SL Value Row (Matches TP list style)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Text(
                  "SL",
                  style: TextStyle(color: Colors.white38, fontSize: 11)
              ),
              const Spacer(),
              Text(
                  signal.sl.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Color(0xFFFF3B30),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'monospace', // Keeps numbers aligned
                  )
              ),
            ],
          ),
        ),

        // Optional: Risk Label
        const Spacer(), // Pushes the label to the bottom if inside IntrinsicHeight
        const Text(
            "PROTECTION ACTIVE",
            style: TextStyle(color: Colors.white12, fontSize: 8, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }

  Widget _buildNoSignalsYetScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.candlestick_chart_outlined, size: 90, color: Colors.amber.withOpacity(0.6)),
            const SizedBox(height: 24),
            const Text("No Signals Yet", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            const Text("The admin will add new Gold signals soon.\n\nPull down to refresh.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5)),
            const SizedBox(height: 40),
            ElevatedButton.icon(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh), label: const Text("Refresh"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black)),
          ],
        ),
      ),
    );
  }


}