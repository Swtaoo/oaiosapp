/// 排班管理数据模型

/// 可排班的员工
class ScheduleUser {
  final int userId;
  final String name;
  final String department;
  final String avatar;

  const ScheduleUser({
    required this.userId,
    required this.name,
    required this.department,
    required this.avatar,
  });

  factory ScheduleUser.fromJson(Map<String, dynamic> json) {
    return ScheduleUser(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      department: json['department'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
    );
  }
}

/// 单日排班记录（后端只返回有显式记录的日期，未返回 = 默认工作日）
class ScheduleDay {
  final String date;

  /// workday / rest
  final String scheduleType;

  const ScheduleDay({required this.date, required this.scheduleType});

  bool get isRest => scheduleType == 'rest';

  factory ScheduleDay.fromJson(Map<String, dynamic> json) {
    // 后端字段名: scheduleDate (LocalDate 序列化为 yyyy-MM-dd)
    final rawDate = json['scheduleDate'];
    final date = rawDate is String ? rawDate : '';
    return ScheduleDay(
      date: date,
      scheduleType: json['scheduleType'] as String? ?? 'workday',
    );
  }
}
