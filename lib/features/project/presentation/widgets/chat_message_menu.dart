import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/chat_colors.dart';

/// 消息操作类型
enum ChatMessageAction {
  copy,
  reply,
  forward,
  delete,
  revoke,
}

/// 企微风格消息长按菜单
/// 黑色浮窗: 复制 / 回复 / 转发 / 删除 / 撤回(自己消息且2分钟内)
class ChatMessageMenu extends StatelessWidget {
  final bool isOwn;
  final bool canRevoke;
  final String? textContent;
  final void Function(ChatMessageAction action) onAction;

  const ChatMessageMenu({
    super.key,
    required this.isOwn,
    this.canRevoke = false,
    this.textContent,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      if (textContent != null && textContent!.isNotEmpty)
        _MenuItem(Icons.copy, '复制', ChatMessageAction.copy),
      _MenuItem(Icons.reply, '回复', ChatMessageAction.reply),
      _MenuItem(Icons.forward, '转发', ChatMessageAction.forward),
      _MenuItem(Icons.delete_outline, '删除', ChatMessageAction.delete),
      if (isOwn && canRevoke)
        _MenuItem(Icons.undo, '撤回', ChatMessageAction.revoke),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: ChatColors.menuBg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items
            .map((item) => _buildMenuItem(context, item))
            .toList(),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onAction(item.action);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 20, color: ChatColors.menuText),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 10,
                color: ChatColors.menuText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final ChatMessageAction action;

  const _MenuItem(this.icon, this.label, this.action);
}

/// 显示消息菜单弹窗
/// 在气泡附近弹出
void showChatMessageMenu({
  required BuildContext context,
  required Offset position,
  required bool isOwn,
  required bool canRevoke,
  String? textContent,
  required void Function(ChatMessageAction action) onAction,
}) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (overlay == null) return;

  showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx - 80,
      position.dy - 60,
      overlay.size.width - position.dx + 80,
      overlay.size.height - position.dy,
    ),
    color: Colors.transparent,
    elevation: 0,
    items: [
      PopupMenuItem(
        enabled: false,
        padding: EdgeInsets.zero,
        child: ChatMessageMenu(
          isOwn: isOwn,
          canRevoke: canRevoke,
          textContent: textContent,
          onAction: onAction,
        ),
      ),
    ],
  );
}

/// 复制文本到剪贴板
Future<void> copyMessageText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
