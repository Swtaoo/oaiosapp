import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../project/presentation/theme/chat_colors.dart';
import '../../../regulation/data/api/regulation_api.dart';
import '../../../regulation/data/models/regulation_models.dart';
import '../../data/api/assistant_api.dart';
import '../../data/models/assistant_models.dart';
import '../../domain/assistant_action_catalog.dart';
import '../../domain/assistant_html_document_builder.dart';

final _assistantApiProvider = Provider<AssistantApi>((ref) {
  return AssistantApi(ref.watch(dioProvider));
});

final _regulationAiApiProvider = Provider<RegulationApi>((ref) {
  return RegulationApi(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  static const List<String> _samplePrompts = <String>[
    '帮我生成一份请假申请表单',
    '我要申请出差',
    '加班申请',
    '请假制度是什么？',
  ];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_AssistantMessage> _messages = <_AssistantMessage>[];

  _AssistantFormSession? _activeForm;
  WebViewController? _formController;
  bool _isGenerating = false;
  bool _isSubmitting = false;
  bool _isFormCollapsed = false;

  bool get _isBusy => _isGenerating || _isSubmitting;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _inputController.removeListener(_handleInputChanged);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submitPrompt([String? preset]) async {
    final String prompt = (preset ?? _inputController.text).trim();
    if (prompt.isEmpty || _isBusy) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _messages.add(_AssistantMessage.user(prompt));
      if (preset == null) {
        _inputController.clear();
      }
    });
    _scrollToBottom();

    if (_looksLikeKnowledgeQuestion(prompt)) {
      _appendAssistantLoading('正在查询制度知识库...');
      setState(() => _isGenerating = true);
      await _askRegulation(prompt);
      if (mounted) {
        setState(() => _isGenerating = false);
      }
      return;
    }

    _appendAssistantLoading('正在调用模型生成表单...');
    setState(() => _isGenerating = true);

    final _FormGenerationResult result = await _generateForm(prompt);
    if (!mounted) return;

    if (result.session != null) {
      setState(() {
        _activeForm = result.session;
        _isFormCollapsed = false;
      });
      _replaceLastAssistantMessage(
        _AssistantMessage.assistant(
          '已为你生成”${result.session!.generatedForm.title}”表单，请在下方填写并提交。',
          hasForm: true,
        ),
      );
      _scrollToBottom();
    } else {
      _replaceLastAssistantMessage(
        _AssistantMessage.assistant(
          result.errorMessage ?? '模型没有生成可提交表单。请把意图描述得更具体一些。',
          tone: _AssistantMessageTone.error,
        ),
      );
    }

    if (mounted) {
      setState(() => _isGenerating = false);
    }
  }

  Future<_FormGenerationResult> _generateForm(String prompt) async {
    try {
      final response = await ref
          .read(_assistantApiProvider)
          .generateActionForm(
            AssistantFormGenerateRequest(
              userPrompt: prompt,
              allowedActions: AssistantActionCatalog.descriptors(),
            ),
          );

      if (!response.isSuccess || response.data == null) {
        return _FormGenerationResult(errorMessage: response.errorMessage);
      }

      final AssistantGeneratedForm generatedForm = response.data!;
      final AssistantActionSpec? actionSpec = AssistantActionCatalog.find(
        generatedForm.actionKey,
      );
      if (actionSpec == null) {
        return const _FormGenerationResult(errorMessage: '模型返回了未授权的动作类型');
      }
      if (!_isCompatibleGeneratedForm(generatedForm, actionSpec.descriptor)) {
        return const _FormGenerationResult(errorMessage: '模型生成的表单不符合字段约束，请重试');
      }

      return _FormGenerationResult(
        session: _AssistantFormSession(
          generatedForm: generatedForm,
          actionSpec: actionSpec,
        ),
      );
    } catch (error) {
      return _FormGenerationResult(errorMessage: _normalizeErrorMessage(error));
    }
  }


  bool _isCompatibleGeneratedForm(
    AssistantGeneratedForm generatedForm,
    AssistantActionDescriptor descriptor,
  ) {
    if (!generatedForm.isUsable) {
      return false;
    }
    if (!generatedForm.html.contains('assistant-form')) {
      return false;
    }
    return descriptor.fields.every((AssistantFieldSpec field) {
      return generatedForm.html.contains('name="${field.key}"') ||
          generatedForm.html.contains("name='${field.key}'");
    });
  }

  Future<void> _askRegulation(String prompt) async {
    try {
      final response = await ref
          .read(_regulationAiApiProvider)
          .askRegulation(
            AiRegulationAskRequest(
              question: prompt,
              topK: 6,
              citationRequired: true,
            ),
          );

      if (!mounted) return;

      if (!response.isSuccess || response.data == null) {
        _replaceLastAssistantMessage(
          _AssistantMessage.assistant(
            response.errorMessage,
            tone: _AssistantMessageTone.error,
          ),
        );
        return;
      }

      final AiRegulationAnswer answer = response.data!;
      _replaceLastAssistantMessage(
        _AssistantMessage.assistant(
          (answer.answer ?? '').trim().isEmpty
              ? '本次没有返回明确答案，但我找到了相关制度依据。'
              : answer.answer!.trim(),
          references: answer.references,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _replaceLastAssistantMessage(
        _AssistantMessage.assistant(
          '查询失败：${_normalizeErrorMessage(error)}',
          tone: _AssistantMessageTone.error,
        ),
      );
    }
  }

  Future<void> _handleFormBridgeMessage(String rawMessage) async {
    if (_activeForm == null) {
      return;
    }

    Map<String, dynamic> payload;
    try {
      payload = Map<String, dynamic>.from(jsonDecode(rawMessage) as Map);
    } catch (_) {
      await _notifyFormError('表单提交数据解析失败');
      return;
    }

    if (payload['type']?.toString() != 'submit') {
      return;
    }

    final String actionKey = payload['actionKey']?.toString() ?? '';
    if (actionKey != _activeForm!.actionSpec.descriptor.actionKey) {
      await _notifyFormError('表单动作与系统约束不匹配');
      return;
    }

    final Map<String, dynamic> rawValues = Map<String, dynamic>.from(
      payload['values'] as Map? ?? <String, dynamic>{},
    );
    final Map<String, String> values = rawValues.map(
      (String key, dynamic value) => MapEntry(key, value?.toString() ?? ''),
    );

    AssistantSubmissionPayload submission;
    try {
      submission = _activeForm!.actionSpec.buildSubmission(values);
    } on FormatException catch (error) {
      await _notifyFormError(error.message);
      _showSnack(error.message, isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final Dio dio = ref.read(dioProvider);
      final response = await dio.request(
        submission.apiPath,
        data: submission.body,
        options: Options(method: submission.method),
      );
      final apiResponse = ApiResponse<void>.fromJson(
        ensureJsonMap(response.data),
        (_) {},
      );

      if (!mounted) return;

      if (apiResponse.isSuccess) {
        await _notifyFormSuccess('提交成功');
        setState(() {
          _activeForm = null;
          _formController = null;
        });
        _messages.add(
          _AssistantMessage.assistant(
            '申请已提交成功。',
            tone: _AssistantMessageTone.success,
            actionLabel: '查看审批列表',
            actionRoute: '/approval/list',
          ),
        );
        _showSnack('申请已提交成功');
      } else {
        await _notifyFormError(apiResponse.errorMessage);
        _showSnack(apiResponse.errorMessage, isError: true);
      }
    } catch (error) {
      final String message = _normalizeErrorMessage(error);
      await _notifyFormError(message);
      _showSnack(message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _notifyFormError(String message) async {
    if (_formController == null) return;
    await _formController!.runJavaScript(
      'assistantHandleNativeValidationError(${jsonEncode(message)});',
    );
  }

  Future<void> _notifyFormSuccess(String message) async {
    if (_formController == null) return;
    await _formController!.runJavaScript(
      'assistantHandleNativeSuccess(${jsonEncode(message)});',
    );
  }

  void _appendAssistantLoading(String text) {
    setState(() {
      _messages.add(_AssistantMessage.loading(text));
    });
    _scrollToBottom();
  }

  void _replaceLastAssistantMessage(_AssistantMessage message) {
    setState(() {
      final int lastIndex = _messages.lastIndexWhere(
        (_AssistantMessage item) => !item.isUser,
      );
      if (lastIndex == -1) {
        _messages.add(message);
      } else {
        _messages[lastIndex] = message;
      }
    });
    _scrollToBottom();
  }

  bool _looksLikeKnowledgeQuestion(String text) {
    return text.contains('制度') ||
        text.contains('规则') ||
        text.contains('依据') ||
        text.contains('怎么') ||
        text.contains('如何') ||
        text.contains('什么') ||
        text.contains('吗') ||
        text.contains('?') ||
        text.contains('？');
  }

  String _normalizeErrorMessage(Object error) {
    final String message = error.toString().trim();
    const String prefix = 'Exception: ';
    if (message.startsWith(prefix)) {
      return message.substring(prefix.length);
    }
    return message.isEmpty ? '请求失败，请稍后重试' : message;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? AppColors.error : AppColors.success,
        ),
      );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openFullscreenForm() {
    if (_activeForm == null) return;
    final session = _activeForm!;
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (BuildContext dialogContext) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
            title: Text(session.generatedForm.title),
            centerTitle: true,
          ),
          body: _AssistantFormWebView(
            key: const ValueKey<String>('fullscreen-form'),
            documentHtml: session.documentHtml,
            onControllerReady: (WebViewController controller) {
              _formController = controller;
            },
            onBridgeMessage: _handleFormBridgeMessage,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('AI助手'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeState()
                : _buildConversationList(),
          ),
          _buildComposer(keyboardInset),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1F7FF), Colors.white],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '让模型生成可直接提交的业务表单',
                style: AppTypography.title3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '你输入诉求后，我会先调用模型生成一份内嵌 HTML + CSS + JS 表单，再由 Flutter 按固定接口和字段约束提交。',
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '支持动作: 请假 / 出差 / 加班 / 离职 / 调薪 / 调岗 / 补卡 / 转正',
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _samplePrompts
              .map(
                (String prompt) => ActionChip(
                  label: Text(prompt),
                  onPressed: _isBusy ? null : () => _submitPrompt(prompt),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildConversationList() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: _messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (BuildContext context, int index) {
        final _AssistantMessage message = _messages[index];
        return message.isUser
            ? _buildUserBubble(message)
            : _buildAssistantBubble(message);
      },
    );
  }

  Widget _buildUserBubble(_AssistantMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFFE8F3FF),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Text(message.text, style: AppTypography.callout),
      ),
    );
  }

  Widget _buildAssistantBubble(_AssistantMessage message) {
    final Color accent = switch (message.tone) {
      _AssistantMessageTone.success => AppColors.success,
      _AssistantMessageTone.error => AppColors.error,
      _AssistantMessageTone.normal => AppColors.primary,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: accent,
          child: Icon(
            message.tone == _AssistantMessageTone.error
                ? Icons.priority_high_rounded
                : Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ChatColors.otherBubble,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('AI助手', style: AppTypography.formFieldSemibold),
                        if (message.isLoading) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message.text,
                      style: AppTypography.callout.copyWith(
                        color: message.tone == _AssistantMessageTone.error
                            ? AppColors.error
                            : AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                    if (message.actionRoute != null && message.actionLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton(
                          onPressed: () => context.push(message.actionRoute!),
                          child: Text(message.actionLabel!),
                        ),
                      ),
                    if (message.references.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildReferenceSection(message.references),
                      ),
                  ],
                ),
              ),
              if (message.hasForm && _activeForm != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _buildInlineFormCard(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReferenceSection(List<AiRegulationReference> references) {
    return Column(
      children: references
          .map(
            (AiRegulationReference reference) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(reference.title ?? '制度引用'),
              subtitle: Text(reference.snippet ?? '当前引用未返回摘要。'),
              trailing: (reference.sourceUrl ?? '').isNotEmpty
                  ? const Icon(Icons.open_in_new_rounded, size: 16)
                  : null,
              onTap: (reference.sourceUrl ?? '').isEmpty
                  ? null
                  : () {
                      context.push(
                        '/pdf-viewer?url=${Uri.encodeComponent(reference.sourceUrl!)}&title=${Uri.encodeComponent(reference.title ?? '制度引用')}',
                      );
                    },
            ),
          )
          .toList(),
    );
  }

  Widget _buildInlineFormCard() {
    final _AssistantFormSession session = _activeForm!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isFormCollapsed = !_isFormCollapsed),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.generatedForm.title,
                          style: AppTypography.formFieldSemibold,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${session.actionSpec.descriptor.submitMethod} ${session.actionSpec.descriptor.submitApi}',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isFormCollapsed ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    onPressed: _openFullscreenForm,
                    icon: const Icon(Icons.open_in_full_rounded, size: 16),
                    tooltip: '全屏',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1),
                SizedBox(
                  height: 420,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: _AssistantFormWebView(
                      key: ValueKey<String>(session.documentHtml),
                      documentHtml: session.documentHtml,
                      onControllerReady: (WebViewController controller) {
                        _formController = controller;
                      },
                      onBridgeMessage: _handleFormBridgeMessage,
                    ),
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isFormCollapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(double keyboardInset) {
    final bool canSubmit = !_isBusy && _inputController.text.trim().isNotEmpty;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => canSubmit ? _submitPrompt() : null,
                    decoration: InputDecoration(
                      hintText: '输入需求，例如“帮我生成一份请假申请表单”',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canSubmit ? _submitPrompt : null,
                  icon: _isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantFormWebView extends StatefulWidget {
  final String documentHtml;
  final ValueChanged<WebViewController> onControllerReady;
  final ValueChanged<String> onBridgeMessage;

  const _AssistantFormWebView({
    super.key,
    required this.documentHtml,
    required this.onControllerReady,
    required this.onBridgeMessage,
  });

  @override
  State<_AssistantFormWebView> createState() => _AssistantFormWebViewState();
}

class _AssistantFormWebViewState extends State<_AssistantFormWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final Uri? uri = Uri.tryParse(request.url);
            final String scheme = uri?.scheme.toLowerCase() ?? '';
            if (request.url == 'about:blank' ||
                scheme == 'data' ||
                scheme == 'about') {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'AssistantBridge',
        onMessageReceived: (JavaScriptMessage message) {
          widget.onBridgeMessage(message.message);
        },
      )
      ..loadHtmlString(widget.documentHtml);
    widget.onControllerReady(_controller);
  }

  @override
  void didUpdateWidget(covariant _AssistantFormWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentHtml != widget.documentHtml) {
      _controller.loadHtmlString(widget.documentHtml);
      widget.onControllerReady(_controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

class _AssistantFormSession {
  final AssistantGeneratedForm generatedForm;
  final AssistantActionSpec actionSpec;

  const _AssistantFormSession({
    required this.generatedForm,
    required this.actionSpec,
  });

  String get documentHtml => AssistantHtmlDocumentBuilder.build(
    generatedForm: generatedForm,
    descriptor: actionSpec.descriptor,
  );
}

class _FormGenerationResult {
  final _AssistantFormSession? session;
  final String? errorMessage;

  const _FormGenerationResult({
    this.session,
    this.errorMessage,
  });
}

enum _AssistantMessageTone { normal, success, error }

class _AssistantMessage {
  final bool isUser;
  final String text;
  final bool isLoading;
  final bool hasForm;
  final _AssistantMessageTone tone;
  final List<AiRegulationReference> references;
  final String? actionLabel;
  final String? actionRoute;

  const _AssistantMessage({
    required this.isUser,
    required this.text,
    this.isLoading = false,
    this.hasForm = false,
    this.tone = _AssistantMessageTone.normal,
    this.references = const <AiRegulationReference>[],
    this.actionLabel,
    this.actionRoute,
  });

  factory _AssistantMessage.user(String text) {
    return _AssistantMessage(isUser: true, text: text);
  }

  factory _AssistantMessage.loading(String text) {
    return _AssistantMessage(isUser: false, text: text, isLoading: true);
  }

  factory _AssistantMessage.assistant(
    String text, {
    _AssistantMessageTone tone = _AssistantMessageTone.normal,
    List<AiRegulationReference> references = const <AiRegulationReference>[],
    String? actionLabel,
    String? actionRoute,
    bool hasForm = false,
  }) {
    return _AssistantMessage(
      isUser: false,
      text: text,
      tone: tone,
      references: references,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
      hasForm: hasForm,
    );
  }
}
