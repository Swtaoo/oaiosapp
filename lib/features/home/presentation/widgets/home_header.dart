import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 首页头部 - 对应 HomeHeader.vue
/// 显示问候语、日期、通知铃铛、头像
class HomeHeader extends StatelessWidget {
  final String nickname;
  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const HomeHeader({
    super.key,
    required this.nickname,
    this.avatarUrl,
    this.unreadCount = 0,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  String _getGreetingText() {
    final hour = DateTime.now().hour;
    if (hour < 11) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  String _getTodayLabel() {
    final now = DateTime.now();
    const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return '${now.month}月${now.day}日 ${weekDays[now.weekday % 7]}';
  }

  @override
  Widget build(BuildContext context) {
    final badgeText = unreadCount <= 0
        ? null
        : unreadCount > 99
            ? '99+'
            : '$unreadCount';

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          // 左侧: 问候语 + 日期
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreetingText()}，$nickname',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _getTodayLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
          // 右侧: 通知铃铛 + 头像
          Row(
            children: [
              // 通知铃铛
              GestureDetector(
                onTap: onNotificationTap,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_outlined, size: 24),
                      if (badgeText != null)
                        Positioned(
                          top: 4,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 头像
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.neutral200,
                  child: const Icon(Icons.person, size: 24, color: AppColors.neutral400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
