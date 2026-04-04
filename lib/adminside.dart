import 'package:alpha_trader/userside1.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';


class AlphaTraderAdminApp extends StatelessWidget {
  const AlphaTraderAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alpha Trader - Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFFD700),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        // Fixed: Use CardThemeData instead of CardTheme
        cardTheme: const CardThemeData(
          color: Color(0xFF1F1F1F),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      home: const AdminMainScreen(),
    );
  }
}

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AddSignalScreen(),
     SignalsListScreen(),
    SubscriptionsScreen(),
   // AlphaTraderApp10(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          children: [
            const Icon(Icons.candlestick_chart, color: Color(0xFFFFD700), size: 28),
            const SizedBox(width: 12),
            const Text("ALPHA TRADER", style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
          ],
        ),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0A0A0A),
        selectedItemColor: const Color(0xFFFFD700),
        unselectedItemColor: Colors.white60,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Add Signal"),
          BottomNavigationBarItem(icon: Icon(Icons.signal_cellular_alt), label: "All Signals"),
          BottomNavigationBarItem(icon: Icon(Icons.subscriptions), label: "Subscriptions"),
         // BottomNavigationBarItem(icon: Icon(Icons.supervised_user_circle_outlined), label: "User"),
        ],
      ),
    );
  }
}

// ====================== ADD SIGNAL SCREEN ======================
// ====================== ADD SIGNAL SCREEN ======================
class AddSignalScreen extends StatefulWidget {
  const AddSignalScreen({super.key});

  @override
  State<AddSignalScreen> createState() => _AddSignalScreenState();
}

class _AddSignalScreenState extends State<AddSignalScreen> {
  final CollectionReference signalsRef = FirebaseFirestore.instance.collection('alphatrader');
  final _formKey = GlobalKey<FormState>();

  String type = "BUY";
  String status = "LIVE";
  List<double> tpList = [2665.0, 2675.0];
  bool isPremium = false;        // ← New: Premium toggle

  final entryController = TextEditingController(text: "2654.75");
  final slController = TextEditingController(text: "2638.20");

  void addTpField() => setState(() => tpList.add(0.0));

  void removeTpField(int index) {
    if (tpList.length > 1) setState(() => tpList.removeAt(index));
  }

  Future<void> saveSignal() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final entryPrice = double.tryParse(entryController.text.trim()) ?? 0.0;
      final stopLoss = double.tryParse(slController.text.trim()) ?? 0.0;

      final tpValues = tpList
          .map((e) => double.tryParse(e.toString().trim()) ?? 0.0)
          .where((v) => v > 0)
          .toList();

      if (tpValues.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Add at least one TP"), backgroundColor: Colors.orange),
        );
        return;
      }

      await signalsRef.add({
        'symbol': 'XAU/USD',
        'type': type,
        'entry': entryPrice,
        'tp': tpValues,
        'sl': stopLoss,
        'status': status,
        'isPremium': isPremium,           // ← Saved as boolean
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Signal Saved Successfully!"), backgroundColor: Colors.green),
      );

      // Reset form
      entryController.clear();
      slController.clear();
      setState(() {
        tpList = [2665.0, 2675.0];
        type = "BUY";
        status = "LIVE";
        isPremium = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text("Signal Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTypeChip("BUY", Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildTypeChip("SELL", Colors.red)),
              ],
            ),

            const SizedBox(height: 28),
            _buildTextField("Entry Price", entryController),
            const SizedBox(height: 20),
            _buildTextField("Stop Loss (SL)", slController),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Take Profit Levels", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(onPressed: addTpField, icon: const Icon(Icons.add_circle, color: Color(0xFFFFD700))),
              ],
            ),

            const SizedBox(height: 12),
            ...tpList.asMap().entries.map((e) => _buildTpField(e.key)).toList(),

            const SizedBox(height: 24),
            _buildStatusDropdown(),

            // ==================== NEW: PREMIUM CHECKBOX ====================
            const SizedBox(height: 24),
            CheckboxListTile(
              title: const Text("Premium Signal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: const Text("Only subscribed users can see this signal"),
              value: isPremium,
              activeColor: const Color(0xFFFFD700),
              onChanged: (value) {
                setState(() => isPremium = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: saveSignal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
                child: const Text("SAVE SIGNAL TO FIREBASE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildTypeChip(String label, Color color) {
    final isSelected = type == label;
    return GestureDetector(
      onTap: () => setState(() => type = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFF1F1F1F),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.white10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: const Color(0xFF1F1F1F),
      ),
      keyboardType: TextInputType.number,
      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
    );
  }

  Widget _buildTpField(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: tpList[index].toString(),
              decoration: InputDecoration(
                labelText: "TP ${index + 1}",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: const Color(0xFF1F1F1F),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => tpList[index] = double.tryParse(val) ?? 0.0,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
            onPressed: () => removeTpField(index),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: status,
      decoration: InputDecoration(
        labelText: "Status",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: const Color(0xFF1F1F1F),
      ),
      items: const [
        DropdownMenuItem(value: "LIVE", child: Text("LIVE")),
        DropdownMenuItem(value: "NEXT", child: Text("NEXT")),
      ],
      onChanged: (val) => setState(() => status = val!),
    );
  }
}

// ====================== SIGNALS LIST SCREEN ======================
class SignalsListScreen extends StatelessWidget {
   SignalsListScreen({super.key});

  final CollectionReference signalsRef = FirebaseFirestore.instance.collection('alphatrader');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: signalsRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 80, color: Colors.white54),
                        SizedBox(height: 16),
                        Text("No signals added yet", style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isBuy = data['type'] == "BUY";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isBuy ? Colors.green : Colors.red,
                                      radius: 20,
                                      child: Text(
                                        data['type'],
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(data['symbol'], style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: data['status'] == "LIVE"
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    data['status'],
                                    style: TextStyle(
                                      color: data['status'] == "LIVE" ? Colors.green : Colors.amber,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text("Entry: ${data['entry']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 14),
                            Text(
                              "TP: ${(data['tp'] as List).join("  |  ")}",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "SL: ${data['sl']}",
                              style: const TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => signalsRef.doc(docs[index].id).delete(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
// In SubscriptionsScreen
// ====================== SUBSCRIPTIONS SCREEN ======================
class SubscriptionsScreen extends StatelessWidget {
   SubscriptionsScreen({super.key});

  final CollectionReference subscriptionsRef = FirebaseFirestore.instance.collection('alphatrader_subscriptions');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //const Text("Subscription Requests", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),


          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: subscriptionsRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No subscription requests yet"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String status = data['status'] ?? 'pending';
                    final String? txHash = data['txHash'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  data['name'] ?? 'Unknown User',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                ),
                                _statusChip(status),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Text("Phone: ${data['phone'] ?? 'N/A'}", style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),

                            Text(
                              "Amount: \$${data['amount'] ?? 10}",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.amber),
                            ),

                            const SizedBox(height: 8),

                            if (data['createdAt'] != null)
                              Text(
                                "Requested on: ${DateFormat('dd MMM yyyy, hh:mm a').format((data['createdAt'] as Timestamp).toDate())}",
                                style: const TextStyle(fontSize: 14, color: Colors.white70),
                              ),

                            if (txHash != null && txHash.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: GestureDetector(
                                  onTap: () => _openTronScan(context, txHash),   // Pass context here
                                  child: Row(
                                    children: [
                                      const Text("TX Hash: ", style: TextStyle(color: Colors.white70)),
                                      Expanded(
                                        child: Text(
                                          txHash,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration: TextDecoration.underline,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.open_in_new, size: 18, color: Colors.blue),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),

                            if (status == 'pending')
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      onPressed: () => _updateStatus(docs[index].id, 'approved'),
                                      child: const Text("Approve"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => _updateStatus(docs[index].id, 'rejected'),
                                      child: const Text("Reject"),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.orange;
    if (status == 'approved') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  void _updateStatus(String docId, String newStatus) {
    subscriptionsRef.doc(docId).update({'status': newStatus});
  }

  // Fixed: Now accepts BuildContext as parameter
  void _openTronScan(BuildContext context, String txHash) async {
    await Clipboard.setData(ClipboardData(text: txHash));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("TX Hash copied!\nOpen TronScan and search: $txHash"),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Optional: You can open browser directly if you add url_launcher later
     launchUrl(Uri.parse('https://tronscan.org/#/transaction/$txHash'));
  }
}