// 考勤模块数据模型 - 对应 src/api/attendance.ts 类型定义

/// 单次打卡记录 - 对应 AttendancePunchRecordVo
class AttendancePunchRecord {
  final int id;
  final int userId;
  final String punchTime;
  final String punchLocation;

  /// 0=范围内 1=外勤
  final int punchType;

  /// 0=上班 1=下班
  final int punchCategory;

  /// normal / late / early / absent
  final String? status;
  final String? createTime;

  const AttendancePunchRecord({
    required this.id,
    required this.userId,
    required this.punchTime,
    required this.punchLocation,
    required this.punchType,
    required this.punchCategory,
    this.status,
    this.createTime,
  });

  factory AttendancePunchRecord.fromJson(Map<String, dynamic> json) {
    return AttendancePunchRecord(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      punchTime: json['punchTime'] as String? ?? '',
      punchLocation: json['punchLocation'] as String? ?? '',
      punchType: json['punchType'] as int? ?? 0,
      punchCategory: json['punchCategory'] as int? ?? 0,
      status: json['status'] as String?,
      createTime: json['createTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'punchTime': punchTime,
        'punchLocation': punchLocation,
        'punchType': punchType,
        'punchCategory': punchCategory,
        if (status != null) 'status': status,
        if (createTime != null) 'createTime': createTime,
      };
}

/// 每日考勤状态 - 对应 AttendanceDailyStatusVo
class DailyAttendance {
  final String date;

  /// work / rest / holiday
  final String scheduleType;
  final String scheduledClockIn;
  final String scheduledClockOut;
  final AttendancePunchRecord? clockInRecord;
  final AttendancePunchRecord? clockOutRecord;
  final double workHours;
  final List<String> anomalies;

  const DailyAttendance({
    required this.date,
    required this.scheduleType,
    required this.scheduledClockIn,
    required this.scheduledClockOut,
    this.clockInRecord,
    this.clockOutRecord,
    required this.workHours,
    required this.anomalies,
  });

  factory DailyAttendance.fromJson(Map<String, dynamic> json) {
    return DailyAttendance(
      date: json['date'] as String? ?? '',
      scheduleType: json['scheduleType'] as String? ?? '',
      scheduledClockIn: json['scheduledClockIn'] as String? ?? '',
      scheduledClockOut: json['scheduledClockOut'] as String? ?? '',
      clockInRecord: json['clockInRecord'] == null
          ? null
          : AttendancePunchRecord.fromJson(
              json['clockInRecord'] as Map<String, dynamic>),
      clockOutRecord: json['clockOutRecord'] == null
          ? null
          : AttendancePunchRecord.fromJson(
              json['clockOutRecord'] as Map<String, dynamic>),
      workHours: (json['workHours'] as num?)?.toDouble() ?? 0.0,
      anomalies: (json['anomalies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// 月度统计 - 对应 AttendanceMonthlyStatsVo
class MonthlyStats {
  final int totalWorkDays;
  final int actualWorkDays;
  final int lateCount;
  final int earlyLeaveCount;
  final int absentCount;
  final int leaveCount;
  final double totalWorkHours;
  final double averageWorkHours;
  final double overtimeHours;

  const MonthlyStats({
    required this.totalWorkDays,
    required this.actualWorkDays,
    required this.lateCount,
    required this.earlyLeaveCount,
    required this.absentCount,
    required this.leaveCount,
    required this.totalWorkHours,
    required this.averageWorkHours,
    required this.overtimeHours,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      totalWorkDays: json['totalWorkDays'] as int? ?? 0,
      actualWorkDays: json['actualWorkDays'] as int? ?? 0,
      lateCount: json['lateCount'] as int? ?? 0,
      earlyLeaveCount: json['earlyLeaveCount'] as int? ?? 0,
      absentCount: json['absentCount'] as int? ?? 0,
      leaveCount: json['leaveCount'] as int? ?? 0,
      totalWorkHours: (json['totalWorkHours'] as num?)?.toDouble() ?? 0.0,
      averageWorkHours: (json['averageWorkHours'] as num?)?.toDouble() ?? 0.0,
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// 周期详细统计 - 对应 AttendancePeriodStatsVo
class PeriodStats {
  final double averageWorkHours;
  final int actualWorkDays;
  final int workShiftCount;
  final int restDays;
  final int lateCount;
  final int earlyLeaveCount;
  final int absentCount;
  final int absenteeismCount;
  final int fieldWorkCount;
  final double overtimeHours;
  final int makeupPunchCount;
  final String statisticsTime;

  const PeriodStats({
    required this.averageWorkHours,
    required this.actualWorkDays,
    required this.workShiftCount,
    required this.restDays,
    required this.lateCount,
    required this.earlyLeaveCount,
    required this.absentCount,
    required this.absenteeismCount,
    required this.fieldWorkCount,
    required this.overtimeHours,
    required this.makeupPunchCount,
    required this.statisticsTime,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) {
    return PeriodStats(
      averageWorkHours: (json['averageWorkHours'] as num?)?.toDouble() ?? 0.0,
      actualWorkDays: json['actualWorkDays'] as int? ?? 0,
      workShiftCount: json['workShiftCount'] as int? ?? 0,
      restDays: json['restDays'] as int? ?? 0,
      lateCount: json['lateCount'] as int? ?? 0,
      earlyLeaveCount: json['earlyLeaveCount'] as int? ?? 0,
      absentCount: json['absentCount'] as int? ?? 0,
      absenteeismCount: json['absenteeismCount'] as int? ?? 0,
      fieldWorkCount: json['fieldWorkCount'] as int? ?? 0,
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0.0,
      makeupPunchCount: json['makeupPunchCount'] as int? ?? 0,
      statisticsTime: json['statisticsTime'] as String? ?? '',
    );
  }
}

/// 团队成员统计 - 对应 AttendanceTeamMemberStatsVo
class TeamMemberStats {
  final int userId;
  final String name;
  final String avatar;
  final String department;
  final double averageWorkHours;
  final int actualWorkDays;
  final int lateCount;
  final int earlyLeaveCount;
  final int absentCount;
  final int absenteeismCount;
  final int fieldWorkCount;

  const TeamMemberStats({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.department,
    required this.averageWorkHours,
    required this.actualWorkDays,
    required this.lateCount,
    required this.earlyLeaveCount,
    required this.absentCount,
    required this.absenteeismCount,
    required this.fieldWorkCount,
  });

  factory TeamMemberStats.fromJson(Map<String, dynamic> json) {
    return TeamMemberStats(
      userId: json['userId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      department: json['department'] as String? ?? '',
      averageWorkHours:
          (json['averageWorkHours'] as num?)?.toDouble() ?? 0.0,
      actualWorkDays: json['actualWorkDays'] as int? ?? 0,
      lateCount: json['lateCount'] as int? ?? 0,
      earlyLeaveCount: json['earlyLeaveCount'] as int? ?? 0,
      absentCount: json['absentCount'] as int? ?? 0,
      absenteeismCount: json['absenteeismCount'] as int? ?? 0,
      fieldWorkCount: json['fieldWorkCount'] as int? ?? 0,
    );
  }

  /// 按 sortKey 获取数值
  num getValueByKey(String key) {
    switch (key) {
      case 'averageWorkHours':
        return averageWorkHours;
      case 'lateCount':
        return lateCount;
      case 'earlyLeaveCount':
        return earlyLeaveCount;
      case 'absentCount':
        return absentCount;
      case 'absenteeismCount':
        return absenteeismCount;
      case 'fieldWorkCount':
        return fieldWorkCount;
      default:
        return 0;
    }
  }
}

/// 团队统计 - 对应 AttendanceTeamStatsVo
class TeamStats {
  final double teamAverageHours;
  final List<TeamMemberStats> members;

  const TeamStats({
    required this.teamAverageHours,
    required this.members,
  });

  factory TeamStats.fromJson(Map<String, dynamic> json) {
    return TeamStats(
      teamAverageHours:
          (json['teamAverageHours'] as num?)?.toDouble() ?? 0.0,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) =>
                  TeamMemberStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 考勤规则 - 对应 AttendanceRuleVo
class AttendanceRule {
  final int id;
  final String companyName;
  final String workStartTime;
  final String workEndTime;
  final int lateGraceMinutes;
  final double fenceLat;
  final double fenceLng;
  final int fenceRadius;
  final List<String> wifiNames;
  final bool requirePhoto;

  const AttendanceRule({
    required this.id,
    required this.companyName,
    required this.workStartTime,
    required this.workEndTime,
    required this.lateGraceMinutes,
    required this.fenceLat,
    required this.fenceLng,
    required this.fenceRadius,
    required this.wifiNames,
    required this.requirePhoto,
  });

  factory AttendanceRule.fromJson(Map<String, dynamic> json) {
    return AttendanceRule(
      id: json['id'] as int? ?? 0,
      companyName: json['companyName'] as String? ?? '',
      workStartTime: json['workStartTime'] as String? ?? '09:00',
      workEndTime: json['workEndTime'] as String? ?? '18:00',
      lateGraceMinutes: json['lateGraceMinutes'] as int? ?? 0,
      fenceLat: (json['fenceLat'] as num?)?.toDouble() ?? 0.0,
      fenceLng: (json['fenceLng'] as num?)?.toDouble() ?? 0.0,
      fenceRadius: json['fenceRadius'] as int? ?? 250,
      wifiNames: (json['wifiNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      requirePhoto: json['requirePhoto'] as bool? ?? false,
    );
  }
}

/// 日历记录 - 对应 AttendanceCalendarRecordVo
/// 后端只返回 date, status, clockInTime, clockOutTime
/// 其他字段从这些基础字段派生
class CalendarRecord {
  final String date;

  /// 后端返回的原始状态: normal / late / early / absent / rest / future
  final String status;
  final String? clockInTime;
  final String? clockOutTime;

  const CalendarRecord({
    required this.date,
    required this.status,
    this.clockInTime,
    this.clockOutTime,
  });

  /// 派生: 排班类型 (用于日历显示)
  String get scheduleType => status == 'rest' ? 'rest' : 'work';

  /// 派生: 是否有上班打卡
  bool get hasClockIn => clockInTime != null && clockInTime!.isNotEmpty;

  /// 派生: 是否有下班打卡
  bool get hasClockOut => clockOutTime != null && clockOutTime!.isNotEmpty;

  /// 派生: 异常列表 (用于日历着色)
  List<String> get anomalies {
    switch (status) {
      case 'late':
        return ['late'];
      case 'early':
        return ['early'];
      case 'absent':
        return ['missing_clock_in', 'missing_clock_out'];
      default:
        return [];
    }
  }

  factory CalendarRecord.fromJson(Map<String, dynamic> json) {
    return CalendarRecord(
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      clockInTime: json['clockInTime'] as String?,
      clockOutTime: json['clockOutTime'] as String?,
    );
  }
}

/// 成员详情 - 对应 AttendanceMemberDetailVo
class MemberDetail {
  final MemberInfo? memberInfo;

  /// 后端返回 AttendanceTeamMemberStatsVo 类型
  final TeamMemberStats? stats;
  final List<CalendarRecord> calendarRecords;

  const MemberDetail({
    this.memberInfo,
    this.stats,
    required this.calendarRecords,
  });

  factory MemberDetail.fromJson(Map<String, dynamic> json) {
    return MemberDetail(
      memberInfo: json['memberInfo'] == null
          ? null
          : MemberInfo.fromJson(
              json['memberInfo'] as Map<String, dynamic>),
      stats: json['stats'] == null
          ? null
          : TeamMemberStats.fromJson(json['stats'] as Map<String, dynamic>),
      calendarRecords: (json['calendarRecords'] as List<dynamic>?)
              ?.map((e) =>
                  CalendarRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 成员基本信息
class MemberInfo {
  final int userId;
  final String name;
  final String avatar;
  final String department;

  const MemberInfo({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.department,
  });

  factory MemberInfo.fromJson(Map<String, dynamic> json) {
    return MemberInfo(
      userId: json['userId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      department: json['department'] as String? ?? '',
    );
  }
}

/// 本地打卡数据缓存
class LocalPunchData {
  String lastPunchDate;
  bool morningPunch;
  bool eveningPunch;
  String morningTime;
  String eveningTime;

  LocalPunchData({
    this.lastPunchDate = '',
    this.morningPunch = false,
    this.eveningPunch = false,
    this.morningTime = '',
    this.eveningTime = '',
  });

  factory LocalPunchData.fromJson(Map<String, dynamic> json) {
    return LocalPunchData(
      lastPunchDate: json['lastPunchDate'] as String? ?? '',
      morningPunch: json['morningPunch'] as bool? ?? false,
      eveningPunch: json['eveningPunch'] as bool? ?? false,
      morningTime: json['morningTime'] as String? ?? '',
      eveningTime: json['eveningTime'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'lastPunchDate': lastPunchDate,
        'morningPunch': morningPunch,
        'eveningPunch': eveningPunch,
        'morningTime': morningTime,
        'eveningTime': eveningTime,
      };
}
