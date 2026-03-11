class AssistantFieldSpec {
  final String key;
  final String label;
  final String type;
  final bool required;
  final String? placeholder;
  final String? description;
  final String? formatHint;
  final int? maxLength;
  final List<String> options;

  const AssistantFieldSpec({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.placeholder,
    this.description,
    this.formatHint,
    this.maxLength,
    this.options = const <String>[],
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    'label': label,
    'type': type,
    'required': required,
    if (placeholder != null) 'placeholder': placeholder,
    if (description != null) 'description': description,
    if (formatHint != null) 'formatHint': formatHint,
    if (maxLength != null) 'maxLength': maxLength,
    if (options.isNotEmpty) 'options': options,
  };
}

class AssistantActionDescriptor {
  final String actionKey;
  final String title;
  final String submitApi;
  final String submitMethod;
  final String contentType;
  final String summary;
  final List<AssistantFieldSpec> fields;

  const AssistantActionDescriptor({
    required this.actionKey,
    required this.title,
    required this.submitApi,
    required this.submitMethod,
    required this.contentType,
    required this.summary,
    required this.fields,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'actionKey': actionKey,
    'title': title,
    'submitApi': submitApi,
    'submitMethod': submitMethod,
    'contentType': contentType,
    'summary': summary,
    'fields': fields.map((AssistantFieldSpec field) => field.toJson()).toList(),
  };
}

class AssistantFormGenerateRequest {
  final String userPrompt;
  final List<AssistantActionDescriptor> allowedActions;

  const AssistantFormGenerateRequest({
    required this.userPrompt,
    required this.allowedActions,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'userPrompt': userPrompt,
    'allowedActions': allowedActions
        .map((AssistantActionDescriptor action) => action.toJson())
        .toList(),
    'renderRules': <String, dynamic>{
      'format': 'html_css_js',
      'theme': 'mobile_oa',
      'mustUseFieldNames': true,
      'formElementId': 'assistant-form',
      'submitAction': 'call window.assistantSubmitCurrentForm()',
      'allowedScriptRuntime': 'vanilla_js_only',
      'forbiddenCapabilities': <String>[
        'network_request',
        'dynamic_script_injection',
        'external_cdn',
      ],
    },
  };
}

class AssistantGeneratedForm {
  final String actionKey;
  final String title;
  final String? summary;
  final String html;
  final String css;
  final String javascript;

  const AssistantGeneratedForm({
    required this.actionKey,
    required this.title,
    this.summary,
    required this.html,
    required this.css,
    required this.javascript,
  });

  factory AssistantGeneratedForm.fromJson(Map<String, dynamic> json) {
    return AssistantGeneratedForm(
      actionKey: json['actionKey']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      html: json['html']?.toString() ?? '',
      css: json['css']?.toString() ?? '',
      javascript: json['javascript']?.toString() ?? '',
    );
  }

  bool get isUsable =>
      actionKey.isNotEmpty &&
      title.isNotEmpty &&
      html.trim().isNotEmpty &&
      css.trim().isNotEmpty &&
      javascript.trim().isNotEmpty;
}
