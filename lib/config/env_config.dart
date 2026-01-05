/// Application environment configuration
enum AppEnvironment {
  local,  // Firebase Emulator (localhost)
  dev,    // Firebase dev project (online)
  prod,   // Firebase prod project (online)
}

class EnvConfig {
  static const String _envKey = String.fromEnvironment('ENV', defaultValue: 'local');

  static AppEnvironment get current {
    switch (_envKey) {
      case 'dev':
        return AppEnvironment.dev;
      case 'prod':
        return AppEnvironment.prod;
      case 'local':
      default:
        return AppEnvironment.local;
    }
  }

  static bool get isLocal => current == AppEnvironment.local;
  static bool get isDev => current == AppEnvironment.dev;
  static bool get isProd => current == AppEnvironment.prod;

  static String get name => _envKey;

  /// Firebase Emulator host
  /// - Web/macOS: localhost
  /// - Android emulator: 10.0.2.2 (to access host machine's localhost)
  /// - iOS simulator: localhost
  static String get emulatorHost {
    // For web platform, use localhost
    // This is determined at runtime using kIsWeb
    return 'localhost';
  }

  /// Firebase Emulator ports
  static int get firestorePort => 8080;
  static int get authPort => 9099;
  static int get realtimeDbPort => 9000;
  static int get emulatorUiPort => 4000;
}
