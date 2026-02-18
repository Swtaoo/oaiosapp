// 合同管理列表页 - 对应 src/pages/contract/index.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/api/contract_api.dart';
import '../../data/models/contract_models.dart';

final _contractApiProvider = Provider<ContractApi>((ref) {
  return ContractApi(ref.watch(dioProvider));
});

class ContractListPage extends ConsumerStatefulWidget {
  const ContractListPage({super.key});

  @override
  ConsumerState<ContractListPage> createState() => _ContractListPageState();
}

class _ContractListPageState extends ConsumerState<ContractListPage> {
  /// 按 personnelId 去重后的合同用户列表
  List<_ContractUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(_contractApiProvider);
      final res = await api.getList(
        orderByColumn: 'contractExpiryDate',
        isAsc: 'desc',
      );
      if (res.isSuccess) {
        final rows = res.rows ?? [];
        // 按 personnelId 分组，每个员工只保留最近到期的合同
        final userMap = <int, _ContractUser>{};
        for (final item in rows) {
          final pid = item.personnelId ?? item.id ?? 0;
          final name = item.personnelName ?? '未知用户';
          final endDate = item.contractExpiryDate ?? '';
          final file = item.contractFile ?? '';
          if (file.isEmpty || pid == 0 || endDate.isEmpty) continue;

          final existing = userMap[pid];
          if (existing == null) {
            userMap[pid] = _ContractUser(
                id: pid, name: name, contractEndDate: endDate);
          } else if (_parseDate(endDate)
              .isAfter(_parseDate(existing.contractEndDate))) {
            userMap[pid] = _ContractUser(
                id: pid, name: name, contractEndDate: endDate);
          }
        }
        // 按到期时间排序（最早到期在上）
        final list = userMap.values.toList()
          ..sort((a, b) => _parseDate(a.contractEndDate)
              .compareTo(_parseDate(b.contractEndDate)));
        setState(() => _users = list);
      }
    } catch (e) { debugPrint('[contract_list_page] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime _parseDate(String s) => DateTime.tryParse(s) ?? DateTime(2000);

  ExpiryInfo _calculateExpiry(String endDate) {
    final now = DateTime.now();
    final expiry = DateTime.tryParse(endDate) ?? DateTime(2000);
    final diff = expiry.difference(now).inDays;

    if (diff < 0) {
      return ExpiryInfo(text: '已过期', days: diff, type: ExpiryType.expired);
    }
    if (diff == 0) {
      return ExpiryInfo(text: '今天到期', days: 0, type: ExpiryType.today);
    }
    if (diff <= 30) {
      return ExpiryInfo(
          text: '还剩$diff天', days: diff, type: ExpiryType.urgent);
    }
    if (diff <= 90) {
      return ExpiryInfo(
          text: '还剩${diff ~/ 30}个月', days: diff, type: ExpiryType.warning);
    }
    return ExpiryInfo(
        text: _formatDate(endDate), days: diff, type: ExpiryType.normal);
  }

  Color _expiryColor(ExpiryType type) => switch (type) {
        ExpiryType.expired => const Color(0xFFF44336),
        ExpiryType.today => const Color(0xFFFF4757),
        ExpiryType.urgent => const Color(0xFFFF9800),
        ExpiryType.warning => const Color(0xFFFFC107),
        ExpiryType.normal => const Color(0xFF2ED573),
      };

  String _formatDate(String s) {
    final d = DateTime.tryParse(s);
    if (d == null) return s;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('合同管理')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildUserCard(_users[index]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined,
              size: 60, color: Color(0xFFC7C7CC)),
          SizedBox(height: 12),
          Text('暂无合同数据',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _buildUserCard(_ContractUser user) {
    final info = _calculateExpiry(user.contractEndDate);
    final color = _expiryColor(info.type);

    return GestureDetector(
      onTap: () => context.push(
        '/contract/detail?userId=${user.id}&realName=${Uri.encodeComponent(user.name)}',
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Column(
              children: [
                Text(info.text,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color)),
                const SizedBox(height: 2),
                Text(_formatDate(user.contractEndDate),
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF666666))),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: Color(0xFFC7C7CC), size: 20),
          ],
        ),
      ),
    );
  }
}

class _ContractUser {
  final int id;
  final String name;
  final String contractEndDate;
  const _ContractUser(
      {required this.id, required this.name, required this.contractEndDate});
}
