import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/api/project_api.dart';

/// 共享的 ProjectApi provider，供 project 模块内各页面使用
final projectApiProvider = Provider<ProjectApi>((ref) {
  return ProjectApi(ref.watch(dioProvider));
});
