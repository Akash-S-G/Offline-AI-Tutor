import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class BootstrapTokenPayload {
  const BootstrapTokenPayload({
    required this.secret,
    required this.createdAt,
    required this.expiresAt,
    required this.nonce,
  });

  final String secret;
  final int createdAt;
  final int expiresAt;
  final String nonce;
}

class P2PSecretBootstrapService {
  String createBootstrapToken({
    required String sharedSecret,
    required String passcode,
    required Duration ttl,
  }) {
    final secret = sharedSecret.trim();
    final pin = passcode.trim();
    if (secret.isEmpty || pin.isEmpty) {
      throw Exception('Secret and passcode are required for bootstrap token.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + ttl.inMilliseconds;
    final nonceBytes = _randomBytes(16);
    final nonce = base64UrlEncode(nonceBytes);

    final key = _deriveKey(passcode: pin, nonce: nonce);
    final cipherBytes = _xorBytes(utf8.encode(secret), key);
    final cipherText = base64UrlEncode(cipherBytes);

    final metadata = <String, dynamic>{
      'version': 1,
      'createdAt': now,
      'expiresAt': expiresAt,
      'nonce': nonce,
      'cipher': cipherText,
      'algo': 'xor+sha256+hmac',
    };

    final canonical = jsonEncode(metadata);
    final mac = Hmac(sha256, utf8.encode(pin)).convert(utf8.encode(canonical)).toString();

    final token = <String, dynamic>{
      'metadata': metadata,
      'mac': mac,
    };

    final tokenJson = jsonEncode(token);
    return base64UrlEncode(utf8.encode(tokenJson));
  }

  BootstrapTokenPayload importBootstrapToken({
    required String token,
    required String passcode,
  }) {
    final rawToken = token.trim();
    final pin = passcode.trim();
    if (rawToken.isEmpty || pin.isEmpty) {
      throw Exception('Token and passcode are required.');
    }

    final decodedJson = utf8.decode(base64Url.decode(base64Url.normalize(rawToken)));
    final decoded = jsonDecode(decodedJson) as Map<String, dynamic>;
    final metadata = decoded['metadata'] as Map<String, dynamic>?;
    final mac = decoded['mac'] as String? ?? '';
    if (metadata == null || mac.isEmpty) {
      throw Exception('Invalid bootstrap token format.');
    }

    final canonical = jsonEncode(metadata);
    final expectedMac = Hmac(sha256, utf8.encode(pin)).convert(utf8.encode(canonical)).toString();
    if (expectedMac != mac) {
      throw Exception('Bootstrap token verification failed. Wrong passcode or tampered token.');
    }

    final nonce = metadata['nonce'] as String? ?? '';
    final cipher = metadata['cipher'] as String? ?? '';
    final createdAt = metadata['createdAt'] as int? ?? 0;
    final expiresAt = metadata['expiresAt'] as int? ?? 0;
    if (nonce.isEmpty || cipher.isEmpty || createdAt <= 0 || expiresAt <= 0) {
      throw Exception('Bootstrap token payload is incomplete.');
    }

    if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
      throw Exception('Bootstrap token has expired.');
    }

    final key = _deriveKey(passcode: pin, nonce: nonce);
    final cipherBytes = base64Url.decode(base64Url.normalize(cipher));
    final plainBytes = _xorBytes(cipherBytes, key);
    final secret = utf8.decode(plainBytes).trim();
    if (secret.isEmpty) {
      throw Exception('Bootstrap token does not contain a valid secret.');
    }

    return BootstrapTokenPayload(
      secret: secret,
      createdAt: createdAt,
      expiresAt: expiresAt,
      nonce: nonce,
    );
  }

  Uint8List _deriveKey({required String passcode, required String nonce}) {
    final material = utf8.encode('$passcode::$nonce');
    final digest = sha256.convert(material).bytes;
    return Uint8List.fromList(digest);
  }

  Uint8List _xorBytes(List<int> source, List<int> key) {
    final out = Uint8List(source.length);
    for (var i = 0; i < source.length; i++) {
      out[i] = source[i] ^ key[i % key.length];
    }
    return out;
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
