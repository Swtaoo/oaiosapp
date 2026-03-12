// 投标信息列表页

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/api/bidding_api.dart';
import '../../data/models/bidding_models.dart';

final _biddingApiProvider = Provider<BiddingApi>((ref) {
  return BiddingApi(ref.watch(dioProvider));
});

class BiddingListPage extends ConsumerStatefulWidget {
  const BiddingListPage({super.key});

  @override
  ConsumerState<BiddingListPage> createState() => _BiddingListPageState();
}

class _BiddingListPageState extends ConsumerState<BiddingListPage> {
  List<BiddingVo> _list = [];
  bool _isLoading = true;
  int _pageNum = 1;
  int _total = 0;
  bool _hasMore = true;
  static const int _pageSize = 20;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool refresh = true}) async {
    if (refresh) {
      _pageNum = 1;
      _hasMore = true;
    }
    if (!_hasMore && !refresh) return;

    if (refresh) setState(() => _isLoading = true);
    try {
      final api = ref.read(_biddingApiProvider);
      final res = await api.getList(
        pageNum: _pageNum,
        pageSize: _pageSize,
        biddingName: _searchQuery.isEmpty ? null : _searchQuery,
        orderByColumn: 'bidding_time',
        isAsc: 'desc',
      );
      if (res.isSuccess) {
        final rows = res.rows ?? [];
        _total = res.total ?? 0;
        setState(() {
          if (refresh) {
            _list = rows;
          } else {
            _list.addAll(rows);
          }
          _hasMore = _list.length < _total;
          _pageNum++;
        });
      }
    } catch (e) {
      debugPrint('[bidding_list_page] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final trimmed = value.trim();
      if (trimmed == _searchQuery) return;
      _searchQuery = trimmed;
      _loadData(refresh: true);
    });
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无链接'), duration: Duration(seconds: 1)),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开链接'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  String _formatDate(String? s) {
    if (s == null || s.isEmpty) return '-';
    final d = DateTime.tryParse(s);
    if (d == null) return s;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('投标信息')),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: () => _loadData(refresh: true),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification &&
                                notification.metrics.pixels >=
                                    notification.metrics.maxScrollExtent - 100) {
                              _loadData(refresh: false);
                            }
                            return false;
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: _list.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index >= _list.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }
                              return _buildCard(_list[index]);
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.separatorNonOpaque, width: 0.5),
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
            Icon(Icons.search, size: 20, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '搜索招标名称',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPlaceholder,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _onSearch('');
                },
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_outlined, size: 60, color: Color(0xFFC7C7CC)),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty ? '暂无投标数据' : '未找到相关招标信息',
            style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BiddingVo item) {
    final hasUrl = item.biddingUrl != null && item.biddingUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => _openUrl(item.biddingUrl),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行: 招标名称
            Text(
              item.biddingName ?? '-',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            // 第二行: 招标时间 + 链接图标
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(
                  _formatDate(item.biddingTime),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                ),
                const Spacer(),
                if (hasUrl)
                  const Icon(Icons.open_in_new, size: 16, color: Color(0xFF667EEA)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
