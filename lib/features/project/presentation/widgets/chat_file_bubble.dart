import 'package:flutter/material.dart';

import '../theme/chat_colors.dart';

/// 文件消息气泡
/// [文件图标] [文件名 + 大小]，点击可下载/预览
class ChatFileBubble extends StatelessWidget {
  final String? fileName;
  final int? fileSize;
  final String? fileUrl;
  final bool isOwn;
  final VoidCallback? onTap;

  const ChatFileBubble({
    super.key,
    this.fileName,
    this.fileSize,
    this.fileUrl,
    this.isOwn = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isOwn ? ChatColors.ownBubble : ChatColors.otherBubble;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 文件图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90D9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.insert_drive_file,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            // 文件信息
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName ?? '未知文件',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF111111),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatFileSize(fileSize),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
