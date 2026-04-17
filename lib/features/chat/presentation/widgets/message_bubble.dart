import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final DateTime timestamp;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMe ? AppColors.primary : AppColors.surface;
    final textColor = isMe ? Colors.white : AppColors.textPrimary;
    final metaColor =
        isMe ? Colors.white.withValues(alpha: 0.75) : AppColors.textSecondary;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isMe ? 14 : 2),
      bottomRight: Radius.circular(isMe ? 2 : 14),
    );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
            border: isMe
                ? null
                : Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, style: TextStyle(color: textColor, fontSize: 15)),
              const SizedBox(height: 2),
              Text(
                DateFormat.Hm().format(timestamp),
                style: TextStyle(color: metaColor, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
