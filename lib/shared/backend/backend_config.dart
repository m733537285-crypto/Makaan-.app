class BackendConfig {
  const BackendConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.storageBucket,
    required this.requestTimeoutSeconds,
    required this.retryCount,
    required this.pageSize,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String storageBucket;
  final int requestTimeoutSeconds;
  final int retryCount;
  final int pageSize;

  bool get isConfigured => supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  Uri restUri(String table) => Uri.parse('${_cleanUrl(supabaseUrl)}/rest/v1/$table');

  Uri authUri(String path) => Uri.parse('${_cleanUrl(supabaseUrl)}/auth/v1/$path');

  Uri storageUri(String objectPath) => Uri.parse(
        '${_cleanUrl(supabaseUrl)}/storage/v1/object/$storageBucket/${_cleanPath(objectPath)}',
      );

  Uri publicStorageUri(String objectPath) => Uri.parse(
        '${_cleanUrl(supabaseUrl)}/storage/v1/object/public/$storageBucket/${_cleanPath(objectPath)}',
      );

  static BackendConfig fromEnvironment() {
    const String url = String.fromEnvironment('MAKAAN_SUPABASE_URL');
    const String anonKey = String.fromEnvironment('MAKAAN_SUPABASE_ANON_KEY');
    const String bucket = String.fromEnvironment(
      'MAKAAN_SUPABASE_STORAGE_BUCKET',
      defaultValue: 'makaan-media',
    );
    const int timeout = int.fromEnvironment(
      'MAKAAN_BACKEND_TIMEOUT_SECONDS',
      defaultValue: 20,
    );
    const int retries = int.fromEnvironment(
      'MAKAAN_BACKEND_RETRY_COUNT',
      defaultValue: 2,
    );
    const int pageSize = int.fromEnvironment(
      'MAKAAN_BACKEND_PAGE_SIZE',
      defaultValue: 200,
    );
    return BackendConfig(
      supabaseUrl: url,
      supabaseAnonKey: anonKey,
      storageBucket: bucket,
      requestTimeoutSeconds: timeout,
      retryCount: retries,
      pageSize: pageSize,
    );
  }

  static String _cleanUrl(String value) => value.endsWith('/') ? value.substring(0, value.length - 1) : value;

  static String _cleanPath(String value) => value.startsWith('/') ? value.substring(1) : value;
}
