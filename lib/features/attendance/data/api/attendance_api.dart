import 'package:dio/dio.dart';

import '../models/attendance_models.dart';
import '../../../../core/network/api_response.dart';

/// 考勤 API - 对应 src/api/attendance.ts
class AttendanceApi {
  final Dio _dio;

  AttendanceApi(this._dio);

  /// 打卡
  /// POST /oa/attendancePunch
  Future<ApiResponse<AttendancePunchRecord>> punch({
    required String punchLocation,
    required String punchTime,
    required int userId,
    int? punchCategory,
  }) async {
    final response = await _dio.post('/oa/attendancePunch', data: {
      'punchLocation': punchLocation,
      'punchTime': punchTime,
      'userId': userId,
                  'punchCategory': ?punchCategory,
    });
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) =>
          AttendancePunchRecord.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取今日考勤状态
  /// GET /oa/attendance/today
  Future<ApiResponse<DailyAttendance>> getToday(int userId) async {
    final response = await _dio.get(
      '/oa/attendance/today',
      queryParameters: {'userId': userId},
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => DailyAttendance.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取考勤记录列表
  /// GET /oa/attendance/records
  Future<ApiResponse<List<DailyAttendance>>> getRecords({
    required int userId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get(
      '/oa/attendance/records',
      queryParameters: {
        'userId': userId,
        'startDate': startDate,
        'endDate': endDate,
      },
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => (json as List<dynamic>)
          .map((e) => DailyAttendance.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 获取月度统计
  /// GET /oa/attendance/monthly-stats
  Future<ApiResponse<MonthlyStats>> getMonthlyStats({
    required int userId,
    required int year,
    required int month,
  }) async {
    final response = await _dio.get(
      '/oa/attendance/monthly-stats',
      queryParameters: {'userId': userId, 'year': year, 'month': month},
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => MonthlyStats.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取周统计
  /// GET /oa/attendance/weekly-stats
  Future<ApiResponse<PeriodStats>> getWeeklyStats({
    required int userId,
    required int year,
    required int month,
    required int weekOfMonth,
  }) async {
    final response = await _dio.get(
      '/oa/attendance/weekly-stats',
      queryParameters: {
        'userId': userId,
        'year': year,
        'month': month,
        'weekOfMonth': weekOfMonth,
      },
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => PeriodStats.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取月度详细统计
  /// GET /oa/attendance/monthly-detailed-stats
  Future<ApiResponse<PeriodStats>> getMonthlyDetailedStats({
    required int userId,
    required int year,
    required int month,
  }) async {
    final response = await _dio.get(
      '/oa/attendance/monthly-detailed-stats',
      queryParameters: {'userId': userId, 'year': year, 'month': month},
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => PeriodStats.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取成员考勤详情
  /// GET /oa/attendance/member-detail
  Future<ApiResponse<MemberDetail>> getMemberDetail({
    required int userId,
    required int year,
    required int month,
    String? endDate,
  }) async {
    final response = await _dio.get(
      '/oa/attendance/member-detail',
      queryParameters: {
        'userId': userId,
        'year': year,
        'month': month,
        'endDate': ?endDate,
      },
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => MemberDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取团队统计
  /// GET /oa/attendance/team-stats
  Future<ApiResponse<TeamStats>> getTeamStats({
    required int year,
    required int month,
    String? endDate,
  }) async {
    final response = await _dio.get(
      '/oa/attendance/team-stats',
      queryParameters: {
        'year': year,
        'month': month,
        'endDate': ?endDate,
      },
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => TeamStats.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取考勤规则
  /// GET /oa/attendance/rule
  Future<ApiResponse<AttendanceRule>> getRule(int userId) async {
    final response = await _dio.get(
      '/oa/attendance/rule',
      queryParameters: {'userId': userId},
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => AttendanceRule.fromJson(json as Map<String, dynamic>),
    );
  }
}
