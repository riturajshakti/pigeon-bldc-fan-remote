class AppInfo {
  static const author = 'Rituraj Shakti';
  static const email = 'riturajshakti@gmail.com';
  static const version = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  static const versionCode = String.fromEnvironment('APP_BUILD', defaultValue: '1');
}
