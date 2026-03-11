import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../home_modules.dart';
import '../../providers/quick_actions_provider.dart';

/// 编辑首页「常用功能」
///
/// - 支持增删
/// - 支持长按拖动排序（网格内拖拽）
class QuickActionsEditPage extends ConsumerStatefulWidget {
  const QuickActionsEditPage({super.key});

  @override
  ConsumerState<QuickActionsEditPage> createState() =>
      _QuickActionsEditPageState();
}

class _QuickActionsEditPageState extends ConsumerState<QuickActionsEditPage> {
  static const int _gridColumns = 3;
  static const double _gridSpacing = 10;

  String? _draggingKey;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final state = ref.watch(quickActionsProvider);
    final notifier = ref.read(quickActionsProvider.notifier);

    final moduleMap = <String, HomeModule>{
      for (final module in kAllHomeModules) module.key: module,
    };

    final selectedModules = state.keys
        .map((key) => moduleMap[key])
        .whereType<HomeModule>()
        .toList();

    final availableModules = kAllHomeModules
        .where((m) => !state.keys.contains(m.key))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('编辑常用功能'),
        actions: [
          TextButton(
            onPressed: state.isSaving
                ? null
                : () async {
                    final ok = await notifier.save();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? '已保存' : '保存失败（已保存到本地）'),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.warning,
                      ),
                    );
                    if (ok) Navigator.pop(context);
                  },
            child: Text(state.isSaving ? '保存中...' : '保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('常用功能'),
            const SizedBox(height: 6),
            Text(
              '长按拖动排序，点击红色按钮删除',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 12),
            _card(
              child: selectedModules.isEmpty
                  ? _emptyHint('暂无常用功能，请从下面添加')
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final tileWidth = (constraints.maxWidth -
                                _gridSpacing * (_gridColumns - 1)) /
                            _gridColumns;
                        return Wrap(
                          spacing: _gridSpacing,
                          runSpacing: _gridSpacing,
                          children: selectedModules.map((m) {
                            return _buildSelectedItem(
                              tileWidth: tileWidth,
                              module: m,
                              isAdmin: isAdmin,
                              onRemove: () => notifier.removeKey(m.key),
                              onMove: (fromKey) =>
                                  notifier.moveKey(fromKey, m.key),
                            );
                          }).toList(),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('全部应用'),
            const SizedBox(height: 6),
            Text(
              '点击添加到常用功能',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 12),
            _card(
              child: availableModules.isEmpty
                  ? _emptyHint('已添加全部应用')
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final tileWidth = (constraints.maxWidth -
                                _gridSpacing * (_gridColumns - 1)) /
                            _gridColumns;
                        return Wrap(
                          spacing: _gridSpacing,
                          runSpacing: _gridSpacing,
                          children: availableModules.map((m) {
                            return _buildAvailableItem(
                              tileWidth: tileWidth,
                              module: m,
                              onAdd: () => notifier.addKey(m.key),
                            );
                          }).toList(),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${selectedModules.length}/${kAllHomeModules.length}',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
      ),
    );
  }

  Widget _buildSelectedItem({
    required double tileWidth,
    required HomeModule module,
    required bool isAdmin,
    required VoidCallback onRemove,
    required void Function(String fromKey) onMove,
  }) {
    final key = module.key;
    final isDragging = _draggingKey == key;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != key,
      onAcceptWithDetails: (details) => onMove(details.data),
      builder: (context, candidateData, _) {
        final isHover = candidateData.isNotEmpty;
        final tile = _moduleTile(
          width: tileWidth,
          module: module,
          badge: '−',
          badgeColor: AppColors.error,
          showBadge: true,
          onBadgeTap: onRemove,
          highlight: isHover,
        );

        return LongPressDraggable<String>(
          data: key,
          onDragStarted: () => setState(() => _draggingKey = key),
          onDragEnd: (_) => setState(() => _draggingKey = null),
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(opacity: 0.9, child: tile),
          ),
          childWhenDragging: Opacity(opacity: 0.25, child: tile),
          child: Opacity(opacity: isDragging ? 0.6 : 1, child: tile),
        );
      },
    );
  }

  Widget _buildAvailableItem({
    required double tileWidth,
    required HomeModule module,
    required VoidCallback onAdd,
  }) {
    return GestureDetector(
      onTap: onAdd,
      child: _moduleTile(
        width: tileWidth,
        module: module,
        badge: '+',
        badgeColor: AppColors.success,
        showBadge: true,
      ),
    );
  }

  Widget _moduleTile({
    required double width,
    required HomeModule module,
    required String badge,
    required Color badgeColor,
    required bool showBadge,
    VoidCallback? onBadgeTap,
    bool highlight = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      width: width,
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFF2F2F7) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: module.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(module.icon, color: Colors.white, size: 24),
              ),
              if (showBadge)
                Positioned(
                  top: -6,
                  left: -6,
                  child: (onBadgeTap == null)
                      ? _badge(badge, badgeColor)
                      : GestureDetector(
                          onTap: onBadgeTap,
                          child: _badge(badge, badgeColor),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            module.label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
