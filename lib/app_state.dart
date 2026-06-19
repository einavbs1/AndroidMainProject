import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Profile data
  String customDisplayName = '';
  String profileImageUrl = 'https://ui-avatars.com/api/?name=User&background=6C63FF&color=fff';

  // Firebase integration
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // Check if current user profile is complete (has display name and phone number in Firestore)
  Future<bool> isCurrentProfileComplete() async {
    final uid = currentUid;
    if (uid == null) return false;

    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        final String name = data['displayName'] ?? '';
        final String phone = data['phoneNumber'] ?? '';
        return name.trim().isNotEmpty && phone.trim().isNotEmpty;
      }
    } catch (e) {
      debugPrint('Error checking profile completeness: $e');
    }
    return false;
  }
}
