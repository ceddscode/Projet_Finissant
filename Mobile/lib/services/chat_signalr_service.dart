import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/foundation.dart';
import '../http/lib_http.dart';

class ChatSignalRService {
  late HubConnection _hub;

  final List<Function(int, String, DateTime)> _onMessageHandlers = [];
  final List<Function(bool)> _onPartnerOnlineHandlers = [];
  final List<Function()> _onPartnerTypingHandlers = [];
  final List<Function(int, String, String, DateTime)> _onNewConversationHandlers = [];
  final List<Function()> _onTypingClearedHandlers = [];
  final List<Function(int, Map<String, dynamic>, DateTime)> _onIncidentHandlers = [];

  Future<void> connect() async {
    debugPrint('[ChatSignalR] Connecting to $API_URL/hubs/chat');

    _hub = HubConnectionBuilder()
        .withUrl(
      '$API_URL/hubs/chat',
      options: HttpConnectionOptions(
        accessTokenFactory: () async => AuthStore.token ?? '',
        transport: HttpTransportType.WebSockets,
        skipNegotiation: true,
      ),
    )
        .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000, 30000])
        .build();

    _hub.serverTimeoutInMilliseconds = 60000;
    _hub.keepAliveIntervalInMilliseconds = 15000;

    _hub.onclose(({error}) {
      debugPrint('[ChatSignalR] Connection closed: $error');
    });

    _hub.onreconnecting(({error}) {
      debugPrint('[ChatSignalR] Reconnecting: $error');
    });

    _hub.onreconnected(({connectionId}) {
      debugPrint('[ChatSignalR] Reconnected: $connectionId');
    });

    _hub.off('ReceiveMessage');
    _hub.on('ReceiveMessage', (args) {
      if (args == null || args.length < 3) return;
      final fromCitizenId = args[0] as int;
      final message = args[1] as String;
      final sentAt = DateTime.parse(args[2] as String);
      for (final h in _onMessageHandlers) h(fromCitizenId, message, sentAt);
      _clearTyping();
    });

    _hub.off('ReceiveIncident');
    _hub.on('ReceiveIncident', (args) {
      if (args == null || args.length < 3) return;
      final fromCitizenId = args[0] as int;
      final incident = Map<String, dynamic>.from(args[1] as Map);
      final sentAt = DateTime.parse(args[2] as String);
      for (final h in _onIncidentHandlers) h(fromCitizenId, incident, sentAt);
      _clearTyping();
    });

    _hub.off('PartnerOnline');
    _hub.on('PartnerOnline', (args) {
      for (final h in _onPartnerOnlineHandlers) h(true);
    });

    _hub.off('PartnerOffline');
    _hub.on('PartnerOffline', (args) {
      for (final h in _onPartnerOnlineHandlers) h(false);
    });

    _hub.off('PartnerTyping');
    _hub.on('PartnerTyping', (args) {
      for (final h in _onPartnerTypingHandlers) h();
    });

    _hub.off('NewConversationMessage');
    _hub.on('NewConversationMessage', (args) {
      if (args == null || args.length < 4) return;
      final fromCitizenId = args[0] as int;
      final fromName = args[1] as String;
      final message = args[2] as String;
      final sentAt = DateTime.parse(args[3] as String);
      for (final h in _onNewConversationHandlers) {
        h(fromCitizenId, fromName, message, sentAt);
      }
    });

    await _hub.start();
    debugPrint('[ChatSignalR] Connected successfully! State: ${_hub.state}');
  }

  Future<List<Map<String, dynamic>>> getChatIncidents() async {
    final res = await SingletonDio.getDio().get('$API_URL/api/Chat/incidents');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<void> openConversation(int partnerCitizenId) async {
    await _hub.invoke('OpenConversation', args: [partnerCitizenId]);
  }

  Future<void> closeConversation(int partnerCitizenId) async {
    await _hub.invoke('CloseConversation', args: [partnerCitizenId]);
  }

  Future<void> sendMessage(int toCitizenId, String message) async {
    await _hub.invoke('SendMessage', args: [toCitizenId, message]);
  }

  Future<void> sendIncident(int toCitizenId, int incidentId) async {
    await _hub.invoke('SendIncident', args: [toCitizenId, incidentId]);
  }

  Future<void> sendTyping(int toCitizenId) async {
    await _hub.invoke('Typing', args: [toCitizenId]);
  }

  void onTypingCleared(Function() handler) =>
      _onTypingClearedHandlers.add(handler);

  void _clearTyping() {
    for (final h in _onTypingClearedHandlers) h();
  }

  void onIncident(Function(int, Map<String, dynamic>, DateTime) handler) =>
      _onIncidentHandlers.add(handler);
  void onMessage(Function(int, String, DateTime) handler) =>
      _onMessageHandlers.add(handler);
  void onPartnerOnline(Function(bool) handler) =>
      _onPartnerOnlineHandlers.add(handler);
  void onPartnerTyping(Function() handler) =>
      _onPartnerTypingHandlers.add(handler);
  void onNewConversation(Function(int, String, String, DateTime) handler) =>
      _onNewConversationHandlers.add(handler);

  Future<void> disconnect() async {
    await _hub.stop();
  }
}