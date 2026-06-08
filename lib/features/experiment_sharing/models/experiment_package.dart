import 'dart:convert';
import 'package:crypto/crypto.dart';

class ExperimentPackage {
  final Map<String, dynamic> manifest;
  final String author;
  final String version;
  final String signature;
  final int timestamp;

  ExperimentPackage({
    required this.manifest,
    required this.author,
    required this.version,
    required this.signature,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'manifest': manifest,
      'author': author,
      'version': version,
      'signature': signature,
      'timestamp': timestamp,
    };
  }

  factory ExperimentPackage.fromJson(Map<String, dynamic> json) {
    return ExperimentPackage(
      manifest: json['manifest'] as Map<String, dynamic>? ?? {},
      author: json['author'] ?? 'Unknown',
      version: json['version'] ?? '1.0.0',
      signature: json['signature'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Verifies if the signature matches the hash of the manifest + author + timestamp.
  bool get isSignatureValid {
    if (signature.isEmpty) return false;
    final payload = '${jsonEncode(manifest)}|$author|$timestamp';
    final computedSignature = sha256.convert(utf8.encode(payload)).toString();
    return signature == computedSignature;
  }

  /// Creates a new package with a computed signature.
  static ExperimentPackage create({
    required Map<String, dynamic> manifest,
    required String author,
    String version = '1.0.0',
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload = '${jsonEncode(manifest)}|$author|$timestamp';
    final signature = sha256.convert(utf8.encode(payload)).toString();

    return ExperimentPackage(
      manifest: manifest,
      author: author,
      version: version,
      signature: signature,
      timestamp: timestamp,
    );
  }
}
