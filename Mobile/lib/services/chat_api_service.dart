import '../http/lib_http.dart';

class ChatApiService {
  Future<List<Map<String, dynamic>>> getConversations() async {
    final res = await SingletonDio.getDio().get('$API_URL/api/Chat/conversations');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> getMessages(int partnerCitizenId, {int page = 1, int pageSize = 50}) async {
    final res = await SingletonDio.getDio().get(
      '$API_URL/api/Chat/messages/$partnerCitizenId',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> searchCitizens(String query) async {
    final res = await SingletonDio.getDio().get(
      '$API_URL/api/Chat/users',
      queryParameters: {'search': query},
    );
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> getChatIncidents() async {
    final res = await SingletonDio.getDio().get('$API_URL/api/Chat/incidents');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<void> markAsRead(int partnerCitizenId) async {
    await SingletonDio.getDio().post('$API_URL/api/Chat/messages/read/$partnerCitizenId');
  }

  Future<void> deleteConversation(int partnerCitizenId) async {
    await SingletonDio.getDio().delete('$API_URL/api/Chat/conversations/$partnerCitizenId');
  }
}