// 个人信息详情页（只读展示） - 对应 src/pages/me/changeInfo.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../register/data/api/register_api.dart';
import '../../../register/data/models/register_models.dart';

final _registerApiProvider = Provider<RegisterApi>((ref) {
  return RegisterApi(ref.watch(dioProvider));
});

class ChangeInfoPage extends ConsumerStatefulWidget {
  final int? personnelId;

  const ChangeInfoPage({super.key, this.personnelId});

  @override
  ConsumerState<ChangeInfoPage> createState() => _ChangeInfoPageState();
}

class _ChangeInfoPageState extends ConsumerState<ChangeInfoPage> {
  bool _isLoading = true;
  PersonnelBasicInfoVo? _basicInfo;
  PersonnelEntryPlanVo? _entryPlan;
  List<PersonnelResumeVo> _resumeList = [];
  List<PersonnelFamilyRelationVo> _familyList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pid =
        widget.personnelId ?? ref.read(currentUserProvider)?.effectiveUserId;
    if (pid == null || pid <= 0) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final api = ref.read(_registerApiProvider);
      final results = await Future.wait([
        api.getPersonnelInfo(pid),
        api.getEntryPlanList(personnelId: pid),
        api.getResumeList(personnelId: pid),
        api.getFamilyList(personnelId: pid),
      ]);

      final basicRes = results[0] as ApiResponse<PersonnelBasicInfoVo>;
      final planRes = results[1] as PaginatedResponse<PersonnelEntryPlanVo>;
      final resumeRes = results[2] as PaginatedResponse<PersonnelResumeVo>;
      final familyRes =
          results[3] as PaginatedResponse<PersonnelFamilyRelationVo>;

      setState(() {
        if (basicRes.isSuccess && basicRes.data != null) {
          _basicInfo = basicRes.data;
        }
        if (planRes.isSuccess && (planRes.rows?.isNotEmpty ?? false)) {
          _entryPlan = planRes.rows!.first;
        }
        if (resumeRes.isSuccess) {
          _resumeList = resumeRes.rows ?? [];
        }
        if (familyRes.isSuccess) {
          _familyList = familyRes.rows ?? [];
        }
      });
    } catch (e) {
      debugPrint('[change_info_page] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PersonnelResumeVo> _filterByType(int type) =>
      _resumeList.where((e) => e.experienceType == type).toList();

  /// 格式化薪资显示
  String _formatSalary(num? salary) {
    if (salary == null) return '未填写';
    if (salary == salary.toInt()) return '${salary.toInt()}元';
    return '${salary.toStringAsFixed(2)}元';
  }

  /// 将相对路径或完整 URL 统一转为可访问的完整 URL
  String? _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = ApiConstants.baseUrl;
    return path.startsWith('/') ? '$base$path' : '$base/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGroupedPrimary,
      appBar: AppBar(title: const Text('人员信息')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    _buildBasicInfoSection(),
                    _buildBodySection(),
                    _buildEntrySection(),
                    _buildIdCardSection(),
                    _buildBankCardSection(),
                    _buildEntryPlanSection(),
                    _buildResumeSection(
                      '学习经历',
                      Icons.school_outlined,
                      _filterByType(1),
                    ),
                    _buildResumeSection(
                      '培训经历',
                      Icons.menu_book_outlined,
                      _filterByType(2),
                    ),
                    _buildWorkSection(),
                    _buildFamilySection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // ==================== 个人头像摘要 ====================

  Widget _buildProfileHeader() {
    final info = _basicInfo;
    final name = info?.name ?? '未填写';
    final initial = name.isNotEmpty ? name[0] : '?';
    final avatarUrl =
        _buildImageUrl(info?.avatar) ?? _buildImageUrl(info?.personnelPhoto);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF3399FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            onBackgroundImageError: avatarUrl != null ? (_, _) {} : null,
            child: avatarUrl == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (info?.genderText != null && info?.gender != null)
                      info!.genderText,
                    if (info?.age != null) '${info!.age}岁',
                    if (info?.phone != null) info!.phone,
                  ].join('  '),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 通用 section 组件 ====================

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _cell(String label, String? value, {bool isLast = false}) {
    final display = (value != null && value.isNotEmpty) ? value : '未填写';
    final isEmpty = value == null || value.isEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  display,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    color: isEmpty
                        ? AppColors.neutral400
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.neutral200,
          ),
      ],
    );
  }

  /// 生成带分隔线的 cell 列表，自动标记最后一个
  List<Widget> _cells(List<(String, String?)> items) {
    return [
      for (var i = 0; i < items.length; i++)
        _cell(items[i].$1, items[i].$2, isLast: i == items.length - 1),
    ];
  }

  Widget _emptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 32, color: AppColors.neutral300),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.neutral400),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 各 Section 构建 ====================

  Widget _buildBasicInfoSection() {
    final info = _basicInfo;
    return _section(
      '基本信息',
      Icons.person_outline,
      _cells([
        ('姓名', info?.name),
        ('性别', info?.genderText),
        ('联系电话', info?.phone),
        ('邮箱', info?.email),
        ('民族', info?.ethnicity),
        ('籍贯', info?.nativePlace),
        ('出生年月', info?.birthDate),
        ('年龄', info?.age != null ? '${info!.age}岁' : null),
      ]),
    );
  }

  Widget _buildBodySection() {
    final info = _basicInfo;
    return _section(
      '身体与状态',
      Icons.favorite_outline,
      _cells([
        ('身高', info?.height != null ? '${info!.height}cm' : null),
        ('体重', info?.weight != null ? '${info!.weight}kg' : null),
        ('血型', info?.bloodType),
        ('政治面貌', info?.politicalStatus),
        ('婚姻状况', info?.maritalStatusText),
      ]),
    );
  }

  Widget _buildEntrySection() {
    final info = _basicInfo;
    return _section('入职相关', Icons.work_outline, [
      ..._cells([
        ('居住地址', info?.residenceAddress),
        ('特长', info?.specialty),
        ('重大疾病', info?.hasMajorDisease == 1 ? '是' : '否'),
        ('竞业协议', info?.hasNonCompeteAgreement == 1 ? '是' : '否'),
      ]),
    ]);
  }

  Widget _buildIdCardSection() {
    final info = _basicInfo;
    return _section('身份证信息', Icons.badge_outlined, [
      ..._cells([
        ('身份证号码', info?.idCardNumber),
        ('身份证地址', info?.idCardAddress),
      ]),
      _photoRow([
        ('身份证正面', info?.idCardFrontPhoto),
        ('身份证背面', info?.idCardBackPhoto),
      ]),
    ]);
  }

  Widget _buildBankCardSection() {
    final info = _basicInfo;
    return _section('银行卡信息', Icons.credit_card_outlined, [
      ..._cells([
        ('银行卡号', info?.bankCardNumber),
        ('开户行地址', info?.bankCardAddress),
      ]),
      _photoRow([
        ('银行卡正面', info?.bankCardFrontPhoto),
        ('银行卡背面', info?.bankCardBackPhoto),
      ]),
    ]);
  }

  Widget _buildEntryPlanSection() {
    final plan = _entryPlan;
    return _section(
      '入职规划',
      Icons.trending_up_outlined,
      _cells([
        ('应聘职位', plan?.appliedPosition),
        (
          '期望薪金',
          plan?.expectedSalary != null
              ? _formatSalary(plan!.expectedSalary)
              : null,
        ),
        (
          '能否加班',
          plan?.canOvertime == 1 ? '是' : (plan?.canOvertime == 0 ? '否' : null),
        ),
        (
          '能否外地工作',
          plan?.canWorkRemote == 1
              ? '是'
              : (plan?.canWorkRemote == 0 ? '否' : null),
        ),
        ('职业规划', plan?.careerPlanning),
        ('自我评价', plan?.selfEvaluation),
      ]),
    );
  }

  Widget _buildResumeSection(
    String title,
    IconData icon,
    List<PersonnelResumeVo> list,
  ) {
    return _section(title, icon, [
      if (list.isEmpty)
        _emptyState('暂无$title')
      else
        ...list.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return _timelineItem(
            title: item.unitName ?? '未填写',
            subtitle: item.position ?? item.education ?? '',
            dateRange: '${item.startDate ?? ''} ~ ${item.endDate ?? ''}',
            photoUrl: item.certificatePhoto,
            isLast: i == list.length - 1,
          );
        }),
    ]);
  }

  Widget _buildWorkSection() {
    final list = _filterByType(3);
    return _section('工作经历', Icons.business_center_outlined, [
      if (list.isEmpty)
        _emptyState('暂无工作经历')
      else
        ...list.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return _timelineItem(
            title: item.unitName ?? '未填写',
            subtitle: [
              item.position,
              item.leaveReason != null ? '离职原因: ${item.leaveReason}' : null,
            ].where((e) => e != null && e.isNotEmpty).join('\n'),
            dateRange: '${item.startDate ?? ''} ~ ${item.endDate ?? ''}',
            isLast: i == list.length - 1,
          );
        }),
    ]);
  }

  Widget _buildFamilySection() {
    return _section('家庭成员', Icons.people_outline, [
      if (_familyList.isEmpty)
        _emptyState('暂无家庭成员信息')
      else
        ..._familyList.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return _familyItem(item, isLast: i == _familyList.length - 1);
        }),
    ]);
  }

  // ==================== 列表项组件 ====================

  /// 时间线风格的经历条目
  Widget _timelineItem({
    required String title,
    required String subtitle,
    required String dateRange,
    String? photoUrl,
    bool isLast = false,
  }) {
    final fullUrl = _buildImageUrl(photoUrl);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.neutral400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateRange,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                    if (fullUrl != null) ...[
                      const SizedBox(height: 8),
                      _photoThumbnail(fullUrl, label: '证书'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 36,
            endIndent: 16,
            color: AppColors.neutral200,
          ),
      ],
    );
  }

  /// 家庭成员条目
  Widget _familyItem(PersonnelFamilyRelationVo item, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.relation ?? '亲属',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.familyName ?? '未填写',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: AppColors.neutral400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.contactPhone ?? '未填写',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                        if (item.age != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            '${item.age}岁',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.occupation != null &&
                        item.occupation!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '职业: ${item.occupation}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.neutral200,
          ),
      ],
    );
  }

  // ==================== 图片展示组件 ====================

  /// 照片行：展示多张带标签的缩略图
  Widget _photoRow(List<(String, String?)> photos) {
    final validPhotos = photos
        .map((p) => (p.$1, _buildImageUrl(p.$2)))
        .where((p) => p.$2 != null)
        .toList();
    if (validPhotos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          for (var i = 0; i < validPhotos.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _photoThumbnail(
                validPhotos[i].$2!,
                label: validPhotos[i].$1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 单张图片缩略图（可点击预览大图）
  Widget _photoThumbnail(String url, {String? label}) {
    return GestureDetector(
      onTap: () => _showImagePreview(url, label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 32,
                    color: AppColors.neutral300,
                  ),
                ),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.neutral400),
            ),
          ],
        ],
      ),
    );
  }

  /// 全屏图片预览
  void _showImagePreview(String url, String? title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              title ?? '图片预览',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '图片加载失败',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
