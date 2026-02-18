import 'package:flutter/material.dart';

/// 企微风格聊天配色方案
class ChatColors {
  ChatColors._();

  /// 聊天页背景色（企微灰色）
  static const Color background = Color(0xFFEDEDED);

  /// 自己的气泡色（企微绿色）
  static const Color ownBubble = Color(0xFF95EC69);

  /// 他人的气泡色（白色）
  static const Color otherBubble = Color(0xFFFFFFFF);

  /// 自己消息文字色
  static const Color ownText = Color(0xFF000000);

  /// 他人消息文字色
  static const Color otherText = Color(0xFF000000);

  /// 时间分隔符文字色
  static const Color timeSeparator = Color(0xFFB2B2B2);

  /// 时间分隔符背景色
  static const Color timeSeparatorBg = Color(0xFFCECECE);

  /// 输入栏背景色
  static const Color inputBarBg = Color(0xFFF7F7F7);

  /// 输入栏边框色
  static const Color inputBarBorder = Color(0xFFDDDDDD);

  /// 未读徽章红色
  static const Color unreadBadge = Color(0xFFFA5151);

  /// 发送按钮激活色（企微绿色）
  static const Color sendBtnActive = Color(0xFF07C160);

  /// 发送按钮禁用色
  static const Color sendBtnDisabled = Color(0xFFAEAEAE);

  /// 消息发送者姓名色
  static const Color senderName = Color(0xFF888888);

  /// 撤回消息文字色
  static const Color revokedText = Color(0xFFB0B0B0);

  /// 消息菜单背景色
  static const Color menuBg = Color(0xFF4C4C4C);

  /// 消息菜单文字色
  static const Color menuText = Color(0xFFFFFFFF);
}
