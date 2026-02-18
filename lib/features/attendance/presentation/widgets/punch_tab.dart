import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/attendance_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../services/geolocation_service.dart';
import 'punch_button.dart';

/// 打卡标签页 - 对应 src/pages/attendance/components/PunchTab.vue
class PunchTab extends ConsumerStatefulWidget {
  const PunchTab({super.key});

  @override
  ConsumerState<PunchTab> createState() => _PunchTabState();
}

class _PunchTabState extends ConsumerState<PunchTab> {
  String _currentDate = '';
  String _currentTime = '';
  bool _canClick = true;
  bool _isPunching = false;
  bool _punchSuccess = false;
  String _lastDateStr = '';
  Timer? _timeInterval;
  Timer? _cooldownTimer;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    _timeInterval = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCurrentTime(),
    );
    // 初始化考勤数据
    Future.microtask(() {
      ref.read(attendanceProvider.notifier).init();
      ref.read(geolocationProvider.notifier).getCurrentLocation();
    });
    _setupMidnightReset();
  }

  @override
  void dispose() {
    _timeInterval?.cancel();
    _cooldownTimer?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    // 跨天检测
    if (_lastDateStr.isNotEmpty && todayStr != _lastDateStr) {
      ref.read(attendanceProvider.notifier).resetDailyStatus();
      ref.read(attendanceProvider.notifier).init();
    }
    _lastDateStr = todayStr;
    if (mounted) {
      setState(() {
        _currentDate = todayStr;
        _currentTime = DateFormat('HH:mm:ss').format(now);
      });
    }
  }

  void _setupMidnightReset() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final msUntilMidnight = tomorrow.difference(now);

    _midnightTimer = Timer(msUntilMidnight, () {
      ref.read(attendanceProvider.notifier).resetDailyStatus();
      ref.read(attendanceProvider.notifier).init();
      _setupMidnightReset();
    });
  }

  int _parseTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 +
        (int.tryParse(parts[1]) ?? 0);
  }

  String get _statusMessage {
    final store = ref.read(attendanceProvider);
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final clockInMinutes = _parseTimeToMinutes(store.scheduledClockIn);
    final clockOutMinutes = _parseTimeToMinutes(store.scheduledClockOut);

    if (store.hasClockedIn && store.hasClockedOut) {
      return '下班已打卡 ${store.clockOutTime}，可随时更新';
    }
    if (!store.hasClockedIn) {
      if (nowMinutes < clockInMinutes) {
        final diff = clockInMinutes - nowMinutes;
        return '距离上班还有 $diff 分钟';
      }
      final diff = nowMinutes - clockInMinutes;
      return '已迟到 $diff 分钟，请尽快打卡';
    }
    if (nowMinutes < clockOutMinutes) {
      return '工作中...';
    }
    return '已到下班时间，别忘了打卡';
  }

  Color get _statusColor {
    final store = ref.read(attendanceProvider);
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final clockInMinutes = _parseTimeToMinutes(store.scheduledClockIn);
    final clockOutMinutes = _parseTimeToMinutes(store.scheduledClockOut);

    if (store.hasClockedIn && store.hasClockedOut) return AppColors.success;
    if (!store.hasClockedIn && nowMinutes >= clockInMinutes) {
      return AppColors.error;
    }
    if (store.hasClockedIn && !store.hasClockedOut && nowMinutes >= clockOutMinutes) {
      return AppColors.warning;
    }
    return AppColors.textSecondary;
  }

  Color get _statusBgColor {
    final color = _statusColor;
    if (color == AppColors.success) return AppColors.success.withValues(alpha: 0.1);
    if (color == AppColors.error) return AppColors.error.withValues(alpha: 0.1);
    if (color == AppColors.warning) return AppColors.warning.withValues(alpha: 0.1);
    return const Color(0xFFF2F2F7);
  }

  void _updateWithinRange() {
    final store = ref.read(attendanceProvider);
    ref.read(geolocationProvider.notifier).checkWithinRange(
      store.rule.fenceLat,
      store.rule.fenceLng,
      store.rule.fenceRadius,
    );
  }

  Future<String> _handleGetLocation() async {
    final addr =
        await ref.read(geolocationProvider.notifier).getCurrentLocation();
    _updateWithinRange();
    return addr;
  }

  Future<void> _handlePunch() async {
    if (!_canClick || _isPunching) return;

    setState(() {
      _isPunching = true;
      _canClick = false;
      _punchSuccess = false;
    });

    final store = ref.read(attendanceProvider);
    final isUpdate = store.hasClockedIn && store.hasClockedOut;
    final punchType = store.hasClockedIn ? '下班' : '上班';

    try {
      final currentLocation = await _handleGetLocation();
      final now = DateTime.now();
      final punchTime =
          '${DateFormat('yyyy-MM-dd').format(now)} ${DateFormat('HH:mm:ss').format(now)}';

      await ref.read(attendanceProvider.notifier).doPunch(
            punchLocation: currentLocation,
            punchTime: punchTime,
          );

      setState(() => _punchSuccess = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUpdate ? '下班卡已更新' : '$punchType打卡成功'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _punchSuccess = false);
      });
    } catch (e) { debugPrint('[punch_tab] Error: $e');
      // 401 等已在 HTTP 层处理
    } finally {
      setState(() => _isPunching = false);
      _handleGetLocation().whenComplete(() {
        _cooldownTimer = Timer(
          const Duration(milliseconds: AttendanceConstants.punchCooldownMs),
          () {
            if (mounted) setState(() => _canClick = true);
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(attendanceProvider);
    final geoState = ref.watch(geolocationProvider);

    // 骨架屏
    if (store.isLoading && store.todayData == null) {
      return _buildSkeleton();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 考勤信息卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  store.rule.companyName.isNotEmpty
                      ? store.rule.companyName
                      : '考勤打卡',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '上班 ${store.scheduledClockIn}',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '~',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textTertiary),
                      ),
                    ),
                    Text(
                      '下班 ${store.scheduledClockOut}',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 状态提示条
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: _statusBgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _statusColor),
            ),
          ),

          // 打卡按钮
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: PunchButton(
              currentTime: _currentTime,
              currentDate: _currentDate,
              location: geoState.location,
              isWithinRange: geoState.isWithinRange,
              isLoading: geoState.isGettingLocation,
              disabled: !_canClick || _isPunching,
              punchSuccess: _punchSuccess,
              hasClockedIn: store.hasClockedIn,
              hasClockedOut: store.hasClockedOut,
              onPunch: _handlePunch,
            ),
          ),

          // 围栏范围提示
          if (!geoState.isWithinRange)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '当前不在考勤范围内，将记录为外勤',
                style: TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            ),

          // 打卡记录卡片
          Row(
            children: [
              Expanded(child: _buildRecordCard(
                label: '上班 (${store.scheduledClockIn})',
                hasPunched: store.hasClockedIn,
                time: store.clockInTime,
                showUpdateHint: false,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildRecordCard(
                label: '下班 (${store.scheduledClockOut})',
                hasPunched: store.hasClockedOut,
                time: store.clockOutTime,
                showUpdateHint: store.hasClockedOut,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard({
    required String label,
    required bool hasPunched,
    required String time,
    required bool showUpdateHint,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // 打卡状态图标
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasPunched ? AppColors.success : const Color(0xFFF2F2F7),
                  border: hasPunched
                      ? null
                      : Border.all(color: AppColors.textQuaternary, width: 1),
                  boxShadow: hasPunched
                      ? [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: hasPunched
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPunched ? '打卡 $time' : '--:--',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: hasPunched ? FontWeight.w600 : FontWeight.normal,
                        color: hasPunched
                            ? AppColors.textPrimary
                            : AppColors.textQuaternary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showUpdateHint)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '可更新',
                  style: TextStyle(fontSize: 10, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 信息卡骨架
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // 按钮骨架
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neutral200,
              ),
            ),
          ),
          // 记录卡骨架
          Row(
            children: [
              Expanded(child: _buildSkeletonCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildSkeletonCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity * 0.6,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
