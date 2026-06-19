# 📚 Toddlers Stories Portal

Welcome to the **Toddlers Stories Portal** project. This repository contains a feature-rich, modern Flutter application designed for parents to browse, read, and share custom stories for toddlers and young children. 

This project is tailored specifically for the **Android** and **Web** platforms and is integrated with Firebase for story storage, metadata tracking, and parent authentication.

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
│   ├── screens/             # UI screen widgets (Dashboard, Story List, Profile, etc.)
│   ├── utils/               # App utilities and painters (e.g., Google Logo Painter)
│   ├── app_state.dart       # State management and Firestore controllers
│   └── main.dart            # Flutter application entry point
├── test/                    # Unit and widget tests
├── pubspec.yaml             # Flutter dependencies and configuration
└── .gitignore               # Configured to secure Firebase credentials
```

---

## 🌟 Features

### 📖 Read a Story Together
* **Browse by Age Group**: Interactive categorizations for **Ages 0-4**, **Ages 4-8**, and **Ages 8-12**.
* **Browse by Document Format**: Supports both **DOC Stories** (Word documents) and **PDF Stories** (PDF documents) for all age categories.

### 📤 Upload & Share Stories
* **Upload PDFs and Word Documents**: Logged-in parents can upload custom story files directly to the platform.
* **Smart Access Control (Visibility Settings)**:
  * **Everyone (Public)**: Open to all visitors.
  * **Logged-in Parents Only**: Visible only to registered users.
  * **Specific Parents**: Choose specific parents from a list of registered users in the database to grant access to the story.
* **Upload Progress Visuals**: Reactive progress bars tracking the file upload stream.

### 🔑 Authentication & Profiles
* **Multi-Method Login**: Supports Email/Password, Phone Number Verification, and Google Sign-in (for Web).
* **Profile Setup**: Custom displayName configurations and avatar generators matching parent names.

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

3. **Database & Storage Structures**:
   * **Firebase Storage Bucket**: `gs://toddlersstoriesfinalapp-et445s.firebasestorage.app`
     - Story files are uploaded dynamically to `stories/{categoryKey}/{timestamp}_{filename}`.
   * **Cloud Firestore**:
     - **`users` Collection**: `users/{uid}` contains parent profile documents (fields: `displayName`, `email`, `phoneNumber`, `updatedAt`).
     - **`stories` Collection**: `stories/{story_id}` contains story documents (fields: `name`, `fileName`, `url`, `storagePath`, `category`, `uploadedBy`, `uploadedAt`, `authorId`, `visibility`, `allowedUsers`).
