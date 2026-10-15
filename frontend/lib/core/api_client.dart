import 'package:dio/dio.dart';
import 'config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  final Map<String, String> fieldErrors;
  ApiException(this.message, {this.status, this.fieldErrors = const {}});

  bool get isUnauthorized => status == 401;
  bool get isNotFound => status == 404;

  /// Message plus any per-field validation messages.
  String get detailed => fieldErrors.isEmpty ? message : fieldErrors.entries.map((e) => '${e.key}: ${e.value}').join('\n');

  @override
  String toString() => message;
}

/// Single place that knows about HTTP: base URL, bearer token, error mapping, session expiry.
class ApiClient {
  final TokenStorage tokens;
  late final Dio _dio;
  String? _token;

  /// Called when the server answers 401 for a request that carried a token (expired / revoked session).
  void Function()? onUnauthorized;

  ApiClient(this.tokens) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) {
        if (_token != null) o.headers['Authorization'] = 'Bearer $_token';
        h.next(o);
      },
      onError: (e, h) {
        if (e.response?.statusCode == 401 && _token != null && !e.requestOptions.path.startsWith('/api/auth/login')) {
          onUnauthorized?.call();
        }
        h.next(e);
      },
    ));
  }

  Future<void> setToken(String? token) async {
    _token = token;
    if (token == null) {
      await tokens.clear();
    } else {
      await tokens.write(token);
    }
  }

  Future<String?> loadStoredToken() async {
    _token = await tokens.read();
    return _token;
  }

  bool get hasToken => _token != null;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _run(() => _dio.get(path, queryParameters: _clean(query)));
  Future<dynamic> post(String path, [Object? body]) => _run(() => _dio.post(path, data: body));
  Future<dynamic> put(String path, [Object? body]) => _run(() => _dio.put(path, data: body));
  Future<dynamic> patch(String path, [Object? body]) => _run(() => _dio.patch(path, data: body));
  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) => _run(() => _dio.delete(path, queryParameters: _clean(query)));

  Future<dynamic> upload(String path, String filePath, String fileName) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath, filename: fileName)});
    return _run(() => _dio.post(path, data: form));
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? q) {
    if (q == null) return null;
    return Map.fromEntries(q.entries.where((e) => e.value != null));
  }

  Future<dynamic> _run(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      return res.data;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  ApiException _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException('Cannot reach the server. Check your internet connection and that the backend is running.');
      default:
        break;
    }
    final data = e.response?.data;
    final status = e.response?.statusCode;
    if (data is Map) {
      final fields = <String, String>{};
      final fe = data['fieldErrors'];
      if (fe is Map) fe.forEach((k, v) => fields[k.toString()] = v.toString());
      return ApiException((data['message'] ?? 'Request failed').toString(), status: status, fieldErrors: fields);
    }
    return ApiException(status == null ? 'Unexpected network error' : 'Request failed ($status)', status: status);
  }
}
