import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../project/presentation/theme/chat_colors.dart';
import '../../data/api/regulation_api.dart';
import '../../data/models/regulation_models.dart';

final _regulationAiApiProvider = Provider<RegulationApi>((ref) {
  return RegulationApi(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

class RegulationAiPage extends ConsumerStatefulWidget {
  final String? title;
  final int? regulationType;

  const RegulationAiPage({super.key, this.title, this.regulationType});

  @override
  ConsumerState<RegulationAiPage> createState() => _RegulationAiPageState();
}

class _RegulationAiPageState extends ConsumerState<RegulationAiPage>
    with TickerProviderStateMixin {
  static const _quickPrompts = <String>[
    '试用期请假会影响转正吗？',
    '迟到早退如何认定？',
    '加班调休规则是什么？',
    '报销凭证有哪些要求？',
  ];

  final _questionController = TextEditingController();
  final _conversationScrollController = ScrollController();
  late final AnimationController _welcomePulseController;
  late final AnimationController _cursorBlinkController;
  late final Animation<double> _welcomePulseAnimation;
  late final Animation<double> _cursorBlinkAnimation;

  bool _isSubmitting = false;
  final List<_AiChatTurn> _turns = [];
  final Set<int> _expandedSourceTurns = <int>{};

  @override
  void initState() {
    super.initState();
    _questionController.addListener(_handleInputChanged);
    _welcomePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _cursorBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _welcomePulseAnimation = Tween<double>(begin: 1, end: 1.04).animate(
      CurvedAnimation(parent: _welcomePulseController, curve: Curves.easeInOut),
    );
    _cursorBlinkAnimation = Tween<double>(begin: 0.25, end: 1).animate(
      CurvedAnimation(parent: _cursorBlinkController, curve: Curves.easeInOut),
    );
  }

  void _handleInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _questionController.removeListener(_handleInputChanged);
    _questionController.dispose();
    _conversationScrollController.dispose();
    _welcomePulseController.dispose();
    _cursorBlinkController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion([String? quickQuestion]) async {
    final question = (quickQuestion ?? _questionController.text).trim();
    if (question.isEmpty || _isSubmitting) return;

    final request = AiRegulationAskRequest(
      question: question,
      regulationType: widget.regulationType?.toString(),
      topK: 6,
      citationRequired: true,
    );

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _turns.add(
        _AiChatTurn(
          question: question,
          answer: const AiRegulationAnswer(answer: ''),
          isStreaming: true,
        ),
      );
      _questionController.clear();
    });
    _scrollToBottom();

    try {
      final api = ref.read(_regulationAiApiProvider);
      try {
        await for (final chunk in api.askRegulationStream(request)) {
          if (!mounted) return;
          switch (chunk.type) {
            case 'meta':
              _updateLastTurn(
                answer: _mergeAnswer(
                  base: _turns.last.answer,
                  from: chunk.answer,
                ),
                isStreaming: true,
              );
              break;
            case 'token':
              _updateLastTurn(
                answer: _mergeAnswer(
                  base: _turns.last.answer,
                  answerText:
                      '${_turns.last.answer.answer ?? ''}${chunk.text ?? ''}',
                ),
                isStreaming: true,
              );
              break;
            case 'done':
              _updateLastTurn(
                answer: chunk.answer ?? _turns.last.answer,
                isStreaming: false,
              );
              break;
            case 'error':
              throw Exception(chunk.message ?? '提问失败，请稍后重试');
          }
        }
      } catch (_) {
        final response = await api.askRegulation(request);
        if (!mounted) return;
        if (!response.isSuccess || response.data == null) {
          throw Exception(response.errorMessage);
        }
        _updateLastTurn(answer: response.data!, isStreaming: false);
      }
    } catch (e) {
      if (mounted) {
        final message = _normalizeErrorMessage(e);
        _updateLastTurn(
          answer: _turns.last.answer,
          isStreaming: false,
          errorMessage: message,
        );
        _showSnack(message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _updateLastTurn({
    required AiRegulationAnswer answer,
    required bool isStreaming,
    String? errorMessage,
  }) {
    if (_turns.isEmpty) return;
    setState(() {
      final lastIndex = _turns.length - 1;
      _turns[lastIndex] = _turns[lastIndex].copyWith(
        answer: answer,
        isStreaming: isStreaming,
        errorMessage: errorMessage,
      );
      if (!isStreaming &&
          errorMessage == null &&
          answer.references.isNotEmpty) {
        _expandedSourceTurns.add(lastIndex);
      }
    });
    _scrollToBottom();
  }

  AiRegulationAnswer _mergeAnswer({
    required AiRegulationAnswer base,
    AiRegulationAnswer? from,
    String? answerText,
  }) {
    return AiRegulationAnswer(
      answer: answerText ?? from?.answer ?? base.answer,
      model: from?.model ?? base.model,
      provider: from?.provider ?? base.provider,
      retrievedCount: from?.retrievedCount ?? base.retrievedCount,
      traceId: from?.traceId ?? base.traceId,
      strictCitation: from?.strictCitation ?? base.strictCitation,
      references: from?.references ?? base.references,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_conversationScrollController.hasClients) return;
      _conversationScrollController.animateTo(
        _conversationScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _normalizeErrorMessage(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) return '提问失败，请稍后重试';
    const prefix = 'Exception: ';
    return message.startsWith(prefix)
        ? message.substring(prefix.length)
        : message;
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _clearConversation() {
    if (_turns.isEmpty || _isSubmitting) return;
    setState(() {
      _turns.clear();
      _expandedSourceTurns.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        titleSpacing: AppSpacing.pagePadding,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title ?? 'AI助手'),
            Text(
              widget.regulationType == null ? '制度知识库' : '当前分类制度问答',
              style: AppTypography.caption1.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (_turns.isNotEmpty)
            IconButton(
              tooltip: '清空会话',
              onPressed: _clearConversation,
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _turns.isEmpty
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.s20,
        AppSpacing.pagePadding,
        AppSpacing.s24,
      ),
      children: [
        Center(
          child: ScaleTransition(
            scale: _welcomePulseAnimation,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary300, AppColors.primary700],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(
          '你好，我可以帮你查制度',
          textAlign: TextAlign.center,
          style: AppTypography.title3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          '支持请假、考勤、转正、报销、奖惩等制度问答，并优先给出引用依据。',
          textAlign: TextAlign.center,
          style: AppTypography.subheadline.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        Text(
          '可以直接这样问',
          style: AppTypography.formFieldSemibold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Wrap(
          spacing: AppSpacing.s10,
          runSpacing: AppSpacing.s10,
          children: _quickPrompts
              .map((prompt) => _buildPromptChip(prompt))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPromptChip(String prompt) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isSubmitting ? null : () => _submitQuestion(prompt),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s14,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neutral200, width: 0.8),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.north_east_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.s8),
                Flexible(
                  child: Text(
                    prompt,
                    style: AppTypography.subheadline.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList() {
    return ListView.separated(
      controller: _conversationScrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.s16,
        AppSpacing.pagePadding,
        AppSpacing.s20,
      ),
      itemBuilder: (context, index) => _buildChatTurn(_turns[index]),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s18),
      itemCount: _turns.length,
    );
  }

  Widget _buildChatTurn(_AiChatTurn turn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s14,
                vertical: AppSpacing.s12,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F3FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: SelectableText(
                turn.question,
                style: AppTypography.callout.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        _buildAssistantBubble(turn),
      ],
    );
  }

  Widget _buildAssistantBubble(_AiChatTurn turn) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary300, AppColors.primary700],
            ),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.s10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
            decoration: BoxDecoration(
              color: ChatColors.otherBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: AppColors.neutral200, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI助手',
                      style: AppTypography.formFieldSemibold.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    if ((turn.answer.model ?? '').isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8,
                          vertical: AppSpacing.s4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          turn.answer.model!,
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.primary700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (turn.answer.answer?.trim().isNotEmpty == true &&
                        turn.errorMessage == null)
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: _normalizeAnswerText(
                                turn.answer.answer ?? '',
                              ),
                            ),
                          );
                          if (!mounted) return;
                          _showSnack('回答已复制');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: AppSpacing.s4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.content_copy_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.s4),
                              Text(
                                '复制',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                if (turn.errorMessage != null)
                  _buildErrorState(turn)
                else if (turn.isStreaming &&
                    (turn.answer.answer ?? '').trim().isEmpty)
                  _buildTypingState()
                else
                  _buildAnswerContent(
                    turn.answer.answer ?? '',
                    showCursor: turn.isStreaming,
                  ),
                if (turn.isStreaming &&
                    (turn.answer.answer ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s10),
                  _buildStreamingHint(),
                ],
                if (!turn.isStreaming && turn.errorMessage == null) ...[
                  const SizedBox(height: AppSpacing.s12),
                  _buildTurnActions(turn),
                ],
                if (!turn.isStreaming && turn.answer.references.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s14),
                  _buildSourceSection(
                    turnIndex: _turns.indexOf(turn),
                    references: turn.answer.references,
                  ),
                ],
                if (!turn.isStreaming &&
                    turn.errorMessage == null &&
                    ((turn.answer.traceId ?? '').isNotEmpty ||
                        turn.answer.retrievedCount != null)) ...[
                  const SizedBox(height: AppSpacing.s12),
                  _buildAnswerMeta(turn.answer),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingState() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.s6),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.65),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.s6),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.s10),
        Text(
          '正在生成回答…',
          style: AppTypography.footnote.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingHint() {
    return Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Text(
          '回答仍在生成中',
          style: AppTypography.caption1.copyWith(
            color: AppColors.primary700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(_AiChatTurn turn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD5D2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                '这次回答失败了',
                style: AppTypography.formFieldSemibold.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          Text(
            turn.errorMessage ?? '提问失败，请稍后重试。',
            style: AppTypography.subheadline.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          TextButton.icon(
            onPressed: _isSubmitting
                ? null
                : () => _submitQuestion(turn.question),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('重新提问'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary700,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnActions(_AiChatTurn turn) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        _buildActionChip(
          icon: Icons.refresh_rounded,
          label: '重新生成',
          onTap: _isSubmitting ? null : () => _submitQuestion(turn.question),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s10,
            vertical: AppSpacing.s8,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.neutral200, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.s6),
              Text(
                label,
                style: AppTypography.caption1.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerMeta(AiRegulationAnswer answer) {
    final details = <String>[
      if (answer.retrievedCount != null) '${answer.retrievedCount} 条依据',
      if ((answer.traceId ?? '').isNotEmpty) '追踪ID ${answer.traceId}',
    ];
    return Text(
      details.join(' · '),
      style: AppTypography.caption1.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _buildAnswerContent(String text, {bool showCursor = false}) {
    final normalizedText = _normalizeAnswerText(text);
    final lines = normalizedText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return Text(
        '当前未生成有效回答。',
        style: AppTypography.callout.copyWith(
          color: AppColors.textPrimary,
          height: 1.7,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) ...[
          if (_isNumberedLine(line))
            _buildNumberedLine(
              line,
              showCursor: showCursor && line == lines.last,
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s10),
              child: SelectableText.rich(
                _buildAnswerTextSpan(
                  line,
                  style: AppTypography.callout.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.72,
                  ),
                  showCursor: showCursor && line == lines.last,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildNumberedLine(String line, {bool showCursor = false}) {
    final match = RegExp(r'^(\d+)\.\s*(.*)$').firstMatch(line);
    final indexLabel = match?.group(1) ?? '•';
    final content = match?.group(2) ?? line;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              indexLabel,
              style: AppTypography.caption1.copyWith(
                color: AppColors.primary700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: SelectableText.rich(
              _buildAnswerTextSpan(
                content,
                style: AppTypography.callout.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.72,
                ),
                showCursor: showCursor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildAnswerTextSpan(
    String text, {
    required TextStyle style,
    bool showCursor = false,
  }) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(\*\*.*?\*\*|\[REF-\d+\])');
    var start = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(text: text.substring(start, match.start), style: style),
        );
      }
      final token = match.group(0) ?? '';
      if (token.startsWith('**') && token.endsWith('**')) {
        spans.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: ' $token ',
            style: AppTypography.footnote.copyWith(
              color: AppColors.primary700,
              fontWeight: FontWeight.w700,
              backgroundColor: AppColors.primary50,
            ),
          ),
        );
      }
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }

    if (showCursor) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: FadeTransition(
            opacity: _cursorBlinkAnimation,
            child: Container(
              width: 10,
              height: 18,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      );
    }

    return TextSpan(style: style, children: spans);
  }

  bool _isNumberedLine(String line) {
    return RegExp(r'^\d+\.').hasMatch(line);
  }

  String _normalizeAnswerText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAllMapped(
          RegExp(r'\n(\[REF-\d+\])'),
          (match) => ' ${match.group(1)}',
        )
        .replaceAllMapped(RegExp(r'\n{3,}'), (_) => '\n\n')
        .trim();
  }

  Widget _buildSourceSection({
    required int turnIndex,
    required List<AiRegulationReference> references,
  }) {
    final expanded = _expandedSourceTurns.contains(turnIndex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedSourceTurns.remove(turnIndex);
                } else {
                  _expandedSourceTurns.add(turnIndex);
                }
              });
            },
            child: Ink(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s10,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.neutral200, width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    'Sources',
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s6),
                  Text(
                    '${references.length} 条依据',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s10),
            child: SizedBox(
              height: 144,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: references.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.s10),
                itemBuilder: (context, index) =>
                    _buildSourceCard(references[index]),
              ),
            ),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }

  Widget _buildSourceCard(AiRegulationReference reference) {
    final canOpen = (reference.sourceUrl ?? '').isNotEmpty;
    return SizedBox(
      width: 248,
      child: Material(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canOpen
              ? () {
                  final url = reference.sourceUrl!;
                  context.push(
                    '/pdf-viewer?url=${Uri.encodeComponent(url)}&title=${Uri.encodeComponent(reference.title ?? '引用文档')}',
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPaddingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: AppSpacing.s4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        reference.citationId ?? 'REF',
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.primary700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (canOpen)
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  reference.title ?? '制度引用',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subheadline.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  [
                    if (reference.page != null) '第${reference.page}页',
                    if (reference.score != null)
                      '相关度 ${(reference.score! * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  ].join(' · '),
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Expanded(
                  child: Text(
                    reference.snippet?.trim().isNotEmpty == true
                        ? reference.snippet!
                        : '当前引用未返回摘要。',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(double keyboardInset) {
    final canSubmit =
        !_isSubmitting && _questionController.text.trim().isNotEmpty;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.s10,
              AppSpacing.pagePadding,
              AppSpacing.s12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.s4,
                    bottom: AppSpacing.s8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.s6),
                      Text(
                        _isSubmitting ? '正在生成回答' : '基于制度知识库回答',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isSubmitting) ...[
                        const SizedBox(width: AppSpacing.s6),
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _questionController.text.trim().isNotEmpty
                          ? AppColors.primary.withValues(alpha: 0.28)
                          : AppColors.neutral200,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          decoration: BoxDecoration(
                            color: ChatColors.inputBarBg,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _questionController,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) =>
                                canSubmit ? _submitQuestion() : null,
                            style: AppTypography.callout.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.45,
                            ),
                            decoration: InputDecoration(
                              hintText: '输入你的问题',
                              hintStyle: AppTypography.callout.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.fromLTRB(
                                AppSpacing.s16,
                                AppSpacing.s14,
                                AppSpacing.s16,
                                AppSpacing.s14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: canSubmit
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary400,
                                    AppColors.primary700,
                                  ],
                                )
                              : null,
                          color: canSubmit ? null : ChatColors.sendBtnDisabled,
                          boxShadow: canSubmit
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.22,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: IconButton(
                          onPressed: canSubmit ? _submitQuestion : null,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiChatTurn {
  final String question;
  final AiRegulationAnswer answer;
  final bool isStreaming;
  final String? errorMessage;

  const _AiChatTurn({
    required this.question,
    required this.answer,
    required this.isStreaming,
    this.errorMessage,
  });

  _AiChatTurn copyWith({
    String? question,
    AiRegulationAnswer? answer,
    bool? isStreaming,
    String? errorMessage,
  }) {
    return _AiChatTurn(
      question: question ?? this.question,
      answer: answer ?? this.answer,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: errorMessage,
    );
  }
}
