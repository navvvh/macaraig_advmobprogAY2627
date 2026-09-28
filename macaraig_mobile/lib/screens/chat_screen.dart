import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart' as app;
import '../services/chat_service.dart';
import '../services/user_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _searchController = TextEditingController();
  final _chatService = ChatService();
  String? _currentUid;
  String? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _prepareChatList();
  }

  Future<void> _prepareChatList() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw StateError('Sign in with a Firebase account to use chat.');
      }
      final profile = await UserService().getUser();
      await _chatService.upsertCurrentUserProfile(profile);
      if (!mounted) return;
      setState(() {
        _currentUid = uid;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString().replaceFirst('Bad state: ', '');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(app.User user) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    final name = _chatService.displayName(user).toLowerCase();
    return name.contains(query) || user.email.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: true,
        foregroundColor: colors.onPrimary,
        backgroundColor: const Color(0xFF3840A2),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withValues(
                    alpha: .55,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildUserList(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(ColorScheme colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return _EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Chat is unavailable',
        message: _loadError!,
        actionLabel: FirebaseAuth.instance.currentUser == null
            ? 'Sign in with Firebase'
            : 'Retry',
        onAction: FirebaseAuth.instance.currentUser == null
            ? () => Navigator.pushNamed(context, '/signin')
            : _retry,
      );
    }

    return StreamBuilder<List<app.User>>(
      stream: _chatService.watchRegisteredUsers(_currentUid!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load users',
            message: 'Check Firestore setup and rules, then try again.',
            actionLabel: 'Retry',
            onAction: _retry,
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data!.where(_matches).toList();
        if (users.isEmpty) {
          final isSearching = _searchController.text.trim().isNotEmpty;
          return _EmptyState(
            icon: isSearching ? Icons.search_off : Icons.people_outline,
            title: isSearching ? 'No matching users' : 'No chat users yet',
            message: isSearching
                ? 'Try another name or email.'
                : 'Other Firebase users appear here after they sign in to the app.',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
          itemCount: users.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            indent: 76.w,
            color: colors.outlineVariant.withValues(alpha: .55),
          ),
          itemBuilder: (context, index) {
            final user = users[index];
            return TweenAnimationBuilder<double>(
              key: ValueKey(user.firebaseUid),
              tween: Tween(begin: .96, end: 1),
              duration: const Duration(milliseconds: 180),
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: child,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 5.h,
                  horizontal: 4.w,
                ),
                leading: _UserAvatar(user: user, radius: 25.r),
                title: Text(
                  _chatService.displayName(user),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.chat_bubble_outline,
                  color: colors.primary,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/chat-details',
                  arguments: user,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _prepareChatList();
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, required this.radius});

  final app.User user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.image;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: imageUrl.isEmpty
          ? Icon(
              Icons.person,
              size: radius,
              color: Theme.of(context).colorScheme.primary,
            )
          : ClipOval(
              child: Image.network(
                imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(Icons.person, size: radius),
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: colors.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
