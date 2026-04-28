/// HTTP/HTTPS storage adapter for bundle I/O.
///
/// Implements [BundleStoragePort] using HTTP client for remote bundles.
/// Useful for loading bundles from registries or CDNs.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'bundle_storage_port.dart';
import 'exceptions.dart';

/// HTTP storage adapter implementing [BundleStoragePort].
///
/// Provides bundle storage operations over HTTP/HTTPS.
/// Supports authentication and custom headers.
class HttpStorageAdapter implements BundleStoragePort {
  /// HTTP client for making requests.
  final http.Client _client;

  /// Base URL for relative URIs.
  final String? baseUrl;

  /// Default headers to include in requests.
  final Map<String, String> headers;

  /// Authentication configuration.
  final HttpAuthConfig? auth;

  /// Request timeout duration.
  final Duration timeout;

  /// Create an HTTP storage adapter.
  ///
  /// If [baseUrl] is provided, relative URIs will be resolved against it.
  /// Custom [headers] will be included in all requests.
  /// [auth] configuration will be applied to authenticated requests.
  HttpStorageAdapter({
    http.Client? client,
    this.baseUrl,
    this.headers = const {},
    this.auth,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  /// Create an adapter for a specific registry.
  factory HttpStorageAdapter.registry(
    String registryUrl, {
    String? apiKey,
    Map<String, String>? headers,
  }) {
    return HttpStorageAdapter(
      baseUrl: registryUrl,
      headers: {
        ...?headers,
        if (apiKey != null) 'X-API-Key': apiKey,
      },
    );
  }

  String _resolveUrl(Uri uri) {
    if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return uri.toString();
    }
    if (baseUrl != null) {
      final base = baseUrl!.endsWith('/') ? baseUrl! : '$baseUrl/';
      return '$base${uri.toString()}';
    }
    throw BundleLoadException('Cannot resolve URI without base URL: $uri');
  }

  Map<String, String> _buildHeaders({bool json = true}) {
    final result = <String, String>{
      ...headers,
      if (json) 'Accept': 'application/json',
    };

    if (auth != null) {
      switch (auth!.type) {
        case HttpAuthType.bearer:
          result['Authorization'] = 'Bearer ${auth!.token}';
        case HttpAuthType.basic:
          final credentials = base64Encode(
            utf8.encode('${auth!.username}:${auth!.password}'),
          );
          result['Authorization'] = 'Basic $credentials';
        case HttpAuthType.apiKey:
          result[auth!.headerName ?? 'X-API-Key'] = auth!.token ?? '';
      }
    }

    return result;
  }

  @override
  Future<Map<String, dynamic>> readBundle(Uri uri) async {
    final url = _resolveUrl(uri);

    try {
      final response = await _client
          .get(Uri.parse(url), headers: _buildHeaders())
          .timeout(timeout);

      if (response.statusCode == 404) {
        throw BundleNotFoundException(uri);
      }

      if (response.statusCode != 200) {
        throw BundleReadException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          uri: uri,
        );
      }

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw BundleParseException('Bundle must be a JSON object');
      }
      return json;
    } on FormatException catch (e) {
      throw BundleParseException('Invalid JSON: ${e.message}');
    } on TimeoutException {
      throw BundleReadException('Request timeout', uri: uri);
    } on http.ClientException catch (e) {
      throw BundleReadException('HTTP error: ${e.message}', uri: uri);
    }
  }

  @override
  Future<void> writeBundle(Uri uri, Map<String, dynamic> data) async {
    final url = _resolveUrl(uri);

    try {
      final response = await _client
          .put(
            Uri.parse(url),
            headers: {
              ..._buildHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(timeout);

      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw BundleWriteException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } on TimeoutException {
      throw BundleWriteException('Request timeout', uri: uri);
    } on http.ClientException catch (e) {
      throw BundleWriteException('HTTP error: ${e.message}', uri: uri);
    }
  }

  @override
  Future<Uint8List> readAsset(Uri uri) async {
    final url = _resolveUrl(uri);

    try {
      final response = await _client
          .get(Uri.parse(url), headers: _buildHeaders(json: false))
          .timeout(timeout);

      if (response.statusCode == 404) {
        throw AssetNotFoundException(uri);
      }

      if (response.statusCode != 200) {
        throw BundleReadException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          uri: uri,
        );
      }

      return response.bodyBytes;
    } on TimeoutException {
      throw BundleReadException('Request timeout', uri: uri);
    } on http.ClientException catch (e) {
      throw BundleReadException('HTTP error: ${e.message}', uri: uri);
    }
  }

  @override
  Future<void> writeAsset(Uri uri, Uint8List data) async {
    final url = _resolveUrl(uri);

    try {
      final response = await _client
          .put(
            Uri.parse(url),
            headers: {
              ..._buildHeaders(json: false),
              'Content-Type': 'application/octet-stream',
            },
            body: data,
          )
          .timeout(timeout);

      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw BundleWriteException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } on TimeoutException {
      throw BundleWriteException('Request timeout', uri: uri);
    } on http.ClientException catch (e) {
      throw BundleWriteException('HTTP error: ${e.message}', uri: uri);
    }
  }

  @override
  Future<bool> exists(Uri uri) async {
    final url = _resolveUrl(uri);

    try {
      final response = await _client
          .head(Uri.parse(url), headers: _buildHeaders())
          .timeout(timeout);

      return response.statusCode == 200;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    }
  }

  @override
  Future<void> delete(Uri uri) async {
    final url = _resolveUrl(uri);

    try {
      final response = await _client
          .delete(Uri.parse(url), headers: _buildHeaders())
          .timeout(timeout);

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 404) {
        throw BundleWriteException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } on TimeoutException {
      throw BundleWriteException('Request timeout', uri: uri);
    } on http.ClientException catch (e) {
      throw BundleWriteException('HTTP error: ${e.message}', uri: uri);
    }
  }

  @override
  Future<List<Uri>> list(Uri directoryUri) async {
    final url = _resolveUrl(directoryUri);

    try {
      final response = await _client
          .get(Uri.parse(url), headers: _buildHeaders())
          .timeout(timeout);

      if (response.statusCode != 200) {
        return [];
      }

      final json = jsonDecode(response.body);

      // Expect a JSON array of URIs or objects with 'uri' field
      if (json is List) {
        return json.map((item) {
          if (item is String) {
            return Uri.parse(item);
          } else if (item is Map && item['uri'] != null) {
            return Uri.parse(item['uri'] as String);
          } else if (item is Map && item['path'] != null) {
            return Uri.parse(item['path'] as String);
          }
          return null;
        }).whereType<Uri>().toList();
      }

      return [];
    } on FormatException {
      return [];
    } on TimeoutException {
      return [];
    } on http.ClientException {
      return [];
    }
  }

  @override
  Stream<BundleChangeEvent>? watch(Uri uri) {
    // HTTP does not support real-time watching
    // Could potentially be implemented with SSE or WebSocket
    return null;
  }

  /// Close the HTTP client.
  void close() {
    _client.close();
  }
}

/// Authentication types for HTTP requests.
enum HttpAuthType {
  /// Bearer token authentication.
  bearer,

  /// Basic username/password authentication.
  basic,

  /// API key in header.
  apiKey,
}

/// HTTP authentication configuration.
class HttpAuthConfig {
  /// Authentication type.
  final HttpAuthType type;

  /// Token for bearer or API key auth.
  final String? token;

  /// Username for basic auth.
  final String? username;

  /// Password for basic auth.
  final String? password;

  /// Custom header name for API key auth.
  final String? headerName;

  const HttpAuthConfig.bearer(this.token)
      : type = HttpAuthType.bearer,
        username = null,
        password = null,
        headerName = null;

  const HttpAuthConfig.basic({
    required this.username,
    required this.password,
  })  : type = HttpAuthType.basic,
        token = null,
        headerName = null;

  const HttpAuthConfig.apiKey(
    this.token, {
    this.headerName = 'X-API-Key',
  })  : type = HttpAuthType.apiKey,
        username = null,
        password = null;
}
