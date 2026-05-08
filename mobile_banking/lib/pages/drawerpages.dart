import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DrawerPages {
  static List<Map<String, dynamic>> drawerItems = [
    {
      'icon': Icons.account_circle,
      'label': 'My Account',
      'page': MyAccountPage(),
    },
    {
      'icon': Icons.people,
      'label': 'Beneficiary Management',
      'page': BeneficiaryManagementPage(),
    },
    {
      'icon': Icons.monetization_on,
      'label': 'Loan Management',
      'page': LoanManagementPage(),
    },
    {
      'icon': Icons.language,
      'label': 'Global Wallet Payment',
      'page': GlobalWalletPage(),
    },
    {'icon': Icons.assignment, 'label': 'Apply', 'page': ApplyPage()},
  ];
}

class CustomDrawer extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String lastLogin;

  const CustomDrawer({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.lastLogin,
  }) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Modern header with gradient background.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 40,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isDarkMode
                        ? [Colors.black87, Colors.black54]
                        : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Profile avatar.
                CircleAvatar(
                  radius: 30,
                  backgroundImage: const AssetImage('assets/user.jpg'),
                ),
                const SizedBox(width: 16),
                // User details.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.userEmail,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Account created on: ${widget.lastLogin}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Drawer list items.
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: DrawerPages.drawerItems.length,
              separatorBuilder:
                  (context, index) =>
                      const Divider(color: Colors.grey, height: 1),
              itemBuilder: (context, index) {
                final item = DrawerPages.drawerItems[index];
                return ListTile(
                  leading: Icon(
                    item['icon'],
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  title: Text(
                    item['label'],
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer.
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => item['page']),
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

// Data wrapper for CustomDrawer.
class CustomDrawerDataWrapper extends StatelessWidget {
  const CustomDrawerDataWrapper({Key? key}) : super(key: key);

  // Helper function to format Firestore Timestamp to a readable time.
  String formatLastLogin(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return DateFormat('hh:mm:ss a').format(dateTime);
    }
    return "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Drawer(child: Center(child: Text("No user logged in")));
    }

    final docStream =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: docStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Drawer(child: Center(child: Text("Error: ${snapshot.error}")));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Drawer(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Drawer(
            child: Center(child: Text("User document not found")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final userName = data['name'] ?? '';
        final userEmail = data['email'] ?? '';
        final accountCreationTime = user.metadata.creationTime;
        final formattedAccountCreation =
            accountCreationTime != null
                ? DateFormat(
                  'yyyy-MM-dd hh:mm:ss a',
                ).format(accountCreationTime)
                : "Unknown";

        return CustomDrawer(
          userName: userName,
          userEmail: userEmail,
          lastLogin:
              formattedAccountCreation, // Now shows account creation time
        );
      },
    );
  }
}

class MyAccountPage extends StatelessWidget {
  const MyAccountPage({Key? key}) : super(key: key);

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return "Unknown";
    return DateFormat('yyyy-MM-dd hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Account")),
        body: const Center(child: Text("No user logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Account")),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final userName = data['name'] ?? 'N/A';
          final userEmail = data['email'] ?? 'N/A';
          final accountCreation = formatDateTime(user.metadata.creationTime);
          final accountBalance = data['balance'] ?? '0.00';
          final accountNumber = data['accountNumber'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage('assets/user.jpg'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoTile("Account Number", accountNumber),
                _buildInfoTile("Account Balance", "$accountBalance"),
                _buildInfoTile("Account Created", accountCreation),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text("Log Out"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class BeneficiaryManagementPage extends StatelessWidget {
  const BeneficiaryManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beneficiary Management"),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Beneficiaries",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildBeneficiaryCard("John Doe", "1234567890", "XYZ Bank"),
                  _buildBeneficiaryCard("Jane Smith", "9876543210", "ABC Bank"),
                  _buildBeneficiaryCard(
                    "Michael Johnson",
                    "5678901234",
                    "LMN Bank",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Center(
                child: Text(
                  "Add Beneficiary",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficiaryCard(String name, String account, String bank) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.person, color: Color(0xFF1E3A8A)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$bank\nAcc: $account"),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ),
    );
  }
}

class LoanManagementPage extends StatelessWidget {
  const LoanManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Management'),
        backgroundColor: Color(0xFF1E3A8A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Loans',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: const [
                  LoanCard(
                    loanType: 'Home Loan',
                    amount: '\$120,000',
                    interestRate: '3.5%',
                    dueDate: '10/12/2025',
                    status: 'Ongoing',
                  ),
                  LoanCard(
                    loanType: 'Car Loan',
                    amount: '\$30,000',
                    interestRate: '5.2%',
                    dueDate: '05/08/2026',
                    status: 'Ongoing',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Apply for a New Loan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoanCard extends StatelessWidget {
  final String loanType;
  final String amount;
  final String interestRate;
  final String dueDate;
  final String status;

  const LoanCard({
    Key? key,
    required this.loanType,
    required this.amount,
    required this.interestRate,
    required this.dueDate,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loanType,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text('Amount: $amount', style: const TextStyle(fontSize: 16)),
            Text(
              'Interest Rate: $interestRate',
              style: const TextStyle(fontSize: 16),
            ),
            Text('Due Date: $dueDate', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            Text(
              'Status: $status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: status == 'Ongoing' ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlobalWalletPage extends StatelessWidget {
  const GlobalWalletPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Global Wallet Payment"),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Your Global Wallets",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildWalletCard("PayPal", "\$1,250.75", "assets/paypal.png"),
                  _buildWalletCard("Skrill", "€890.50", "assets/skrill.png"),
                  _buildWalletCard(
                    "Payoneer",
                    "£540.30",
                    "assets/payoneer.png",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Center(
                child: Text(
                  "Add New Wallet",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(String name, String balance, String assetPath) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Image.asset(assetPath, width: 40, height: 40),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Balance: $balance"),
        trailing: IconButton(
          icon: const Icon(Icons.send, color: Color(0xFF1E3A8A)),
          onPressed: () {},
        ),
      ),
    );
  }
}

class ApplyPage extends StatefulWidget {
  const ApplyPage({Key? key}) : super(key: key);

  @override
  _ApplyPageState createState() => _ApplyPageState();
}

class _ApplyPageState extends State<ApplyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Apply"),
        backgroundColor: Color(0xFF1E3A8A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Apply for Services",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildApplicationTile(
                    Icons.credit_card,
                    "Credit Card",
                    "Apply for a new credit card",
                  ),
                  _buildApplicationTile(
                    Icons.monetization_on,
                    "Loan",
                    "Apply for personal, home, or car loan",
                  ),
                  _buildApplicationTile(
                    Icons.account_balance,
                    "New Account",
                    "Open a new savings or checking account",
                  ),
                  _buildApplicationTile(
                    Icons.trending_up,
                    "Investment Plan",
                    "Invest in savings plans or mutual funds",
                  ),
                  _buildApplicationTile(
                    Icons.upload_file,
                    "Upload Documents",
                    "Submit necessary documents",
                  ),
                  _buildApplicationTile(
                    Icons.assignment,
                    "Application Status",
                    "Track the status of your applications",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationTile(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF1E3A8A), size: 30),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF1E3A8A)),
        onTap: () {
          // Navigate to specific application forms
        },
      ),
    );
  }
}
