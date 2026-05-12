import 'pack_version_manager.dart';

class DeferredSyncManager {
  final List<PackManifest> _pending = [];

  void defer(PackManifest manifest) => _pending.add(manifest);

  List<PackManifest> drain() {
    final items = List<PackManifest>.from(_pending);
    _pending.clear();
    return items;
  }
}
