import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../widgets/custom_text.dart';
import 'chat_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
  });

  final User currentUser;
  final User otherUser;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _scheduledStatusUpdates = {};
  late final Stream<List<Message>> _messagesStream;
  String? _pendingMessage;
  bool _isSending = false;

  String get _currentUserId => widget.currentUser.firebaseUid ?? '';
  String get _otherUserId => widget.otherUser.firebaseUid ?? '';

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.watchMessages(_currentUserId, _otherUserId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
      _pendingMessage = text;
      _messageController.clear();
    });

    try {
      await _chatService.sendMessage(
        senderId: _currentUserId,
        senderEmail: widget.currentUser.email,
        receiverId: _otherUserId,
        text: text,
      );
    } catch (_) {
      if (!mounted) return;
      _messageController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Message not sent. Check your connection and Firestore rules.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _pendingMessage = null;
        });
      }
    }
  }

  void _scheduleStatusUpdates(List<Message> messages) {
    for (final message in messages) {
      if (message.receiverId != _currentUserId) continue;

      final nextStatus = switch (message.status) {
        'sent' => 'delivered',
        'delivered' => 'seen',
        _ => null,
      };
      if (nextStatus == null) continue;

      final key = '${message.id}:$nextStatus';
      if (!_scheduledStatusUpdates.add(key)) continue;

      if (nextStatus == 'seen') {
        Future<void>.delayed(const Duration(milliseconds: 450), () {
          return _updateStatus(message, nextStatus);
        });
      } else {
        unawaited(_updateStatus(message, nextStatus));
      }
    }
  }

  Future<void> _updateStatus(Message message, String status) async {
    try {
      await _chatService.updateMessageStatus(
        senderId: message.senderId,
        receiverId: message.receiverId,
        messageId: message.id,
        status: status,
      );
    } catch (_) {
      _scheduledStatusUpdates.remove('${message.id}:$status');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(user: widget.otherUser, size: 38),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: widget.otherUser.fullName,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  CustomText(
                    text: widget.otherUser.email,
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Could not load this conversation. Check your connection and Firestore rules.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? const <Message>[];
                _scheduleStatusUpdates(messages);

                if (messages.isEmpty && _pendingMessage == null) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(28.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 38.sp,
                            color: AppColors.nuBlue,
                          ),
                          SizedBox(height: 12.h),
                          CustomText(
                            text: 'Start the conversation',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 5.h),
                          CustomText(
                            text: 'Your messages will appear here.',
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final pendingMessage = _pendingMessage;
                final itemCount =
                    messages.length + (pendingMessage == null ? 0 : 1);
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (pendingMessage != null && index == 0) {
                      return _MessageBubble(
                        key: const ValueKey('pending-message'),
                        text: pendingMessage,
                        time: TimeOfDay.now().format(context),
                        isMine: true,
                        status: 'sending',
                      );
                    }

                    final messageIndex =
                        index - (pendingMessage == null ? 0 : 1);
                    final message = messages[messageIndex];
                    return _MessageBubble(
                      key: ValueKey(message.id),
                      text: message.text,
                      time: message.sentAt == null
                          ? ''
                          : TimeOfDay.fromDateTime(message.sentAt!)
                              .format(context),
                      isMine: message.senderId == _currentUserId,
                      status: message.status,
                    );
                  },
                );
              },
            ),
          ),
          _MessageComposer(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Write a message',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 9.w),
            SizedBox.square(
              dimension: 46.w,
              child: IconButton.filled(
                tooltip: 'Send message',
                onPressed: isSending ? null : onSend,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.nuBlue,
                  foregroundColor: Colors.white,
                ),
                icon: isSending
                    ? SizedBox.square(
                        dimension: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMine,
    required this.status,
  });

  final String text;
  final String time;
  final bool isMine;
  final String status;

  @override
  Widget build(BuildContext context) {
    final background = isMine ? AppColors.nuBlue : AppColors.surface;
    final foreground = isMine ? Colors.white : AppColors.textPrimary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(isMine ? 12 * (1 - value) : -12 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: 0.78.sw),
          margin: EdgeInsets.symmetric(vertical: 4.h),
          padding: EdgeInsets.fromLTRB(13.w, 10.h, 11.w, 7.h),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(isMine ? 16.r : 4.r),
              bottomRight: Radius.circular(isMine ? 4.r : 16.r),
            ),
            boxShadow: isMine
                ? null
                : [
                    BoxShadow(
                      color: AppColors.nuNavy.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  text: text,
                  fontSize: 14.sp,
                  color: foreground,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (time.isNotEmpty)
                    CustomText(
                      text: time,
                      fontSize: 9.sp,
                      color: isMine ? Colors.white70 : AppColors.textSecondary,
                    ),
                  if (isMine) ...[
                    SizedBox(width: 4.w),
                    _DeliveryStatus(status: status),
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

class _DeliveryStatus extends StatelessWidget {
  const _DeliveryStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    if (status == 'sending') {
      return Text(
        'Sending',
        style: TextStyle(color: Colors.white70, fontSize: 9.sp),
      );
    }

    final seen = status == 'seen';
    final delivered = status == 'delivered' || seen;
    return Tooltip(
      message: seen
          ? 'Seen'
          : delivered
              ? 'Delivered'
              : 'Sent',
      child: Icon(
        delivered ? Icons.done_all : Icons.done,
        size: 13.sp,
        color: seen ? AppColors.nuGold : Colors.white70,
      ),
    );
  }
}
