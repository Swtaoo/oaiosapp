// 人员列表页（占位） - 对应 src/pages/me/personnelList.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../register/data/api/register_api.dart';
import '../../../register/data/models/register_models.dart';

final _registerApiProvider = Provider<RegisterApi>((ref) {
  return RegisterApi(ref.watch(dioProvider));
});

class PersonnelListPage extends ConsumerStatefulWidget {
  const PersonnelListPage({super.key});

  @override
  ConsumerState<PersonnelListPage> createState() => _PersonnelListPageState();
}

class _PersonnelListPageState extends ConsumerState<PersonnelListPage> {
  List<PersonnelBasicInfoVo> _list = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(_registerApiProvider);
      final res = await api.getPersonnelList();
      if (res.isSuccess) {
        setState(() => _list = res.rows ?? []);
      }
    } catch (e) { debugPrint('[personnel_list_page] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('人员列表')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 60, color: Color(0xFFC7C7CC)),
                      SizedBox(height: 12),
                      Text('暂无人员数据',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildPersonnelCard(_list[index]),
                  ),
                ),
    );
  }

  Widget _buildPersonnelCard(PersonnelBasicInfoVo info) {
    return Container(
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE5E7EB),
            child: Text(
              (info.name ?? '?').characters.first,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.name ?? '未填写',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  info.phone ?? '',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: Color(0xFFC7C7CC), size: 20),
        ],
      ),
    );
  }
}
