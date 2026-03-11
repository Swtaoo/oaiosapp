import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/schedule_models.dart';

/// 排班管理 API
class ScheduleApi {
  final Dio _dio;

  ScheduleApi(this._dio);

  /// 获取可排班的在职人员列表
  /// GET /oa/attendanceSchedule/users
  Future<ApiResponse<List<ScheduleUser>>> getPersonnel() async {
    final response = await _dio.get('/oa/attendanceSchedule/users');
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => (json as List<dynamic>)
          .map((e) => ScheduleUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 查询某用户某月的排班记录
  /// GET /oa/attendanceSchedule/month?userId&year&month
  Future<ApiResponse<List<ScheduleDay>>> getMonthSchedule({
    required int userId,
    required int year,
    required int month,
  }) async {
    final response = await _dio.get(
      '/oa/attendanceSchedule/month',
      queryParameters: {'userId': userId, 'year': year, 'month': month},
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => (json as List<dynamic>)
          .map((e) => ScheduleDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 设置某天排班类型
  /// POST /oa/attendanceSchedule/setDay
  Future<ApiResponse<void>> setDaySchedule({
    required int userId,
    required String date,
    required String scheduleType,
  }) async {
    final response = await _dio.post(
      '/oa/attendanceSchedule/setDay',
      data: {
        'userId': userId,
        'scheduleDate': date,
        'scheduleType': scheduleType,
      },
    );
    return ApiResponse.fromJson(ensureJsonMap(response.data), (_) {});
  }

  /// 全体员工批量设置某月排班
  /// POST /oa/attendanceSchedule/setBatch
  Future<ApiResponse<void>> setBatchMonth({
    required int year,
    required int month,
    required List<String> restDates,
  }) async {
    final response = await _dio.post(
      '/oa/attendanceSchedule/setBatch',
      data: {
        'year': year,
        'month': month,
        'restDates': restDates,
      },
    );
    return ApiResponse.fromJson(ensureJsonMap(response.data), (_) {});
  }
}
