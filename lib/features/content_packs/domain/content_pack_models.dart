class ContentPackManifest {
  const ContentPackManifest({
    required this.packId,
    required this.title,
    required this.medium,
    required this.subject,
    required this.gradeMin,
    required this.gradeMax,
    required this.version,
    required this.manifestPath,
    required this.rootPath,
    required this.contentHash,
    required this.contentSizeBytes,
    required this.installedAt,
    this.status = 'installed',
  });

  final String packId;
  final String title;
  final String medium;
  final String subject;
  final int gradeMin;
  final int gradeMax;
  final int version;
  final String manifestPath;
  final String rootPath;
  final String contentHash;
  final int contentSizeBytes;
  final int installedAt;
  final String status;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pack_id': packId,
      'title': title,
      'medium': medium,
      'subject': subject,
      'grade_min': gradeMin,
      'grade_max': gradeMax,
      'version': version,
      'manifest_path': manifestPath,
      'root_path': rootPath,
      'content_hash': contentHash,
      'content_size_bytes': contentSizeBytes,
      'installed_at': installedAt,
      'status': status,
    };
  }

  factory ContentPackManifest.fromMap(Map<String, Object?> row) {
    return ContentPackManifest(
      packId: row['pack_id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      medium: row['medium'] as String? ?? '',
      subject: row['subject'] as String? ?? '',
      gradeMin: row['grade_min'] as int? ?? 0,
      gradeMax: row['grade_max'] as int? ?? 0,
      version: row['version'] as int? ?? 1,
      manifestPath: row['manifest_path'] as String? ?? '',
      rootPath: row['root_path'] as String? ?? '',
      contentHash: row['content_hash'] as String? ?? '',
      contentSizeBytes: row['content_size_bytes'] as int? ?? 0,
      installedAt: row['installed_at'] as int? ?? 0,
      status: row['status'] as String? ?? 'installed',
    );
  }
}

class ContentPackItem {
  const ContentPackItem({
    this.id,
    required this.packId,
    required this.kind,
    required this.title,
    required this.relativePath,
    required this.absolutePath,
    required this.sizeBytes,
    required this.orderIndex,
    this.grade,
    this.subject,
    this.medium,
    this.chapterId,
    this.languageCode,
    this.metadataJson,
  });

  final int? id;
  final String packId;
  final String kind;
  final String title;
  final String relativePath;
  final String absolutePath;
  final int sizeBytes;
  final int orderIndex;
  final int? grade;
  final String? subject;
  final String? medium;
  final String? chapterId;
  final String? languageCode;
  final String? metadataJson;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'pack_id': packId,
      'kind': kind,
      'title': title,
      'relative_path': relativePath,
      'absolute_path': absolutePath,
      'grade': grade,
      'subject': subject,
      'medium': medium,
      'chapter_id': chapterId,
      'language_code': languageCode,
      'order_index': orderIndex,
      'size_bytes': sizeBytes,
      'metadata_json': metadataJson,
    };
  }

  factory ContentPackItem.fromMap(Map<String, Object?> row) {
    return ContentPackItem(
      id: row['id'] as int?,
      packId: row['pack_id'] as String? ?? '',
      kind: row['kind'] as String? ?? '',
      title: row['title'] as String? ?? '',
      relativePath: row['relative_path'] as String? ?? '',
      absolutePath: row['absolute_path'] as String? ?? '',
      grade: row['grade'] as int?,
      subject: row['subject'] as String?,
      medium: row['medium'] as String?,
      chapterId: row['chapter_id'] as String?,
      languageCode: row['language_code'] as String?,
      orderIndex: row['order_index'] as int? ?? 0,
      sizeBytes: row['size_bytes'] as int? ?? 0,
      metadataJson: row['metadata_json'] as String?,
    );
  }
}

class ContentPackCatalogEntry {
  const ContentPackCatalogEntry({
    required this.manifest,
    required this.itemCount,
    required this.pdfCount,
    required this.videoCount,
    required this.quizCount,
    required this.otherCount,
  });

  final ContentPackManifest manifest;
  final int itemCount;
  final int pdfCount;
  final int videoCount;
  final int quizCount;
  final int otherCount;
}

class RequiredContentPackRule {
  const RequiredContentPackRule({
    required this.id,
    required this.title,
    required this.medium,
    required this.subject,
    required this.gradeMin,
    required this.gradeMax,
    this.minVersion = 1,
    this.mandatory = true,
  });

  final String id;
  final String title;
  final String medium;
  final String subject;
  final int gradeMin;
  final int gradeMax;
  final int minVersion;
  final bool mandatory;
}

class RequiredContentPackStatus {
  const RequiredContentPackStatus({
    required this.rule,
    required this.matchingPacks,
  });

  final RequiredContentPackRule rule;
  final List<ContentPackManifest> matchingPacks;

  bool get isSatisfied => matchingPacks.isNotEmpty;
}

class ContentPackReadinessReport {
  const ContentPackReadinessReport({required this.statuses});

  final List<RequiredContentPackStatus> statuses;

  int get requiredCount => statuses.where((status) => status.rule.mandatory).length;

  int get satisfiedRequiredCount => statuses
      .where((status) => status.rule.mandatory && status.isSatisfied)
      .length;

  int get missingRequiredCount => requiredCount - satisfiedRequiredCount;

  bool get isSchoolReady => missingRequiredCount == 0;

  List<RequiredContentPackStatus> get missingRequiredStatuses => statuses
      .where((status) => status.rule.mandatory && !status.isSatisfied)
      .toList(growable: false);
}
