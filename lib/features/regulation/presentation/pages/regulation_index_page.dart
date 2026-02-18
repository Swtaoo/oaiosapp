// 规章制度首页 - 对应 src/pages/rules/index.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/api/regulation_api.dart';
import '../../data/models/regulation_models.dart';

final _regulationApiProvider = Provider<RegulationApi>((ref) {
  return RegulationApi(ref.watch(dioProvider));
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

  static const _topCards = [
    _CategoryCard(
      title: '岗位职责',
      icon: Icons.assignment,
      regulationType: 1,
      gradientColors: [Color(0xFFB8C5E3), Color(0xFFC8B0D8)],
    ),
    _CategoryCard(
      title: '行为规范',
      icon: Icons.bar_chart,
      regulationType: 2,
      gradientColors: [Color(0xFFE8C5EF), Color(0xFFF0A2B5)],
    ),
    _CategoryCard(
      title: '员工福利',
      icon: Icons.card_giftcard,
      regulationType: 3,
      gradientColors: [Color(0xFFA0C8E8), Color(0xFF7CD8E8)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData(isRefresh: true);
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
    } catch (e, st) { debugPrint('[regulation_index_page] Error: $e\n$st');
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
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('规章制度')),
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
              // 三个分类卡片
              SliverToBoxAdapter(child: _buildTopCards()),
              // 列表
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_list.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('暂无规章制度',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF9CA3AF))),
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
                      )),
                    ),
                  ),
                if (_finished && _list.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('没有更多数据了',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFFC7C7CC))),
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

  Widget _buildTopCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: _topCards.map((card) {
          return Expanded(
            child: GestureDetector(
              onTap: () => context.push(
                '/regulation/classification?title=${Uri.encodeComponent(card.title)}&regulationType=${card.regulationType}',
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: card.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(card.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(card.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
              child: const Icon(Icons.description,
                  size: 20, color: Color(0xFF6B7280)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayFileName(reg),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (reg.regulationTypeName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(reg.regulationTypeName!,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF6B7280))),
                        ),
                      if (reg.updateTime != null) ...[
                        const SizedBox(width: 8),
                        Text(_formatDate(reg.updateTime),
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF9CA3AF))),
                      ],
                    ],
                  ),
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

class _CategoryCard {
  final String title;
  final IconData icon;
  final int regulationType;
  final List<Color> gradientColors;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.regulationType,
    required this.gradientColors,
  });
}
