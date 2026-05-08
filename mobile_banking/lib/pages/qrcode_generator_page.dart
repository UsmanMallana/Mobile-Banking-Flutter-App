import 'dart:typed_data';
import 'package:mobile_banking/utils/textfield.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // For QR code generation
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class QRCodeGeneratorPage extends StatefulWidget {
  const QRCodeGeneratorPage({Key? key}) : super(key: key);

  @override
  _QRCodeGeneratorPageState createState() => _QRCodeGeneratorPageState();
}

class _QRCodeGeneratorPageState extends State<QRCodeGeneratorPage> {
  final TextEditingController receiverController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final ScreenshotController screenshotController = ScreenshotController();

  String? qrData;

  void generateQRCode() {
    final receiver = receiverController.text.trim();
    final amountText = amountController.text.trim();

    // Email validation using regex
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    if (!emailRegex.hasMatch(receiver)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address.")),
      );
      return;
    }

    // Validate amount
    double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Amount must be a valid number greater than 0."),
        ),
      );
      return;
    }

    setState(() {
      qrData = "$receiver|$amount";
    });

    // Show the QR code dialog
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Generated QR Code"),
            content: Screenshot(
              controller: screenshotController,
              child: QrImageView(
                data: qrData!,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () async {
                  Uint8List? imageBytes = await screenshotController.capture();
                  if (imageBytes != null) {
                    // Use the image_gallery_saver_plus package
                    final result = await ImageGallerySaverPlus.saveImage(
                      imageBytes,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result != null
                              ? "Image saved to gallery!"
                              : "Failed to save image.",
                        ),
                      ),
                    );
                  }
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "Save QR Code",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap:
                    () =>
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop(), // Close dialog
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "Close",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    receiverController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generate QR Code")),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Textfield(
                  controller: receiverController,
                  hintText: "Enter receiver's email address",
                  obscureText: false,
                ),
                const SizedBox(height: 25),
                Textfield(
                  controller: amountController,
                  hintText: "Enter Amount",
                  obscureText: false,
                ),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: generateQRCode,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "Generate QR Code",
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
