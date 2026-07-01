import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/core/providers/real_time_providers.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationThreadScreen extends ConsumerStatefulWidget {
  const ConversationThreadScreen({required this.conversation, super.key});

  final MessengerConversationPreview conversation;

  @override
  ConsumerState<ConversationThreadScreen> createState() =>
      _ConversationThreadScreenState();
}

class _ConversationThreadScreenState
    extends ConsumerState<ConversationThreadScreen> {
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markConversationRead();
    });
  }

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conversation')),
        body: const Center(child: Text('Sign in to access this conversation.')),
      );
    }

    final messagesAsync = ref.watch(
      messengerConversationMessagesProvider(widget.conversation.id),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(widget.conversation.avatarText),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    widget.conversation.isOnline ? 'Online' : 'Offline',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: widget.conversation.isOnline
                          ? Colors.green
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyThread();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == user.id;
                    return _MessageBubble(message: message, isMine: isMine);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to load messages: $error',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.muted),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildComposer(context, user.id),
        ],
      ),
    );
  }

  Widget _buildEmptyThread() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 52, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              'No messages yet',
              style: AppTextStyles.h4.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              'Start this conversation with your first message.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context, String userId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _composerController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(userId),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: const Color(0xFFF6F6F7),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSending ? null : () => _sendMessage(userId),
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Future<void> _markConversationRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    final doc = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversation.id);

    try {
      await doc.update({
        'unreadByUser.${user.id}': 0,
        'unreadCounts.${user.id}': 0,
      });
    } catch (_) {}
  }

  Future<void> _sendMessage(String userId) async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final firestore = FirebaseFirestore.instance;
    final conversationRef =
        firestore.collection('conversations').doc(widget.conversation.id);
    final messageRef = conversationRef.collection('messages').doc();

    try {
      final snapshot = await conversationRef.get();
      final data = snapshot.data() ?? <String, dynamic>{};
      final participants =
          List<String>.from(data['participantIds'] ?? const []);

      final batch = firestore.batch();
      final now = Timestamp.now();

      batch.set(messageRef, {
        'id': messageRef.id,
        'conversationId': widget.conversation.id,
        'text': text,
        'senderId': user.id,
        'senderName': user.name,
        'senderAvatar': user.photoUrl,
        'createdAt': now,
      });

      final updates = <String, dynamic>{
        'lastMessageText': text,
        'lastMessageAt': now,
        'updatedAt': now,
        'lastMessageSenderId': user.id,
        'unreadByUser.${user.id}': 0,
        'unreadCounts.${user.id}': 0,
      };

      for (final participantId in participants) {
        if (participantId == user.id) {
          continue;
        }
        updates['unreadByUser.$participantId'] = FieldValue.increment(1);
        updates['unreadCounts.$participantId'] = FieldValue.increment(1);
      }

      batch.set(conversationRef, updates, SetOptions(merge: true));
      await batch.commit();

      _composerController.clear();
      await _markConversationRead();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final MessengerConversationMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMine ? Colors.white : AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: AppTextStyles.bodySmall.copyWith(
                color: isMine
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
