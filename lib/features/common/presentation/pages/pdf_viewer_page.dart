// 通用文档查看器页面
// PDF 使用内建渲染，其他格式下载后调用系统应用打开

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';

class PdfViewerPage extends ConsumerStatefulWidget {
  final String url;
  final String title;

  const PdfViewerPage({super.key, required this.url, required this.title});

  @override
  ConsumerState<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends ConsumerState<PdfViewerPage> {
  String? _localPath;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;

  bool get _isPdf {
    final lower = widget.url.toLowerCase();
    return lower.contains('.pdf');
  }

  @override
  void initState() {
    super.initState();
    if (widget.url.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = '文件地址无效';
      });
    } else {
      _downloadFile();
    }
  }

  Future<void> _downloadFile() async {
    try {
      final dio = ref.read(dioProvider);
      final dir = await getTemporaryDirectory();
      final fileName = _extractFileName(widget.url);
      final filePath = '${dir.path}/$fileName';

      // 如果文件已缓存且大小>0，直接使用
      final file = File(filePath);
      if (file.existsSync() && file.lengthSync() > 0) {
        if (mounted) {
          setState(() {
            _localPath = filePath;
            _isLoading = false;
          });
          if (!_isPdf) _openWithSystem(filePath);
        }
        return;
      }

      await dio.download(
        widget.url,
        filePath,
        options: Options(responseType: ResponseType.bytes),
      );

      if (mounted) {
        setState(() {
          _localPath = filePath;
          _isLoading = false;
        });
        if (!_isPdf) _openWithSystem(filePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '文件下载失败: $e';
        });
      }
    }
  }

  String _extractFileName(String url) {
    // 从 URL 中提取文件名，去掉 query 参数
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    // fallback: 使用 hash + 扩展名
    final ext = _isPdf ? '.pdf' : '.doc';
    return '${url.hashCode}$ext';
  }

  void _openWithSystem(String filePath) {
    OpenFile.open(filePath).then((result) {
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开文件: ${result.message}')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isPdf ? Colors.grey.shade900 : AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_localPath != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: '用其他应用打开',
              onPressed: () => _openWithSystem(_localPath!),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_localPath == null) return _buildError();
    if (_isPdf) return _buildPdfViewer();
    return _buildNonPdfPlaceholder();
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载文件...', style: TextStyle(color: AppColors.neutral400)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 60, color: AppColors.neutral300),
          const SizedBox(height: 12),
          Text(
            _error ?? '文件加载失败',
            style: const TextStyle(fontSize: 14, color: AppColors.neutral400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _downloadFile();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Stack(
      children: [
        PDFView(
          filePath: _localPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          onRender: (pages) {
            if (mounted) setState(() => _totalPages = pages ?? 0);
          },
          onError: (error) {
            if (mounted) setState(() => _error = 'PDF 渲染失败: $error');
          },
          onPageError: (page, error) {
            debugPrint('[pdf_viewer] Page $page error: $error');
          },
          onPageChanged: (page, total) {
            if (mounted) setState(() => _currentPage = page ?? 0);
          },
        ),
        if (_totalPages > 1)
          Positioned(
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNonPdfPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description, size: 60, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '该文件格式不支持内建预览\n已尝试调用系统应用打开',
            style: TextStyle(fontSize: 13, color: AppColors.neutral400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openWithSystem(_localPath!),
            icon: const Icon(Icons.open_in_new),
            label: const Text('用其他应用打开'),
          ),
        ],
      ),
    );
  }
}
