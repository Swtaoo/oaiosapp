import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_colors.dart';
import 'app_update_service.dart';

/// 显示更新弹窗
void showUpdateDialog(BuildContext context, VersionInfo info) {
  showGeneralDialog(
    context: context,
    barrierDismissible: !info.forceUpdate,
    barrierLabel: 'update',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (context, anim, secondaryAnim, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (dialogContext, anim1, anim2) => _UpdateDialogContent(info: info),
  );
}

class _UpdateDialogContent extends ConsumerWidget {
  final VersionInfo info;
  const _UpdateDialogContent({required this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(appUpdateProvider);
    final isDownloading = updateState.status == UpdateStatus.downloading;
    final isInstalling = updateState.status == UpdateStatus.installing;
    final progress = updateState.downloadProgress;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
        width: MediaQuery.of(context).size.width * 0.82,
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部渐变头图
            _buildHeader(context),
            // 内容区
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 版本信息行
                  _buildVersionRow(),
                  if (info.fileSize.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '安装包大小: ${info.fileSize}',
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                  // 更新内容
                  if (info.updateContent.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildChangelog(),
                  ],
                  const SizedBox(height: 24),
                  // 下载进度 or 按钮
                  if (isDownloading || isInstalling)
                    _buildProgress(progress, isInstalling)
                  else
                    _buildButtons(context, ref),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F8CFF), Color(0xFF6C5CE7)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.system_update, color: Colors.white, size: 28),
              ),
              const Spacer(),
              if (info.forceUpdate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '重要更新',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '发现新版本',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow() {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final current = snapshot.data?.version ?? '';
        return Row(
          children: [
            if (current.isNotEmpty) ...[
              _versionChip(current, isOld: true),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16, color: AppColors.textTertiary),
              ),
            ],
            _versionChip(info.versionName, isOld: false),
          ],
        );
      },
    );
  }

  Widget _versionChip(String version, {required bool isOld}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOld ? AppColors.neutral100 : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'v$version',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isOld ? AppColors.textSecondary : const Color(0xFF4F8CFF),
        ),
      ),
    );
  }

  Widget _buildChangelog() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article_outlined, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '更新内容',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Text(
                info.updateContent,
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(double progress, bool isInstalling) {
    final percent = (progress * 100).toInt();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: isInstalling ? null : progress,
            minHeight: 8,
            backgroundColor: AppColors.neutral100,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F8CFF)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isInstalling ? '正在安装...' : '下载中 $percent%',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appUpdateProvider.notifier);

    return Column(
      children: [
        // 立即更新按钮
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: () {
              notifier.downloadAndInstall(info.downloadUrl);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F8CFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            child: const Text('立即更新'),
          ),
        ),
        // 稍后提醒
        if (!info.forceUpdate) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: TextButton(
              onPressed: () {
                notifier.setRemindLaterOneDay();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('稍后提醒', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ],
    );
  }
}
