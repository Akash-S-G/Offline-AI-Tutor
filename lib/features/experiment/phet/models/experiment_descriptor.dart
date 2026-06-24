enum ExperimentLaunchSource { installedPack, classroomGateway, bundledFallback }

class ExperimentDescriptor {
  const ExperimentDescriptor({
    required this.id,
    required this.slug,
    required this.title,
    required this.subject,
    required this.provider,
    required this.launchLocation,
    required this.launchSource,
    this.publicUrl,
  });

  final String id;
  final String slug;
  final String title;
  final String subject;
  final String provider;
  final String launchLocation;
  final ExperimentLaunchSource launchSource;
  final String? publicUrl;

  bool get isInstalled => launchSource == ExperimentLaunchSource.installedPack;
  bool get usesBundledAsset =>
      launchSource == ExperimentLaunchSource.bundledFallback;

  factory ExperimentDescriptor.fromPhetCatalog({
    required Map<String, dynamic> json,
    required String launchLocation,
    required ExperimentLaunchSource launchSource,
  }) {
    final manifest = json['manifest'] is Map<String, dynamic>
        ? json['manifest'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final slug = _string(json['slug']).isNotEmpty
        ? _string(json['slug'])
        : _slugFromId(_string(manifest['id']));
    final title = _string(manifest['title']).isNotEmpty
        ? _string(manifest['title'])
        : _titleFromSlug(slug);

    return ExperimentDescriptor(
      id: _string(manifest['id']).isNotEmpty
          ? _string(manifest['id'])
          : 'phet-$slug',
      slug: slug,
      title: title,
      subject: _string(manifest['subject']).isNotEmpty
          ? _string(manifest['subject'])
          : inferSubject(slug),
      provider: _string(manifest['provider']).isNotEmpty
          ? _string(manifest['provider'])
          : 'PhET',
      launchLocation: launchLocation,
      launchSource: launchSource,
      publicUrl: _nullableString(json['url']),
    );
  }

  factory ExperimentDescriptor.fromLegacyJson(Map<String, dynamic> json) {
    final id = _string(json['id']);
    return ExperimentDescriptor(
      id: id,
      slug: _slugFromId(id),
      title: _string(json['title']),
      subject: _string(json['subject']),
      provider: _string(json['provider']),
      launchLocation: _string(json['localPath']),
      launchSource: ExperimentLaunchSource.bundledFallback,
    );
  }

  static String inferSubject(String slug) {
    const chemistry = <String>{
      'acid-base-solutions',
      'balancing-chemical-equations',
      'beers-law-lab',
      'build-a-molecule',
      'build-an-atom',
      'molarity',
      'molecule-polarity',
      'molecule-shapes',
      'molecules-and-light',
      'ph-scale',
      'reactants-products-and-leftovers',
      'rutherford-scattering',
      'states-of-matter',
    };
    const mathematics = <String>{
      'arithmetic',
      'calculus-grapher',
      'curve-fitting',
      'plinko-probability',
    };
    const biology = <String>{'natural-selection', 'neuron'};

    if (chemistry.contains(slug)) return 'Chemistry';
    if (mathematics.contains(slug)) return 'Mathematics';
    if (biology.contains(slug)) return 'Biology';
    return 'Physics';
  }

  static String _slugFromId(String id) {
    return id.startsWith('phet-') ? id.substring(5) : id;
  }

  static String _titleFromSlug(String slug) {
    return slug
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static String? _nullableString(Object? value) {
    final string = _string(value);
    return string.isEmpty ? null : string;
  }
}

class PhetCatalogSnapshot {
  const PhetCatalogSnapshot({
    required this.experiments,
    required this.source,
    required this.packInstalled,
    this.message,
  });

  final List<ExperimentDescriptor> experiments;
  final ExperimentLaunchSource source;
  final bool packInstalled;
  final String? message;
}
