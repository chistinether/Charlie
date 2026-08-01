import 'dart:convert';
import 'dart:typed_data';

// A single document the user has uploaded, stored on-device (not in
// Firebase Storage). The raw bytes are kept so the file can be reopened
// later, and are base64-encoded when persisted via LocalStorageService so
// they survive app restarts.
class UserDocument {
  final String id;
  final String name;
  final Uint8List bytes;
  final DateTime uploadedAt;

  UserDocument({
    required this.id,
    required this.name,
    required this.bytes,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "bytes": base64Encode(bytes),
      "uploadedAt": uploadedAt.toIso8601String(),
    };
  }

  factory UserDocument.fromJson(Map<String, dynamic> json) {
    Uint8List decodedBytes;

    try {
      decodedBytes = base64Decode(json["bytes"]?.toString() ?? "");
    } catch (_) {
      decodedBytes = Uint8List(0);
    }

    return UserDocument(
      id: json["id"]?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json["name"]?.toString() ?? "Document",
      bytes: decodedBytes,
      uploadedAt:
          DateTime.tryParse(json["uploadedAt"]?.toString() ?? "") ??
              DateTime.now(),
    );
  }
}
