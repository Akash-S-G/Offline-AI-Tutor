import '../../../course/data/local/app_database.dart';
import 'package:sqflite/sqflite.dart';

class P2PSecuritySettingsRepository {
  static const String _kSharedSecret = 'shared_secret';
  static const String _kPreviousSharedSecret = 'previous_shared_secret';
  static const String _kPreviousSharedSecretExpiresAt =
      'previous_shared_secret_expires_at';
  static const String _kAutoAcceptTrustedUnknown = 'auto_accept_trusted_unknown';

  Future<String> getSharedSecret() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'p2p_settings',
      columns: const <String>['value'],
      where: 'key = ?',
      whereArgs: const <Object>[_kSharedSecret],
      limit: 1,
    );
    if (rows.isEmpty) {
      return '';
    }
    return rows.first['value'] as String? ?? '';
  }

  Future<void> setSharedSecret(String value) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'p2p_settings',
      <String, Object>{
        'key': _kSharedSecret,
        'value': value.trim(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>> getRotationStatus() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'p2p_settings',
      columns: const <String>['key', 'value'],
      where: 'key IN (?, ?, ?)',
      whereArgs: const <Object>[
        _kSharedSecret,
        _kPreviousSharedSecret,
        _kPreviousSharedSecretExpiresAt,
      ],
    );

    String current = '';
    String previous = '';
    int expiresAt = 0;
    for (final row in rows) {
      final key = row['key'] as String? ?? '';
      final value = row['value'] as String? ?? '';
      if (key == _kSharedSecret) {
        current = value;
      } else if (key == _kPreviousSharedSecret) {
        previous = value;
      } else if (key == _kPreviousSharedSecretExpiresAt) {
        expiresAt = int.tryParse(value) ?? 0;
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final previousActive = previous.isNotEmpty && expiresAt > now;
    return <String, dynamic>{
      'currentSecret': current,
      'previousSecret': previous,
      'previousSecretExpiresAt': expiresAt,
      'previousSecretActive': previousActive,
    };
  }

  Future<List<String>> getVerificationSecrets() async {
    final status = await getRotationStatus();
    final current = (status['currentSecret'] as String? ?? '').trim();
    final previous = (status['previousSecret'] as String? ?? '').trim();
    final previousActive = status['previousSecretActive'] as bool? ?? false;

    final out = <String>[];
    if (current.isNotEmpty) {
      out.add(current);
    }
    if (previousActive && previous.isNotEmpty && previous != current) {
      out.add(previous);
    }
    return out;
  }

  Future<void> rotateSharedSecret({
    required String newSecret,
    required Duration gracePeriod,
  }) async {
    final trimmed = newSecret.trim();
    if (trimmed.isEmpty) {
      throw Exception('New secret cannot be empty.');
    }

    final db = await AppDatabase.instance.database;
    final current = await getSharedSecret();
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + gracePeriod.inMilliseconds;

    await db.transaction((txn) async {
      if (current.isNotEmpty && current != trimmed) {
        await txn.insert(
          'p2p_settings',
          <String, Object>{
            'key': _kPreviousSharedSecret,
            'value': current,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.insert(
          'p2p_settings',
          <String, Object>{
            'key': _kPreviousSharedSecretExpiresAt,
            'value': expiresAt.toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await txn.insert(
        'p2p_settings',
        <String, Object>{
          'key': _kSharedSecret,
          'value': trimmed,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> clearExpiredPreviousSecret() async {
    final status = await getRotationStatus();
    final previousActive = status['previousSecretActive'] as bool? ?? false;
    if (previousActive) {
      return;
    }

    final db = await AppDatabase.instance.database;
    await db.delete(
      'p2p_settings',
      where: 'key IN (?, ?)',
      whereArgs: const <Object>[
        _kPreviousSharedSecret,
        _kPreviousSharedSecretExpiresAt,
      ],
    );
  }

  Future<bool> getAutoAcceptTrustedUnknown() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'p2p_settings',
      columns: const <String>['value'],
      where: 'key = ?',
      whereArgs: const <Object>[_kAutoAcceptTrustedUnknown],
      limit: 1,
    );
    if (rows.isEmpty) {
      return true;
    }
    return (rows.first['value'] as String? ?? '1') == '1';
  }

  Future<void> setAutoAcceptTrustedUnknown(bool value) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'p2p_settings',
      <String, Object>{
        'key': _kAutoAcceptTrustedUnknown,
        'value': value ? '1' : '0',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
