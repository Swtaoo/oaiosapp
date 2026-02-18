import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 学习空间页 - 对应 src/pages/study/index.vue
/// Phase 2 简化版: 分类网格 + 占位内容
class StudyPage extends StatelessWidget {
  const StudyPage({super.key});

  static const _categories = [
    _Category(name: '规章制度', icon: Icons.menu_book, count: 12, color: Color(0xFF667EEA)),
    _Category(name: '培训课程', icon: Icons.school, count: 8, color: Color(0xFFF5576C)),
    _Category(name: '技术文档', icon: Icons.auto_stories, count: 25, color: Color(0xFF4FACFE)),
    _Category(name: '视频教程', icon: Icons.play_circle_outline, count: 15, color: Color(0xFFFA709A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习空间')),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学习分类
            const Text(
              '学习分类',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
              children: _categories.map((cat) {
                return GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${cat.name} - 开发中'), duration: const Duration(seconds: 1)),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cat.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cat.icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cat.count}篇',
                          style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // 推荐课程占位
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '推荐课程',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '查看更多 \u203A',
                  style: TextStyle(fontSize: 13, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 空状态
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.school_outlined, size: 48, color: AppColors.neutral300),
                  const SizedBox(height: 8),
                  Text(
                    '课程内容即将上线',
                    style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Category {
  final String name;
  final IconData icon;
  final int count;
  final Color color;

  const _Category({
    required this.name,
    required this.icon,
    required this.count,
    required this.color,
  });
}
