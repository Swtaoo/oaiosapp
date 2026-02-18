// 注册表单共享组件 - DatePicker、AreaPicker 等表单元素的 Flutter 实现

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 表单分区卡片
class FormSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const FormSection({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.pagePadding,
                AppSpacing.pagePadding,
                AppSpacing.s4,
              ),
              child: Text(
                title!,
                style: AppTypography.subheadline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ...children,
          // 底部圆角留白
          const SizedBox(height: AppSpacing.s4),
        ],
      ),
    );
  }
}

/// 表单行 - iOS 风格: label 左对齐 + value 右对齐, 底部 Divider 分隔
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // label 区域
              _buildLabel(),
              const SizedBox(width: AppSpacing.s12),
              // value 区域
              Expanded(child: child),
            ],
          ),
        ),
        // 内联错误
        if (errorText != null && errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.pagePadding,
              right: AppSpacing.pagePadding,
              bottom: AppSpacing.s8,
            ),
            child: Text(
              errorText!,
              style: AppTypography.caption1.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        // 分隔线 (非最后一行)
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

  Widget _buildLabel() {
    return SizedBox(
      width: 86,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (required)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(
                '*',
                style: AppTypography.formField.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          Flexible(
            child: Text(
              label,
              style: AppTypography.formField.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 日期选择器
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
    return GestureDetector(
      onTap: () async {
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
      },
      child: Container(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                value?.isNotEmpty == true ? value! : placeholder,
                style: AppTypography.formField.copyWith(
                  color: value?.isNotEmpty == true
                      ? AppColors.textPrimary
                      : AppColors.textPlaceholder,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}

/// Picker 选择器字段
/// 当 options.length > 10 时自动启用搜索功能
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
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                value?.isNotEmpty == true ? value! : placeholder,
                style: AppTypography.formField.copyWith(
                  color: value?.isNotEmpty == true
                      ? AppColors.textPrimary
                      : AppColors.textPlaceholder,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHeader(ctx, headerTitle),
              Divider(height: 0.5, color: AppColors.neutral200),
              ...options.map(
                (opt) => _buildOptionTile(ctx, opt),
              ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
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

  Widget _buildSheetHeader(BuildContext ctx, String headerTitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s4,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: AppTypography.callout.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              headerTitle,
              textAlign: TextAlign.center,
              style: AppTypography.callout.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 68), // 平衡取消按钮宽度
        ],
      ),
    );
  }

  Widget _buildOptionTile(BuildContext ctx, String opt) {
    final selected = opt == value;
    return InkWell(
      onTap: () {
        onChanged(opt);
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.s14,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                opt,
                style: AppTypography.callout.copyWith(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

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

class _SearchablePickerContentState extends State<_SearchablePickerContent> {
  final _searchCtl = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
    _searchCtl.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchCtl.text.trim();
    setState(() {
      _filtered = query.isEmpty
          ? widget.options
          : widget.options.where((o) => o.contains(query)).toList();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示条
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.s8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4,
                vertical: AppSpacing.s4,
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '取消',
                      style: AppTypography.callout.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.headerTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 68),
                ],
              ),
            ),
            // 搜索框
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: TextField(
                controller: _searchCtl,
                decoration: InputDecoration(
                  hintText: '搜索...',
                  hintStyle: AppTypography.formField.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.neutral400,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.s10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                style: AppTypography.formField,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Divider(height: 0.5, color: AppColors.neutral200),
            Flexible(
              child: ListView.separated(
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
                  final selected = opt == widget.value;
                  return InkWell(
                    onTap: () => widget.onChanged(opt),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pagePadding,
                        vertical: AppSpacing.s14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt,
                              style: AppTypography.callout.copyWith(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check,
                              size: 20,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
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

/// 详情行 - 只读展示
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: AppTypography.formField.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value.isEmpty ? '未填写' : value,
                  style: AppTypography.formField.copyWith(
                    color: value.isEmpty
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

/// 表单加载占位
class FormLoadingPlaceholder extends StatelessWidget {
  const FormLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2.5),
          const SizedBox(height: AppSpacing.s16),
          Text(
            '加载中...',
            style: AppTypography.footnote.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
