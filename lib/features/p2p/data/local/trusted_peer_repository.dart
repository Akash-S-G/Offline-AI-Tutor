import '../../../course/data/local/app_database.dart';
import 'package:sqflite/sqflite.dart';

class TrustedPeer {
  const TrustedPeer({
    required this.address,
    required this.alternateAddress,
    required this.name,
    required this.transport,
    required this.addedAt,
  });

  final String address;
  final String? alternateAddress;
  final String name;
  final String transport;
  final int addedAt;
}

class TrustedPeerRepository {
  Future<void> trustPeer({
    required String address,
    String? alternateAddress,
    required String name,
    required String transport,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'trusted_peers',
      <String, Object>{
        'address': address,
        'alternate_address': alternateAddress ?? '',
        'name': name,
        'transport': transport,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> untrustPeer(String address) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'trusted_peers',
      where: 'address = ? OR alternate_address = ?',
      whereArgs: <Object>[address, address],
    );
  }

  Future<List<TrustedPeer>> listTrustedPeers() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'trusted_peers',
      orderBy: 'added_at DESC',
    );

    return rows
        .map(
          (row) => TrustedPeer(
            address: row['address'] as String,
            alternateAddress: (row['alternate_address'] as String?)?.trim().isEmpty == true
                ? null
                : row['alternate_address'] as String?,
            name: row['name'] as String? ?? 'Unknown Device',
            transport: row['transport'] as String? ?? 'unknown',
            addedAt: row['added_at'] as int? ?? 0,
          ),
        )
        .toList();
  }

  Future<Set<String>> listTrustedAddresses() async {
    final peers = await listTrustedPeers();
    final out = <String>{};
    for (final peer in peers) {
      out.add(peer.address);
      final alt = peer.alternateAddress;
      if (alt != null && alt.isNotEmpty) {
        out.add(alt);
      }
    }
    return out;
  }

  Future<bool> isTrustedSenderAddress(String senderAddress) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'trusted_peers',
      columns: const <String>['address'],
      where: 'address = ? OR alternate_address = ?',
      whereArgs: <Object>[senderAddress, senderAddress],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}