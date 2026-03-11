import '../data/models/assistant_models.dart';

class AssistantSubmissionPayload {
  final String apiPath;
  final String method;
  final Map<String, dynamic> body;

  const AssistantSubmissionPayload({
    required this.apiPath,
    required this.method,
    required this.body,
  });
}

class AssistantActionSpec {
  final AssistantActionDescriptor descriptor;
  final AssistantSubmissionPayload Function(Map<String, String> values)
  buildSubmission;

  const AssistantActionSpec({
    required this.descriptor,
    required this.buildSubmission,
  });
}

class AssistantActionCatalog {
  AssistantActionCatalog._();

  // ---------------------------------------------------------------------------
  // Option lists
  // ---------------------------------------------------------------------------

  static const List<String> _leaveTypeOptions = <String>[
    '事假', '病假', '年假', '婚假', '产假', '丧假', '调休', '其他',
  ];

  static const List<String> _transportOptions = <String>[
    '飞机', '高铁/动车', '火车', '长途汽车', '自驾', '其他',
  ];

  static const List<String> _resignTypeOptions = <String>[
    '主动离职', '协商离职', '其他',
  ];

  static const List<String> _salaryAdjustTypeOptions = <String>[
    '晋升调薪', '年度调薪', '特殊调薪', '其他',
  ];

  static const List<String> _punchTypeOptions = <String>[
    '上班打卡', '下班打卡',
  ];

  // ---------------------------------------------------------------------------
  // Action specs
  // ---------------------------------------------------------------------------

  static final Map<String, AssistantActionSpec> specs =
      <String, AssistantActionSpec>{
    'leave_apply': AssistantActionSpec(
      descriptor: const AssistantActionDescriptor(
        actionKey: 'leave_apply',
        title: '请假申请',
        submitApi: '/oa/leave',
        submitMethod: 'POST',
        contentType: 'application/json',
        summary: '填写请假类型、开始时间、结束时间和请假事由后提交请假申请。',
        fields: <AssistantFieldSpec>[
          AssistantFieldSpec(
            key: 'leaveType',
            label: '请假类型',
            type: 'select',
            required: true,
            placeholder: '请选择请假类型',
            options: _leaveTypeOptions,
          ),
          AssistantFieldSpec(
            key: 'startTime',
            label: '开始时间',
            type: 'text',
            required: true,
            placeholder: '例如 2026-03-10 09:00',
            formatHint: 'yyyy-MM-dd HH:mm',
          ),
          AssistantFieldSpec(
            key: 'endTime',
            label: '结束时间',
            type: 'text',
            required: true,
            placeholder: '例如 2026-03-10 18:00',
            formatHint: 'yyyy-MM-dd HH:mm',
          ),
          AssistantFieldSpec(
            key: 'reason',
            label: '请假事由',
            type: 'textarea',
            required: true,
            placeholder: '请输入请假事由',
            maxLength: 500,
          ),
        ],
      ),
      buildSubmission: _buildLeaveSubmission,
    ),

    'trip_apply': AssistantActionSpec(
      descriptor: const AssistantActionDescriptor(
        actionKey: 'trip_apply',
        title: '出差申请',
        submitApi: '/oa/trip',
        submitMethod: 'POST',
        contentType: 'application/json',
        summary: '填写出差目的地、起止日期、交通方式和出差事由后提交出差申请。',
        fields: <AssistantFieldSpec>[
          AssistantFieldSpec(
            key: 'destination',
            label: '出差目的地',
            type: 'text',
            required: true,
            placeholder: '请输入出差目的地',
          ),
          AssistantFieldSpec(
            key: 'startDate',
            label: '开始日期',
            type: 'text',
            required: true,
            placeholder: '例如 2026-03-10',
            formatHint: 'yyyy-MM-dd',
          ),
          AssistantFieldSpec(
            key: 'endDate',
            label: '结束日期',
            type: 'text',
            required: true,
            placeholder: '例如 2026-03-15',
            formatHint: 'yyyy-MM-dd',
          ),
          AssistantFieldSpec(
            key: 'transport',
            label: '交通方式',
            type: 'select',
            required: true,
            placeholder: '请选择交通方式',
            options: _transportOptions,
          ),
          AssistantFieldSpec(
            key: 'reason',
            label: '出差事由',
            type: 'textarea',
            required: true,
            placeholder: '请输入出差事由',
            maxLength: 500,
          ),
        ],
      ),
      buildSubmission: _buildUnimplemented,
    ),

    'overtime_apply': AssistantActionSpec(
      descriptor: const AssistantActionDescriptor(
        actionKey: 'overtime_apply',
        title: '加班申请',
        submitApi: '/oa/overtime',
        submitMethod: 'POST',
        contentType: 'application/json',
        summary: '填写加班日期、起止时间和加班原因后提交加班申请。',
        fields: <AssistantFieldSpec>[
          AssistantFieldSpec(
            key: 'overtimeDate',
            label: '加班日期',
            type: 'text',
            required: true,
            placeholder: '例如 2026-03-10',
            formatHint: 'yyyy-MM-dd',
          ),
          AssistantFieldSpec(
            key: 'startTime',
            label: '开始时间',
            type: 'text',
            required: true,
            placeholder: '例如 18:00',
            formatHint: 'HH:mm',
          ),
          AssistantFieldSpec(
            key: 'endTime',
            label: '结束时间',
            type: 'text',
            required: true,
            placeholder: '例如 22:00',
            formatHint: 'HH:mm',
          ),
          AssistantFieldSpec(
            key: 'reason',
            label: '加班原因',
            type: 'textarea',
            required: true,
            placeholder: '请输入加班原因',
            maxLength: 500,
          ),
        ],
      ),
      buildSubmission: _buildUnimplemented,
    ),

    'resign_apply': AssistantActionSpec(
      descriptor: const AssistantActionDescriptor(
        actionKey: 'resign_apply',
        title: '离职申请',
        submitApi: '/oa/resign',
        submitMethod: 'POST',
        contentType: 'application/json',
        summary: '填写离职类型、预计离职日期和离职原因后提交离职申请。',
        fields: <AssistantFieldSpec>[
          AssistantFieldSpec(
            key: 'resignType',
            label: '离职类型',
            type: 'select',
            required: true,
            placeholder: '请选择离职类型',
            options: _resignTypeOptions,
          ),
          AssistantFieldSpec(
            key: 'resignDate',
            label: '预计离职日期',
            type: 'text',
            required: true,
            placeholder: '例如 2026-04-01',
            formatHint: 'yyyy-MM-dd',
          ),
          AssistantFieldSpec(
            key: 'reason',
            label: '离职原因',
            type: 'textarea',
            required: true,
            placeholder: '请输入离职原因',
            maxLength: 500,
          ),
        ],
      ),
      buildSubmission: _buildUnimplemented,
    ),

    'salary_adjust': AssistantActionSpec(
      descriptor: const AssistantActionDescriptor(
        actionKey: 'salary_adjust',
        title: '调薪申请',
        submitApi: '/oa/salaryAdjust',
        submitMethod: 'POST',
        contentType: 'application/json',
        summary: '填写调薪类型、现岗位、现薪资、申请薪资和调薪原因后提交调薪申请。',
        fields: <AssistantFieldSpec>[
          AssistantFieldSpec(
            key: 'adjustType',
            label: '调薪类型',
            type: 'select',
            required: true,
            placeholder: '请选择调薪类型',
            options: _salaryAdjustTypeOptions,
          ),
          AssistantFieldSpec(
            key: 'position',
            label: '现岗位',
            type: 'text',
            required: true,
            placeholder: '请输入现岗位',
          ),
          AssistantFieldSpec(
            key: 'currentSalary',
            label: '现薪资',
            type: 'text',
            required: true,
            placeholder: '请输入现薪资（元）',
          ),
          AssistantFieldSpec(
            key: 'applySalary',
            label: '申请薪资',
            type: 'text',
            required: true,
            placeholder: '请输入申请薪资（元）',
          ),
          AssistantFieldSpec(
            key: 'reason',
            label: '调薪原因',
            type: 'textarea',
            required: true,
            placeholder: '请输入调薪原因',
            maxLength: 500,
          ),
        ],
      ),
      buildSubmission: _buildUnimplemented,
    ),

    'position_transfer': AssistantActionSpec(
      descriptor: const AssistantActionDescriptor(
        actionKey: 'position_transfer',
        title: '调岗申请',
        submitApi: '/oa/positionTransfer',
        submitMethod: 'POST',
        contentType: 'application/json',
        summary: '填写现部门、现岗位、申请部门、申请岗位和调岗原因后提交调岗申请。',
        fields: <AssistantFieldSpec>[
          AssistantFieldSpec(
            key: 'currentDept',
            label: '现部门',
            type: 'text',
            required: true,
            placeholder: '请输入现部门',
          ),
          AssistantFieldSpec(
            key: 'currentPosition',
            label: '现岗位',
            type: 'text',
            required: true,
            placeholder: '请输入现岗位',
          ),
          AssistantFieldSpec(
            key: 'applyDept',
            label: '申请部门',
            type: 'text',
            required: true,
            placeholder: '请输入申请部门',
          ),
          AssistantFieldSpec(
            key: 'applyPosition',
            label: '申请岗位',
            type: 'text',
            required: true,
            placeholder: '请输入申请岗位',
          ),
          AssistantFieldSpec(
            key: 'reason',
            label: '调岗原因',
            type: 'textarea',
            required: true,
            placeholder: '请输入调岗原因',
            maxLength: 500,
          ),
        ],
      ),
      buildSubmission: _buildUnimplemented,
    ),

    'punch_correct': AssistantActionSpec(
      descriptor: const AssistantActionDescriptor(
        actionKey: 'punch_correct',
        title: '补卡申请',
        submitApi: '/oa/punchCorrect',
        submitMethod: 'POST',
        contentType: 'application/json',
        summary: '填写补卡日期、补卡类型、补卡时间和补卡原因后提交补卡申请。',
        fields: <AssistantFieldSpec>[
          AssistantFieldSpec(
            key: 'punchDate',
            label: '补卡日期',
            type: 'text',
            required: true,
            placeholder: '例如 2026-03-10',
            formatHint: 'yyyy-MM-dd',
          ),
          AssistantFieldSpec(
            key: 'punchType',
            label: '补卡类型',
            type: 'select',
            required: true,
            placeholder: '请选择补卡类型',
            options: _punchTypeOptions,
          ),
          AssistantFieldSpec(
            key: 'punchTime',
            label: '补卡时间',
            type: 'text',
            required: true,
            placeholder: '例如 09:00',
            formatHint: 'HH:mm',
          ),
          AssistantFieldSpec(
            key: 'reason',
            label: '补卡原因',
            type: 'textarea',
            required: true,
            placeholder: '请输入补卡原因',
            maxLength: 500,
          ),
        ],
      ),
      buildSubmission: _buildUnimplemented,
    ),

    'confirmation_apply': AssistantActionSpec(
      descriptor: const AssistantActionDescriptor(
        actionKey: 'confirmation_apply',
        title: '转正申请',
        submitApi: '/oa/confirmation',
        submitMethod: 'POST',
        contentType: 'application/json',
        summary: '填写试用期起止日期、申请转正日期和试用期工作总结后提交转正申请。',
        fields: <AssistantFieldSpec>[
          AssistantFieldSpec(
            key: 'probationStart',
            label: '试用期开始日期',
            type: 'text',
            required: true,
            placeholder: '例如 2025-09-01',
            formatHint: 'yyyy-MM-dd',
          ),
          AssistantFieldSpec(
            key: 'probationEnd',
            label: '试用期结束日期',
            type: 'text',
            required: true,
            placeholder: '例如 2026-03-01',
            formatHint: 'yyyy-MM-dd',
          ),
          AssistantFieldSpec(
            key: 'confirmDate',
            label: '申请转正日期',
            type: 'text',
            required: true,
            placeholder: '例如 2026-03-10',
            formatHint: 'yyyy-MM-dd',
          ),
          AssistantFieldSpec(
            key: 'summary',
            label: '试用期工作总结',
            type: 'textarea',
            required: true,
            placeholder: '请输入试用期工作总结',
            maxLength: 500,
          ),
        ],
      ),
      buildSubmission: _buildUnimplemented,
    ),
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static List<AssistantActionDescriptor> descriptors() {
    return specs.values
        .map((AssistantActionSpec spec) => spec.descriptor)
        .toList(growable: false);
  }

  static AssistantActionSpec? find(String actionKey) => specs[actionKey];

  // ---------------------------------------------------------------------------
  // Submission builders
  // ---------------------------------------------------------------------------

  static AssistantSubmissionPayload _buildLeaveSubmission(
    Map<String, String> values,
  ) {
    final String leaveType = values['leaveType']?.trim() ?? '';
    final String startTimeRaw = values['startTime']?.trim() ?? '';
    final String endTimeRaw = values['endTime']?.trim() ?? '';
    final String reason = values['reason']?.trim() ?? '';

    if (!_leaveTypeOptions.contains(leaveType)) {
      throw const FormatException('请假类型不在允许范围内');
    }

    final DateTime startTime = _parseDateTime(startTimeRaw, '开始时间');
    final DateTime endTime = _parseDateTime(endTimeRaw, '结束时间');
    if (!endTime.isAfter(startTime)) {
      throw const FormatException('结束时间必须晚于开始时间');
    }
    if (reason.isEmpty) {
      throw const FormatException('请填写请假事由');
    }
    if (reason.length > 500) {
      throw const FormatException('请假事由不能超过 500 字');
    }

    final int totalMinutes = endTime.difference(startTime).inMinutes;
    final double leaveDays = totalMinutes / (8 * 60);

    return AssistantSubmissionPayload(
      apiPath: '/oa/leave',
      method: 'POST',
      body: <String, dynamic>{
        'leaveType': leaveType,
        'startTime': '${startTimeRaw.trim()}:00',
        'endTime': '${endTimeRaw.trim()}:00',
        'leaveDays': leaveDays,
        'reason': reason,
      },
    );
  }

  static AssistantSubmissionPayload _buildUnimplemented(
    Map<String, String> _,
  ) {
    throw const FormatException(
      '该审批类型的后端接口尚未开放，暂时无法通过 AI 助手提交',
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static DateTime _parseDateTime(String input, String fieldName) {
    final RegExp pattern = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})$',
    );
    final Match? match = pattern.firstMatch(input);
    if (match == null) {
      throw FormatException('$fieldName格式必须为 yyyy-MM-dd HH:mm');
    }

    final int year = int.parse(match.group(1)!);
    final int month = int.parse(match.group(2)!);
    final int day = int.parse(match.group(3)!);
    final int hour = int.parse(match.group(4)!);
    final int minute = int.parse(match.group(5)!);
    final DateTime dateTime = DateTime(year, month, day, hour, minute);
    if (dateTime.year != year ||
        dateTime.month != month ||
        dateTime.day != day ||
        dateTime.hour != hour ||
        dateTime.minute != minute) {
      throw FormatException('$fieldName不是有效日期');
    }
    return dateTime;
  }
}
