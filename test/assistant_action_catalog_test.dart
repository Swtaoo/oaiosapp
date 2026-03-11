import 'package:flutter_test/flutter_test.dart';

import 'package:oa_flutter/features/assistant/domain/assistant_action_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssistantActionCatalog', () {
    test('请假动作会生成固定接口请求体', () {
      final spec = AssistantActionCatalog.find('leave_apply');
      expect(spec, isNotNull);

      final payload = spec!.buildSubmission(<String, String>{
        'leaveType': '病假',
        'startTime': '2026-03-10 09:00',
        'endTime': '2026-03-10 18:00',
        'reason': '发烧请假',
      });

      expect(payload.apiPath, '/oa/leave');
      expect(payload.method, 'POST');
      expect(payload.body['leaveType'], '病假');
      expect(payload.body['startTime'], '2026-03-10 09:00:00');
      expect(payload.body['endTime'], '2026-03-10 18:00:00');
      expect(payload.body['leaveDays'], closeTo(1.125, 0.0001));
      expect(payload.body['reason'], '发烧请假');
    });

    test('结束时间早于开始时间时抛出格式错误', () {
      final spec = AssistantActionCatalog.find('leave_apply')!;

      expect(
        () => spec.buildSubmission(<String, String>{
          'leaveType': '事假',
          'startTime': '2026-03-10 18:00',
          'endTime': '2026-03-10 09:00',
          'reason': '有事外出',
        }),
        throwsA(
          isA<FormatException>().having(
            (FormatException error) => error.message,
            'message',
            contains('结束时间必须晚于开始时间'),
          ),
        ),
      );
    });

    test('请假诉求会命中请假动作', () {
      final spec = AssistantActionCatalog.matchByPrompt('帮我生成一份请假申请表单');
      expect(spec?.descriptor.actionKey, 'leave_apply');
    });
  });
}
