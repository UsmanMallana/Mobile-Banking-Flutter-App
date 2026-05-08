import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_banking/utils/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

// Common Template for All Pages
class SimplePage extends StatelessWidget {
  final String title;
  SimplePage(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Color(0xFF1E3A8A)),
      body: Center(child: Text(title, style: TextStyle(fontSize: 24))),
    );
  }
}

class MobileRechargePage extends StatefulWidget {
  @override
  _MobileRechargePageState createState() => _MobileRechargePageState();
}

class _MobileRechargePageState extends State<MobileRechargePage> {
  final TextEditingController _mobileNumberController = TextEditingController();
  String? selectedCarrier;
  double? selectedAmount;

  final List<String> carriers = ["Jazz", "Zong", "Ufone"];
  final List<double> amounts = [10.0, 20.0, 50.0, 100.0];

  void processRecharge() {
    if (_mobileNumberController.text.isEmpty ||
        selectedCarrier == null ||
        selectedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Recharge of \$${selectedAmount} for ${_mobileNumberController.text} on $selectedCarrier successful!",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(title: Text("Mobile Recharge")),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Enter Mobile Number"),
                  SizedBox(height: 10),
                  TextField(
                    controller: _mobileNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "Mobile Number",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 25),
                  Text("Select Carrier"),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCarrier,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: carriers.map((carrier) {
                      return DropdownMenuItem(
                        value: carrier,
                        child: Text(carrier),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCarrier = value;
                      });
                    },
                  ),
                  SizedBox(height: 25),
                  Text("Select Amount"),
                  SizedBox(height: 10),
                  DropdownButtonFormField<double>(
                    value: selectedAmount,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: amounts.map((amount) {
                      return DropdownMenuItem(
                        value: amount,
                        child: Text("\$${amount.toString()}"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAmount = value;
                      });
                    },
                  ),
                  SizedBox(height: 25),
                  GestureDetector(
                    onTap: processRecharge,
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "Recharge Now",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
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


class SendMoneyPage extends StatefulWidget {
  @override
  State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage> {
  final emailController = TextEditingController();
  final amountController = TextEditingController();
  bool success = true;

  @override
  void dispose() {
    emailController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void displayResult(String result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              result,
              style: TextStyle(color: Colors.black),
              textScaler: TextScaler.linear(0.5),
            ),
          ),
        );
      },
    );
  }

  Future<String?> getUserUidByEmail(String email) async {
    // Query Firestore for the user with the given name
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

    if (querySnapshot.docs.isEmpty) {
      return null; // No user found
    }

    // Return the first matching document ID (which is the user’s uid in Firestore)
    return querySnapshot.docs.first.id;
  }

  Future<bool> transferMoney(
    String senderUid,
    String receiverEmail,
    double amount,
  ) async {
    final receiverUid = await getUserUidByEmail(receiverEmail);
    if (receiverUid == null) {
      throw Exception("User with email $receiverEmail not found!");
    }

    final firestore = FirebaseFirestore.instance;

    // 1) Start Firestore transaction to update balances
    await firestore.runTransaction((transaction) async {
      final senderRef = firestore.collection('users').doc(senderUid);
      final receiverRef = firestore.collection('users').doc(receiverUid);

      final senderSnap = await transaction.get(senderRef);
      final receiverSnap = await transaction.get(receiverRef);

      if (!senderSnap.exists) throw Exception("Sender does not exist!");
      if (!receiverSnap.exists) throw Exception("Receiver does not exist!");

      final senderBalance = senderSnap.data()?['balance'] as double;
      final receiverBalance = receiverSnap.data()?['balance'] as double;

      if (senderBalance < amount) {
        success = false;
        return;
      }

      // 2) Update balances
      transaction.update(senderRef, {'balance': senderBalance - amount});
      transaction.update(receiverRef, {'balance': receiverBalance + amount});

      // 3) Create a transaction record in "transactions" collection
      final transactionRef = firestore.collection('transactions').doc();

      // 1) Fetch sender's name
      final senderDoc =
          await firestore.collection('users').doc(senderUid).get();
      final senderName =
          senderDoc.exists
              ? (senderDoc.data()?['name'] as String? ?? 'Unknown')
              : 'Unknown';

      // 2) Fetch receiver's name
      final receiverDoc =
          await firestore.collection('users').doc(receiverUid).get();
      final receiverName =
          senderDoc.exists
              ? (receiverDoc.data()?['name'] as String? ?? 'Unknown')
              : 'Unknown';

      // 3) Create transaction doc
      transaction.set(transactionRef, {
        'senderUid': senderUid,
        'receiverUid': receiverUid,
        'senderName': senderName,
        'receiverName': receiverName,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'participants': [senderUid, receiverUid],
      });
    });
    return success;
  }

  void sendMoney(String email) async {
    final senderUid = FirebaseAuth.instance.currentUser!.uid;

    // Validate the amount
    double amount;
    try {
      amount = double.parse(amountController.text.trim());
    } catch (_) {
      displayResult("Invalid amount!");
      return;
    }

    try {
      success = await transferMoney(senderUid, email, amount);
      if (success) {
        displayResult("Transaction Successful!");
      } else {
        displayResult("Insufficient funds!");
        success = true;
      }
    } catch (e) {
      displayResult("Transaction Failed: $e");
    }

    // Clear fields after the attempt (success or failure)
    emailController.clear();
    amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Send Money")),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Textfield(
                  controller: emailController,
                  hintText: "Enter receiver's email address",
                  obscureText: false,
                ),
                SizedBox(height: 25),
                Textfield(
                  hintText: "Enter Amount",
                  obscureText: false,
                  controller: amountController,
                ),
                SizedBox(height: 25),
                GestureDetector(
                  onTap: () => sendMoney(emailController.text),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "Send Money",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionHistoryPage extends StatelessWidget {
  final String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

  TransactionHistoryPage({Key? key}) : super(key: key);

  Future<void> _exportToPDF(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Bank Statement", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final senderName = data['senderName'];
                final receiverName = data['receiverName'];
                final amount = data['amount'];
                final timestamp = data['timestamp'] as Timestamp?;
                final dateString = timestamp != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                    : "Unknown date";
                return pw.Text("$senderName to $receiverName - \$${amount.toString()} - $dateString");
              }).toList(),
            ],
          );
        },
      ),
    );

    final status = await Permission.storage.request();
    if (status.isGranted) {
      final directory = await getExternalStorageDirectory();
      final file = File("${directory!.path}/bank_statement.pdf");
      await file.writeAsBytes(await pdf.save());

      // Show success message
      print("PDF Saved: ${file.path}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance
                  .collection('transactions')
                  .where('participants', arrayContains: currentUserUid)
                  .get();
              _exportToPDF(snapshot.docs);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('participants', arrayContains: currentUserUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No transactions yet."));
          }

          docs.sort((a, b) {
            final timestampA = (a['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final timestampB = (b['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return timestampB.compareTo(timestampA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final senderUid = data['senderUid'];
              final senderName = data['senderName'];
              final receiverName = data['receiverName'];
              final amount = data['amount'];
              final timestamp = data['timestamp'] as Timestamp?;

              final dateString = timestamp != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                  : "Unknown date";

              final isSender = senderUid == currentUserUid;
              final transactionType = isSender ? "Sent" : "Received";
              final otherParty = isSender ? receiverName : senderName;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Icon(
                    isSender ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isSender ? Colors.red : Colors.green,
                  ),
                  title: Text(
                    "$transactionType \$${amount.toString()}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "$otherParty\n$dateString",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class CardsPage extends StatelessWidget {
  final String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

  CardsPage({Key? key}) : super(key: key);

  Future<String> getUserName() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .get();
    return userDoc.exists ? userDoc['name'] as String : 'User Name';
  }

  // Generates a random 16-digit card number.
  String generateRandomCardNumber() {
    final random = Random();
    String cardNumber = '';
    for (int i = 0; i < 16; i++) {
      cardNumber += random.nextInt(10).toString();
    }
    return cardNumber;
  }

  void addNewCard(BuildContext context) async {
    String cardHolderName = await getUserName();
    final random = Random();
    String cardNumber = generateRandomCardNumber();

    // Preset list of bank details with actual bank names and card brands.
    final List<Map<String, String>> bankDetails = [
      {'bankName': 'Chase', 'brand': 'Visa'},
      {'bankName': 'Bank of America', 'brand': 'Mastercard'},
      {'bankName': 'Wells Fargo', 'brand': 'Visa'},
      {'bankName': 'Citi', 'brand': 'Mastercard'},
    ];
    final bank = bankDetails[random.nextInt(bankDetails.length)];

    // Randomly choose an expiry date from a preset list.
    final List<String> expiryDates = ['12/26', '06/25', '09/27', '03/28'];
    final expiryDate = expiryDates[random.nextInt(expiryDates.length)];

    // Randomly assign the card type.
    final String type = random.nextBool() ? 'Credit' : 'Debit';

    try {
      await FirebaseFirestore.instance.collection('cards').add({
        'cardNumber': cardNumber,
        'cardHolder': cardHolderName,
        'expiryDate': expiryDate,
        'bankName': bank['bankName']!,
        'type': type,
        'brand': bank['brand']!,
        'userId': currentUserUid,
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add card: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Credit/Debit Cards")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('cards')
                .where('userId', isEqualTo: currentUserUid)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No cards available."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              String brand = data['brand'] ?? 'Visa';
              String assetPath =
                  brand == 'Visa'
                      ? 'assets/visa_white.png'
                      : 'assets/mastercard_white.png';
              Color cardColor =
                  brand == 'Visa' ? Colors.blue.shade900 : Colors.red.shade900;

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with bank name and brand icon.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['bankName'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Image.asset(assetPath, height: 30),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Masked card number
                    Text(
                      "**** **** **** " + data['cardNumber'].substring(12),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 12),
                    // Card Holder and Expiry labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Card Holder",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          "Expires",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    // Card Holder name and expiry date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['cardHolder'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          data['expiryDate'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addNewCard(context),
        child: Icon(Icons.add),
      ),
    );
  }
}

class EducationPage extends StatelessWidget {
  const EducationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Education"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Education",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.school, size: 40, color: Colors.blue),
                title: const Text(
                  "Bachelor of Science in Computer Science",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("University of Example, 2015 - 2019"),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.school,
                  size: 40,
                  color: Colors.green,
                ),
                title: const Text(
                  "Master of Science in Software Engineering",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Institute of Technology, 2019 - 2021"),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.school, size: 40, color: Colors.red),
                title: const Text(
                  "Ph.D. in Artificial Intelligence",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Research University, 2021 - Present"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnlineShoppingPage extends StatelessWidget {
  const OnlineShoppingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Online Shopping"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Online Shopping",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.shopping_bag, size: 40, color: Colors.blue),
                title: const Text(
                  "Electronics Sale",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Up to 50% off on gadgets & more"),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.shopping_cart,
                  size: 40,
                  color: Colors.green,
                ),
                title: const Text(
                  "Fashion Deals",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Latest trends with amazing discounts"),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.home, size: 40, color: Colors.red),
                title: const Text(
                  "Home Essentials",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Everything you need for your home"),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.fastfood, size: 40, color: Colors.orange),
                title: const Text(
                  "Grocery Offers",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Fresh groceries delivered to your doorstep",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MutualFundsPage extends StatelessWidget {
  const MutualFundsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mutual Funds"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Mutual Funds",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.trending_up, size: 40, color: Colors.blue),
                title: const Text(
                  "Equity Fund",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("High growth potential with higher risk."),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.trending_up, size: 40, color: Colors.green),
                title: const Text(
                  "Debt Fund",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Lower risk and steady returns."),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.trending_up,
                  size: 40,
                  color: Colors.orange,
                ),
                title: const Text(
                  "Balanced Fund",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "A mix of equity and debt for balanced growth.",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DonationsPage extends StatelessWidget {
  const DonationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donations"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Donations",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.favorite, size: 40, color: Colors.red),
                title: const Text(
                  "Education for All",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Support education programs for underprivileged children.",
                ),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.local_hospital,
                  size: 40,
                  color: Colors.green,
                ),
                title: const Text(
                  "Healthcare Assistance",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Donate to provide healthcare to those in need.",
                ),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.nature_people,
                  size: 40,
                  color: Colors.blue,
                ),
                title: const Text(
                  "Environmental Protection",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Help us protect our environment and promote sustainability.",
                ),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.food_bank, size: 40, color: Colors.orange),
                title: const Text(
                  "Hunger Relief",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Contribute to programs fighting hunger and food insecurity.",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountUsagePage extends StatelessWidget {
  const AccountUsagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account Usage"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Account Usage",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.person, size: 40, color: Colors.blue),
                title: const Text(
                  "Profile Visits",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Your profile was viewed 123 times this month.",
                ),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.monetization_on,
                  size: 40,
                  color: Colors.green,
                ),
                title: const Text(
                  "Transactions",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "You completed 45 transactions this month.",
                ),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.security,
                  size: 40,
                  color: Colors.red,
                ),
                title: const Text(
                  "Security Level",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Your account security is set to high."),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.notifications,
                  size: 40,
                  color: Colors.orange,
                ),
                title: const Text(
                  "Notifications",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "You received 7 new notifications this week.",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocatorPage extends StatelessWidget {
  // Fixed branch location (example: Islamabad, Pakistan)
  final LatLng branchLocation = LatLng(29.375402, 71.760089);

  LocatorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location"), centerTitle: true),
      body: FlutterMap(
        options: MapOptions(center: branchLocation, zoom: 14.0),
        // Use nonRotatedChildren for attribution widgets in flutter_map 8.x
        nonRotatedChildren: [
          AttributionWidget.defaultWidget(
            source: '© OpenStreetMap contributors',
            onSourceTapped: () {},
          ),
        ],
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: branchLocation,
                width: 80,
                height: 80,
                builder:
                    (context) => const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//Drawer Pages
class DarkModePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimplePage("Dark Mode");
  }
}

class MyAccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimplePage("My Account");
  }
}

class BeneficiaryManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimplePage("Beneficiary Management");
  }
}

class LoanManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimplePage("Loan Management");
  }
}

class GlobalWalletPaymentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimplePage("Global Wallet Payment");
  }
}

class ApplyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimplePage("Apply");
  }
}

class CardsManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimplePage("Cards Management");
  }
}

class TransactionActivityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimplePage("Transaction Activity");
  }
}

class GlobalWalletPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimplePage("Global Wallet Page");
  }
}
