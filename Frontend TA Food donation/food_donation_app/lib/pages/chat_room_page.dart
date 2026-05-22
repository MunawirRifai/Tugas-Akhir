import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/food_mapper.dart';

class ChatRoomPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> food;
  final String counterpartName;

  const ChatRoomPage({
    super.key,
    required this.token,
    required this.food,
    required this.counterpartName,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final FoodRecord _food;

  bool _isSending = false;
  bool _isTyping = false;

  late List<_ChatMessage> _messages;

  @override
  void initState() {
    super.initState();

    _food = FoodRecord(widget.food);

    _messages = [
      _ChatMessage(
        id: 'm1',
        text:
            'Halo, saya tertarik dengan donasi "${_food.name}". Apakah masih tersedia?',
        isMine: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        status: _MessageStatus.read,
      ),
      _ChatMessage(
        id: 'm2',
        text:
            'Masih tersedia. Silakan datang ke titik pickup sesuai lokasi yang tertera.',
        isMine: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
        status: _MessageStatus.read,
      ),
      _ChatMessage(
        id: 'm3',
        text: 'Baik, saya akan menuju lokasi sekarang.',
        isMine: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: _MessageStatus.delivered,
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    final _ChatMessage userMessage = _ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isMine: true,
      timestamp: DateTime.now(),
      status: _MessageStatus.sent,
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    setState(() {
      _isSending = false;
      _isTyping = false;
      _messages.add(
        _ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text:
              'Pesan diterima. Fitur ini masih mockup frontend untuk analisis komunikasi in-app.',
          isMine: false,
          timestamp: DateTime.now(),
          status: _MessageStatus.read,
        ),
      );
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _timeLabel(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: _ChatHeaderTitle(
          counterpartName: widget.counterpartName,
          foodName: _food.name,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _FoodContextCard(
              food: _food,
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x2,
                  AppSpacing.x3,
                  AppSpacing.x2,
                ),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return const _TypingBubble();
                  }

                  final _ChatMessage message = _messages[index];

                  return _ChatBubble(
                    message: message,
                    timeLabel: _timeLabel(message.timestamp),
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
      ),
    );
  }
}

class _ChatHeaderTitle extends StatelessWidget {
  final String counterpartName;
  final String foodName;

  const _ChatHeaderTitle({
    required this.counterpartName,
    required this.foodName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: AppSpacing.x1),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                counterpartName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                foodName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodContextCard extends StatelessWidget {
  final FoodRecord food;

  const _FoodContextCard({
    required this.food,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x2,
        AppSpacing.x3,
        AppSpacing.x1,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Row(
            children: [
              _FoodMiniImage(
                imageUrl: food.photoUrl,
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${food.quantity} porsi • ${food.statusLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodMiniImage extends StatelessWidget {
  final String? imageUrl;

  const _FoodMiniImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Icon(
        Icons.fastfood_rounded,
        color: AppColors.accent,
      ),
    );

    if (imageUrl == null) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.network(
        imageUrl!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final String timeLabel;

  const _ChatBubble({
    required this.message,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMine = message.isMine;
    final Color bubbleColor = isMine ? AppColors.primary : AppColors.surface;
    final Color textColor = isMine ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.x1),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.all(AppSpacing.x2),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMine ? AppRadius.lg : 4),
            bottomRight: Radius.circular(isMine ? 4 : AppRadius.lg),
          ),
          border: isMine ? null : Border.all(color: AppColors.border),
          boxShadow: isMine ? AppShadows.brand : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.78)
                            : AppColors.textMuted,
                      ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == _MessageStatus.read
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.x1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x2,
          vertical: AppSpacing.x1,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            const SizedBox(width: 4),
            _Dot(delay: 120),
            const SizedBox(width: 4),
            _Dot(delay: 240),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;

  const _Dot({
    required this.delay,
  });

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );

    _opacity = Tween<double>(
      begin: 0.32,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    Timer(Duration(milliseconds: widget.delay), () {
      if (!mounted) return;
      _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x2,
          AppSpacing.x2,
          AppSpacing.x2,
          AppSpacing.x2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan...',
                  prefixIcon: Icon(Icons.message_outlined),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: AppSpacing.x1),
            SizedBox(
              width: 52,
              height: 52,
              child: ElevatedButton(
                onPressed: isSending ? null : onSend,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(52, 52),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
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

class _ChatMessage {
  final String id;
  final String text;
  final bool isMine;
  final DateTime timestamp;
  final _MessageStatus status;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.timestamp,
    required this.status,
  });
}

enum _MessageStatus {
  sent,
  delivered,
  read,
}