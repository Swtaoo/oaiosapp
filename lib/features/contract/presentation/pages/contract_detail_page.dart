// 个人合同详情页 - 对应 src/pages/contract/detail.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/api/contract_api.dart';
import '../../data/models/contract_models.dart';

final _contractApiProvider = Provider<ContractApi>((ref) {
  return ContractApi(ref.watch(dioProvider));
});

class ContractDetailPage extends ConsumerStatefulWidget {
  final int userId;
  final String realName;

  const ContractDetailPage({
    super.key,
    required this.userId,
    required this.realName,
  });

  @override
  ConsumerState<ContractDetailPage> createState() =>
      _ContractDetailPageState();
}

class _ContractDetailPageState extends ConsumerState<ContractDetailPage> {
  List<ContractVo> _contracts = [];
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
      final res = await api.getList();
      if (res.isSuccess) {
        // 前端过滤出当前用户的合同
        setState(() {
          _contracts = (res.rows ?? [])
              .where((c) =>
                  c.personnelId == widget.userId &&
                  (c.contractFile ?? '').isNotEmpty)
              .toList();
        });
      }
    } catch (e) { debugPrint('[contract_detail_page] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _buildPreviewUrl(String? file) {
    if (file == null || file.isEmpty) return '';
    if (file.startsWith('http://') || file.startsWith('https://')) return file;
    final base = ApiConstants.baseUrl;
    return file.startsWith('/') ? '$base$file' : '$base/$file';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('个人合同详情')),
      body: Column(
        children: [
          // 头部
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Text(
              '${widget.realName}的个人合同',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          // 合同列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contracts.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _contracts.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildContractCard(_contracts[index]),
                      ),
          ),
        ],
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
          Text('暂无合同文件',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _buildContractCard(ContractVo contract) {
    return GestureDetector(
      onTap: () {
        final url = _buildPreviewUrl(contract.contractFile);
        if (url.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF文件地址无效')),
          );
          return;
        }
        context.push(
          '/pdf-viewer?url=${Uri.encodeComponent(url)}&title=${Uri.encodeComponent('劳动合同')}',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('劳动合同',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  if (contract.contractExpiryDate != null) ...[
                    const SizedBox(height: 4),
                    Text('到期时间: ${contract.contractExpiryDate}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF666666))),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFC7C7CC), size: 20),
          ],
        ),
      ),
    );
  }
}
