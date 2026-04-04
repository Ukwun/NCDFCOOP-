import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  int selectedChatIndex = 0;

  // Mock data for conversations
  final conversations = [
    {
      'id': 1,
      'name': 'Fresh Produce Farm',
      'avatar': '🏪',
      'lastMessage': 'Your order has been shipped!',
      'time': '2 mins ago',
      'unread': 2,
      'isOnline': true,
    },
    {
      'id': 2,
      'name': 'Customer Support',
      'avatar': '💬',
      'lastMessage': 'How can we help you today?',
      'time': '1 hour ago',
      'unread': 0,
      'isOnline': true,
    },
    {
      'id': 3,
      'name': 'John\'s Farm Products',
      'avatar': '👨‍🌾',
      'lastMessage': 'Thank you for your purchase',
      'time': '5 hours ago',
      'unread': 0,
      'isOnline': false,
    },
    {
      'id': 4,
      'name': 'Mary (Member)',
      'avatar': '👩',
      'lastMessage': 'Do you have more of this product?',
      'time': 'Yesterday',
      'unread': 1,
      'isOnline': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

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
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: conversations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final chat = conversations[index];
                return _buildChatTile(context, chat, index);
              },
            ),
    );
  }

  Widget _buildChatTile(BuildContext context, Map chat, int index) {
    final hasUnread = chat['unread'] as int > 0;

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
                    chat['avatar'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              if (chat['isOnline'] as bool)
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
            chat['name'] as String,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            chat['lastMessage'] as String,
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
                chat['time'] as String,
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
                    '${chat['unread']}',
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

  void _openChat(BuildContext context, Map chat) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Text(
              chat['avatar'] as String,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat['name'] as String),
                  Text(
                    chat['isOnline'] as bool ? 'Online' : 'Offline',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: chat['isOnline'] as bool
                          ? Colors.green
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                chat['lastMessage'] as String,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: const Icon(Icons.send),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Message sent to ${chat['name']}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Search Messages'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Search by name or message...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Searching messages...'),
                  duration: Duration(seconds: 1),
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
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
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All marked as read')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive chats'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chats archived')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Message settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening settings...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
