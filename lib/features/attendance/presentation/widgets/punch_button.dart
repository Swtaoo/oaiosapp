import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 圆形打卡按钮 - 对应 src/pages/attendance/components/PunchButton.vue
class PunchButton extends StatefulWidget {
  final String currentTime;
  final String currentDate;
  final String location;
  final bool isWithinRange;
  final bool isLoading;
  final bool disabled;
  final bool punchSuccess;
  final bool hasClockedIn;
  final bool hasClockedOut;
  final VoidCallback? onPunch;

  const PunchButton({
    super.key,
    required this.currentTime,
    required this.currentDate,
    required this.location,
    this.isWithinRange = true,
    this.isLoading = false,
    this.disabled = false,
    this.punchSuccess = false,
    this.hasClockedIn = false,
    this.hasClockedOut = false,
    this.onPunch,
  });

  @override
  State<PunchButton> createState() => _PunchButtonState();
}

class _PunchButtonState extends State<PunchButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rippleController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _rippleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(PunchButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.punchSuccess && !oldWidget.punchSuccess) {
      _rippleController.forward(from: 0);
    }
    if (widget.disabled) {
      _pulseController.stop();
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  String get _buttonText {
    if (widget.isLoading) return '定位中...';
    if (!widget.hasClockedIn) {
      return widget.isWithinRange ? '上班打卡' : '外勤上班打卡';
    }
    final prefix = widget.isWithinRange ? '' : '外勤';
    return widget.hasClockedOut ? '$prefix更新下班卡' : '$prefix下班打卡';
  }

  bool get _isSmallText => widget.hasClockedOut || !widget.isWithinRange;

  List<Color> get _gradientColors {
    if (!widget.isWithinRange) {
      return [AppColors.warning, const Color(0xFFFFCB7C)];
    }
    // 正常打卡按钮：改为绿色（与统计页“正常”一致）
    return [AppColors.success, const Color(0xFF6EEB83)];
  }

  Color get _shadowColor {
    if (!widget.isWithinRange) {
      return AppColors.warning.withValues(alpha: 0.3);
    }
    return AppColors.success.withValues(alpha: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    const size = 210.0;

    return GestureDetector(
      onTap: (!widget.disabled && !widget.isLoading) ? widget.onPunch : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _rippleAnimation]),
        builder: (context, child) {
          final scale = widget.disabled ? 1.0 : _pulseAnimation.value;
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: size + 40,
              height: size + 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 涟漪效果
                  if (_rippleController.isAnimating)
                    AnimatedBuilder(
                      animation: _rippleAnimation,
                      builder: (context, _) => Transform.scale(
                        scale: _rippleAnimation.value,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _gradientColors[0]
                                  .withValues(alpha: 1 - _rippleController.value),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // 光晕环
                  if (!widget.disabled)
                    Container(
                      width: size + 20,
                      height: size + 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _gradientColors[1].withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  // 主按钮
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _gradientColors,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _shadowColor,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Opacity(
                      opacity: widget.disabled ? 0.6 : 1.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _buttonText,
                            style: TextStyle(
                              fontSize: _isSmallText ? 22 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.currentDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.currentTime,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 150,
                            child: Text(
                              widget.location,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
