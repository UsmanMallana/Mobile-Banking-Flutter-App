import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRCodeReaderPage extends StatefulWidget {
  const QRCodeReaderPage({Key? key}) : super(key: key);

  @override
  _QRCodeReaderPageState createState() => _QRCodeReaderPageState();
}

class _QRCodeReaderPageState extends State<QRCodeReaderPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? barcode;
  QRViewController? controller;
  bool _dialogShown = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      // Only trigger if no dialog is shown yet.
      if (!_dialogShown && scanData.code != null) {
        setState(() {
          barcode = scanData;
          _dialogShown = true;
        });
        controller.pauseCamera();
        _showConfirmationDialog(scanData.code!);
      }
    });
  }

  Future<void> _showConfirmationDialog(String scannedData) async {
    // Expected format: "receiverEmail|amount"
    List<String> parts = scannedData.split("|");
    if (parts.length != 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid QR code format.")));
      setState(() {
        _dialogShown = false;
        barcode = null;
      });
      controller?.resumeCamera();
      return;
    }
    String receiverEmail = parts[0].trim();
    double amount;
    try {
      amount = double.parse(parts[1].trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid amount in QR code.")),
      );
      setState(() {
        _dialogShown = false;
        barcode = null;
      });
      controller?.resumeCamera();
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Amount must be greater than zero.")),
      );
      setState(() {
        _dialogShown = false;
        barcode = null;
      });
      controller?.resumeCamera();
      return;
    }

    // Show confirmation dialog
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Don't allow dismiss by tapping outside.
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Transaction'),
          content: Text(
            'Send \$${amount.toStringAsFixed(2)} to $receiverEmail?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _dialogShown = false;
                  barcode = null;
                });
                controller?.resumeCamera();
              },
            ),
            TextButton(
              child: const Text('Send'),
              onPressed: () {
                Navigator.of(context).pop();
                _initiateTransaction(receiverEmail, amount);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _initiateTransaction(String receiverEmail, double amount) async {
    final senderUid = FirebaseAuth.instance.currentUser?.uid;
    if (senderUid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No user logged in.")));
      setState(() {
        _dialogShown = false;
        barcode = null;
      });
      controller?.resumeCamera();
      return;
    }

    try {
      bool success = await transferMoney(senderUid, receiverEmail, amount);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction Successful!")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Insufficient funds!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Transaction Failed: $e")));
    }
    setState(() {
      _dialogShown = false;
      barcode = null;
    });
    controller?.resumeCamera();
  }

  Future<bool> transferMoney(
    String senderUid,
    String receiverEmail,
    double amount,
  ) async {
    final firestore = FirebaseFirestore.instance;
    // Get receiver's UID from email.
    final receiverUid = await getUserUidByEmail(receiverEmail);
    if (receiverUid == null) {
      throw Exception("User with email $receiverEmail not found!");
    }
    bool success = true;
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
      // Update balances.
      transaction.update(senderRef, {'balance': senderBalance - amount});
      transaction.update(receiverRef, {'balance': receiverBalance + amount});
      // Create a transaction record.
      final transactionRef = firestore.collection('transactions').doc();
      // Fetch names for record.
      final senderDoc =
          await firestore.collection('users').doc(senderUid).get();
      final senderName =
          senderDoc.exists
              ? (senderDoc.data()?['name'] as String? ?? 'Unknown')
              : 'Unknown';
      final receiverDoc =
          await firestore.collection('users').doc(receiverUid).get();
      final receiverName =
          receiverDoc.exists
              ? (receiverDoc.data()?['name'] as String? ?? 'Unknown')
              : 'Unknown';
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

  Future<String?> getUserUidByEmail(String email) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
    if (querySnapshot.docs.isEmpty) return null;
    return querySnapshot.docs.first.id;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan to Pay')),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Theme.of(context).primaryColor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child:
                  barcode != null
                      ? Text(
                        'Code has been scanned!',
                        style: const TextStyle(fontSize: 16),
                      )
                      : const Text(
                        'Scan a code',
                        style: TextStyle(fontSize: 16),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
