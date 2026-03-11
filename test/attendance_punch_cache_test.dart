import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oa_flutter/core/network/api_response.dart';
import 'package:oa_flutter/features/attendance/data/api/attendance_api.dart';
import 'package:oa_flutter/features/attendance/data/models/attendance_models.dart';
import 'package:oa_flutter/features/attendance/providers/attendance_provider.dart';
import 'package:oa_flutter/features/auth/data/models/auth_models.dart';
import 'package:oa_flutter/features/auth/providers/auth_provider.dart';

class _FakeAttendanceApi extends AttendanceApi {
  final DailyAttendance today;

  _FakeAttendanceApi({required this.today}) : super(Dio());

  @override
  Future<ApiResponse<DailyAttendance>> getToday(int userId) async {
    return ApiResponse(code: 0, data: today);
  }
}

DailyAttendance _buildDailyAttendance({
  required String date,
  AttendancePunchRecord? clockInRecord,
  AttendancePunchRecord? clockOutRecord,
}) {
  return DailyAttendance(
    date: date,
    scheduleType: 'work',
    scheduledClockIn: '09:00',
    scheduledClockOut: '18:00',
    clockInRecord: clockInRecord,
    clockOutRecord: clockOutRecord,
    workHours: 0,
    anomalies: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hasClockedIn/Out：有后端今日数据时以服务端为准', () {
    final state = AttendanceState(
      todayData: _buildDailyAttendance(date: '2026-02-28'),
      localPunchData: LocalPunchData(
        lastPunchDate: '2026-02-28',
        morningPunch: true,
        eveningPunch: true,
        morningTime: '09:12',
        eveningTime: '09:15',
      ),
    );

    expect(state.hasClockedIn, isFalse);
    expect(state.hasClockedOut, isFalse);
  });

  test('hasClockedIn/Out：未获取到后端数据时使用本地缓存兜底', () {
    final state = AttendanceState(
      todayData: null,
      localPunchData: LocalPunchData(
        lastPunchDate: '2026-02-28',
        morningPunch: true,
        eveningPunch: false,
        morningTime: '09:12',
        eveningTime: '',
      ),
    );

    expect(state.hasClockedIn, isTrue);
    expect(state.hasClockedOut, isFalse);
  });

  test('fetchTodayData：后端无打卡记录时清理本地已打卡缓存', () async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    SharedPreferences.setMockInitialValues({
      'attendance_punch_data_1': jsonEncode({
        'lastPunchDate': todayStr,
        'morningPunch': true,
        'eveningPunch': true,
        'morningTime': '09:12',
        'eveningTime': '09:15',
      }),
    });

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(const UserInfo(personnelId: 1)),
        attendanceApiProvider.overrideWithValue(
          _FakeAttendanceApi(today: _buildDailyAttendance(date: todayStr)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(attendanceProvider.notifier);

    await notifier.loadLocalPunchData();
    expect(container.read(attendanceProvider).hasClockedIn, isTrue);
    expect(container.read(attendanceProvider).hasClockedOut, isTrue);

    await notifier.fetchTodayData();

    final state = container.read(attendanceProvider);
    expect(state.hasClockedIn, isFalse);
    expect(state.hasClockedOut, isFalse);
    expect(state.localPunchData.morningPunch, isFalse);
    expect(state.localPunchData.eveningPunch, isFalse);
    expect(state.localPunchData.morningTime, isEmpty);
    expect(state.localPunchData.eveningTime, isEmpty);
  });

  test('fetchTodayData：有打卡记录时同步本地缓存时间', () async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(const UserInfo(personnelId: 1)),
        attendanceApiProvider.overrideWithValue(
          _FakeAttendanceApi(
            today: _buildDailyAttendance(
              date: todayStr,
              clockInRecord: AttendancePunchRecord(
                id: 1,
                userId: 1,
                punchTime: '$todayStr 09:12:00',
                punchLocation: 'test',
                punchType: 0,
                punchCategory: 0,
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(attendanceProvider.notifier).fetchTodayData();

    final state = container.read(attendanceProvider);
    expect(state.hasClockedIn, isTrue);
    expect(state.hasClockedOut, isFalse);
    expect(state.localPunchData.morningPunch, isTrue);
    expect(state.localPunchData.morningTime, '09:12');
  });
}

