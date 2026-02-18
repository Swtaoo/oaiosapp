import 'package:flutter/material.dart';

/// 附件面板 - 九宫格: [相册] [拍摄] [文件]
class ChatAttachmentPanel extends StatelessWidget {
  final VoidCallback? onPickImage;
  final VoidCallback? onTakePhoto;
  final VoidCallback? onPickFile;

  const ChatAttachmentPanel({
    super.key,
    this.onPickImage,
    this.onTakePhoto,
    this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildItem(Icons.photo_library, '相册', onPickImage),
          const SizedBox(width: 32),
          _buildItem(Icons.camera_alt, '拍摄', onTakePhoto),
          const SizedBox(width: 32),
          _buildItem(Icons.folder, '文件', onPickFile),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: const Color(0xFF555555)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}
