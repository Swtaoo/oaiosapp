import 'package:flutter/material.dart';

import '../theme/chat_colors.dart';

/// 企微风格时间分隔线
/// 灰色背景圆角胶囊 + 灰色小字，居中显示
class ChatTimeSeparator extends StatelessWidget {
  final String timeText;

  const ChatTimeSeparator({
    super.key,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: ChatColors.timeSeparatorBg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          timeText,
          style: const TextStyle(
            fontSize: 11,
            color: ChatColors.timeSeparator,
          ),
        ),
      ),
    );
  }
}
