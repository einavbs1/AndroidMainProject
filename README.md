# 🛠️ Service Management & Auth Ecosystem

Welcome to the **Service Management & Auth Ecosystem** project. This repository contains a feature-rich, modern Flutter application designed to provide seamless authentication, real-time service booking, profile editing, and document/resume management. 

This project is tailored specifically for the **Android** and **Web** platforms.

---

## 👥 Authors
* **Einav Momi Ben Shushan**
* **Chen Tzafir**

---

## 📁 Repository Structure

```text
AndroidMainProject/
├── android/                 # Android specific platform files
├── web/                     # Web specific platform files
├── lib/                     # Dart source code files
│   ├── screens/             # UI screen widgets (Login, Dashboard, etc.)
│   ├── utils/               # App utilities and painters
│   ├── app_state.dart       # State management and Firestore controllers
│   └── main.dart            # Flutter application entry point
├── test/                    # Unit and widget tests
├── pubspec.yaml             # Flutter dependencies and configuration
└── .gitignore               # Configured to secure Firebase credentials
```

---

## 🌟 Features

### Flutter Application (Android & Web)
The application is designed with modern glassmorphic/gradient aesthetics and features a fully integrated Firebase backend:
* **Advanced Authentication**: 
  * Phone Number Verification Login.
  * Standard Email/Password Sign Up and Login.
  * Customizable profile screen allowing users to edit display names and profile pictures.
* **Service Booking Dashboard**:
  * Book technicians for domestic services (Cleaning, Plumbing, AC Repair, Electrical).
  * Real-time sync with Cloud Firestore.
  * Advanced scheduling options (pick service date and 2-hour slots).
  * Booking list showing active status (with auto-detecting `LATE` indicator badge).
* **Reference Document Library**:
  * Access official service documents stored in Firebase Storage.
  * Premium custom download UI displaying download progress, last-updated metadata, and remote URL viewing.
* **Resume Management Center**:
  * Select PDF files using a native file picker.
  * Stream upload to Firebase Storage with reactive progress tracking.
  * Store resume metadata in Firestore user subcollections, enabling real-time retrieval, viewing, and deletion.

---

## 🚀 Getting Started & Installation

Make sure you have Flutter installed and configured on your system.

1. Fetch the required pub packages:
   ```bash
   flutter pub get
   ```

2. Run the application on your connected Android emulator, device, or web browser:
   * To run on Android:
     ```bash
     flutter run -d android
     ```
   * To run on Web:
     ```bash
     flutter run -d chrome
     ```

---

## 🔒 Firebase Configuration & Security

For security purposes, Firebase credential and configuration files are **ignored** by Git and are not stored in this repository.

To set up Firebase locally for this project:
1. **Google Services Configuration**:
   - Place your `google-services.json` inside the root directory `AndroidMainProject/` and `android/app/`.
2. **Firebase Options**:
   - Create/generate `lib/firebase_options.dart` using the FlutterFire CLI:
     ```bash
     flutterfire configure
     ```
3. **Database Configurations**:
   - **Firebase Storage Bucket**: Ensure your Storage bucket is configured. PDF documents should be placed at the root of the bucket for the reference document library.
   - **Cloud Firestore Collections**:
     - **Orders Collection**: `users/{uid}/orders/{order_id}` containing service details, timestamps, and order status.
     - **Resumes Collection**: `users/{uid}/resumes/{resume_id}` containing document metadata (storage path, url, timestamp, name).
