// 规章制度分类详情页 - 对应 src/pages/rules/classification_detail.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/api/regulation_api.dart';
import '../../data/models/regulation_models.dart';

final _regulationApiProvider = Provider<RegulationApi>((ref) {
  return RegulationApi(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

class RegulationClassificationPage extends ConsumerStatefulWidget {
  final String title;
  final int regulationType;

  const RegulationClassificationPage({
    super.key,
    required this.title,
    required this.regulationType,
  });

  @override
  ConsumerState<RegulationClassificationPage> createState() =>
      _RegulationClassificationPageState();
}

class _RegulationClassificationPageState
    extends ConsumerState<RegulationClassificationPage> {
  List<RegulationVo> _list = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(_regulationApiProvider);
      final res = await api.getList(
        regulationType: widget.regulationType,
        isAsc: 'desc',
      );
      if (res.isSuccess) {
        setState(() => _list = res.rows ?? []);
      }
    } catch (e) {
      debugPrint('[regulation_classification_page] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _buildPreviewUrl(RegulationVo reg) {
    if (reg.regulationDetail != null && reg.regulationDetail!.isNotEmpty) {
      final detail = reg.regulationDetail!;
      if (detail.startsWith('http://') || detail.startsWith('https://')) {
        return detail;
      }
      final base = ApiConstants.baseUrl;
      return detail.startsWith('/') ? '$base$detail' : '$base/$detail';
    }
    return '${ApiConstants.baseUrl}/oa/companyRegulation/preview/${reg.id}';
  }

  String _displayFileName(RegulationVo reg) {
    final name = reg.fileName ?? '';
    if (name.isEmpty) return reg.regulationTypeName ?? '规章制度文件';
    final ossHash = RegExp(r'^[a-f0-9]{32}\.pdf$', caseSensitive: false);
    if (ossHash.hasMatch(name)) return reg.regulationTypeName ?? '规章制度文件';
    if (name.length > 30) {
      final ext = name.substring(name.lastIndexOf('.'));
      return '${name.substring(0, 27)}...$ext';
    }
    return name;
  }

  String _formatDate(String? s) {
    if (s == null || s.isEmpty) return '';
    final d = DateTime.tryParse(s);
    if (d == null) return s;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGroupedPrimary,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => context.push(
                '/regulation/ai?title=${Uri.encodeComponent('AI问${widget.title}')}&regulationType=${widget.regulationType}',
              ),
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: const Text('AI问制度'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.caption1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _buildFileCard(_list[index]),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 60, color: Color(0xFFC7C7CC)),
          SizedBox(height: 12),
          Text(
            '暂无文件',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
          SizedBox(height: 4),
          Text(
            '该分类下暂无文件',
            style: TextStyle(fontSize: 12, color: Color(0xFFC7C7CC)),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(RegulationVo reg) {
    return GestureDetector(
      onTap: () {
        final url = _buildPreviewUrl(reg);
        context.push(
          '/pdf-viewer?url=${Uri.encodeComponent(url)}&title=${Uri.encodeComponent(reg.fileName ?? '规章制度')}',
        );
      },
      child: Container(
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4757), Color(0xFFFF6B81)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayFileName(reg),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (reg.regulationTypeName != null)
                        Text(
                          reg.regulationTypeName!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      if (reg.updateTime != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(reg.updateTime),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4757).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PDF',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC), size: 20),
          ],
        ),
      ),
    );
  }
}
