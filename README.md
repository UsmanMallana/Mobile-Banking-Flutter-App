# Secure Mobile Banking App: Flutter & Firebase Architecture

## System Objective
This repository contains a full-stack, cross-platform mobile financial application built using the Flutter framework. It demonstrates the implementation of secure user authentication pipelines, reactive state management, and a real-time transaction engine powered by Firebase backend services.

## Interface Showcase
*Dashboard*

<div align="center">
  <!-- Drag and drop your .mp4/.mov or image files here in the GitHub editor -->
  <img width="288" height="621" alt="Dashboard Preview" src="https://github.com/user-attachments/assets/e1eba1b4-1f43-4f19-87d6-41ff8b9b8118" />
</div>

---

## System Architecture & Backend Integration

### 1. Frontend Framework (Flutter / Dart)
* **Cross-Platform UI:** Built with Flutter's Material Design widget tree to ensure native-level performance and a consistent, fluid UI across both iOS and Android devices.
* **Secure Routing:** Implements an authentication gatekeeper (`auth_page.dart`) that dynamically resolves the user's session state, routing them securely to the dashboard (`firstpage.dart`) or locking them out upon token expiration.

### 2. Backend Infrastructure (Firebase)
* **Authentication Pipeline (`firebase_auth`):** Handles encrypted credential verification, user registration, and secure session management.
* **Real-Time Transaction Engine (`cloud_firestore`):** Utilizes NoSQL cloud databases to instantly process and sync financial data. Account balances and transaction histories update dynamically via real-time listeners without requiring manual client-side refreshes.

---

## Quick Start Guide

### Prerequisites
* **Flutter SDK:** Version 3.0+ installed and configured on your machine.
* **Firebase Project:** You must have a Firebase project setup with Authentication and Firestore enabled.
* **IDE:** VS Code, Android Studio, or IntelliJ.

### Installation & Setup

1. **Clone the Repository:**
```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/Mobile-Banking-App.git
cd Mobile-Banking-App
```

2. **Install Dependencies:**
```bash
flutter pub get
```

3. **Configure Firebase Credentials:**
* **Android:** Download your `google-services.json` file from the Firebase console and place it in the `android/app/` directory.
* **iOS:** Download your `GoogleService-Info.plist` file and place it in the `ios/Runner/` directory via Xcode.

4. **Run the Application:**
Connect a physical device or launch an emulator, then execute:
```bash
flutter run
```

---
