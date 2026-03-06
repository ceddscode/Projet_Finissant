import 'dart:ui';
import 'package:flutter/material.dart';
import '../generated/l10n.dart';
import '../http/dtos/transfer.dart';
import '../http/lib_http.dart';
import 'common_widgets.dart';

/// Bottom sheet pour afficher les commentaires d'un incident
class CommentsSheet extends StatefulWidget {
  final int incidentId;

  const CommentsSheet({super.key, required this.incidentId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<CommentDTO> _comments = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  int? _newCommentId;
  int? _replyingToId;
  String? _replyingToName;

  void Function(String, CommentDTO)? _onReplySent;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(() {
      final threshold = _scrollController.position.maxScrollExtent - 200;
      if (_scrollController.position.pixels >= threshold) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
    _focusNode.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final message = _replyingToName != null ? '@$_replyingToName $text' : text;
    final wasReply = _replyingToId != null;

    try {
      final response = await postComment(widget.incidentId, message, _replyingToId);

      setState(() {
        _ctrl.clear();
        _replyingToId = null;
        _replyingToName = null;
      });

      if (!wasReply) {
        setState(() {
          _comments.insert(0, CommentDTO(
            id: response.id,
            citizenName: response.citizenName,
            message: response.message,
            repliesCount: response.repliesCount,
            likeCount: response.likeCount,
            isLiked: response.isLiked,
            isOwner: true,
            isReported: false,
          ));
          _newCommentId = response.id;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _newCommentId = null);
        });
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      } else {
        final cb = _onReplySent;
        _onReplySent = null;
        cb?.call('', response);
      }

      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _load() async {
    if (_loadingMore || !_hasMore) return;

    if (_page == 1) {
      setState(() => _loading = true);
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final items = await getComments(widget.incidentId, _page, 8);
      setState(() {
        _comments.addAll(items);
        _page++;
        _hasMore = items.length == 8;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _toggleLike(CommentDTO c) async {
    final idx = _comments.indexWhere((x) => x.id == c.id);
    if (idx == -1) return;

    final old = _comments[idx];
    setState(() {
      _comments[idx] = CommentDTO(
        id: old.id,
        citizenName: old.citizenName,
        message: old.message,
        repliesCount: old.repliesCount,
        likeCount: old.likeCount + (old.isLiked ? -1 : 1),
        isLiked: !old.isLiked,
        isOwner: old.isOwner,
        isReported: old.isReported,
      );
    });

    try {
      await toggleLikeComment(old.id);
    } catch (e) {
      setState(() => _comments[idx] = old);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _reply(
      int parentCommentId,
      String citizenName,
      void Function(String, CommentDTO) registerCallback,
      ) async {
    setState(() {
      _replyingToId = parentCommentId;
      _replyingToName = citizenName;
      _onReplySent = registerCallback;
    });
    _ctrl.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      minChildSize: 0.35,
      maxChildSize: 0.98,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 60),
                  child: const SheetHandle(),
                ),
              ),
              const SizedBox(height: 10),
              _buildHeader(),
              Expanded(child: _buildCommentsList(scrollCtrl)),
              _buildInputField(bottomInset),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          Text(s.comments, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCommentsList(ScrollController scrollCtrl) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _comments.length,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemBuilder: (context, index) => _CommentTile(
        key: ValueKey(_comments[index].id),
        comment: _comments[index],
        isNew: _comments[index].id == _newCommentId,
        onToggleLike: () => _toggleLike(_comments[index]),
        onReply: (citizenName, registerCallback) => _reply(
          _comments[index].id,
          citizenName,
          registerCallback,
        ),
        onDelete: (id) async {
          final idx = _comments.indexWhere((c) => c.id == id);
          if (idx == -1) return;
          final removed = _comments[idx];
          setState(() => _comments.removeWhere((c) => c.id == id));
          try {
            await deleteComment(id);
          } catch (e) {
            setState(() => _comments.insert(idx, removed));
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        },
        onReport: (id) {
          final idx = _comments.indexWhere((c) => c.id == id);
          if (idx == -1) return;
          final old = _comments[idx];
          setState(() {
            _comments[idx] = CommentDTO(
              id: old.id,
              citizenName: old.citizenName,
              message: old.message,
              repliesCount: old.repliesCount,
              likeCount: old.likeCount,
              isLiked: old.isLiked,
              isOwner: old.isOwner,
              isReported: true,
            );
          });
        },
      ),
    );
  }

  Widget _buildInputField(double bottomInset) {
    final s = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingToId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${s.replyingTo} $_replyingToName', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    _focusNode.unfocus();
                    setState(() {
                      _replyingToId = null;
                      _replyingToName = null;
                      _onReplySent = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomInset),
          child: Row(
            children: [
              const AnonymousAvatar(),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: _replyingToId != null ? s.addReply : s.addComment,
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: _send,
                child: Text(s.post),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CommentTile extends StatefulWidget {
  final CommentDTO comment;
  final VoidCallback onToggleLike;
  final void Function(String citizenName, void Function(String, CommentDTO)) onReply;
  final void Function(int commentId) onDelete;
  final void Function(int commentId) onReport;
  final bool isNew;

  const _CommentTile({
    super.key,
    required this.comment,
    required this.onToggleLike,
    required this.onReply,
    required this.onDelete,
    required this.onReport,
    required this.isNew,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplies = false;
  List<CommentDTO> _replies = [];
  bool _loading = false;
  int _repliesPage = 1;
  bool _hasMoreReplies = false;
  bool _hasBeenFetched = false;
  bool _loadingMore = false;
  int? _newReplyId;
  bool _isPressed = false;
  int? _pressedReplyId;
  CommentDTO? _pendingReply;

  // Censor bad words by replacing them with an emoji while preserving @mentions
  String _censorText(String input) {
    if (input.isEmpty) return input;
    // Keep mentions intact: we'll replace words only outside mentions
    // Define bad words (English + common French insults)
    final badWords = [
      'shit','fuck','bitch','asshole','damn','crap','nigga', 'nigger' , 'esti','tabarnak',
      'merde','putain','salope','encule','enculé','con','conne' ,'karl', 'wishlist' , 'eternal angler',
      'dih', 'dick', 'pussy', 'le mot en n' , 'cracker' , 'retard', 'retardé' , 'retardée',  'Aigrefin',
      'Basse‑cour',
      'Bigoterie',
      'Bebite',
      'Bebites',
      'Bonniche',
      'Boss des bécosses',
      'Boucher de Charlesbourg',
      'Bouffon',
      'Capitaine Bonhomme',
      'carpette',
      'Chien de poche',
      'Clown',
      'cocu des caquistes',
      'Deux de pique',
      'Ding et Dong',
      'Dupont',
      'Dupond',
      'eunuques',
      'Girouette',
      'Goon',
      'Hurluberlu',
      'jolin-barrettées',
      'Loser',
      'Lucky Luke du Twitter',
      'Mascotte',
      'Ministre de l’insécurité publique',
      'Nono',
      'Peddleur',
      'Pickpocket',
      'Pickpockets',
      'Raciste',
      'Shylock',
      'Tapis de porte',
      'Tête de Slinky',
      'Ti‑coune',
      'Ti‑Gus',
      'Yes man',
      'Contourner la loi',
      'Effronté',
      'Avoir du front',
      'C’est honteux',
      'Incapable',
      'Marie‑Antoinette des pauvres',
      'Niaiser',
      'Se parjurer',
      'Shame on him'

    ];

    // Build regex matching whole words for bad words
    final pattern = RegExp('\\b(' + badWords.map(RegExp.escape).join('|') + ')\\b', caseSensitive: false, unicode: true);

    // Replace function that keeps case-insensitive matches replaced with emoji
    String replacer(Match m) => '🤬';

    // We need to avoid replacing inside mentions: split by words starting with @
    // Approach: replace globally, but ensure @word patterns are not altered by post-processing
    // Simpler: perform replacement but skip segments that are mentions (tokens starting with '@')
    final parts = <String>[];
    final tokens = input.splitMapJoin(RegExp(r'(@[\w-]+)|([^@]+)'),
        onMatch: (m) {
          if (m.group(1) != null) {
            parts.add(m.group(1)!); // mention
            return '';
          } else {
            parts.add(m.group(2)!);
            return '';
          }
        }, onNonMatch: (s) => '');

    for (var i = 0; i < parts.length; i++) {
      final p = parts[i];
      if (p.startsWith('@')) continue; // leave mentions
      parts[i] = p.replaceAllMapped(pattern, (m) => replacer(m));
    }
    return parts.join();
  }

  void _showCommentMenu(
      BuildContext context, {
        required bool isOwner,
        required bool isReported,
        required VoidCallback onDelete,
        required VoidCallback onReport,
      }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, _, __) {
        return FadeTransition(
          opacity: animation,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 220,
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MenuOption(
                            icon: isReported ? Icons.flag : Icons.flag_outlined,
                            label: isReported ? 'Reported' : 'Report',
                            enabled: !isReported && !isOwner,
                            onTap: () {
                              Navigator.pop(ctx);
                              onReport();
                            },
                          ),
                          if (isOwner) ...[
                            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                            _MenuOption(
                              icon: Icons.delete_outline,
                              label: 'Delete',
                              color: Colors.red,
                              onTap: () {
                                Navigator.pop(ctx);
                                onDelete();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _insertReply(String citizenName, CommentDTO reply) {
    setState(() {
      _pendingReply = CommentDTO(
        id: reply.id,
        citizenName: reply.citizenName,
        message: reply.message,
        repliesCount: reply.repliesCount,
        likeCount: reply.likeCount,
        isLiked: reply.isLiked,
        isOwner: true,
        isReported: false,
      );
      _newReplyId = reply.id;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _newReplyId = null);
    });
  }

  void _toggleReplyLike(CommentDTO reply) async {
    if (_pendingReply?.id == reply.id) {
      final old = _pendingReply!;
      setState(() {
        _pendingReply = CommentDTO(
          id: old.id,
          citizenName: old.citizenName,
          message: old.message,
          repliesCount: old.repliesCount,
          likeCount: old.likeCount + (old.isLiked ? -1 : 1),
          isLiked: !old.isLiked,
          isOwner: old.isOwner,
          isReported: old.isReported,
        );
      });
      try {
        await toggleLikeComment(old.id);
      } catch (e) {
        setState(() => _pendingReply = old);
      }
      return;
    }

    final idx = _replies.indexWhere((r) => r.id == reply.id);
    if (idx == -1) return;

    final old = _replies[idx];
    setState(() {
      _replies[idx] = CommentDTO(
        id: old.id,
        citizenName: old.citizenName,
        message: old.message,
        repliesCount: old.repliesCount,
        likeCount: old.likeCount + (old.isLiked ? -1 : 1),
        isLiked: !old.isLiked,
        isOwner: old.isOwner,
        isReported: old.isReported,
      );
    });

    try {
      await toggleLikeComment(old.id);
    } catch (e) {
      setState(() => _replies[idx] = old);
    }
  }

  void _reportReply(CommentDTO reply) async {
    if (_pendingReply?.id == reply.id) {
      final old = _pendingReply!;
      setState(() {
        _pendingReply = CommentDTO(
          id: old.id,
          citizenName: old.citizenName,
          message: old.message,
          repliesCount: old.repliesCount,
          likeCount: old.likeCount,
          isLiked: old.isLiked,
          isOwner: old.isOwner,
          isReported: true,
        );
      });
      try {
        await reportComment(reply.id);
      } catch (e) {
        setState(() => _pendingReply = old);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }

    final idx = _replies.indexWhere((r) => r.id == reply.id);
    if (idx == -1) return;
    final old = _replies[idx];
    setState(() {
      _replies[idx] = CommentDTO(
        id: old.id,
        citizenName: old.citizenName,
        message: old.message,
        repliesCount: old.repliesCount,
        likeCount: old.likeCount,
        isLiked: old.isLiked,
        isOwner: old.isOwner,
        isReported: true,
      );
    });
    try {
      await reportComment(reply.id);
    } catch (e) {
      setState(() => _replies[idx] = old);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _loadReplies() async {
    if (_showReplies) {
      setState(() => _showReplies = false);
      return;
    }

    if (_hasBeenFetched) {
      setState(() => _showReplies = true);
      return;
    }

    setState(() => _loading = true);
    try {
      final replies = await getReplies(widget.comment.id, _repliesPage, 5);
      setState(() {
        _hasBeenFetched = true;
        final pending = _pendingReply;
        _pendingReply = null;
        final existingIds = replies.map((r) => r.id).toSet();
        _replies = [
          if (pending != null && !existingIds.contains(pending.id)) pending,
          ...replies,
        ];
        _repliesPage++;
        _hasMoreReplies = replies.length == 5;
        _showReplies = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Widget _buildReplyMessage(String message) {
    // If message starts with mention(s) keep them as-is and censor the rest.
    if (!message.startsWith('@')) {
      return Text(_censorText(message), style: const TextStyle(fontSize: 13));
    }

    final parts = message.split(' ');
    if (parts.length < 2) {
      return Text(_censorText(message), style: const TextStyle(fontSize: 13));
    }

    // collect leading mention tokens (starting with @)
    final mentionTokens = <String>[];
    int i = 0;
    while (i < parts.length && parts[i].startsWith('@')) {
      mentionTokens.add(parts[i]);
      i++;
    }

    final mention = mentionTokens.join(' ') + (mentionTokens.isNotEmpty ? ' ' : '');
    final rest = parts.sublist(i).join(' ');

    return RichText(
      text: TextSpan(
        children: [
          if (mentionTokens.isNotEmpty)
            TextSpan(
              text: mention,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 13,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
          TextSpan(
            text: _censorText(rest),
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyTile(CommentDTO reply) {
    final s = S.of(context);
    return GestureDetector(
      onLongPress: () {
        setState(() => _pressedReplyId = null);
        _showCommentMenu(
          context,
          isOwner: reply.isOwner,
          isReported: reply.isReported,
          onReport: () => _reportReply(reply),
          onDelete: () async {
            if (_pendingReply?.id == reply.id) {
              setState(() => _pendingReply = null);
              try {
                await deleteComment(reply.id);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
              return;
            }
            final idx = _replies.indexWhere((r) => r.id == reply.id);
            if (idx == -1) return;
            final removed = _replies[idx];
            setState(() => _replies.removeWhere((r) => r.id == reply.id));
            try {
              await deleteComment(reply.id);
            } catch (e) {
              setState(() => _replies.insert(idx, removed));
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
        );
      },
      onTapDown: (_) => setState(() => _pressedReplyId = reply.id),
      onTapUp: (_) => setState(() => _pressedReplyId = null),
      onTapCancel: () => setState(() => _pressedReplyId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(left: 44),
        decoration: BoxDecoration(
          color: _pressedReplyId == reply.id
              ? Colors.grey.withValues(alpha: 0.15)
              : reply.id == _newReplyId
              ? Colors.grey.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(7, 7, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AnonymousAvatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reply.citizenName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(height: 2),
                    _buildReplyMessage(reply.message),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => widget.onReply(reply.citizenName, _insertReply),
                      child: Text(
                        s.replyComment,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _toggleReplyLike(reply),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) => ScaleTransition(
                          scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                            CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                          ),
                          child: child,
                        ),
                        child: Icon(
                          reply.isLiked ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey(reply.isLiked),
                          size: 20,
                          color: reply.isLiked ? Colors.red : null,
                        ),
                      ),
                    ),
                  ),
                  if (reply.likeCount > 0)
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: Text(
                        '${reply.likeCount}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main comment row ──────────────────────────────────────────────
          GestureDetector(
            onLongPress: () {
              setState(() => _isPressed = false);
              _showCommentMenu(
                context,
                isOwner: widget.comment.isOwner,
                isReported: widget.comment.isReported,
                onReport: () async {
                  widget.onReport(widget.comment.id);
                  try {
                    await reportComment(widget.comment.id);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                onDelete: () async {
                  widget.onDelete(widget.comment.id);
                  try {
                    await deleteComment(widget.comment.id);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
              );
            },
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: _isPressed
                    ? Colors.grey.withValues(alpha: 0.15)
                    : widget.isNew
                    ? Colors.grey.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AnonymousAvatar(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.comment.citizenName, style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          _buildReplyMessage(widget.comment.message),
                          const SizedBox(height: 5),
                          InkWell(
                            onTap: () => widget.onReply(widget.comment.citizenName, _insertReply),
                            child: Text(
                              s.replyComment,
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.55),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (widget.comment.repliesCount > 0 || _pendingReply != null || _showReplies || _replies.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: InkWell(
                                onTap: _loading ? null : _loadReplies,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 30, height: 1, color: Colors.grey),
                                    const SizedBox(width: 12),
                                    if (_loading)
                                      const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2))
                                    else
                                      Text(
                                        _showReplies ? s.hideReplies : s.viewReplies,
                                        style: TextStyle(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: widget.onToggleLike,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) => ScaleTransition(
                                scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                                  CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                                ),
                                child: child,
                              ),
                              child: Icon(
                                widget.comment.isLiked ? Icons.favorite : Icons.favorite_border,
                                key: ValueKey(widget.comment.isLiked),
                                size: 20,
                                color: widget.comment.isLiked ? Colors.red : null,
                              ),
                            ),
                          ),
                        ),
                        if (widget.comment.likeCount > 0)
                          Transform.translate(
                            offset: const Offset(0, -6),
                            child: Text(
                              '${widget.comment.likeCount}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Pending reply (shown immediately after posting) ───────────────
          if (_pendingReply != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildReplyTile(_pendingReply!),
            ),

          // ── Fetched replies ───────────────────────────────────────────────
          if (_showReplies)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  ..._replies.map((reply) => _buildReplyTile(reply)),
                  if (_hasMoreReplies)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, left: 44),
                        child: InkWell(
                          onTap: _loadingMore ? null : () async {
                            setState(() => _loadingMore = true);
                            try {
                              final more = await getReplies(widget.comment.id, _repliesPage, 5);
                              setState(() {
                                final existingIds = _replies.map((r) => r.id).toSet();
                                final newReplies = more.where((r) => !existingIds.contains(r.id)).toList();
                                _replies.addAll(newReplies);
                                _repliesPage++;
                                _hasMoreReplies = more.length == 5;
                                _loadingMore = false;
                              });
                            } catch (e) {
                              setState(() => _loadingMore = false);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 30, height: 1, color: Colors.grey),
                              const SizedBox(width: 12),
                              if (_loadingMore)
                                const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2))
                              else
                                Text(
                                  s.loadMoreReplies,
                                  style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool enabled;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.enabled = true
  });

  @override
  Widget build(BuildContext context) {
    final c = enabled
        ? (color ?? Theme
        .of(context)
        .textTheme
        .bodyMedium
        ?.color)
        : Colors.grey.withValues(alpha: 0.4);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: c)),
          ],
        ),
      ),
    );
  }
}

