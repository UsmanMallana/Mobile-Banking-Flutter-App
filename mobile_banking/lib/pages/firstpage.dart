import 'package:mobile_banking/pages/drawerpages.dart';
import 'package:mobile_banking/pages/pages.dart';
import 'package:mobile_banking/pages/qrcode_generator_page.dart';
import 'package:mobile_banking/pages/qrcode_reader_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

bool isDarkMode = false;

void signUserOut() {
  FirebaseAuth.instance.signOut();
}

class Firstpage extends StatefulWidget {
  @override
  _FirstpageState createState() => _FirstpageState();
}

class _FirstpageState extends State<Firstpage> {
  int _selectedIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _onTabChange(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // For the home tab (index 0) we force the nested Navigator to rebuild when isDarkMode changes.
  Widget _buildOffstageNavigator(int index, Widget page) {
    Key navigatorKey =
        index == 0
            ? ValueKey(
              "nav_home_$isDarkMode",
            ) // Navigator rebuilds when isDarkMode changes
            : _navigatorKeys[index];
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: navigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(builder: (_) => page);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Persistent scaffold with AppBar and Bottom Navigation Bar.
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        elevation: 0,
        title: Image.asset('assets/icon.png', height: 40),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.brightness_6,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: toggleDarkMode,
          ),
        ],
      ),
      drawer: CustomDrawerDataWrapper(),
      body: Stack(
        children: [
          // For home tab, we also pass a key to HomePageDataWrapper (optional)
          _buildOffstageNavigator(
            0,
            HomePageDataWrapper(
              isDarkMode: isDarkMode,
              key: ValueKey(isDarkMode),
            ),
          ),
          _buildOffstageNavigator(1, ProfilePageDataWrapper()),
          _buildOffstageNavigator(2, SettingsPage()),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
        child: GNav(
          gap: 8,
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
          activeColor: isDarkMode ? const Color(0xFF1E3A8A) : Colors.white,
          tabBackgroundColor:
              isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
          padding: const EdgeInsets.all(16),
          selectedIndex: _selectedIndex,
          onTabChange: _onTabChange,
          tabs: const [
            GButton(icon: Icons.home, text: 'Home'),
            GButton(icon: Icons.person, text: 'Profile'),
            GButton(icon: Icons.settings, text: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class HomePageDataWrapper extends StatelessWidget {
  final bool isDarkMode;

  const HomePageDataWrapper({Key? key, required this.isDarkMode})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("No user is logged in."));
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
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("User document not found"));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final userName = data['name'] ?? '';
        final userEmail = data['email'] ?? '';
        double userBalance = double.parse(data['balance']) ?? 0.0;

        return HomePageContent(
          key: ValueKey(
            isDarkMode,
          ), // Rebuild HomePageContent when isDarkMode changes.
          userName: userName,
          userEmail: userEmail,
          balance: userBalance,
          isDarkMode: isDarkMode,
        );
      },
    );
  }
}

class HomePageContent extends StatelessWidget {
  final String userName;
  final String userEmail;
  final double balance;
  final bool isDarkMode;

  const HomePageContent({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.balance,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            "Welcome!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            color: isDarkMode ? null : const Color(0xFF1E3A8A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF252A34) : null,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "My Account:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  Text(
                    userEmail,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        balance.toString(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Image.asset(
                            isDarkMode
                                ? 'assets/visa_black.png'
                                : 'assets/visa_white.png',
                            height: 30,
                            width: 30,
                          ),
                          const SizedBox(width: 10),
                          Image.asset(
                            isDarkMode
                                ? 'assets/mastercard_black.png'
                                : 'assets/mastercard_white.png',
                            height: 30,
                            width: 30,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Text(
                    "Available balance",
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // GridView of menu items
          Expanded(
            child: GridView.builder(
              itemCount: menuItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => menuItems[index]['page'],
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Icon(
                        menuItems[index]['icon'],
                        size: 40,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF1E3A8A),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        menuItems[index]['label'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePageDataWrapper extends StatelessWidget {
  const ProfilePageDataWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Profile",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: const Center(child: Text("No user logged in")),
      );
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
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                "Profile",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                "Profile",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                "Profile",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: const Center(child: Text("User document not found")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final userName = data['name'] ?? '';
        final userEmail = data['email'] ?? '';

        return ProfilePageContent(
          userName: userName,
          userEmail: userEmail,
          uid: user.uid,
        );
      },
    );
  }
}

class ProfilePageContent extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String uid;

  const ProfilePageContent({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.uid,
  }) : super(key: key);

  void signUserOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(userEmail, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Name"),
              subtitle: Text(userName),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text("Email"),
              subtitle: Text(userEmail),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text("User ID"),
              subtitle: Text(uid),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => signUserOut(context),
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
                      "Sign out",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text("Privacy & Security"),
            onTap: () {
              // TODO: Navigate to privacy settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("Help & Support"),
            onTap: () {
              // TODO: Navigate to help/support page
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About"),
            onTap: () {
              // TODO: Navigate to about page
            },
          ),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> menuItems = [
  {'icon': Icons.send, 'label': 'Send Money', 'page': SendMoneyPage()},
  {
    'icon': Icons.receipt,
    'label': 'Transaction History',
    'page': TransactionHistoryPage(),
  },
  {
    'icon': Icons.qr_code,
    'label': 'Scan to Pay',
    'page': const QRCodeReaderPage(),
  },
  {
    'icon': Icons.qr_code,
    'label': 'Generate QR',
    'page': const QRCodeGeneratorPage(),
  },
  {
    'icon': Icons.credit_card,
    'label': 'Credit/Debit Cards',
    'page': CardsPage(),
  },
  {
    'icon': Icons.phone_android,
    'label': 'Mobile Recharge',
    'page': MobileRechargePage(),
  },
  {'icon': Icons.school, 'label': 'Education', 'page': EducationPage()},
  {
    'icon': Icons.shopping_cart,
    'label': 'Online Shopping',
    'page': OnlineShoppingPage(),
  },
  {'icon': Icons.money, 'label': 'Mutual Funds', 'page': MutualFundsPage()},
  {
    'icon': Icons.volunteer_activism,
    'label': 'Donations',
    'page': DonationsPage(),
  },
  {
    'icon': Icons.account_balance,
    'label': 'Account Usage',
    'page': AccountUsagePage(),
  },
  {'icon': Icons.location_on, 'label': 'Branch Locator', 'page': LocatorPage()},
];
