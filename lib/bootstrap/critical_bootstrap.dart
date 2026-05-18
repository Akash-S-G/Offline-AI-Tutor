import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'runtime_mode.dart';

class CriticalBootstrap {
  const CriticalBootstrap._();

  static void configureDesktopSqlite() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  static RuntimeMode resolveRuntimeMode() {
    return RuntimeModeResolver.resolve();
  }
}
