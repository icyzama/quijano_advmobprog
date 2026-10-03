import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/lab4_components.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  late Future<User?> _userFuture;
  Stream<List<User>>? _usersStream;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.ensureFirebaseProfileSynced();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retryUsers(String uid) {
    setState(() => _usersStream = _chatService.watchUsers(uid));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userSnapshot.hasError) {
          return AppStateMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Firestore is not ready',
            message:
                'Create the Cloud Firestore database and publish the Lab 6 rules, then retry.',
            actionLabel: 'Retry',
            onAction: () => setState(
              () => _userFuture = _userService.ensureFirebaseProfileSynced(),
            ),
            accentColor: AppColors.coral,
          );
        }

        final currentUser = userSnapshot.data;
        final uid = currentUser?.firebaseUid;
        if (currentUser == null || !currentUser.isFirebase || uid == null) {
          return const AppStateMessage(
            icon: Icons.lock_outline,
            title: 'Firebase account required',
            message:
                'Sign in with a Firebase account to find people and start a conversation.',
            accentColor: AppColors.teal,
          );
        }

        _usersStream ??= _chatService.watchUsers(uid);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'Campus conversations',
                    fontSize: 21.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nuNavy,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: 'Find a Firebase user to start chatting.',
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchText = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search name or email',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchText.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchText = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<User>>(
                stream: _usersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return AppStateMessage(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load people',
                      message:
                          'Check that Cloud Firestore is created and its Lab 6 rules are published.',
                      actionLabel: 'Retry',
                      onAction: () => _retryUsers(uid),
                      accentColor: AppColors.coral,
                    );
                  }

                  final query = _searchText.trim().toLowerCase();
                  final users = (snapshot.data ?? const <User>[])
                      .where((user) =>
                          user.fullName.toLowerCase().contains(query) ||
                          user.email.toLowerCase().contains(query) ||
                          user.username.toLowerCase().contains(query))
                      .toList();

                  if (users.isEmpty) {
                    return AppStateMessage(
                      icon: query.isEmpty
                          ? Icons.people_outline
                          : Icons.search_off,
                      title:
                          query.isEmpty ? 'No other users yet' : 'No matches',
                      message: query.isEmpty
                          ? 'Other Firebase accounts appear here after they sign in to the app.'
                          : 'Try another name or email address.',
                      accentColor: AppColors.nuBlue,
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 16.h),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 68.w,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, index) {
                      final person = users[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 5.h),
                        leading: UserAvatar(user: person, size: 48),
                        title: CustomText(
                          text: person.fullName,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: CustomText(
                            text: person.email,
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                          size: 20.sp,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChatDetailScreen(
                              currentUser: currentUser,
                              otherUser: person,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 42});

  final User user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.image.trim();
    final initials = user.fullName.trim().isEmpty
        ? '?'
        : user.fullName.trim().characters.first.toUpperCase();

    return CircleAvatar(
      radius: size.w / 2,
      backgroundColor: AppColors.blueSoft,
      child: ClipOval(
        child: imageUrl.isEmpty
            ? Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: AppColors.nuBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: (size * 0.36).sp,
                  ),
                ),
              )
            : Image.network(
                imageUrl,
                width: size.w,
                height: size.w,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: AppColors.nuBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: (size * 0.36).sp,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
