import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';



class AlphaTraderApp extends StatelessWidget {
  const AlphaTraderApp({super.key});

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

  Signal({
    required this.id,
    required this.symbol,
    required this.type,
    required this.entry,
    required this.tp,
    required this.sl,
    this.createdAt,
    required this.status,
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
    );
  }
}

class AlphaTraderHome extends StatefulWidget {
  const AlphaTraderHome({super.key});

  @override
  State<AlphaTraderHome> createState() => _AlphaTraderHomeState();
}

class _AlphaTraderHomeState extends State<AlphaTraderHome> {
  final CollectionReference signalsCollection =
  FirebaseFirestore.instance.collection('alphatrader');

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "Just now • LIVE";
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago • LIVE";
    }
    return DateFormat('HH:mm').format(date) + " • LIVE";
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
            const Text('ALPHA TRADER'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Color(0xFFFFD700)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_outline, color: Color(0xFFFFD700)), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(milliseconds: 800)),
        child: StreamBuilder<QuerySnapshot>(
          stream: signalsCollection
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading signals"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
              );
            }

            final signals = snapshot.data!.docs
                .map((doc) => Signal.fromFirestore(doc))
                .toList();

            // Improved Empty State
            if (signals.isEmpty) {
              return _buildNoSignalsYetScreen();
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLivePriceHeader(),
                  const SizedBox(height: 28),
                  const Text(
                    "Gold Signals",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: signals.length,
                    itemBuilder: (context, index) {
                      final signal = signals[index];
                      final isBuy = signal.type == "BUY";
                      final isNext = signal.status == "NEXT";
                      return _buildSignalCard(signal, isBuy, isNext);
                    },
                  ),
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      "Signals are updated in real-time by admin",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: const Color(0xFFFFD700),
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Signals"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  // ==================== Beautiful Empty State ====================
  Widget _buildNoSignalsYetScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.candlestick_chart_outlined,
              size: 90,
              color: Colors.amber.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Signals Yet",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "The admin will add new Gold signals soon.\n\nPull down to refresh.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // Refresh Button
            ElevatedButton.icon(
              onPressed: () {
                // This will trigger RefreshIndicator
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),

            const SizedBox(height: 60),
            const Text(
              "Signals are updated in real-time by admin",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // Live Price Header (unchanged)
  Widget _buildLivePriceHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[700]!, const Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("XAU/USD", style: TextStyle(fontSize: 18, color: Colors.white70)),
              SizedBox(height: 6),
              Text("2,654.75", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Text("+18.45 (+0.70%)", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text("LIVE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Signal Card (unchanged - kept same as before)
  Widget _buildSignalCard(Signal signal, bool isBuy, bool isNext) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1A1A1A),
        border: isNext ? Border.all(color: Colors.amber.withOpacity(0.6), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: (isBuy ? Colors.green : Colors.red).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
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
                  decoration: BoxDecoration(
                    color: isBuy ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: isBuy ? Colors.green : Colors.red),
                  ),
                  child: Text(
                    signal.type,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isBuy ? Colors.green[400] : Colors.red[400],
                    ),
                  ),
                ),
                Text(
                  signal.status == "NEXT" ? "Next Trade" : formatTime(signal.createdAt),
                  style: TextStyle(color: isNext ? Colors.amber[300] : Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("ENTRY", style: TextStyle(color: Colors.white54)),
                const Spacer(),
                Text(signal.entry.toStringAsFixed(2), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              ],
            ),
            const Divider(height: 24, color: Colors.white12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("TAKE PROFIT", style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...signal.tp.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text("TP${e.key + 1}", style: const TextStyle(color: Colors.white70)),
                            const Spacer(),
                            Text(e.value.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("STOP LOSS", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          signal.sl.toStringAsFixed(2),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text("COPY"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD700),
                      side: const BorderSide(color: Color(0xFFFFD700)),
                    ),
                    onPressed: () {
                      final text = "${signal.type} ${signal.symbol} @ ${signal.entry}\nTP: ${signal.tp.join(" | ")}\nSL: ${signal.sl}";
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Signal copied!")));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.show_chart),
                    label: const Text("CHART"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}