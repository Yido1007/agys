class Settings {
  static String baseUrl = const String.fromEnvironment(
    'ANTREPO_BASE_URL',
    defaultValue: 'http://31.57.156.14:65060',
  );
}
