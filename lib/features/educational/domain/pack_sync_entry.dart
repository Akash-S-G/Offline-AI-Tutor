class PackSyncEntry {
  final String packId;
  final String version;
  final String? hash;
  final String? downloadUrl;
  final String? manifestUrl;
  final DateTime? updatedAt;
  final int? sizeBytes;
  final int? grade;
  final String? subject;
  final String? language;

  const PackSyncEntry({
    required this.packId,
    required this.version,
    this.hash,
    this.downloadUrl,
    this.manifestUrl,
    this.updatedAt,
    this.sizeBytes,
    this.grade,
    this.subject,
    this.language,
  });

  factory PackSyncEntry.fromJson(Map<String, dynamic> json) {
    final packId = json['pack_id'] ?? json['packId'];
    if (packId == null || packId.toString().trim().isEmpty) {
      throw const FormatException(
        "Invalid PackSyncEntry: 'pack_id' is required but was null or empty.",
      );
    }

    final version = json['version']?.toString() ?? '1';
    final hash = json['hash'] ?? json['checksum'];
    final downloadUrl = json['download_url'] ?? json['downloadUrl'];
    final manifestUrl = json['manifest_url'] ?? json['manifestUrl'];

    if (hash == null)
      print('[SYNC_VERIFY] MISSING_FIELD field=hash packId=$packId');
    if (downloadUrl == null)
      print('[SYNC_VERIFY] MISSING_FIELD field=downloadUrl packId=$packId');
    if (manifestUrl == null)
      print('[SYNC_VERIFY] MISSING_FIELD field=manifestUrl packId=$packId');

    final updatedAtRaw = json['updated_at'] ?? json['updatedAt'];
    DateTime? updatedAt;
    if (updatedAtRaw != null) {
      updatedAt = DateTime.tryParse(updatedAtRaw.toString());
    } else {
      print('[SYNC_VERIFY] MISSING_FIELD field=updatedAt packId=$packId');
    }

    final sizeBytesRaw = json['size_bytes'] ?? json['sizeBytes'];
    int? sizeBytes;
    if (sizeBytesRaw != null) {
      sizeBytes = int.tryParse(sizeBytesRaw.toString());
    } else {
      print('[SYNC_VERIFY] MISSING_FIELD field=sizeBytes packId=$packId');
    }

    final gradeRaw = json['grade'] ?? json['grade_id'] ?? json['gradeId'];
    final grade = gradeRaw == null ? null : int.tryParse(gradeRaw.toString());
    final subject = json['subject']?.toString();
    final language = json['language']?.toString();

    final entry = PackSyncEntry(
      packId: packId.toString(),
      version: version,
      hash: hash?.toString(),
      downloadUrl: downloadUrl?.toString(),
      manifestUrl: manifestUrl?.toString(),
      updatedAt: updatedAt,
      sizeBytes: sizeBytes,
      grade: grade,
      subject: subject,
      language: language,
    );

    // Static flag to log only the first pack
    if (!_firstPackLogged) {
      print('[SYNC_VERIFY] FIRST_PACK=${entry.packId} v=${entry.version}');
      _firstPackLogged = true;
    }

    return entry;
  }

  static bool _firstPackLogged = false;
}
