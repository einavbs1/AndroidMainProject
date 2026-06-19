# 🛠️ Service Management & Auth Ecosystem

Welcome to the **Service Management & Auth Ecosystem** project. This repository contains a feature-rich, modern Flutter mobile application designed to provide seamless authentication, real-time service booking, profile editing, and document/resume management.

---

## 👥 Authors
* **Einav Momi Ben Shushan**
* **Chen Tzafir**

---

## 📁 Repository Structure

```text
LEC04/
└── flutter_application_lec_04/  # Core Flutter mobile application
    ├── android/                 # Android specific platform files
    ├── ios/                     # iOS specific platform files
    ├── lib/                     # Dart source code files
    │   ├── screens/             # UI screen widgets (Login, Dashboard, Resumes, etc.)
    │   ├── app_state.dart       # State management and Firestore controllers
    │   └── main.dart            # Flutter application entry point
    └── pubspec.yaml             # Flutter dependencies and project configuration
```

---

## 🌟 Features

### Flutter Mobile Application
The mobile app is designed with modern glassmorphic/gradient aesthetics and features a fully integrated Firebase backend:
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

1. Navigate to the Flutter application directory:
   ```bash
   cd flutter_application_lec_04
   ```

2. Fetch the required pub packages:
   ```bash
   flutter pub get
   ```

3. Run the application on your connected emulator or device:
   ```bash
   flutter run
   ```

---

## 🔧 Backend Configuration (Firebase)

The application communicates with Firebase services using the following structure:
* **Firebase Storage Bucket**: `gs://androidnewapp.firebasestorage.app`
  * PDF documents should be uploaded to the root of the bucket.
  * User resumes are uploaded dynamically to `users/{uid}/resumes/{timestamp}_{filename}`.
* **Cloud Firestore Databases**:
  * **Orders Collection**: `users/{uid}/orders/{order_id}` containing service details, timestamps, and order status.
  * **Resumes Collection**: `users/{uid}/resumes/{resume_id}` containing document metadata (storage path, url, timestamp, name).
