import 'package:flutter/material.dart';

import '../theme/chat_colors.dart';

/// 未读消息徽章
/// 1-99 显示数字; >=100 显示 "99+"; 0 隐藏
class UnreadBadge extends StatelessWidget {
  final int count;

  const UnreadBadge({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final text = count > 99 ? '99+' : '$count';
    final minWidth = count > 99 ? 32.0 : (count > 9 ? 24.0 : 18.0);

    return Container(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: ChatColors.unreadBadge,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }
}
