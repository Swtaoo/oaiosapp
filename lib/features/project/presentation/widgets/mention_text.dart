import 'package:flutter/material.dart';

/// @提及文本高亮渲染组件
/// 将消息文本中的 @成员名 以蓝色高亮显示
class MentionText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final Set<String> memberNames;

  /// 企微链接蓝
  static const _mentionColor = Color(0xFF576B95);

  const MentionText({
    super.key,
    required this.text,
    required this.baseStyle,
    required this.memberNames,
  });

  @override
  Widget build(BuildContext context) {
    if (memberNames.isEmpty || !text.contains('@')) {
      return Text(text, style: baseStyle);
    }

    final spans = _buildSpans();
    return RichText(text: TextSpan(children: spans));
  }

  List<TextSpan> _buildSpans() {
    // 按姓名长度降序排列，避免 "张三" 截断 "张三丰"
    final sortedNames = memberNames.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    // 转义正则特殊字符
    final escaped = sortedNames.map(RegExp.escape).join('|');
    final pattern = RegExp('@($escaped)');

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      // 匹配前的普通文本
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }
      // @姓名 蓝色高亮
      spans.add(TextSpan(
        text: match.group(0),
        style: baseStyle.copyWith(color: _mentionColor),
      ));
      lastEnd = match.end;
    }

    // 尾部普通文本
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return spans.isEmpty
        ? [TextSpan(text: text, style: baseStyle)]
        : spans;
  }
}
