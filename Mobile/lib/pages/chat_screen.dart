import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/chat_signalr_service.dart';
import '../services/chat_api_service.dart';
import '../services/chat_notifier.dart';
import '../generated/l10n.dart';
import 'incident_details.dart';

const List<Color> avatarColors = [
  Color(0xFF6366f1), Color(0xFFf59e0b), Color(0xFF10b981),
  Color(0xFFec4899), Color(0xFF8b5cf6), Color(0xFF06b6d4), Color(0xFFf97316),
];

Color getAvatarColor(int id) => avatarColors[id % avatarColors.length];
String getInitial(String name) => name.isNotEmpty ? name[0].toUpperCase() : '?';

String getCategoryLabel(dynamic value, S s) {
  final key = value is String ? int.tryParse(value) : value as int?;
  switch (key) {
    case 0: return s.chatCategoryProprete;
    case 1: return s.chatCategoryMobilier;
    case 2: return s.chatCategorySignalisation;
    case 3: return s.chatCategoryEspacesVerts;
    case 4: return s.chatCategorySaisonnier;
    case 5: return s.chatCategorySocial;
    default: return value.toString();
  }
}

String getStatusLabel(dynamic value, S s) {
  final key = value is String ? int.tryParse(value) : value as int?;
  switch (key) {
    case 0: return s.chatStatusWaitingForValidation;
    case 1: return s.chatStatusWaitingForAssignation;
    case 2: return s.chatStatusAssignedToCitizen;
    case 3: return s.chatStatusUnderRepair;
    case 4: return s.chatStatusDone;
    case 5: return s.chatStatusAssignedToBlueCollar;
    case 6: return s.chatStatusWaitingForAssignationToCitizen;
    case 7: return s.chatStatusWaitingForConfirmation;
    default: return value.toString();
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.onUnreadCountChanged});
  final ValueChanged<int>? onUnreadCountChanged;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatSignalRService _signalR;
  late ChatApiService _api;

  List<Map<String, dynamic>> conversations = [];
  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> citizens = [];
  Map<String, dynamic>? activeConversation;

  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _citizenSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool loading = true;
  bool partnerTyping = false;
  bool showNewChat = false;
  String? _initError;
  bool _signalRConnected = false;

  @override
  void initState() {
    super.initState();
    _signalR = ChatSignalRService();
    _api = ChatApiService();
    _init();
  }

  void _notifyUnreadCount() {
    final total = conversations.fold<int>(
        0, (sum, c) => sum + (c['unreadCount'] as int? ?? 0));
    chatNotifier.setUnreadCount(total);
  }

  /// Ping the REST API to wake up Azure before SignalR connects.
  Future<void> _warmUpServer() async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint('[ChatScreen] Warm-up attempt $attempt...');
        await _api.getConversations();
        debugPrint('[ChatScreen] Server is awake!');
        return;
      } catch (e) {
        debugPrint('[ChatScreen] Warm-up attempt $attempt failed: $e');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    debugPrint('[ChatScreen] Warm-up gave up — will try SignalR anyway');
  }

  Future<void> _init() async {
    // 1. Warm up the server
    await _warmUpServer();

    // 2. Try to connect SignalR (not blocking if it fails)
    try {
      debugPrint('[ChatScreen] Connecting SignalR...');
      await _signalR.connect();
      _signalRConnected = true;
      debugPrint('[ChatScreen] SignalR connected!');
    } catch (e) {
      debugPrint('[ChatScreen] SignalR failed: $e — retrying in 5s...');
      await Future.delayed(const Duration(seconds: 5));
      try {
        await _signalR.connect();
        _signalRConnected = true;
        debugPrint('[ChatScreen] SignalR retry succeeded!');
      } catch (retryError) {
        debugPrint('[ChatScreen] SignalR retry also failed: $retryError');
        _signalRConnected = false;
        if (mounted) setState(() => _initError = 'Real-time unavailable');
      }
    }

    // 3. Always load conversations via REST (even if SignalR failed)
    await _loadConversations();

    // 4. Register SignalR event listeners only if connected
    if (!_signalRConnected) return;

    _signalR.onMessage((fromCitizenId, message, sentAt) {
      final isActive = activeConversation?['citizenId'] == fromCitizenId;

      setState(() {
        partnerTyping = false;

        if (isActive) {
          messages.add({
            'fromCitizenId': fromCitizenId,
            'message': message,
            'sentAt': sentAt.toIso8601String(),
          });
          final idx = conversations.indexWhere((c) => c['citizenId'] == fromCitizenId);
          if (idx >= 0) conversations[idx]['unreadCount'] = 0;
        } else {
          final idx = conversations.indexWhere((c) => c['citizenId'] == fromCitizenId);
          if (idx >= 0) {
            conversations[idx]['unreadCount'] = (conversations[idx]['unreadCount'] ?? 0) + 1;
          }
        }

        _updateConversationLastMessage(fromCitizenId, message, sentAt);
        _notifyUnreadCount();
      });

      if (isActive) _scrollToBottom();
    });

    _signalR.onIncident((fromCitizenId, incident, sentAt) async {
      final isActiveConv = activeConversation?['citizenId'] == fromCitizenId;

      setState(() {
        partnerTyping = false;

        var idx = conversations.indexWhere((c) => c['citizenId'] == fromCitizenId);
        if (idx < 0) {
          conversations.insert(0, {
            'citizenId': fromCitizenId,
            'name': S.current.unknown,
            'online': false,
            'lastMessage': '',
            'lastMessageTime': sentAt.toIso8601String(),
            'unreadCount': 0,
          });
          idx = 0;
        }

        if (isActiveConv) {
          messages.add({
            'fromCitizenId': fromCitizenId,
            'isMe': false,
            'sharedIncident': incident,
            'sentAt': sentAt.toIso8601String(),
          });
          conversations[idx]['unreadCount'] = 0;
        } else {
          conversations[idx]['unreadCount'] = (conversations[idx]['unreadCount'] ?? 0) + 1;
        }

        conversations[idx]['lastMessage'] = '';
        conversations[idx]['lastMessageTime'] = sentAt.toIso8601String();

        final conv = conversations.removeAt(idx);
        conversations.insert(0, conv);

        _notifyUnreadCount();
      });

      if (isActiveConv) {
        await _api.markAsRead(fromCitizenId);
        _scrollToBottom();
      }
    });

    _signalR.onTypingCleared(() {
      if (mounted) setState(() => partnerTyping = false);
    });

    _signalR.onPartnerOnline((online) {
      setState(() {
        if (activeConversation != null) activeConversation!['online'] = online;
      });
    });

    _signalR.onPartnerTyping(() {
      setState(() => partnerTyping = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => partnerTyping = false);
      });
    });

    _signalR.onNewConversation((fromCitizenId, fromName, message, sentAt) {
      setState(() {
        final exists = conversations.indexWhere((c) => c['citizenId'] == fromCitizenId);
        final isActive = activeConversation?['citizenId'] == fromCitizenId;
        if (exists >= 0) {
          conversations[exists]['lastMessage'] = message;
          conversations[exists]['lastMessageTime'] = sentAt.toIso8601String();
          if (!isActive) conversations[exists]['unreadCount']++;
          final conv = conversations.removeAt(exists);
          conversations.insert(0, conv);
        } else {
          conversations.insert(0, {
            'citizenId': fromCitizenId,
            'name': fromName,
            'online': true,
            'lastMessage': message,
            'lastMessageTime': sentAt.toIso8601String(),
            'unreadCount': isActive ? 0 : 1,
          });
        }
        _notifyUnreadCount();
        if (isActive) _api.markAsRead(fromCitizenId);
      });
    });
  }

  Future<void> _loadConversations() async {
    try {
      final data = await _api.getConversations();
      setState(() {
        conversations = data;
        if (activeConversation != null) {
          final idx = conversations.indexWhere(
                  (c) => c['citizenId'] == activeConversation!['citizenId']);
          if (idx >= 0) conversations[idx]['unreadCount'] = 0;
        }
        loading = false;
        _notifyUnreadCount();
      });
    } catch (e) {
      debugPrint('[ChatScreen] _loadConversations FAILED: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _selectConversation(Map<String, dynamic> conv) async {
    if (activeConversation != null && _signalRConnected) {
      await _signalR.closeConversation(activeConversation!['citizenId']);
    }

    final exists = conversations.any((c) => c['citizenId'] == conv['citizenId']);
    if (!exists) {
      setState(() => conversations.insert(0, conv));
    }

    setState(() {
      activeConversation = conv;
      conv['unreadCount'] = 0;
      _notifyUnreadCount();
      messages = [];
      partnerTyping = false;
    });

    if (_signalRConnected) {
      await _signalR.openConversation(conv['citizenId']);
    }
    await _api.markAsRead(conv['citizenId']);
    final msgs = await _api.getMessages(conv['citizenId']);
    setState(() => messages = msgs);
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || activeConversation == null) return;
    _msgController.clear();
    final now = DateTime.now();
    setState(() {
      partnerTyping = false;
      messages.add({
        'fromCitizenId': -1,
        'isMe': true,
        'message': text,
        'sentAt': now.toIso8601String(),
      });
      _updateConversationLastMessage(activeConversation!['citizenId'], text, now);
    });
    if (_signalRConnected) {
      await _signalR.sendMessage(activeConversation!['citizenId'], text);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Real-time unavailable — message not sent'), duration: Duration(seconds: 2)),
        );
      }
    }
    _scrollToBottom();
  }

  void _updateConversationLastMessage(int fromCitizenId, String message, DateTime sentAt) {
    final idx = conversations.indexWhere((c) => c['citizenId'] == fromCitizenId);
    if (idx >= 0) {
      conversations[idx]['lastMessage'] = message;
      conversations[idx]['lastMessageTime'] = sentAt.toIso8601String();
      final conv = conversations.removeAt(idx);
      conversations.insert(0, conv);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Future<void> _deleteConversation(Map<String, dynamic> conv) async {
    await _api.deleteConversation(conv['citizenId']);
    setState(() {
      conversations.removeWhere((c) => c['citizenId'] == conv['citizenId']);
      if (activeConversation?['citizenId'] == conv['citizenId']) {
        activeConversation = null;
        messages = [];
      }
    });
  }

  Future<void> _openNewChat() async {
    _citizenSearchController.clear();
    setState(() => showNewChat = true);
    final results = await _api.searchCitizens('');
    setState(() => citizens = results);
  }

  bool _isMyMessage(Map<String, dynamic> msg) {
    if (msg.containsKey('isMe')) return msg['isMe'] as bool;
    return msg['fromCitizenId'] != activeConversation?['citizenId'];
  }

  @override
  void dispose() {
    if (_signalRConnected) _signalR.disconnect();
    _msgController.dispose();
    _searchController.dispose();
    _citizenSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: activeConversation == null
                ? _buildConversationList(s)
                : _buildChatView(s),
          ),
          if (showNewChat) _buildNewChatModal(s),
        ],
      ),
    );
  }

  // ── Conversation List ──────────────────────────────────────────────────────

  Widget _buildConversationList(S s) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.chatMessages,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1a1a1a))),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 22, color: Color(0xFF4FA37A)),
                onPressed: _openNewChat,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: s.chatSearchConversations,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 4),
        if (_initError != null && !loading)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _initError!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() { loading = true; _initError = null; _signalRConnected = false; });
                    _init();
                  },
                  child: const Icon(Icons.refresh, size: 16, color: Colors.orange),
                ),
              ],
            ),
          ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4FA37A)))
              : conversations.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(s.chatNoConversations,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _openNewChat,
                  icon: const Icon(Icons.add, color: Color(0xFF4FA37A)),
                  label: Text(s.chatNewConversation,
                      style: const TextStyle(color: Color(0xFF4FA37A), fontWeight: FontWeight.w600)),
                )
              ],
            ),
          )
              : ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (_, i) => _buildConvItem(conversations[i], s),
          ),
        ),
      ],
    );
  }

  Widget _buildConvItem(Map<String, dynamic> conv, S s) {
    final citizenId = conv['citizenId'] as int;
    final name = conv['name'] as String;
    final online = conv['online'] as bool? ?? false;
    final lastMessage = conv['lastMessage'] as String? ?? '';
    final unread = conv['unreadCount'] as int? ?? 0;
    final timeStr = conv['lastMessageTime'] != null
        ? DateFormat.jm().format(DateTime.parse(conv['lastMessageTime']))
        : '';

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty &&
        !name.toLowerCase().contains(query) &&
        !lastMessage.toLowerCase().contains(query)) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key('conv_$citizenId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withOpacity(0.08),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => _deleteConversation(conv),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () => _selectConversation(conv),
        leading: Stack(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: getAvatarColor(citizenId),
            child: Text(getInitial(name),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (online)
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 11, height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFF4FA37A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ]),
        title: Text(name,
            style: TextStyle(
                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
                color: const Color(0xFF1a1a1a))),
        subtitle: Text(
          lastMessage.isEmpty ? s.chatSharedIncident : lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 12,
              color: unread > 0 ? const Color(0xFF1a1a1a) : Colors.grey,
              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            if (unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFF4FA37A),
                    borderRadius: BorderRadius.circular(9)),
                child: Text('$unread',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  // ── Chat View ──────────────────────────────────────────────────────────────

  Widget _buildChatView(S s) {
    final conv = activeConversation!;
    final name = conv['name'] as String;
    final online = conv['online'] as bool? ?? false;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF1a1a1a)),
                onPressed: () async {
                  await _signalR.closeConversation(conv['citizenId']);
                  setState(() {
                    activeConversation = null;
                    messages = [];
                  });
                },
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: getAvatarColor(conv['citizenId']),
                child: Text(getInitial(name),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1a1a1a))),
                    Text(
                      online ? s.chatOnline : s.chatOffline,
                      style: TextStyle(
                          fontSize: 12,
                          color: online ? const Color(0xFF4FA37A) : Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: messages.length + (partnerTyping ? 1 : 0),
            itemBuilder: (_, i) {
              if (partnerTyping && i == 0) return _buildTypingIndicator();
              final msgIndex = messages.length - 1 - (partnerTyping ? i - 1 : i);
              return _buildMessageBubble(messages[msgIndex], s);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file_rounded, size: 20, color: Color(0xFF4FA37A)),
                onPressed: _openIncidentPicker,
                tooltip: s.chatShareIncident,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _msgController,
                    maxLines: null,
                    onChanged: (_) {
                      if (activeConversation != null) {
                        _signalR.sendTyping(activeConversation!['citizenId']);
                      }
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: '${s.chatMessageHint} $name...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _msgController.text.trim().isNotEmpty ? _sendMessage : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _msgController.text.trim().isNotEmpty
                        ? const Color(0xFF4FA37A)
                        : const Color(0xFFE6E6E6),
                    shape: BoxShape.circle,
                    boxShadow: _msgController.text.trim().isNotEmpty
                        ? [BoxShadow(
                        color: const Color(0xFF4FA37A).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Icon(Icons.send_rounded,
                      size: 18,
                      color: _msgController.text.trim().isNotEmpty
                          ? Colors.white
                          : Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Message Bubbles ────────────────────────────────────────────────────────

  Widget _buildMessageBubble(Map<String, dynamic> msg, S s) {
    final isMe = _isMyMessage(msg);
    final sentAt = DateTime.parse(msg['sentAt'] as String);
    final partnerName = activeConversation?['name'] as String? ?? '';
    final partnerId = activeConversation?['citizenId'] as int? ?? 0;
    final incident = msg['sharedIncident'] as Map<String, dynamic>?;

    return Padding(
      padding: EdgeInsets.only(bottom: isMe ? 10 : 32),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Transform.translate(
              offset: const Offset(0, 25),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: getAvatarColor(partnerId),
                child: Text(
                  getInitial(partnerName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          incident != null
              ? _buildIncidentCard(incident, isMe, sentAt, s)
              : _buildTextBubble(msg['message'] as String, isMe, sentAt),
        ],
      ),
    );
  }

  Widget _buildTextBubble(String text, bool isMe, DateTime sentAt) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF4FA37A) : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(text,
              style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xFF1a1a1a),
                  fontSize: 14,
                  height: 1.4)),
          const SizedBox(height: 4),
          Text(DateFormat.jm().format(sentAt),
              style: TextStyle(fontSize: 10, color: isMe ? Colors.white60 : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident, bool isMe, DateTime sentAt, S s) {
    final photoUrl = incident['photoUrl'] as String?;
    final title = incident['title'] as String? ?? '';
    final location = incident['location'] as String? ?? '';
    final status = getStatusLabel(incident['status'], s);
    final category = getCategoryLabel(incident['category'], s);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => IncidentDetailsPage(incidentId: incident['id'] as int))),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(photoUrl,
                    height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Title on its own line
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1a1a1a))),
                  const SizedBox(height: 4),
                  // ✅ Status pill below title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FA37A).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4FA37A))),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.label_outline, size: 11, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(category,
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 11, color: Colors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(location,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(DateFormat.jm().format(sentAt),
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
                (i) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + i * 150),
              builder: (_, v, __) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6 + v * 3,
                decoration: BoxDecoration(
                    color: Colors.grey[400], borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Incident Picker ────────────────────────────────────────────────────────

  Future<void> _openIncidentPicker() async {
    final s = S.of(context);
    final incidents = await _api.getChatIncidents();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.chatShareIncident,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: incidents.isEmpty
                ? Center(child: Text(s.chatNoIncidents, style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: incidents.length,
              itemBuilder: (_, i) {
                final inc = incidents[i];
                final photoUrl = inc['photoUrl'] as String?;
                return ListTile(
                  onTap: () async {
                    Navigator.pop(context);
                    await _signalR.sendIncident(activeConversation!['citizenId'], inc['id'] as int);
                    final now = DateTime.now();
                    setState(() {
                      messages.add({
                        'fromCitizenId': -1,
                        'isMe': true,
                        'message': '',
                        'sentAt': now.toIso8601String(),
                        'sharedIncident': inc,
                      });
                      _updateConversationLastMessage(
                          activeConversation!['citizenId'], '', now);
                    });
                    _scrollToBottom();
                  },
                  leading: photoUrl != null && photoUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(photoUrl,
                        width: 44, height: 44, fit: BoxFit.cover),
                  )
                      : Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FA37A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.report_outlined,
                        color: Color(0xFF4FA37A), size: 22),
                  ),
                  title: Text(inc['title'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('📍 ${inc['location'] ?? ''}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FA37A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(getStatusLabel(inc['status'], s),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4FA37A))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── New Chat Modal ─────────────────────────────────────────────────────────

  Widget _buildNewChatModal(S s) {
    return GestureDetector(
      onTap: () => setState(() {
        showNewChat = false;
        _citizenSearchController.clear();
      }),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: Colors.black.withOpacity(0.35),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: MediaQuery.of(context).size.height * 0.55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.chatNewConversation,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF1a1a1a))),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                            onPressed: () => setState(() {
                              showNewChat = false;
                              _citizenSearchController.clear();
                            }),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _citizenSearchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: s.chatSearchPeople,
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (q) async {
                          final results = await _api.searchCitizens(q);
                          setState(() => citizens = results);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: citizens.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(s.chatNoPeople,
                            style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: citizens.length,
                        itemBuilder: (_, i) {
                          final c = citizens[i];
                          final online = c['online'] as bool? ?? false;
                          final name = c['name'] as String;
                          final id = c['id'] as int;
                          return ListTile(
                            onTap: () {
                              setState(() {
                                showNewChat = false;
                                _citizenSearchController.clear();
                              });
                              _selectConversation({
                                'citizenId': id,
                                'name': name,
                                'online': online,
                                'lastMessage': '',
                                'lastMessageTime': DateTime.now().toIso8601String(),
                                'unreadCount': 0,
                              });
                            },
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: getAvatarColor(id),
                              child: Text(getInitial(name),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF1a1a1a))),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: online
                                    ? const Color(0xFF4FA37A).withOpacity(0.1)
                                    : const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                online ? s.chatOnline : s.chatOffline,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: online
                                        ? const Color(0xFF4FA37A)
                                        : Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}