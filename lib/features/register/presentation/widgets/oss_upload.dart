// OSS图片上传组件 - 对应 src/components/OssUpload.vue

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 上传文件项
class UploadFileItem {
  final String uid;
  final String url;
  final int? ossId;
  final String status; // 'uploading', 'success', 'error'
  final int progress;

  const UploadFileItem({
    required this.uid,
    required this.url,
    this.ossId,
    this.status = 'success',
    this.progress = 100,
  });
}

class OssUpload extends StatefulWidget {
  final int maxCount;
  final bool disabled;
  final List<UploadFileItem> initialFiles;
  final ValueChanged<({int ossId, String url})>? onSuccess;
  final ValueChanged<UploadFileItem>? onRemove;
  final double itemSize;
  final WrapAlignment alignment;
  final IconData addButtonIcon;
  final double addButtonIconSize;
  final String addButtonText;
  final Color addButtonIconColor;
  final Color addButtonTextColor;
  final Color addButtonBackgroundColor;
  final Color addButtonBorderColor;
  final double addButtonBorderWidth;

  const OssUpload({
    super.key,
    this.maxCount = 9,
    this.disabled = false,
    this.initialFiles = const [],
    this.onSuccess,
    this.onRemove,
    this.itemSize = 100,
    this.alignment = WrapAlignment.start,
    this.addButtonIcon = Icons.add,
    this.addButtonIconSize = 28,
    this.addButtonText = '上传图片',
    this.addButtonIconColor = AppColors.primary,
    this.addButtonTextColor = AppColors.neutral500,
    this.addButtonBackgroundColor = AppColors.neutral50,
    this.addButtonBorderColor = AppColors.neutral300,
    this.addButtonBorderWidth = 1,
  });

  @override
  State<OssUpload> createState() => _OssUploadState();
}

class _OssUploadState extends State<OssUpload> {
  final _picker = ImagePicker();
  late List<UploadFileItem> _fileList;

  @override
  void initState() {
    super.initState();
    _fileList = List.from(widget.initialFiles);
  }

  @override
  void didUpdateWidget(covariant OssUpload oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFiles != oldWidget.initialFiles) {
      setState(() => _fileList = List.from(widget.initialFiles));
    }
  }

  Future<void> _pickImage() async {
    if (widget.disabled || _fileList.length >= widget.maxCount) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    final uid = '${DateTime.now().millisecondsSinceEpoch}-${image.name}';
    setState(() {
      _fileList.add(
        UploadFileItem(
          uid: uid,
          url: image.path,
          status: 'uploading',
          progress: 0,
        ),
      );
    });

    try {
      final token = await SecureStorageService().getToken();
      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path, filename: image.name),
      });
      final response = await dio.post(
        '${ApiConstants.baseUrl}/resource/oss/upload',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'clientid': ApiConstants.clientId,
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = (sent / total * 100).round();
            setState(() {
              final idx = _fileList.indexWhere((f) => f.uid == uid);
              if (idx >= 0) {
                _fileList[idx] = UploadFileItem(
                  uid: uid,
                  url: image.path,
                  status: 'uploading',
                  progress: progress,
                );
              }
            });
          }
        },
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      if (data['code'] == 200 && data['data'] != null) {
        final ossData = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : Map<String, dynamic>.from(data['data'] as Map);
        final rawOssId = ossData['ossId'];
        final ossId = rawOssId is int
            ? rawOssId
            : rawOssId is num
            ? rawOssId.toInt()
            : rawOssId is String
            ? int.tryParse(rawOssId)
            : null;
        final ossUrl = ossData['url'] as String? ?? image.path;

        setState(() {
          final idx = _fileList.indexWhere((f) => f.uid == uid);
          if (idx >= 0) {
            _fileList[idx] = UploadFileItem(
              uid: ossUrl,
              url: ossUrl,
              ossId: ossId,
              status: 'success',
            );
          }
        });
        widget.onSuccess?.call((ossId: ossId ?? 0, url: ossUrl));
      } else {
        _handleError(uid, data['msg']?.toString() ?? '上传失败');
      }
    } on DioException catch (e) {
      debugPrint('[OssUpload] Upload error: $e');
      final err = e.response?.data;
      if (err is Map && err['msg'] != null) {
        _handleError(uid, err['msg'].toString());
      } else if (err is Map && err['message'] != null) {
        _handleError(uid, err['message'].toString());
      } else {
        _handleError(uid, '上传失败');
      }
    } catch (e) {
      debugPrint('[OssUpload] Upload error: $e');
      _handleError(uid, '上传失败');
    }
  }

  void _handleError(String uid, String msg) {
    setState(() {
      _fileList.removeWhere((f) => f.uid == uid);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _removeFile(int index) {
    final file = _fileList[index];
    setState(() => _fileList.removeAt(index));
    widget.onRemove?.call(file);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: widget.alignment,
      spacing: AppSpacing.s10,
      runSpacing: AppSpacing.s10,
      children: [
        ..._fileList.asMap().entries.map((entry) {
          final idx = entry.key;
          final file = entry.value;
          return _buildItem(file, idx);
        }),
        if (!widget.disabled && _fileList.length < widget.maxCount)
          _buildAddButton(),
      ],
    );
  }

  Widget _buildItem(UploadFileItem file, int index) {
    final size = widget.itemSize;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.s8),
            child: file.url.startsWith('http')
                ? Image.network(
                    file.url,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.neutral100,
                      child: const Icon(
                        Icons.broken_image,
                        color: AppColors.neutral400,
                      ),
                    ),
                  )
                : Image.file(
                    File(file.url),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.neutral100,
                      child: const Icon(
                        Icons.broken_image,
                        color: AppColors.neutral400,
                      ),
                    ),
                  ),
          ),
          if (file.status == 'uploading')
            Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppSpacing.s8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${file.progress}%',
                style: AppTypography.formField.copyWith(
                  color: AppColors.backgroundPrimary,
                ),
              ),
            ),
          if (!widget.disabled && file.status != 'uploading')
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _removeFile(index),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.backgroundPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: widget.itemSize,
        height: widget.itemSize,
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.addButtonBorderColor,
            width: widget.addButtonBorderWidth,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.s8),
          color: widget.addButtonBackgroundColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.addButtonIcon,
              size: widget.addButtonIconSize,
              color: widget.addButtonIconColor,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              widget.addButtonText,
              style: AppTypography.caption1.copyWith(
                color: widget.addButtonTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
