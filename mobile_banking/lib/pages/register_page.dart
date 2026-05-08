import 'dart:math';
import 'package:mobile_banking/utils/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  // Helper method to generate a random 16-digit card number
  String generateRandomCardNumber() {
    final random = Random();
    String cardNumber = '';
    for (int i = 0; i < 16; i++) {
      cardNumber += random.nextInt(10).toString();
    }
    return cardNumber;
  }

  void signUserUp() async {
    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Email validation regex
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    if (!emailRegex.hasMatch(email)) {
      showError("Please enter a valid email address.");
      return;
    }

    // Name validation
    if (name.isEmpty) {
      showError("Name cannot be empty.");
      return;
    }

    // Password match validation
    if (password != confirmPassword) {
      showError("Passwords do not match!");
      return;
    }

    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Create user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user != null) {
        await createUserDocument(user.uid, name, email);
        await addInitialCards(user.uid, name); // Pass the user's actual name
        if (dialogContext != null) {
          Navigator.pop(dialogContext!); // Close loading dialog
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      showError(e.toString()); // Show actual error message
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(message, style: TextStyle(color: Colors.black)),
          ),
        );
      },
    );
  }

  Future<void> createUserDocument(String uid, String name, String email) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'balance': 1000.0, // Initial balance
        'lastLogin': FieldValue.serverTimestamp(), // Save last login time
      });
    } catch (e) {
      showError("Failed to create user database: $e");
    }
  }

  Future<void> addInitialCards(String uid, String userName) async {
    try {
      // Preset list of bank details
      final List<Map<String, String>> bankDetails = [
        {'bankName': 'Chase', 'brand': 'Visa'},
        {'bankName': 'Bank of America', 'brand': 'Mastercard'},
        {'bankName': 'Wells Fargo', 'brand': 'Visa'},
      ];

      // Preset expiry dates for the cards
      final List<String> expiryDates = ['12/26', '06/25', '09/27'];

      for (int i = 0; i < bankDetails.length; i++) {
        final card = {
          'cardNumber': generateRandomCardNumber(),
          'cardHolder': userName,
          'expiryDate': expiryDates[i],
          'bankName': bankDetails[i]['bankName']!,
          'type': i % 2 == 0 ? 'Credit' : 'Debit', // alternate type for demo
          'brand': bankDetails[i]['brand']!,
          'userId': uid,
        };
        await FirebaseFirestore.instance.collection('cards').add(card);
      }
    } catch (e) {
      showError("Failed to add initial cards: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 50),
                Icon(Icons.lock, size: 100),
                SizedBox(height: 25),
                Text("Welcome! Let's create a new account for you"),
                SizedBox(height: 25),
                Textfield(
                  hintText: "Name",
                  obscureText: false,
                  controller: nameController,
                ),
                SizedBox(height: 25),
                Textfield(
                  hintText: "Email",
                  obscureText: false,
                  controller: emailController,
                ),
                SizedBox(height: 25),
                Textfield(
                  hintText: "Password",
                  obscureText: true,
                  controller: passwordController,
                ),
                SizedBox(height: 25),
                Textfield(
                  hintText: "Confirm Password",
                  obscureText: true,
                  controller: confirmPasswordController,
                ),
                SizedBox(height: 25),
                GestureDetector(
                  onTap: signUserUp,
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
                          "Sign up",
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
