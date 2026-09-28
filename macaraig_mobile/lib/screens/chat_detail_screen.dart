import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/message.dart';
import '../models/user.dart' as app;
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.recipient});

  final app.User recipient;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _chatService = ChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Message> _pendingMessages = [];
  String? _currentUid;
  String? _chatId;
  String? _error;
  bool _opening = true;

  @override
  void initState() {
    super.initState();
    _openConversation();
  }

  Future<void> _openConversation() async {
    try {
      final uid = _chatService.currentUid;
      if (widget.recipient.firebaseUid == uid) {
        throw ArgumentError('You cannot start a chat with yourself.');
      }
      final chatId = await _chatService.openConversation(
        widget.recipient.firebaseUid,
      );
      if (!mounted) return;
      setState(() {
        _currentUid = uid;
        _chatId = chatId;
        _opening = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
        _opening = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final chatId = _chatId;
    final senderId = _currentUid;
    if (text.isEmpty || chatId == null || senderId == null) return;

    final pending = Message(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      senderId: senderId,
      receiverId: widget.recipient.firebaseUid,
      text: text,
      createdAt: DateTime.now(),
      status: 'sending',
    );
    _messageController.clear();
    setState(() => _pendingMessages.add(pending));
    _scrollToBottom();

    try {
      await _chatService.sendMessage(
        chatId: chatId,
        receiverUid: widget.recipient.firebaseUid,
        text: text,
        messageId: pending.id,
      );
      if (!mounted) return;
      setState(
        () =>
            _pendingMessages.removeWhere((message) => message.id == pending.id),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () =>
            _pendingMessages.removeWhere((message) => message.id == pending.id),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Message was not sent: $error')));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = _chatService.displayName(widget.recipient);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3840A2),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            _Avatar(user: widget.recipient),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    widget.recipient.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessages(colors)),
            _buildComposer(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(ColorScheme colors) {
    if (_opening) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _openConversation,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<Message>>(
      stream: _chatService.watchMessages(_chatId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load messages. Check the Firestore rules and connection.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.error),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages =
            [
              ...snapshot.data!.where(
                (message) => !_pendingMessages.any(
                  (pending) => pending.id == message.id,
                ),
              ),
              ..._pendingMessages,
            ]..sort((a, b) {
              final left =
                  a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final right =
                  b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return left.compareTo(right);
            });
        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.waving_hand_outlined,
                    size: 42,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text('No messages yet. Say hello!'),
                ],
              ),
            ),
          );
        }

        _scrollToBottom();
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(14.w, 18.h, 14.w, 16.h),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _MessageBubble(
              key: ValueKey(message.id),
              message: message,
              isMine: message.senderId == _currentUid,
            );
          },
        );
      },
    );
  }

  Widget _buildComposer(ColorScheme colors) {
    final disabled = _chatId == null || _opening || _error != null;
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 9.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !disabled,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: disabled ? 'Chat unavailable' : 'Write a message…',
                filled: true,
                fillColor: colors.surfaceContainerHighest.withValues(
                  alpha: .55,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton.filled(
            tooltip: 'Send message',
            onPressed: disabled ? null : _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF3840A2),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final Message message;
  final bool isMine;

  String _time(DateTime? value) {
    if (value == null) return '';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bubbleColor = isMine
        ? const Color(0xFF3840A2)
        : colors.surfaceContainerHighest;
    final textColor = isMine ? Colors.white : colors.onSurface;
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 5),
      bottomRight: Radius.circular(isMine ? 5 : 18),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(
            isMine ? 10 * (1 - value) : -10 * (1 - value),
            8 * (1 - value),
          ),
          child: child,
        ),
      ),
      child: Align(
        alignment: alignment,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .78,
          ),
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 7.h),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.text,
                  style: TextStyle(color: textColor, fontSize: 14.sp),
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.status == 'sending'
                        ? 'Sending…'
                        : _time(message.createdAt),
                    style: TextStyle(
                      color: isMine ? Colors.white70 : colors.onSurfaceVariant,
                      fontSize: 10.sp,
                    ),
                  ),
                  if (isMine && message.status == 'sent') ...[
                    SizedBox(width: 4.w),
                    Icon(Icons.check, size: 13.sp, color: Colors.white70),
                  ],
                  if (isMine && message.status == 'sending') ...[
                    SizedBox(width: 5.w),
                    SizedBox(
                      width: 10.w,
                      height: 10.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});
  final app.User user;

  @override
  Widget build(BuildContext context) {
    final radius = 19.r;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      child: user.image.isEmpty
          ? Icon(Icons.person, size: 21.sp, color: Colors.white)
          : ClipOval(
              child: Image.network(
                user.image,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.person, size: 21.sp, color: Colors.white),
              ),
            ),
    );
  }
}
