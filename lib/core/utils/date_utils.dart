// 日期工具函数 - 对应 src/utils/date.ts

/// 安全地将字符串解析为 DateTime
/// 兼容 "YYYY-MM-DD HH:mm:ss" 和 ISO 格式
DateTime? toDate(dynamic dateStr) {
  if (dateStr == null) return null;
  if (dateStr is DateTime) return dateStr;
  if (dateStr is! String) return null;
  if (dateStr.isEmpty) return null;

  // 兼容 "2024-01-01 12:00:00" 格式
  final normalized = dateStr.replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized);
}

/// 将日期字符串转换为时间戳 (ms)
int toTimestamp(dynamic dateStr, {int fallback = 0}) {
  final d = toDate(dateStr);
  return d?.millisecondsSinceEpoch ?? fallback;
}

/// 提取时间短格式 "HH:mm"
String extractTimeShort(dynamic dateStr) {
  final d = toDate(dateStr);
  if (d == null) return '';
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// 格式化为相对时间: "刚刚" / "x分钟前" / "x小时前" / "x天前"
String formatRelativeTime(dynamic dateStr) {
  final d = toDate(dateStr);
  if (d == null) return '';
  final now = DateTime.now();
  final diff = now.difference(d);
  final minutes = diff.inMinutes;
  if (minutes < 1) return '刚刚';
  if (minutes < 60) return '$minutes分钟前';
  final hours = diff.inHours;
  if (hours < 24) return '$hours小时前';
  final days = diff.inDays;
  if (days < 30) return '$days天前';
  final months = days ~/ 30;
  return '$months个月前';
}

/// 格式化日期为 "YYYY-MM-DD"
String formatDate(dynamic date, {String separator = '-'}) {
  final d = toDate(date);
  if (d == null) return '';
  final y = d.year;
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y$separator$m$separator$day';
}

/// 格式化日期时间为 "YYYY-MM-DD HH:mm:ss"
String formatDateTime(dynamic date) {
  final d = toDate(date);
  if (d == null) return '';
  final s = d.second.toString().padLeft(2, '0');
  return '${formatDate(d)} ${extractTimeShort(d)}:$s';
}

/// 聊天场景时间格式化
/// <1min "刚刚"，<1h "x分钟前"，<24h "x小时前"，>=24h "M-D HH:mm"
String formatChatTime(dynamic dateStr) {
  final d = toDate(dateStr);
  if (d == null) return '';
  final now = DateTime.now();
  final diff = now.difference(d);

  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
  if (diff.inDays < 1) return '${diff.inHours}小时前';

  return '${d.month}-${d.day} ${extractTimeShort(d)}';
}

/// 企微风格聊天分组时间
/// 今天 "HH:mm" / 昨天 "昨天 HH:mm" / 本周 "星期X HH:mm"
/// 今年 "M月D日 HH:mm" / 更早 "YYYY年M月D日 HH:mm"
String formatChatGroupTime(dynamic dateStr) {
  final d = toDate(dateStr);
  if (d == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDay = DateTime(d.year, d.month, d.day);
  final time = extractTimeShort(d);

  final dayDiff = today.difference(msgDay).inDays;

  if (dayDiff == 0) return time;
  if (dayDiff == 1) return '昨天 $time';
  if (dayDiff < 7) {
    const weekdays = ['', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return '${weekdays[d.weekday]} $time';
  }
  if (d.year == now.year) {
    return '${d.month}月${d.day}日 $time';
  }
  return '${d.year}年${d.month}月${d.day}日 $time';
}

/// 判断两条消息之间是否需要显示时间分隔线
/// 间隔 >= 5分钟或跨天返回 true
bool shouldShowTimeSeparator(dynamic time1, dynamic time2) {
  final d1 = toDate(time1);
  final d2 = toDate(time2);
  if (d1 == null || d2 == null) return true;

  // 跨天
  if (d1.year != d2.year || d1.month != d2.month || d1.day != d2.day) {
    return true;
  }

  // 间隔 >= 5分钟
  return (d2.difference(d1)).inMinutes.abs() >= 5;
}

/// 会话列表时间格式化（类似企微）
/// 今天 "HH:mm" / 昨天 "昨天" / 本周 "星期X" / 今年 "M月D日" / 更早 "YYYY/M/D"
String formatConversationTime(int timestampMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDay = DateTime(d.year, d.month, d.day);
  final dayDiff = today.difference(msgDay).inDays;

  if (dayDiff == 0) return extractTimeShort(d);
  if (dayDiff == 1) return '昨天';
  if (dayDiff < 7) {
    const weekdays = ['', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return weekdays[d.weekday];
  }
  if (d.year == now.year) return '${d.month}月${d.day}日';
  return '${d.year}/${d.month}/${d.day}';
}
