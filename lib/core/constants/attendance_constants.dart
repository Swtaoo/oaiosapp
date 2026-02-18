/// 考勤模块常量 - 对应 src/constants/attendance.ts
class AttendanceConstants {
  AttendanceConstants._();

  // 高德 WebService Key（用于逆地理编码）
  static const String amapKey = '5232c66e4d3707d744f6ea15d466b90b';
  static const int maxLocationRetries = 2;
  static const int locationTimeoutMs = 15000;
  static const int punchCooldownMs = 3000;
}

/// 默认考勤规则
class DefaultAttendanceRule {
  DefaultAttendanceRule._();

  static const int id = 0;
  static const String companyName = '武大科技园创业楼';
  static const String workStartTime = '09:00';
  static const String workEndTime = '18:00';
  static const int lateGraceMinutes = 0;
  static const double fenceLat = 30.457416;
  static const double fenceLng = 114.410632;
  static const int fenceRadius = 250; // meters
  static const List<String> wifiNames = [];
  static const bool requirePhoto = false;
}
