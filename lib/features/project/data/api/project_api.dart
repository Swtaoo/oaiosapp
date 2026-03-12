// 项目 API - 对应 service/projectInfo.ts, projectStaff.ts, chatRecord.ts

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_response.dart';
import '../models/project_models.dart';

class ProjectApi {
  final Dio _dio;

  ProjectApi(this._dio);

  // ========== OSS 文件上传 ==========

  /// 上传文件到 OSS
  /// POST /resource/oss/upload
  /// 返回 {ossId, url}
  Future<ApiResponse<Map<String, dynamic>>> uploadFile(String filePath, {String? fileName}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post(
      '/resource/oss/upload',
      data: formData,
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => json as Map<String, dynamic>,
    );
  }

  // ========== 项目信息 ==========

  /// 获取项目列表
  /// GET /oa/projectInfo/list
  Future<PaginatedResponse<ProjectInfoVo>> getProjectList({
    int pageNum = 1,
    int pageSize = 100,
  }) async {
    final response = await _dio.get(
      '/oa/projectInfo/list',
      queryParameters: {
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => ProjectInfoVo.fromJson(json as Map<String, dynamic>),
    );
  }

  // ========== 项目成员 ==========

  /// 获取当前用户的所有项目成员记录（用于判断用户属于哪些项目）
  /// GET /oa/projectStaff/list?personnelId=xxx&delFlag=0
  Future<PaginatedResponse<ProjectStaffVo>> getMyStaffRecords({
    required int personnelId,
  }) async {
    final response = await _dio.get(
      '/oa/projectStaff/list',
      queryParameters: {
        'personnelId': personnelId,
        'delFlag': 0,
        'pageNum': 1,
        'pageSize': 1000,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => ProjectStaffVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取项目成员列表
  /// GET /oa/projectStaff/list
  Future<PaginatedResponse<ProjectStaffVo>> getProjectStaffList({
    required int projectId,
    int pageNum = 1,
    int pageSize = 1000,
  }) async {
    final response = await _dio.get(
      '/oa/projectStaff/list',
      queryParameters: {
        'projectId': projectId,
        'pageNum': pageNum,
        'pageSize': pageSize,
        'delFlag': 0,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => ProjectStaffVo.fromJson(json as Map<String, dynamic>),
    );
  }

  // ========== 聊天记录 ==========

  /// 获取聊天记录列表
  /// GET /oa/chatRecord/list
  Future<PaginatedResponse<ChatRecordVo>> getChatRecordList({
    required int projectId,
    int pageNum = 1,
    int pageSize = 1000,
    String orderByColumn = 'createTime',
    String isAsc = 'asc',
  }) async {
    final response = await _dio.get(
      '/oa/chatRecord/list',
      queryParameters: {
        'projectId': projectId,
        'pageNum': pageNum,
        'pageSize': pageSize,
        'orderByColumn': orderByColumn,
        'isAsc': isAsc,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => ChatRecordVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 发送聊天消息
  /// POST /oa/chatRecord
  Future<ApiResponse<void>> sendChatMessage({
    required int projectId,
    required int personnelId,
    required String chatContent,
    String? atPersonnelIds,
    int? replyId,
    String? replyContent,
    String? replyUserName,
  }) async {
    final data = <String, dynamic>{
      'projectId': projectId,
      'personnelId': personnelId,
      'chatContent': chatContent,
    };
    if (atPersonnelIds != null) data['atPersonnelIds'] = atPersonnelIds;
    if (replyId != null) data['replyId'] = replyId;
    if (replyContent != null) data['replyContent'] = replyContent;
    if (replyUserName != null) data['replyUserName'] = replyUserName;
    final response = await _dio.post(
      '/oa/chatRecord',
      data: data,
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  /// 发送带附件的聊天消息（图片/文件/回复引用）
  /// POST /oa/chatRecord
  Future<ApiResponse<void>> sendChatMessageWithAttachment({
    required int projectId,
    required int personnelId,
    String? chatContent,
    String? imageUrl,
    String? fileUrl,
    int? fileType,
    String? fileName,
    int? fileSize,
    int? replyId,
    String? replyContent,
    String? replyUserName,
    String? atPersonnelIds,
  }) async {
    final data = <String, dynamic>{
      'projectId': projectId,
      'personnelId': personnelId,
    };
    if (chatContent != null) data['chatContent'] = chatContent;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (fileUrl != null) data['fileUrl'] = fileUrl;
    if (fileType != null) data['fileType'] = fileType;
    if (fileName != null) data['fileName'] = fileName;
    if (fileSize != null) data['fileSize'] = fileSize;
    if (replyId != null) data['replyId'] = replyId;
    if (replyContent != null) data['replyContent'] = replyContent;
    if (replyUserName != null) data['replyUserName'] = replyUserName;
    if (atPersonnelIds != null) data['atPersonnelIds'] = atPersonnelIds;

    final response = await _dio.post('/oa/chatRecord', data: data);
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  /// 撤回聊天消息
  /// POST /oa/chatRecord/revoke/{id}?personnelId=xxx
  Future<ApiResponse<void>> revokeChatMessage(int messageId, int personnelId) async {
    try {
      final response = await _dio.post(
        '/oa/chatRecord/revoke/$messageId',
        queryParameters: {'personnelId': personnelId},
      );
      debugPrint('[project_api] revokeChatMessage response: ${response.data}');
      return ApiResponse.fromJson(
        ensureJsonMap(response.data),
        (_) {},
      );
    } catch (e) {
      debugPrint('[project_api] revokeChatMessage error: $e');
      return const ApiResponse(code: -1, msg: '撤回功能暂不可用');
    }
  }

  /// 删除聊天消息
  /// DELETE /oa/chatRecord/{id}
  Future<ApiResponse<void>> deleteChatMessage(int messageId) async {
    try {
      final response = await _dio.delete('/oa/chatRecord/$messageId');
      return ApiResponse.fromJson(
        ensureJsonMap(response.data),
        (_) {},
      );
    } catch (e) {
      return const ApiResponse(code: -1, msg: '删除功能暂不可用');
    }
  }
}
