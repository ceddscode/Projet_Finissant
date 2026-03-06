import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:municipalgo/http/dtos/transfer.dart';
import 'package:flutter/widgets.dart';
import '../services/roleProvider.dart';
import 'dart:convert';
const String API_AZURE = 'https://serveurmunicipaligo-c6c7hbgbhsdugjag.canadacentral-01.azurewebsites.net';
const String API_LOCAL = 'http://10.0.2.2:5177';

// const String API_URL = API_AZURE;
const String API_URL = API_LOCAL;

class AuthStore {
  static String? token;
  static Function? onSessionExpired;
  static bool isLoggingOut = false;
}

bool isTokenExpired(String? token) {
  if (token == null) return true;
  try {
    return Jwt.isExpired(token);
  } catch (e) {
    return true;
  }
}
Future<CitizenBadgeProfileDTO> getMyBadges() async {
  if (isTokenExpired(AuthStore.token)) {
    throw ApiException(code: 'UNAUTHORIZED', message: 'Session expirée.', statusCode: 401);
  }

  try {
    final res = await SingletonDio.getDio().get('$API_URL/api/User/me/badges');
    return CitizenBadgeProfileDTO.fromJson(Map<String, dynamic>.from(res.data));
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}
class SingletonDio {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  )..interceptors.addAll([
    CookieManager(CookieJar()),
    InterceptorsWrapper(
      onError: (error, handler) {
        if (error.response?.statusCode == 401 && !AuthStore.isLoggingOut) {
          AuthStore.isLoggingOut = true;
          AuthStore.onSessionExpired?.call();
        }
        handler.next(error);
      },
    ),
  ]);

  static Dio getDio() => _dio;
}

String _extractRole(Map<String, dynamic> payload) {
  final direct = payload['role'];
  if (direct is String && direct.isNotEmpty) return direct;

  final roles = payload['roles'];
  if (roles is List && roles.isNotEmpty) return roles.first.toString();
  if (roles is String && roles.isNotEmpty) return roles;

  const schemaRole =
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';
  final schema = payload[schemaRole];
  if (schema is List && schema.isNotEmpty) return schema.first.toString();
  if (schema is String && schema.isNotEmpty) return schema;

  return '';
}

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  ApiException({required this.code, required this.message, this.statusCode});

  @override
  String toString() => message;
}

ApiException _mapDioException(DioException e) {
  final status = e.response?.statusCode;

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError) {
    return ApiException(
      code: 'NETWORK',
      message: 'Aucune connexion au serveur.',
    );
  }

  if (status == 401) {
    return ApiException(
      code: 'UNAUTHORIZED',
      message: 'Session expirée.',
      statusCode: status,
    );
  }

  if (status == 404) {
    return ApiException(
      code: 'NOT_FOUND',
      message: 'Ressource introuvable.',
      statusCode: status,
    );
  }

  if (status != null && status >= 500) {
    return ApiException(
      code: 'SERVER',
      message: 'Erreur du serveur.',
      statusCode: status,
    );
  }
else {
    return ApiException(
    code: 'HTTP',
    message: e.message ?? 'Erreur de connexion.',
    statusCode: status,
  );
  }
}

Future<EditUserDto> getMe() async {
  final res = await SingletonDio.getDio().get('$API_URL/api/User/me');
  return EditUserDto.fromJson(Map<String, dynamic>.from(res.data));
}

Future<EditUserDto> patchMe(EditUserDto dto) async {
  final res = await SingletonDio.getDio().patch(
    '$API_URL/api/User/me',
    data: dto.toJson(),
  );
  return EditUserDto.fromJson(Map<String, dynamic>.from(res.data));
}


Future<void> changeMyPassword(ChangePasswordDto dto) async {
  try {
    await SingletonDio.getDio().post(
      '$API_URL/api/User/me/change-password',
      data: dto.toJson(),
    );
  } on DioException catch (e) {
    final data = e.response?.data;
    if (data is Map && data['errors'] is List) {
      final msg = (data['errors'] as List).join('\n');
      throw Exception(msg);
    }
    throw Exception(e.message);
  }
}


// ================================================================================

Future<void> sendDeviceToken(String deviceToken) async {
  if (isTokenExpired(AuthStore.token)) {
    throw ApiException(code: 'UNAUTHORIZED', message: 'Session expirée.', statusCode: 401);
  }
  try {
    final language = _getSystemLanguage();
    await SingletonDio.getDio().post(
      '$API_URL/api/Notifications/deviceToken',
      data: {
        'deviceToken': deviceToken,
        'language': language,
      },
    );
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

String _getSystemLanguage() {
  if (isTokenExpired(AuthStore.token)) {
    throw ApiException(code: 'UNAUTHORIZED', message: 'Session expirée.', statusCode: 401);
  }
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  return locale.languageCode == 'fr' ? 'fr' : 'en';
}


Future<SubscriptionInfo> getSubscriptionInfos(int incidentId) async {
  if (isTokenExpired(AuthStore.token)) {
    throw ApiException(code: 'UNAUTHORIZED', message: 'Session expirée.', statusCode: 401);
  }
  try {
    final response = await SingletonDio.getDio().get(
      '$API_URL/api/Notifications/incidents/$incidentId/subscribe',
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiException(code: 'BAD_FORMAT', message: 'Format de réponse invalide.');
    }

    return SubscriptionInfo.fromJson(data);
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<SubscriptionInfo> toggleSubscriptionInfos(int incidentId) async {
  if (isTokenExpired(AuthStore.token)) {
    throw ApiException(code: 'UNAUTHORIZED', message: 'Session expirée.', statusCode: 401);
  }
  try {
    final response = await SingletonDio.getDio().post(
      '$API_URL/api/Notifications/incidents/$incidentId/subscribe/toggle',
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiException(code: 'BAD_FORMAT', message: 'Format de réponse invalide.');
    }

    return SubscriptionInfo.fromJson(data);
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<CommentDTO> postComment(int incidentId, String message, int? commentId) async {
  try {
    final response = await SingletonDio.getDio().post(
      '$API_URL/api/Comments/PostComment',
      queryParameters: {
        'incidentId': incidentId,
        'message': message,
        if (commentId != null)
          'commentId': commentId,
      },
    );

    return CommentDTO.fromJson(response.data);
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<List<CommentDTO>> getComments(int incidentId, int page, int pageSize) async {
  try {
    final response = await SingletonDio.getDio().get(
      '$API_URL/api/Comments/GetComments',
      queryParameters: {
        'incidentId': incidentId,
        'page': page,
        'pageSize': pageSize,
      },
    );

    final jsonList = response.data as List;

    return jsonList.map((e) {
      return CommentDTO.fromJson(e);
    }).toList();

  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<void> reportComment(int commentId) async {
  try {
    await SingletonDio.getDio().post(
      '$API_URL/api/Comments/ReportComment',
      queryParameters: {'commentId': commentId},
    );
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}


Future<void> deleteComment(int commentId) async {
  try {
    await SingletonDio.getDio().delete(
      '$API_URL/api/Comments/DeleteComment',
      queryParameters: {
        'commentId': commentId,
      },
    );
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<List<CommentDTO>> getReplies(int commentId, int page, int pageSize) async {
  try {
    final response = await SingletonDio.getDio().get(
      '$API_URL/api/Comments/GetReplies',
      queryParameters: {
        'commentId': commentId,
        'page': page,
        'pageSize': pageSize,
      },
    );

    final jsonList = response.data as List;

    return jsonList.map((e) {
      return CommentDTO.fromJson(e);
    }).toList();

  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

Future<void> toggleLikeComment(int commentId) async {
  try {
    await SingletonDio.getDio().put(
      '$API_URL/api/Comments/ToggleLikeComment',
      queryParameters: {'commentId': commentId},
    );
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}

// ================================================================================

Future<String> register({required Register registerInfo}) async {
  try {
    final response = await SingletonDio.getDio().post(
      '$API_URL/api/User/Register',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: registerInfo.toJson(),
    );

    final data = response.data;

    if (data is Map && data['message'] != null) {
      final errors = data['errors'];
      if (errors != null && errors is List) {
        return '${data['message']}\n${errors.join('\n')}';
      }
      return data['message'].toString();
    }

    return 'OK';
  } catch (e) {
    return 'Error: ${e.toString()}';
  }
}

Future<String> getTakeTask({required int id}) async {
  try {
    await SingletonDio.getDio().put(
      '$API_URL/api/Incidents/Assign/Take/$id',
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    return 'OK';
  } catch (e) {
    return 'Error: ${e.toString()}';
  }
}

Future<String> changeStatusToUnderRepair({required int id}) async {
  try {
    await SingletonDio.getDio().put(
      '$API_URL/api/Incidents/UnderRepair/$id',
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    return 'OK';
  } catch (e) {
    return 'Error: ${e.toString()}';
  }
}

Future<UserRole> login(
    {required Login loginInfo, required RoleProvider roleProvider}) async {
  try {
    final response = await SingletonDio.getDio().post(
      '$API_URL/api/User/Login',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'X-Client-Type': 'flutter',
        },
      ),
      data: loginInfo.toJson(),
    );

    final token = response.data?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception("Le serveur n'a pas renvoyé de token.");
    }

    AuthStore.token = token;
    SingletonDio.getDio().options.headers['Authorization'] = 'Bearer $token';

    final payload = Jwt.parseJwt(token);
    final roleString = _extractRole(payload);
    final userId = payload[
    'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
    final role = mapRole(roleString);

    await roleProvider.setUser(token: token, role: role, userId: userId, email: loginInfo.username);

    return role;
  } on DioException catch (e) {
    final data = e.response?.data;
    final msg = (data is Map && data['message'] != null)
        ? data['message'].toString()
        : 'Échec de la connexion';
    throw Exception(msg);
  } catch (e) {
    throw Exception('Erreur inattendue: $e');
  }
}

void restoreAuthFromProvider(RoleProvider provider) {
  if (provider.token != null) {
    AuthStore.token = provider.token;
    SingletonDio.getDio().options.headers['Authorization'] =
    'Bearer ${provider.token}';
  }
}
Future<List<Incident>> getAllIncidentsApi() async {
  try {
    final response = await SingletonDio.getDio().get(
      '$API_URL/api/Incidents/Validated',
    );

    // 🔍 PRINT STATUS + RAW DATA
    print('STATUS CODE: ${response.statusCode}');
    print('RESPONSE DATA: ${response.data}');

    final jsonList = response.data as List;
    print(jsonList.where((e) => e['latitude'] == null));
    print(jsonList.where((e) => e['longitude'] == null));
    return jsonList.map((e) {
      print('ITEM: $e'); // 👈 prints each incident JSON
      return Incident.fromJson(e);
    }).toList();

  } on DioException catch (e) {
    print('DIO ERROR STATUS: ${e.response?.statusCode}');
    print('DIO ERROR DATA: ${e.response?.data}');

    throw Exception(
      e.response?.data?['message'] ?? e.message ?? 'Failed to load incidents',
    );
  } catch (e) {
    print('UNEXPECTED ERROR: $e');
    throw Exception('Unexpected error: $e');
  }

}



Future<List<Incident>> getAllIncidents() async {
  try {
    final response = await SingletonDio.getDio().get(
      '$API_URL/api/Incidents/All',
    );

    // 🔍 PRINT STATUS + RAW DATA
    print('STATUS CODE: ${response.statusCode}');
    print('RESPONSE DATA: ${response.data}');

    final jsonList = response.data as List;
    print(jsonList.where((e) => e['latitude'] == null));
    print(jsonList.where((e) => e['longitude'] == null));
    return jsonList.map((e) {
      print('ITEM: $e'); // 👈 prints each incident JSON
      return Incident.fromJson(e);
    }).toList();

  } on DioException catch (e) {
    print('DIO ERROR STATUS: ${e.response?.statusCode}');
    print('DIO ERROR DATA: ${e.response?.data}');
    rethrow;
  } catch (e) {
    print('UNEXPECTED ERROR: $e');
    throw Exception('Unexpected error: $e');
  }
}
Future<List<String>> getQuartiersApi() async {
  try {
    final response = await SingletonDio.getDio().get('$API_URL/api/Incidents/Quartiers');

    final data = response.data;
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }

    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    }

    return [];
  } on DioException catch (_) {
    return [];
  }
}

Future<IncidentDetailsDTO> getIncidentDetails(int id) async {
  try {
    final response = await SingletonDio.getDio().get(
      '$API_URL/api/Incidents/$id',
    );

    return IncidentDetailsDTO.fromJson(response.data);
  } on DioException catch (e) {
    throw Exception(
      e.response?.data?['message'] ??
          e.message ??
          'Failed to load incident details',
    );
  } catch (e) {
    throw Exception('Unexpected error: $e');
  }
}

Future<List<Incident>> getBlueCollarApi() async {
  try {
    final response = await SingletonDio.getDio().get(
      '$API_URL/api/Incidents/MyAssignedIncidents',
    );

    if (response.data == null) return [];
    final jsonList = response.data as List;
    return jsonList.map((e) => Incident.fromJson(e)).toList();
  } on DioException catch (e) {
    throw Exception(
      e.response?.data?['message'] ??
          e.message ??
          'Failed to load assigned incidents',
    );
  } catch (e) {
    throw Exception('Unexpected error: $e');
  }
}



Future<List<Incident>> getSubbedIncidents() async {
  try {
    final response = await SingletonDio.getDio().get(
      '$API_URL/api/Incidents/MySubbedIncidents',
    );

    final data = response.data;

    dynamic parsed = data;
    if (data is String) {
      parsed = jsonDecode(data);
    }

    if (parsed is! List) {
      throw Exception('Bad response format: ${parsed.runtimeType}');
    }

    return parsed.map<Incident>((e) {
      if (e is String) {
        final decoded = jsonDecode(e);
        return Incident.fromJson(decoded as Map<String, dynamic>);
      }
      print(response.data.runtimeType);
      print(response.data);
      return Incident.fromJson(e as Map<String, dynamic>);
    }).toList();
  } on DioException catch (e) {
    throw Exception(
      e.response?.data?['message'] ??
          e.message ??
          'Failed to load subbed incidents',
    );
  }
}

Future<void> postProbleme(RequeteProblemeAvecPhotos req) async {
  try {
    final response = await SingletonDio.getDio().post(
      '$API_URL/api/Incidents/CreateIncident',
      data: req.toJson(),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    print(response.data);
  } on DioException catch (e) {
    print('status: ${e.response?.statusCode}');
    print('data: ${e.response?.data}');
    rethrow;
  }
}

Future<void> putConfirmIncident(RequeteConfirmIncident req) async {
  try {
    final response = await SingletonDio.getDio().put(
      '$API_URL/api/Incidents/ConfirmationRequest',
      data: req.toJson(),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    print(response.data);
  } on DioException catch (e) {
    print('status: ${e.response?.statusCode}');
    print('data: ${e.response?.data}');
    rethrow;
  }
}

Future<void> putLike(int id) async {
  try {
    final response = await SingletonDio.getDio().put(
      '$API_URL/api/Incidents/Like/$id',
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    print(response.data);
  } on DioException catch (e) {
    print('status: ${e.response?.statusCode}');
    print('data: ${e.response?.data}');
    rethrow;
  }
}

Future<List<IncidentHistoryDTO>> getIncidentHistory(int id) async {
  try {
    final response = await SingletonDio.getDio().get(
      '$API_URL/api/Incidents/IncidentHistory/$id',
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Bad response format: ${data.runtimeType}');
    }

    return data.map<IncidentHistoryDTO>((e) => IncidentHistoryDTO.fromJson(e)).toList();
  } on DioException catch (e) {
    throw Exception(
      e.response?.data?['message'] ??
          e.message ??
          'Failed to load incident history',
    );
  } catch (e) {
    throw Exception('Unexpected error: $e');
  }
}

Future<List<IncidentHistoryDTO>> getMyIncidentHistory() async {
  try {
    final response = await SingletonDio.getDio().get(
      '$API_URL/api/Incidents/MyIncidentHistory',
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Bad response format: ${data.runtimeType}');
    }

    return data.map<IncidentHistoryDTO>((e) => IncidentHistoryDTO.fromJson(e)).toList();
  } on DioException catch (e) {
    throw Exception(
      e.response?.data?['message'] ??
          e.message ??
          'Failed to load incident history',
    );
  } catch (e) {
    throw Exception('Unexpected error: $e');
  }
}
