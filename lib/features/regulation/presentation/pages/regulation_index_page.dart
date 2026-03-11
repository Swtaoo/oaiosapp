// 规章制度首页 - 对应 src/pages/rules/index.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/api/regulation_api.dart';
import '../../data/models/regulation_models.dart';

final _regulationApiProvider = Provider<RegulationApi>((ref) {
  return RegulationApi(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

class RegulationIndexPage extends ConsumerStatefulWidget {
  const RegulationIndexPage({super.key});

  @override
  ConsumerState<RegulationIndexPage> createState() =>
      _RegulationIndexPageState();
}

class _RegulationIndexPageState extends ConsumerState<RegulationIndexPage> {
  List<RegulationVo> _list = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _finished = false;
  int _currentPage = 1;
  static const _pageSize = 10;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData(isRefresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (_isLoadingMore || (_finished && !isRefresh)) return;

    if (isRefresh) {
      setState(() => _isLoading = true);
      _currentPage = 1;
      _finished = false;
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final api = ref.read(_regulationApiProvider);
      final res = await api.getList(
        pageNum: _currentPage,
        pageSize: _pageSize,
        fileName: _searchQuery.isNotEmpty ? _searchQuery : null,
        isAsc: 'desc',
      );
      if (res.isSuccess) {
        final rows = res.rows ?? [];
        setState(() {
          if (isRefresh) {
            _list = rows;
          } else {
            _list = [..._list, ...rows];
          }
          if (_list.length >= (res.total ?? 0)) {
            _finished = true;
          } else {
            _currentPage++;
          }
        });
      }
    } catch (e, st) {
      debugPrint('[regulation_index_page] Error: $e\n$st');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
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
        title: const Text('规章制度'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => context.push(
                '/regulation/ai?title=AI%E9%97%AE%E5%88%B6%E5%BA%A6',
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
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 100) {
            _loadData();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: () => _loadData(isRefresh: true),
          child: CustomScrollView(
            slivers: [
              // 搜索框
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildAiEntryCard()),
              // 列表
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_list.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      '暂无规章制度',
                      style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildRegulationCard(_list[index]),
                      ),
                      childCount: _list.length,
                    ),
                  ),
                ),
                if (_isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                if (_finished && _list.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          '没有更多数据了',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFC7C7CC),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchQuery = value.trim();
    _loadData(isRefresh: true);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: '搜索文件名称',
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: Color(0xFF9CA3AF),
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (_, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
              );
            },
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildAiEntryCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push(
            '/regulation/ai?title=AI%E9%97%AE%E5%88%B6%E5%BA%A6',
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI问制度',
                        style: AppTypography.subheadline.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        '输入问题，AI 会结合制度内容和引用依据回答。',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegulationCard(RegulationVo reg) {
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
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description,
                size: 20,
                color: Color(0xFF6B7280),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            reg.regulationTypeName!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
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
            const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC), size: 20),
          ],
        ),
      ),
    );
  }
}
