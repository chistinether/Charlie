import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_document.dart';

// Replaces the previous (unfinished/broken) Firebase Storage integration.
//
// The profile photo and any uploaded documents are now kept entirely on
// the device via SharedPreferences, keyed per-user (by email) so that:
//   - switching between test users doesn't mix up their photos/documents
//   - data survives navigating away and back within the app
//   - data survives logging out and back in, and app restarts
//
// This is a "for now" local replacement - login/signup still go through
// Firebase Auth + Realtime Database as before.
class LocalStorageService {
  static String _photoKey(String email) => "local_photo_$email";
  static String _documentsKey(String email) => "local_documents_$email";

  // ---------------- PROFILE PHOTO ----------------

  static Future<void> savePhoto(String email, Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_photoKey(email), base64Encode(bytes));
  }

  static Future<Uint8List?> loadPhoto(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_photoKey(email));

    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deletePhoto(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoKey(email));
  }

  // ---------------- DOCUMENTS ----------------

  static Future<void> saveDocuments(
    String email,
    List<UserDocument> documents,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      documents.map((doc) => doc.toJson()).toList(),
    );

    await prefs.setString(_documentsKey(email), encoded);
  }

  static Future<List<UserDocument>> loadDocuments(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_documentsKey(email));

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List;

      return decoded
          .map(
            (item) => UserDocument.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearDocuments(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_documentsKey(email));
  }
}
