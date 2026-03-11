import 'dart:convert';

import '../data/models/assistant_models.dart';

class AssistantHtmlDocumentBuilder {
  AssistantHtmlDocumentBuilder._();

  static String build({
    required AssistantGeneratedForm generatedForm,
    required AssistantActionDescriptor descriptor,
  }) {
    final String specJson = jsonEncode(descriptor.toJson());
    final String title = _escapeHtml(generatedForm.title);
    final String summary = _escapeHtml(
      generatedForm.summary?.trim().isNotEmpty == true
          ? generatedForm.summary!
          : descriptor.summary,
    );

    return '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
  <title>$title</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f4f7fb;
      --surface: #ffffff;
      --border: #d9e3f0;
      --text: #142033;
      --muted: #5c6b80;
      --primary: #1769ff;
      --primary-soft: rgba(23, 105, 255, 0.1);
      --success: #1e9e5a;
      --danger: #d93025;
      --shadow: 0 18px 44px rgba(20, 32, 51, 0.08);
      font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
    }

    * { box-sizing: border-box; }

    html, body {
      margin: 0;
      padding: 0;
      background: linear-gradient(180deg, #f7faff 0%, #eef3f9 100%);
      color: var(--text);
    }

    body {
      min-height: 100vh;
      padding: 16px;
    }

    .shell {
      background: var(--surface);
      border: 1px solid rgba(217, 227, 240, 0.9);
      border-radius: 24px;
      box-shadow: var(--shadow);
      overflow: hidden;
    }

    .hero {
      padding: 18px 18px 14px;
      background:
        radial-gradient(circle at top right, rgba(23, 105, 255, 0.18), transparent 42%),
        linear-gradient(135deg, #f3f8ff 0%, #ffffff 62%);
      border-bottom: 1px solid rgba(217, 227, 240, 0.9);
    }

    .eyebrow {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 10px;
      border-radius: 999px;
      background: var(--primary-soft);
      color: var(--primary);
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 0.04em;
    }

    .hero h1 {
      margin: 12px 0 8px;
      font-size: 22px;
      line-height: 1.25;
    }

    .hero p {
      margin: 0;
      font-size: 13px;
      line-height: 1.6;
      color: var(--muted);
    }

    #native-status {
      margin: 14px 18px 0;
      border-radius: 14px;
      padding: 10px 12px;
      font-size: 13px;
      line-height: 1.5;
      display: none;
    }

    #native-status.info { display: block; background: #eef4ff; color: #224077; }
    #native-status.success { display: block; background: #ecfbf3; color: var(--success); }
    #native-status.error { display: block; background: #fff1f0; color: var(--danger); }

    .model-form {
      padding: 18px;
    }

    button[disabled] {
      opacity: 0.68;
      cursor: not-allowed;
    }

${generatedForm.css}
  </style>
</head>
<body>
  <div class="shell">
    <div class="hero">
      <div class="eyebrow">AI 生成表单</div>
      <h1>$title</h1>
      <p>$summary</p>
    </div>
    <div id="native-status" class="info"></div>
    <div class="model-form">
${generatedForm.html}
    </div>
  </div>
  <script>
    window.__ASSISTANT_ACTION_SPEC__ = $specJson;

    function assistantSetNativeStatus(type, message) {
      const el = document.getElementById('native-status');
      if (!el) return;
      if (!message) {
        el.className = '';
        el.style.display = 'none';
        el.textContent = '';
        return;
      }
      el.className = type;
      el.style.display = 'block';
      el.textContent = message;
    }

    function assistantCollectValues() {
      const spec = window.__ASSISTANT_ACTION_SPEC__;
      const values = {};
      (spec.fields || []).forEach((field) => {
        const element = document.querySelector('[name="' + field.key + '"]');
        values[field.key] = element ? String(element.value || '').trim() : '';
      });
      return values;
    }

    function assistantToggleSubmitting(submitting) {
      const form = document.getElementById('assistant-form');
      if (!form) return;
      form.querySelectorAll('button, input, select, textarea').forEach((el) => {
        el.disabled = !!submitting;
      });
    }

    function assistantSubmitCurrentForm() {
      const payload = {
        type: 'submit',
        actionKey: window.__ASSISTANT_ACTION_SPEC__.actionKey,
        values: assistantCollectValues(),
      };
      assistantToggleSubmitting(true);
      assistantSetNativeStatus('info', '正在提交...');
      AssistantBridge.postMessage(JSON.stringify(payload));
    }

    function assistantHandleNativeValidationError(message) {
      assistantToggleSubmitting(false);
      assistantSetNativeStatus('error', message || '提交失败');
    }

    function assistantHandleNativeSuccess(message) {
      assistantToggleSubmitting(false);
      assistantSetNativeStatus('success', message || '提交成功');
    }

    function assistantHandleNativeReady(message) {
      assistantSetNativeStatus('info', message || '');
    }

    document.addEventListener('DOMContentLoaded', function() {
      const form = document.getElementById('assistant-form');
      if (form) {
        form.addEventListener('submit', function(event) {
          event.preventDefault();
          assistantSubmitCurrentForm();
        });
      }
      assistantHandleNativeReady('表单已生成，请填写后提交。');
    });
  </script>
  <script>
${generatedForm.javascript}
  </script>
</body>
</html>
''';
  }

  static String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
