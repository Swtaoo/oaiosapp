import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 安全地将 Dio response.data 转换为 `Map<String, dynamic>`
/// Dio 默认 responseType=json 时返回 Map，但某些情况可能返回 String
Map<String, dynamic> ensureJsonMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String) {
    try {
      final decoded = json.decode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e) {
      debugPrint('[ensureJsonMap] Failed to parse String as JSON: $e');
    }
  }
  debugPrint('[ensureJsonMap] Unexpected data type: ${data.runtimeType}');
  return <String, dynamic>{'code': -1, 'msg': '响应数据格式异常'};
}

/// 通用 API 响应包装 - 对应 {code, data, msg}
class ApiResponse<T> {
  final int? code;
  final T? data;
  final String? msg;
  final String? message;

  const ApiResponse({this.code, this.data, this.msg, this.message});

  bool get isSuccess => code == 0 || code == 200;

  String get errorMessage => msg ?? message ?? '请求错误';

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int?,
      data: json['data'] == null ? null : fromJsonT(json['data']),
      msg: json['msg'] as String?,
      message: json['message'] as String?,
    );
  }
}

/// 分页 API 响应 - 对应 {total, rows, code, msg}
class PaginatedResponse<T> {
  final int? code;
  final int? total;
  final List<T>? rows;
  final String? msg;

  const PaginatedResponse({this.code, this.total, this.rows, this.msg});

  bool get isSuccess => code == 0 || code == 200;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      code: json['code'] as int?,
      total: json['total'] as int?,
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => fromJsonT(e))
          .toList(),
      msg: json['msg'] as String?,
    );
  }
}
