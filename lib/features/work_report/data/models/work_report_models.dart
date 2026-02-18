// 工作汇报模块数据模型

/// 汇报周期
enum WorkReportPeriod {
  weekly,
  monthly,
  yearly;

  String get label => switch (this) {
        weekly => '周报',
        monthly => '月报',
        yearly => '年报',
      };

  static WorkReportPeriod fromString(String? value) => switch (value) {
        'weekly' => weekly,
        'monthly' => monthly,
        'yearly' => yearly,
        _ => weekly,
      };
}

/// 附件
class WorkReportAttachment {
  final String? name;
  final int? size;
  final String? path;
  final String? type;

  const WorkReportAttachment({
    this.name,
    this.size,
    this.path,
    this.type,
  });

  factory WorkReportAttachment.fromJson(Map<String, dynamic> json) {
    return WorkReportAttachment(
      name: json['name'] as String?,
      size: json['size'] as int?,
      path: json['path'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': ?name,
        'size': ?size,
        'path': ?path,
        'type': ?type,
      };
}

/// 工作汇报 VO
class WorkReportVo {
  final int? id;
  final int? personnelId;
  final String? personnelName;
  final String? period;
  final String? title;
  final String? content;
  final String? reportDate;
  final List<WorkReportAttachment>? attachments;
  final String? createTime;
  final String? updateTime;

  const WorkReportVo({
    this.id,
    this.personnelId,
    this.personnelName,
    this.period,
    this.title,
    this.content,
    this.reportDate,
    this.attachments,
    this.createTime,
    this.updateTime,
  });

  factory WorkReportVo.fromJson(Map<String, dynamic> json) {
    return WorkReportVo(
      id: json['id'] as int?,
      personnelId: json['personnelId'] as int?,
      personnelName: json['personnelName'] as String?,
      period: json['period'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      reportDate: json['reportDate'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map(
              (e) => WorkReportAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  WorkReportPeriod get periodEnum => WorkReportPeriod.fromString(period);
}

/// 工作汇报提交
class WorkReportSubmit {
  final String period;
  final String title;
  final String content;
  final String? reportDate;
  final List<WorkReportAttachment>? attachments;

  const WorkReportSubmit({
    required this.period,
    required this.title,
    required this.content,
    this.reportDate,
    this.attachments,
  });

  Map<String, dynamic> toJson() => {
        'period': period,
        'title': title,
        'content': content,
        'reportDate': ?reportDate,
        'attachments': attachments?.map((e) => e.toJson()).toList(),
      };
}
