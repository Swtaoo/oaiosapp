// 注册表单共享组件

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../constants/area_data.dart';

// ─────────────────────────────────────────────
// FormSection — 表单分区卡片（标题在卡片外部上方）
// ─────────────────────────────────────────────
class FormSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const FormSection({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.s8,
                left: AppSpacing.s4,
              ),
              child: Text(
                title!,
                style: AppTypography.footnote.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...children,
                const SizedBox(height: AppSpacing.s4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FormRow — 左label右value行内布局（iOS设置页风格）
// ─────────────────────────────────────────────
class FormRow extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  final String? errorText;
  final bool isLast;

  const FormRow({
    super.key,
    required this.label,
    this.required = false,
    required this.child,
    this.errorText,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左侧 label 固定宽度
              SizedBox(
                width: 88,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (required)
                      Text(
                        '*',
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (required) const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        label,
                        style: AppTypography.callout.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 右侧输入区域，右对齐
              Expanded(child: child),
            ],
          ),
        ),
        // 错误提示
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.pagePadding + 90,
              top: AppSpacing.s2,
              bottom: AppSpacing.s2,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 12,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppSpacing.s3),
                Text(
                  errorText!,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        if (!isLast)
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppColors.neutral100,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 通用无边框 InputDecoration（用于 FormRow 内部，右对齐）
// ─────────────────────────────────────────────
InputDecoration formInputDecoration({
  String hint = '',
  TextStyle? hintStyle,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: hintStyle ??
        AppTypography.formField.copyWith(color: AppColors.textPlaceholder),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.s8,
      vertical: AppSpacing.s13,
    ),
    suffixIcon: suffixIcon,
  );
}

// ─────────────────────────────────────────────
// DatePickerField
// ─────────────────────────────────────────────
class DatePickerField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final ValueChanged<String> onChanged;

  const DatePickerField({
    super.key,
    this.value,
    this.placeholder = '请选择日期',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value?.isNotEmpty == true;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pick(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s13,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                hasValue ? value! : placeholder,
                style: AppTypography.formField.copyWith(
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textPlaceholder,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.s6),
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final initial = value != null && value!.isNotEmpty
        ? DateTime.tryParse(value!) ?? now
        : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      onChanged(formatted);
    }
  }
}

// ─────────────────────────────────────────────
// PickerField
// ─────────────────────────────────────────────
class PickerField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String? fieldName;

  const PickerField({
    super.key,
    this.value,
    this.placeholder = '请选择',
    required this.options,
    required this.onChanged,
    this.fieldName,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value?.isNotEmpty == true;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showPicker(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s13,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                hasValue ? value! : placeholder,
                style: AppTypography.formField.copyWith(
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textPlaceholder,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.neutral300,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    HapticFeedback.selectionClick();
    final headerTitle = fieldName != null ? '请选择$fieldName' : '请选择';
    if (options.length > 10) {
      _showSearchablePicker(context, headerTitle);
    } else {
      _showFlatPicker(context, headerTitle);
    }
  }

  void _showFlatPicker(BuildContext context, String headerTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(),
              _SheetHeader(
                  title: headerTitle, onCancel: () => Navigator.pop(ctx)),
              Divider(height: 0.5, color: AppColors.neutral200),
              ...options.map((opt) => _OptionTile(
                    option: opt,
                    selected: opt == value,
                    onTap: () {
                      onChanged(opt);
                      Navigator.pop(ctx);
                    },
                  )),
              const SizedBox(height: AppSpacing.s8),
            ],
          ),
        );
      },
    );
  }

  void _showSearchablePicker(BuildContext context, String headerTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _SearchablePickerContent(
          options: options,
          value: value,
          headerTitle: headerTitle,
          onChanged: (opt) {
            onChanged(opt);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Sheet 内部子组件
// ─────────────────────────────────────────────
class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(
            top: AppSpacing.s10, bottom: AppSpacing.s4),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.neutral300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  const _SheetHeader({required this.title, required this.onCancel, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s4,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: onCancel,
            child: Text(
              '取消',
              style: AppTypography.callout.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.callout.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onConfirm != null)
            TextButton(
              onPressed: onConfirm,
              child: Text(
                '确定',
                style: AppTypography.callout.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(width: 68),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String option;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile(
      {required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? AppColors.primary50 : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.s14,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: AppTypography.callout.copyWith(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight:
                      selected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded,
                  size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 可搜索 Picker
// ─────────────────────────────────────────────
class _SearchablePickerContent extends StatefulWidget {
  final List<String> options;
  final String? value;
  final String headerTitle;
  final ValueChanged<String> onChanged;

  const _SearchablePickerContent({
    required this.options,
    required this.value,
    required this.headerTitle,
    required this.onChanged,
  });

  @override
  State<_SearchablePickerContent> createState() =>
      _SearchablePickerContentState();
}

class _SearchablePickerContentState
    extends State<_SearchablePickerContent> {
  final _searchCtl = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
    _searchCtl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtl.text.trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.options
          : widget.options.where((o) => o.contains(q)).toList();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.65;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DragHandle(),
            _SheetHeader(
              title: widget.headerTitle,
              onCancel: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.s4,
                AppSpacing.pagePadding,
                AppSpacing.s8,
              ),
              child: TextField(
                controller: _searchCtl,
                decoration: InputDecoration(
                  hintText: '搜索...',
                  hintStyle: AppTypography.formField
                      .copyWith(color: AppColors.textPlaceholder),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: AppColors.neutral400),
                  suffixIcon: _searchCtl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtl.clear();
                            setState(() => _filtered = widget.options);
                          },
                          child: const Icon(Icons.cancel_rounded,
                              size: 18, color: AppColors.neutral400),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.s10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
                style: AppTypography.formField,
              ),
            ),
            Divider(height: 0.5, color: AppColors.neutral200),
            Flexible(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.s32),
                      child: Text(
                        '没有匹配结果',
                        style: AppTypography.footnote
                            .copyWith(color: AppColors.neutral400),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 0.5,
                        indent: AppSpacing.pagePadding,
                        endIndent: AppSpacing.pagePadding,
                        color: AppColors.neutral200,
                      ),
                      itemBuilder: (ctx, i) {
                        final opt = _filtered[i];
                        return _OptionTile(
                          option: opt,
                          selected: opt == widget.value,
                          onTap: () => widget.onChanged(opt),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DetailRow — 只读展示行（保持原有 label左/value右 风格）
// ─────────────────────────────────────────────
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.isEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.s13,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: AppTypography.formField
                      .copyWith(color: AppColors.neutral500),
                ),
              ),
              Expanded(
                child: Text(
                  isEmpty ? '未填写' : value,
                  style: AppTypography.formField.copyWith(
                    color: isEmpty
                        ? AppColors.textPlaceholder
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: AppSpacing.pagePadding,
            endIndent: AppSpacing.pagePadding,
            color: AppColors.neutral200,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// FormLoadingPlaceholder
// ─────────────────────────────────────────────
class FormLoadingPlaceholder extends StatelessWidget {
  const FormLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            '加载中...',
            style: AppTypography.footnote
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PhotoUploadCard — 个人照片上传卡片
// ─────────────────────────────────────────────
class PhotoUploadCard extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const PhotoUploadCard({
    super.key,
    this.photoUrl,
    required this.onTap,
    this.onRemove,
  });

  bool get _hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.s8,
              left: AppSpacing.s4,
            ),
            child: Text(
              '个人照片',
              style: AppTypography.footnote.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: _hasPhoto ? _buildPreview() : _buildPlaceholder(),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  '请上传近期免冠照片',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.neutral400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppColors.neutral300,
        borderRadius: 8,
      ),
      child: SizedBox(
        width: 100,
        height: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 28,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '上传图片',
              style: AppTypography.caption1.copyWith(
                color: AppColors.neutral400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final isNetwork = photoUrl!.startsWith('http');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isNetwork
              ? Image.network(
                  photoUrl!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildPlaceholder(),
                )
              : Image.file(
                  File(photoUrl!),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildPlaceholder(),
                ),
        ),
        if (onRemove != null)
          Positioned(
            right: -6,
            top: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.borderRadius = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashGap = 3.0;
    const strokeWidth = 1.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, end.toDouble()),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}

// ─────────────────────────────────────────────
// AreaPickerField — 省市区三级级联选择器
// ─────────────────────────────────────────────
class AreaPickerField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final ValueChanged<String> onChanged;

  const AreaPickerField({
    super.key,
    this.value,
    this.placeholder = '请选择省/市/区',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value?.isNotEmpty == true;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showAreaPicker(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s13,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                hasValue ? value! : placeholder,
                style: AppTypography.formField.copyWith(
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textPlaceholder,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.neutral300,
            ),
          ],
        ),
      ),
    );
  }

  void _showAreaPicker(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => AreaPickerSheet(
        initialValue: value,
        onConfirm: (province, city, district) {
          onChanged('$province $city $district');
          Navigator.pop(ctx);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }
}

class AreaPickerSheet extends StatefulWidget {
  final String? initialValue;
  final void Function(String province, String city, String district) onConfirm;
  final VoidCallback onCancel;

  const AreaPickerSheet({
    super.key,
    this.initialValue,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<AreaPickerSheet> {
  late List<String> _provinces;
  late List<String> _cities;
  late List<String> _districts;

  late FixedExtentScrollController _provinceCtl;
  late FixedExtentScrollController _cityCtl;
  late FixedExtentScrollController _districtCtl;

  int _provinceIndex = 0;
  int _cityIndex = 0;
  int _districtIndex = 0;

  @override
  void initState() {
    super.initState();
    _provinces = AreaData.areas.keys.toList();

    // 尝试从 initialValue 恢复选中项
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      final parts = widget.initialValue!.split(' ');
      if (parts.isNotEmpty) {
        final pi = _provinces.indexOf(parts[0]);
        if (pi >= 0) _provinceIndex = pi;
      }
    }

    _cities = (AreaData.areas[_provinces[_provinceIndex]] ?? {}).keys.toList();
    if (widget.initialValue != null) {
      final parts = widget.initialValue!.split(' ');
      if (parts.length > 1) {
        final ci = _cities.indexOf(parts[1]);
        if (ci >= 0) _cityIndex = ci;
      }
    }

    _districts = _cities.isNotEmpty
        ? (AreaData.areas[_provinces[_provinceIndex]] ?? {})[_cities[_cityIndex]] ?? []
        : [];
    if (widget.initialValue != null) {
      final parts = widget.initialValue!.split(' ');
      if (parts.length > 2) {
        final di = _districts.indexOf(parts[2]);
        if (di >= 0) _districtIndex = di;
      }
    }

    _provinceCtl = FixedExtentScrollController(initialItem: _provinceIndex);
    _cityCtl = FixedExtentScrollController(initialItem: _cityIndex);
    _districtCtl = FixedExtentScrollController(initialItem: _districtIndex);
  }

  @override
  void dispose() {
    _provinceCtl.dispose();
    _cityCtl.dispose();
    _districtCtl.dispose();
    super.dispose();
  }

  void _onProvinceChanged(int index) {
    setState(() {
      _provinceIndex = index;
      _cities =
          (AreaData.areas[_provinces[_provinceIndex]] ?? {}).keys.toList();
      _cityIndex = 0;
      _districts = _cities.isNotEmpty
          ? (AreaData.areas[_provinces[_provinceIndex]] ?? {})[_cities[0]] ?? []
          : [];
      _districtIndex = 0;
    });
    _cityCtl.jumpToItem(0);
    _districtCtl.jumpToItem(0);
  }

  void _onCityChanged(int index) {
    setState(() {
      _cityIndex = index;
      _districts = (AreaData.areas[_provinces[_provinceIndex]] ?? {})[_cities[_cityIndex]] ?? [];
      _districtIndex = 0;
    });
    _districtCtl.jumpToItem(0);
  }

  void _onDistrictChanged(int index) {
    setState(() => _districtIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(),
          _SheetHeader(
            title: '请选择地区',
            onCancel: widget.onCancel,
            onConfirm: () {
              final province = _provinces[_provinceIndex];
              final city = _cities.isNotEmpty ? _cities[_cityIndex] : '';
              final district =
                  _districts.isNotEmpty ? _districts[_districtIndex] : '';
              widget.onConfirm(province, city, district);
            },
          ),
          Divider(height: 0.5, color: AppColors.neutral200),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(child: _buildPicker(_provinces, _provinceCtl, _onProvinceChanged)),
                Expanded(child: _buildPicker(_cities, _cityCtl, _onCityChanged)),
                Expanded(child: _buildPicker(_districts, _districtCtl, _onDistrictChanged)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }

  Widget _buildPicker(
    List<String> items,
    FixedExtentScrollController controller,
    ValueChanged<int> onChanged,
  ) {
    return CupertinoPicker(
      scrollController: controller,
      itemExtent: 36,
      diameterRatio: 1.2,
      squeeze: 1.0,
      useMagnifier: true,
      magnification: 1.05,
      onSelectedItemChanged: onChanged,
      children: items
          .map((item) => Center(
                child: Text(
                  item,
                  style: AppTypography.formField.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────
// FormBlockField — 垂直布局表单字段（label在上方）
// ─────────────────────────────────────────────
class FormBlockField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  final String? errorText;

  const FormBlockField({
    super.key,
    required this.label,
    this.required = false,
    required this.child,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (required)
                Text(
                  '*',
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (required) const SizedBox(width: 2),
              Text(
                label,
                style: AppTypography.callout.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          child,
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s4),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 12,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Text(
                    errorText!,
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// InlineFieldRow — 内联行（多字段等分横排）
// ─────────────────────────────────────────────
class InlineFieldItem {
  final String label;
  final bool required;
  final Widget child;
  final String? unit;

  const InlineFieldItem({
    required this.label,
    this.required = false,
    required this.child,
    this.unit,
  });
}

class InlineFieldRow extends StatelessWidget {
  final List<InlineFieldItem> items;
  final String? errorText;

  const InlineFieldRow({
    super.key,
    required this.items,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.s10,
          ),
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i > 0 ? AppSpacing.s12 : 0,
                  ),
                  child: Row(
                    children: [
                      // label
                      if (item.required)
                        Text(
                          '*',
                          style: AppTypography.footnote.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (item.required) const SizedBox(width: 2),
                      Text(
                        item.label,
                        style: AppTypography.callout.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      // input
                      Expanded(child: item.child),
                      // unit
                      if (item.unit != null)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.s4),
                          child: Text(
                            item.unit!,
                            style: AppTypography.footnote.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.pagePadding,
              bottom: AppSpacing.s4,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 12,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppSpacing.s3),
                Text(
                  errorText!,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        Divider(
          height: 0.5,
          thickness: 0.5,
          color: AppColors.neutral100,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// CheckboxGridSection — 复选框网格分区
// ─────────────────────────────────────────────
class CheckboxGridSection extends StatelessWidget {
  final String title;
  final String? hint;
  final List<String> options;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>> onChanged;
  final String? errorText;

  const CheckboxGridSection({
    super.key,
    required this.title,
    this.hint,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.s8,
              left: AppSpacing.s4,
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
                if (hint != null) ...[
                  const Spacer(),
                  Text(
                    hint!,
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.neutral400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s12,
            ),
            child: Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: options.map((opt) {
                final selected = selectedValues.contains(opt);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final newSet = Set<String>.from(selectedValues);
                    if (selected) {
                      newSet.remove(opt);
                    } else {
                      newSet.add(opt);
                    }
                    onChanged(newSet);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s14,
                      vertical: AppSpacing.s8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.neutral200,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      opt,
                      style: AppTypography.callout.copyWith(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.s4,
                left: AppSpacing.s4,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 12,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Text(
                    errorText!,
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FormTextArea — 带边框多行文本域
// ─────────────────────────────────────────────
class FormTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int minLines;

  const FormTextArea({
    super.key,
    required this.controller,
    this.hint = '请输入',
    this.maxLines = 4,
    this.minLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: minLines,
        style: AppTypography.formField,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.formField.copyWith(
            color: AppColors.textPlaceholder,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.s12),
        ),
      ),
    );
  }
}
