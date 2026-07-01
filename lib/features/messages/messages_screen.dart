import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/providers/real_time_providers.dart';
import 'conversation_thread_screen.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// MESSAGES SCREEN
/// Direct messaging with sellers, customer support, and other members
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            '💬 Messages',
            style: AppTextStyles.h3.copyWith(color: AppColors.text),
          ),
        ),
        body: _buildLoginPrompt(),
      );
    }

    final conversationsAsync =
        ref.watch(messengerConversationsProvider(user.id));
    final conversations = conversationsAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <MessengerConversationPreview>[],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '💬 Messages',
          style: AppTextStyles.h3.copyWith(color: AppColors.text),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, conversations),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context, user.id, conversations),
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final chat = items[index];
              return _buildChatTile(context, chat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildChatTile(
      BuildContext context, MessengerConversationPreview chat) {
    final hasUnread = chat.unreadCount > 0;

    return Column(
      children: [
        ListTile(
          leading: Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    chat.avatarText,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              if (chat.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            chat.title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            chat.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: hasUnread ? AppColors.text : AppColors.muted,
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _relativeTime(chat.updatedAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.muted,
                ),
              ),
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${chat.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () => _openChat(context, chat),
        ),
        Divider(
          height: 1,
          indent: 72,
          endIndent: 16,
          color: AppColors.border,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: AppColors.muted,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: AppTextStyles.h4.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with sellers or support',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              'Unable to load messages',
              style: AppTextStyles.h4.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              'Sign in to view your messages',
              textAlign: TextAlign.center,
              style: AppTextStyles.h4.copyWith(color: AppColors.text),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context, MessengerConversationPreview chat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationThreadScreen(conversation: chat),
      ),
    );
  }

  void _showSearchDialog(
    BuildContext context,
    List<MessengerConversationPreview> conversations,
  ) {
    var query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final trimmed = query.trim().toLowerCase();
            final filtered = trimmed.isEmpty
                ? conversations
                : conversations.where((chat) {
                    return chat.title.toLowerCase().contains(trimmed) ||
                        chat.lastMessage.toLowerCase().contains(trimmed);
                  }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      onChanged: (value) => setState(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'Search by name or message...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No conversations found',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.muted),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(
                                color: AppColors.border,
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final chat = filtered[index];
                                return ListTile(
                                  leading: Text(
                                    chat.avatarText,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  title: Text(chat.title),
                                  subtitle: Text(
                                    chat.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    _openChat(context, chat);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMoreOptions(
    BuildContext context,
    String userId,
    List<MessengerConversationPreview> conversations,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_as_unread),
              title: const Text('Mark all as read'),
              onTap: () async {
                Navigator.pop(context);
                if (conversations.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No unread conversations')),
                  );
                  return;
                }

                final updated = await _markAllAsRead(
                  userId: userId,
                  conversations: conversations,
                );

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      updated > 0
                          ? 'Marked $updated conversation(s) as read'
                          : 'No unread conversations',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive chats'),
              onTap: () async {
                Navigator.pop(context);

                final archived = await _archiveAllChats(
                  userId: userId,
                  conversations: conversations,
                );

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      archived > 0
                          ? 'Archived $archived conversation(s)'
                          : 'No conversations to archive',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Message settings'),
              onTap: () async {
                Navigator.pop(context);

                await _showMessageSettingsDialog(context, userId);

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message settings saved')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime value) {
    final now = DateTime.now();
    final delta = now.difference(value);

    if (delta.inMinutes < 1) {
      return 'now';
    }
    if (delta.inMinutes < 60) {
      return '${delta.inMinutes}m';
    }
    if (delta.inHours < 24) {
      return '${delta.inHours}h';
    }
    if (delta.inDays < 7) {
      return '${delta.inDays}d';
    }
    return '${value.day}/${value.month}/${value.year}';
  }

  Future<int> _markAllAsRead({
    required String userId,
    required List<MessengerConversationPreview> conversations,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final unreadConversations =
        conversations.where((item) => item.unreadCount > 0).toList();

    if (unreadConversations.isEmpty) {
      return 0;
    }

    final batch = firestore.batch();
    for (final conversation in unreadConversations) {
      final doc = firestore.collection('conversations').doc(conversation.id);
      batch.update(doc, {
        'unreadByUser.$userId': 0,
        'unreadCounts.$userId': 0,
      });
    }

    try {
      await batch.commit();
      return unreadConversations.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _archiveAllChats({
    required String userId,
    required List<MessengerConversationPreview> conversations,
  }) async {
    if (conversations.isEmpty) {
      return 0;
    }

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (final conversation in conversations) {
      final doc = firestore.collection('conversations').doc(conversation.id);
      batch.set(
          doc,
          {
            'archivedByUser.$userId': true,
            'archivedAt.$userId': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }

    try {
      await batch.commit();
      return conversations.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _showMessageSettingsDialog(
    BuildContext context,
    String userId,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final docRef = firestore.collection('users').doc(userId);
    final snapshot = await docRef.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final messaging =
        (data['messagingSettings'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    bool pushEnabled = messaging['pushEnabled'] as bool? ?? true;
    bool soundEnabled = messaging['soundEnabled'] as bool? ?? true;
    bool previewEnabled = messaging['previewEnabled'] as bool? ?? true;

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Message settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Push notifications'),
                    value: pushEnabled,
                    onChanged: (value) => setState(() => pushEnabled = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Message sounds'),
                    value: soundEnabled,
                    onChanged: (value) => setState(() => soundEnabled = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show message preview'),
                    value: previewEnabled,
                    onChanged: (value) =>
                        setState(() => previewEnabled = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await docRef.set({
                      'messagingSettings': {
                        'pushEnabled': pushEnabled,
                        'soundEnabled': soundEnabled,
                        'previewEnabled': previewEnabled,
                        'updatedAt': FieldValue.serverTimestamp(),
                      },
                    }, SetOptions(merge: true));

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
