import 'package:flutter/material.dart';

import '../../../common/presentation/pages/pdf_viewer_page.dart';
import '../../data/models/project_models.dart';
import '../theme/chat_colors.dart';
import 'chat_file_bubble.dart';
import 'chat_reply_preview.dart';
import 'chat_revoked_message.dart';
import 'mention_text.dart';

/// 企微风格聊天气泡
/// 支持: 文本、图片、文件、回复引用、撤回消息、@提及高亮
class ChatMessageBubble extends StatelessWidget {
  final String senderName;
  final String content;
  final String timeText;
  final bool isOwn;
  final String? imageUrl;
  final ChatRecordVo? message;
  final Set<String> memberNames;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 点击回复引用区域的回调
  final VoidCallback? onReplyTap;

  const ChatMessageBubble({
    super.key,
    required this.senderName,
    required this.content,
    required this.timeText,
    required this.isOwn,
    this.imageUrl,
    this.message,
    this.onLongPress,
    this.onReplyTap,
    this.memberNames = const {},
  });

  bool get _isImageMessage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get _isFileMessage =>
      message?.fileType != null && message!.fileType! > 0 &&
      message?.fileUrl != null && message!.fileUrl!.isNotEmpty;
  bool get _isRevoked => message?.delFlag == 2;
  bool get _hasReply =>
      message?.replyId != null && message!.replyId! > 0;

  @override
  Widget build(BuildContext context) {
    // 撤回消息
    if (_isRevoked) {
      return ChatRevokedMessage(isOwn: isOwn, senderName: senderName);
    }

    final initial = senderName.isNotEmpty ? senderName.characters.first : '?';

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: isOwn ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // 头像: 40x40 圆角矩形
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isOwn
                    ? const Color(0xFF07C160)
                    : const Color(0xFFCCCCCC),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 消息体
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // 发送者姓名（仅他人显示）
                  if (!isOwn)
                    Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 2),
                      child: Text(
                        senderName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ChatColors.senderName,
                        ),
                      ),
                    ),
                  // 气泡 + 状态指示器
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: isOwn ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Flexible(child: _buildContent(context)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  /// 消息类型路由
  Widget _buildContent(BuildContext context) {
    // 文件消息
    if (_isFileMessage) {
      return ChatFileBubble(
        fileName: message!.fileName,
        fileSize: message!.fileSize,
        fileUrl: message!.fileUrl,
        isOwn: isOwn,
        onTap: () => _openFile(context),
      );
    }

    // 图片消息
    if (_isImageMessage) {
      return _buildImageBubble(context);
    }

    // 文本消息（可能带回复引用）
    return _buildTextBubble();
  }

  Widget _buildTextBubble() {
    final bubbleColor =
        isOwn ? ChatColors.ownBubble : ChatColors.otherBubble;
    final textColor =
        isOwn ? ChatColors.ownText : ChatColors.otherText;

    return CustomPaint(
      painter: _BubbleArrowPainter(color: bubbleColor, isOwn: isOwn),
      child: Container(
        padding: EdgeInsets.only(
          left: isOwn ? 12 : 16,
          right: isOwn ? 16 : 12,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 回复引用
            if (_hasReply)
              ChatReplyPreview(
                replyUserName: message?.replyUserName,
                replyContent: message?.replyContent,
                isOwn: isOwn,
                onTap: onReplyTap,
              ),
            MentionText(
              text: content,
              baseStyle: TextStyle(
                fontSize: 15,
                color: textColor,
                height: 1.4,
              ),
              memberNames: memberNames,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBubble(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                width: 200,
                height: 120,
                color: const Color(0xFFF0F0F0),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
            errorBuilder: (_, _, _) => Container(
              width: 200,
              height: 80,
              color: const Color(0xFFF0F0F0),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Color(0xFF999999)),
                  SizedBox(height: 4),
                  Text(
                    '图片加载失败',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(
              imageUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFile(BuildContext context) {
    final url = message?.fileUrl;
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          url: url,
          title: message?.fileName ?? '文件预览',
        ),
      ),
    );
  }
}

/// 气泡尖角绘制器
class _BubbleArrowPainter extends CustomPainter {
  final Color color;
  final bool isOwn;

  _BubbleArrowPainter({required this.color, required this.isOwn});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const arrowWidth = 6.0;
    const arrowHeight = 10.0;
    const top = 14.0;

    final path = Path();
    if (isOwn) {
      path.moveTo(size.width, top);
      path.lineTo(size.width + arrowWidth, top + arrowHeight / 2);
      path.lineTo(size.width, top + arrowHeight);
    } else {
      path.moveTo(0, top);
      path.lineTo(-arrowWidth, top + arrowHeight / 2);
      path.lineTo(0, top + arrowHeight);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleArrowPainter oldDelegate) =>
      color != oldDelegate.color || isOwn != oldDelegate.isOwn;
}
