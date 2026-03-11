import 'package:flutter_test/flutter_test.dart';

import 'package:oa_flutter/features/assistant/data/models/assistant_models.dart';
import 'package:oa_flutter/features/assistant/domain/assistant_action_catalog.dart';
import 'package:oa_flutter/features/assistant/domain/assistant_html_document_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('HTML 文档会注入 bridge 和固定字段规范', () {
    final descriptor = AssistantActionCatalog.find('leave_apply')!.descriptor;
    const generatedForm = AssistantGeneratedForm(
      actionKey: 'leave_apply',
      title: '请假申请',
      summary: '模型生成表单',
      html: '''
<form id="assistant-form">
  <select name="leaveType"></select>
  <input name="startTime" />
  <input name="endTime" />
  <textarea name="reason"></textarea>
  <button type="submit">提交</button>
</form>
''',
      css: '.demo { color: #1769ff; }',
      javascript: 'window.demoReady = true;',
    );

    final document = AssistantHtmlDocumentBuilder.build(
      generatedForm: generatedForm,
      descriptor: descriptor,
    );

    expect(document, contains('window.__ASSISTANT_ACTION_SPEC__'));
    expect(document, contains('AssistantBridge.postMessage'));
    expect(document, contains('"submitApi":"/oa/leave"'));
    expect(document, contains('assistantHandleNativeValidationError'));
    expect(document, contains('name="leaveType"'));
  });

  test('本地回退表单会生成 assistant-form', () {
    final descriptor = AssistantActionCatalog.find('leave_apply')!.descriptor;
    final generatedForm =
        AssistantHtmlDocumentBuilder.buildFallbackGeneratedForm(
          descriptor: descriptor,
          prompt: '帮我生成一份请假申请表单',
        );

    expect(generatedForm.actionKey, 'leave_apply');
    expect(generatedForm.html, contains('id="assistant-form"'));
    expect(generatedForm.html, contains('name="startTime"'));
    expect(generatedForm.css, contains('.primary-submit'));
  });
}
