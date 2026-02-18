// Register module API - 人事登记模块接口
import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/register_models.dart';

/// 人事登记 API
class RegisterApi {
  final Dio _dio;

  RegisterApi(this._dio);

  // ========== 人员基本信息 ==========

  /// 根据手机号获取人员信息
  /// GET /oa/personnelBasicInfo/phone/{phone}
  Future<ApiResponse<PersonnelBasicInfoVo>> getPersonnelInfoByPhone(
      String phone) async {
    final response = await _dio.get('/oa/personnelBasicInfo/phone/$phone');
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => PersonnelBasicInfoVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取人员信息详情
  /// GET /oa/personnelBasicInfo/{id}
  Future<ApiResponse<PersonnelBasicInfoVo>> getPersonnelInfo(int id) async {
    final response = await _dio.get('/oa/personnelBasicInfo/$id');
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => PersonnelBasicInfoVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取人员列表
  /// GET /oa/personnelBasicInfo/list
  Future<PaginatedResponse<PersonnelBasicInfoVo>> getPersonnelList({
    int? personnelId,
  }) async {
    final response = await _dio.get(
      '/oa/personnelBasicInfo/list',
      queryParameters: {
                'personnelId': ?personnelId,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => PersonnelBasicInfoVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 新增人员基本信息
  /// POST /oa/personnelBasicInfo
  Future<ApiResponse<void>> createPersonnelInfo(
      PersonnelBasicInfoSubmit data) async {
    final response = await _dio.post(
      '/oa/personnelBasicInfo',
      data: data.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  /// 修改人员基本信息
  /// PUT /oa/personnelBasicInfo
  Future<ApiResponse<void>> updatePersonnelInfo(
      PersonnelBasicInfoSubmit data) async {
    final response = await _dio.put(
      '/oa/personnelBasicInfo',
      data: data.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  // ========== 人员履历 ==========

  /// 获取人员履历列表
  /// GET /oa/personnelResume/list
  Future<PaginatedResponse<PersonnelResumeVo>> getResumeList({
    required int personnelId,
  }) async {
    final response = await _dio.get(
      '/oa/personnelResume/list',
      queryParameters: {
        'personnelId': personnelId,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => PersonnelResumeVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 新增人员履历
  /// POST /oa/personnelResume
  Future<ApiResponse<void>> createResume(PersonnelResumeSubmit data) async {
    final response = await _dio.post(
      '/oa/personnelResume',
      data: data.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  /// 修改人员履历
  /// PUT /oa/personnelResume
  Future<ApiResponse<void>> updateResume(PersonnelResumeSubmit data) async {
    final response = await _dio.put(
      '/oa/personnelResume',
      data: data.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  /// 删除人员履历
  /// DELETE /oa/personnelResume/{ids}
  Future<ApiResponse<void>> deleteResume(List<int> ids) async {
    final response = await _dio.delete(
      '/oa/personnelResume/${ids.join(',')}',
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  // ========== 入职计划 ==========

  /// 获取入职计划列表
  /// GET /oa/personnelEntryPlan/list
  Future<PaginatedResponse<PersonnelEntryPlanVo>> getEntryPlanList({
    required int personnelId,
  }) async {
    final response = await _dio.get(
      '/oa/personnelEntryPlan/list',
      queryParameters: {
        'personnelId': personnelId,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => PersonnelEntryPlanVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 新增入职计划
  /// POST /oa/personnelEntryPlan
  Future<ApiResponse<void>> createEntryPlan(
      PersonnelEntryPlanSubmit data) async {
    final response = await _dio.post(
      '/oa/personnelEntryPlan',
      data: data.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  /// 修改入职计划
  /// PUT /oa/personnelEntryPlan
  Future<ApiResponse<void>> updateEntryPlan(
      PersonnelEntryPlanSubmit data) async {
    final response = await _dio.put(
      '/oa/personnelEntryPlan',
      data: data.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  // ========== 家庭关系 ==========

  /// 获取家庭关系列表
  /// GET /oa/personnelFamilyRelation/list
  Future<PaginatedResponse<PersonnelFamilyRelationVo>> getFamilyList({
    required int personnelId,
  }) async {
    final response = await _dio.get(
      '/oa/personnelFamilyRelation/list',
      queryParameters: {
        'personnelId': personnelId,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) =>
          PersonnelFamilyRelationVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 新增家庭关系
  /// POST /oa/personnelFamilyRelation
  Future<ApiResponse<void>> createFamilyRelation(
      PersonnelFamilyRelationSubmit data) async {
    final response = await _dio.post(
      '/oa/personnelFamilyRelation',
      data: data.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  /// 修改家庭关系
  /// PUT /oa/personnelFamilyRelation
  Future<ApiResponse<void>> updateFamilyRelation(
      PersonnelFamilyRelationSubmit data) async {
    final response = await _dio.put(
      '/oa/personnelFamilyRelation',
      data: data.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  /// 删除家庭关系
  /// DELETE /oa/personnelFamilyRelation/{ids}
  Future<ApiResponse<void>> deleteFamilyRelation(List<int> ids) async {
    final response = await _dio.delete(
      '/oa/personnelFamilyRelation/${ids.join(',')}',
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (_) {},
    );
  }

  // ========== OSS 文件上传 ==========

  /// 上传文件
  /// POST /resource/oss/upload
  Future<ApiResponse<Map<String, dynamic>>> uploadFile(
      String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
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
}
