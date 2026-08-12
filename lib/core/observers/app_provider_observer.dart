import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_environment.dart';

/// Riverpod Observer to monitor state mutations and diagnose provider issues in debug builds.
class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (AppEnvironment.debugMode) {
      print('[RIVERPOD INIT] ${provider.name ?? provider.runtimeType}');
    }
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (AppEnvironment.debugMode) {
      print('[RIVERPOD UPDATE] ${provider.name ?? provider.runtimeType}');
    }
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    print('[RIVERPOD ERROR] ${provider.name ?? provider.runtimeType}: $error\n$stackTrace');
  }
}
