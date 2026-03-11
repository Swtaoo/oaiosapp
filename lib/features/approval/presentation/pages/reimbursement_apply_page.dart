import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../project/data/models/project_models.dart';
import '../../../project/providers/project_providers.dart';
import '../../data/models/approval_models.dart';
import '../../providers/approval_provider.dart';

const List<_DepartmentOption> _departmentOptions = [
  _DepartmentOption(id: 1, name: '技术部'),
  _DepartmentOption(id: 2, name: '财务部'),
  _DepartmentOption(id: 3, name: '人事部'),
  _DepartmentOption(id: 4, name: '市场部'),
  _DepartmentOption(id: 5, name: '运营部'),
];

const List<String> _categories = [
  '差旅费',
  '办公用品',
  '餐费',
  '交通费',
  '通讯费',
  '其他',
];

class ReimbursementApplyPage extends ConsumerStatefulWidget {
  const ReimbursementApplyPage({super.key});

  @override
  ConsumerState<ReimbursementApplyPage> createState() =>
      _ReimbursementApplyPageState();
}

class _ReimbursementApplyPageState extends ConsumerState<ReimbursementApplyPage> {
  static const int _maxProofCount = 3;

  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _uploadCache = <String, String>{};
  final _invoices = <_InvoiceItem>[
    _InvoiceItem(),
  ];

  DateTime? _applyDate;
  _DepartmentOption? _dept;
  ProjectInfoVo? _project;
  List<ProjectInfoVo> _projects = [];
  bool _loadingProjects = false;
  bool _showInvoices = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    for (final invoice in _invoices) {
      invoice.dispose();
    }
    super.dispose();
  }

  int get _userId => ref.read(currentUserProvider)?.effectiveUserId ?? 0;

  String get _userName {
    final name = ref.read(currentUserProvider)?.displayName.trim() ?? '';
    return name.isEmpty ? '当前用户' : name;
  }

  double get _totalAmount {
    return _invoices.fold<double>(
      0,
      (sum, item) => sum + _toAmount(item.amountCtrl.text),
    );
  }

  Future<void> _loadProjects() async {
    setState(() => _loadingProjects = true);
    try {
      final res = await ref.read(projectApiProvider).getProjectList(pageSize: 1000);
      if (!mounted) return;
      if (res.isSuccess && res.rows != null) {
        setState(() {
          _projects = res.rows!.where((e) => e.delFlag != 2).toList();
        });
      }
    } catch (e) {
      debugPrint('[reimbursement_apply] load projects error: $e');
    } finally {
      if (mounted) setState(() => _loadingProjects = false);
    }
  }

  Future<void> _pickApplyDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _applyDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      setState(() => _applyDate = picked);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.warning),
    );
  }

  double _toAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  String _fmtDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }

  String _fmtMoney(double amount) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '$intPart.${parts[1]}';
  }

  bool get _hasInvoiceData {
    return _invoices.any((item) {
      final amount = _toAmount(item.amountCtrl.text);
      return amount > 0 || item.category.trim().isNotEmpty || item.proofPaths.isNotEmpty;
    });
  }

  void _addInvoice() {
    setState(() {
      _invoices.add(_InvoiceItem());
    });
  }

  void _removeInvoice(int index) {
    if (_invoices.length <= 1 || index < 0 || index >= _invoices.length) return;
    setState(() {
      final removed = _invoices.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickInvoiceImage(int index) async {
    final item = _invoices[index];
    if (item.proofPaths.length >= _maxProofCount) {
      _toast('每条发票最多上传 $_maxProofCount 张支付证明');
      return;
    }
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null || !mounted) return;
    setState(() => item.proofPaths.add(img.path));
  }

  Future<List<String>> _uploadProofs(List<String> proofPaths) async {
    final api = ref.read(approvalApiProvider);
    final urls = <String>[];
    for (final path in proofPaths) {
      if (path.isEmpty) continue;
      if (path.startsWith('http')) {
        urls.add(path);
        continue;
      }
      final cached = _uploadCache[path];
      if (cached != null && cached.isNotEmpty) {
        urls.add(cached);
        continue;
      }
      final res = await api.uploadToOss(path);
      if (!res.isSuccess || res.data == null) {
        throw Exception(res.errorMessage);
      }
      final url = res.data!['url']?.toString() ?? '';
      if (url.isEmpty) throw Exception('上传返回缺少 URL');
      _uploadCache[path] = url;
      urls.add(url);
    }
    return urls;
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  int? _extractId(Object? data) {
    if (data == null) return null;
    if (data is num) return data.toInt();
    if (data is String) return int.tryParse(data);
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      return _asInt(map['id']) ??
          _asInt(map['reimbursementId']) ??
          _extractId(map['data']);
    }
    return null;
  }

  Future<int?> _fallbackQueryMainId({
    required int departmentId,
    required int applicantId,
    required int projectId,
    required double totalAmount,
  }) async {
    final res = await ref.read(approvalApiProvider).getReimbursementList(
          pageNum: 1,
          pageSize: 1,
          departmentId: departmentId,
          applicantId: applicantId,
          reimbursementProjectId: projectId,
          totalAmount: totalAmount,
        );
    if (!res.isSuccess || res.rows == null || res.rows!.isEmpty) return null;
    return res.rows!.first.id;
  }

  bool _validate() {
    if (_userId <= 0) return _toastAndFalse('未获取到当前登录用户');
    if (_applyDate == null) return _toastAndFalse('请选择申请日期');
    if (_dept == null) return _toastAndFalse('请选择部门');
    if (_project?.id == null) return _toastAndFalse('请选择报销项目');
    if (_totalAmount <= 0) return _toastAndFalse('报销总金额必须大于0');
    return true;
  }

  bool _toastAndFalse(String msg) {
    _toast(msg);
    return false;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _submitting = true);
    try {
      final applyDate = _fmtDate(_applyDate!);
      final details = <_DetailDraft>[];

      for (final item in _invoices) {
        final amount = _toAmount(item.amountCtrl.text);
        if (amount <= 0) continue;

        final urls = await _uploadProofs(item.proofPaths);
        final category = item.category.trim();
        final remark = item.remarkCtrl.text.trim();
        final detailText = category.isNotEmpty
            ? '$category${remark.isNotEmpty ? ' - $remark' : ''}'
            : '报销明细';

        details.add(
          _DetailDraft(
            amount: amount,
            category: category,
            remark: remark,
            detail: detailText,
            proof: urls.where((e) => e.isNotEmpty).join(','),
          ),
        );
      }

      if (details.isEmpty) {
        _toast('请至少填写一条金额大于0的发票');
        return;
      }

      final api = ref.read(approvalApiProvider);
      final createMain = await api.createReimbursement(
        ReimbursementSubmit(
          departmentId: _dept!.id,
          departmentName: _dept!.name,
          applicantId: _userId,
          applicantName: _userName,
          applyDate: applyDate,
          reimbursementProjectId: _project!.id!,
          reimbursementProjectName: _project!.projectName,
          totalAmount: _totalAmount,
          remark: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          status: '0',
        ),
      );
      if (!createMain.isSuccess) {
        _toast(createMain.errorMessage);
        return;
      }

      int? reimbursementId = _extractId(createMain.data);
      reimbursementId ??= await _fallbackQueryMainId(
        departmentId: _dept!.id,
        applicantId: _userId,
        projectId: _project!.id!,
        totalAmount: _totalAmount,
      );
      if (reimbursementId == null || reimbursementId <= 0) {
        _toast('提交成功但未获取报销ID，请联系管理员核查');
        return;
      }

      var successCount = 0;
      for (final d in details) {
        final res = await api.createReimbursementDetail(
          ReimbursementDetailSubmit(
            reimbursementId: reimbursementId,
            reimbursementDetail: d.detail,
            reimbursementProof: d.proof,
            reimbursementAmount: d.amount,
            category: d.category.isEmpty ? null : d.category,
            remark: d.remark.isEmpty ? null : d.remark,
            status: '0',
          ),
        );
        if (res.isSuccess) successCount++;
      }

      if (!mounted) return;
      final msg = successCount > 0
          ? '报销申请提交成功，已创建 $successCount 条明细'
          : '报销申请提交成功';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.success),
      );
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) _toast('提交失败: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showDepartmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _departmentOptions.map((opt) {
            final selected = _dept?.id == opt.id;
            return ListTile(
              title: Text(opt.name),
              trailing: selected ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _dept = opt);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showProjectSheet() {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final q = searchCtrl.text.toLowerCase().trim();
            final list = q.isEmpty
                ? _projects
                : _projects
                    .where((p) => (p.projectName ?? '').toLowerCase().contains(q))
                    .toList();
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              expand: false,
              builder: (_, scrollCtrl) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        hintText: '搜索项目名称',
                        filled: true,
                        fillColor: const Color(0xFFF2F2F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _loadingProjects
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final p = list[i];
                              final selected = _project?.id == p.id;
                              return ListTile(
                                title: Text(p.projectName ?? '-'),
                                trailing: selected
                                    ? Icon(Icons.check, color: AppColors.primary)
                                    : null,
                                onTap: () {
                                  setState(() => _project = p);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCategorySheet(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _categories.map((c) {
            final selected = _invoices[index].category == c;
            return ListTile(
              title: Text(c),
              trailing: selected ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _invoices[index].category = c);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('报销申请'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 170),
          child: Column(
            children: [
              _card(
                title: '基本信息',
                subtitle: '请先填写基础资料',
                icon: Icons.badge_outlined,
                children: [
                  _field('申请人', _readonly(_userName)),
                  _field(
                    '申请日期',
                    _selector(
                      value: _applyDate == null ? '' : _fmtDate(_applyDate!),
                      hint: '请选择申请日期',
                      onTap: _pickApplyDate,
                    ),
                    required: true,
                  ),
                  _field(
                    '部门',
                    _selector(
                      value: _dept?.name ?? '',
                      hint: '请选择部门',
                      onTap: _showDepartmentSheet,
                    ),
                    required: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _card(
                title: '报销信息',
                subtitle: '项目与申请说明',
                icon: Icons.business_center_outlined,
                children: [
                  _field(
                    '报销项目',
                    _selector(
                      value: _project?.projectName ?? '',
                      hint: _loadingProjects ? '加载中...' : '选择报销项目',
                      onTap: _showProjectSheet,
                    ),
                    required: true,
                  ),
                  _field(
                    '报销说明',
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: _inputDecoration('请简要描述报销事由...'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _card(
                title: '发票信息',
                subtitle: '金额、类别与支付证明',
                icon: Icons.receipt_long_outlined,
                headerTrailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasInvoiceData)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_invoices.length} 张',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      _showInvoices ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
                onHeaderTap: () => setState(() => _showInvoices = !_showInvoices),
                children: _showInvoices
                    ? [
                        ..._invoices.asMap().entries.map((e) => _invoiceCard(e.key)),
                        Align(
                          alignment: Alignment.center,
                          child: OutlinedButton.icon(
                            onPressed: _addInvoice,
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('添加发票'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.35),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ]
                    : [
                        _invoiceCollapsedHint(),
                      ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _invoiceCollapsedHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '已录入 ${_invoices.length} 张发票，点击展开编辑明细',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _showInvoices = true),
            child: const Text('展开'),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '提交金额',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                '¥${_fmtMoney(_totalAmount)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1,
                ),
              ),
              const Spacer(),
              Text(
                '发票 ${_invoices.length} 张',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_submitting ? '提交中...' : '提交申请'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceCard(int index) {
    final item = _invoices[index];
    final amount = _toAmount(item.amountCtrl.text);
    final categoryText = item.category.trim().isEmpty ? '未选择' : item.category.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '发票信息',
                  style: TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '¥${_fmtMoney(amount)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => item.collapsed = !item.collapsed),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.collapsed ? '展开' : '收起',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        item.collapsed
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_invoices.length > 1)
                IconButton(
                  onPressed: () => _removeInvoice(index),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error.withValues(alpha: 0.9),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                  tooltip: '删除发票',
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (item.collapsed)
            Row(
              children: [
                Expanded(
                  child: _invoiceCompactItem(
                    label: '金额',
                    value: '¥${_fmtMoney(amount)}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _invoiceCompactItem(
                    label: '类别',
                    value: categoryText,
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _field(
                    '发票金额',
                    TextField(
                      controller: item.amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration('0.00'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    '报销类别',
                    _selector(
                      value: item.category,
                      hint: '选择类别',
                      onTap: () => _showCategorySheet(index),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '已上传支付证明 ${item.proofPaths.length}/$_maxProofCount 张',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            _field(
              '支付证明',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...item.proofPaths.asMap().entries.map((entry) {
                        return _proofTile(
                          path: entry.value,
                          onRemove: () => setState(() {
                            item.proofPaths.removeAt(entry.key);
                          }),
                        );
                      }),
                      if (item.proofPaths.length < _maxProofCount)
                        GestureDetector(
                          onTap: () => _pickInvoiceImage(index),
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF4F8FF), Color(0xFFEFF4FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined, color: AppColors.textSecondary),
                                Text(
                                  '上传',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '最多 $_maxProofCount 张，提交时自动上传',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            _field(
              '备注',
              TextField(
                controller: item.remarkCtrl,
                maxLength: 200,
                decoration: _inputDecoration('备注信息（选填）'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _invoiceCompactItem({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _proofTile({required String path, required VoidCallback onRemove}) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.separatorNonOpaque.withValues(alpha: 0.7)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: path.startsWith('http')
                  ? Image.network(path, width: 84, height: 84, fit: BoxFit.cover)
                  : Image.file(File(path), width: 84, height: 84, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    String? subtitle,
    IconData? icon,
    required List<Widget> children,
    Widget? headerTrailing,
    VoidCallback? onHeaderTap,
  }) {
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null)
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
        if (icon != null) const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              if (subtitle != null && subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
              ),
            ],
          ),
        ),
        if (headerTrailing != null) headerTrailing,
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.separatorNonOpaque.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          (onHeaderTap == null)
              ? header
              : GestureDetector(onTap: onHeaderTap, child: header),
          if (children.isNotEmpty) const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _field(String label, Widget child, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(text: label),
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _selector({
    required String value,
    required String hint,
    required VoidCallback onTap,
  }) {
    final hasValue = value.trim().isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.separatorNonOpaque.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value : hint,
                style: TextStyle(
                  color: hasValue ? AppColors.textPrimary : AppColors.textPlaceholder,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _readonly(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.separatorNonOpaque.withValues(alpha: 0.7)),
      ),
      child: Text(text),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textPlaceholder),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: AppColors.separatorNonOpaque.withValues(alpha: 0.7),
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      counterStyle: TextStyle(fontSize: 11, color: AppColors.textTertiary),
    );
  }
}

class _DepartmentOption {
  final int id;
  final String name;

  const _DepartmentOption({required this.id, required this.name});
}

class _InvoiceItem {
  final TextEditingController amountCtrl;
  final TextEditingController remarkCtrl;
  String category;
  bool collapsed;
  final List<String> proofPaths;

  _InvoiceItem({
    this.category = '',
    this.collapsed = false,
    List<String>? proofPaths,
    String amount = '',
    String remark = '',
  })  : amountCtrl = TextEditingController(text: amount),
        remarkCtrl = TextEditingController(text: remark),
        proofPaths = proofPaths == null ? <String>[] : List<String>.from(proofPaths);

  void dispose() {
    amountCtrl.dispose();
    remarkCtrl.dispose();
  }
}

class _DetailDraft {
  final double amount;
  final String category;
  final String remark;
  final String detail;
  final String proof;

  const _DetailDraft({
    required this.amount,
    required this.category,
    required this.remark,
    required this.detail,
    required this.proof,
  });
}
