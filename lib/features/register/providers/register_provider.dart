import 'package:flutter/foundation.dart';
// 注册模块 Provider - 管理注册流程状态

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/dio_client.dart';
import '../data/api/register_api.dart';
import '../data/models/register_models.dart';

/// Register API Provider
final registerApiProvider = Provider<RegisterApi>((ref) {
  final dio = ref.watch(dioProvider);
  return RegisterApi(dio);
});

/// 注册流程状态
class RegisterState {
  final int currentStep; // 1-4
  final int? personnelId;
  final bool isLoading;
  final PersonnelBasicInfoVo? basicInfo;
  final PersonnelEntryPlanVo? entryPlan;
  final List<PersonnelResumeVo> resumeList;
  final List<PersonnelFamilyRelationVo> familyList;

  const RegisterState({
    this.currentStep = 1,
    this.personnelId,
    this.isLoading = false,
    this.basicInfo,
    this.entryPlan,
    this.resumeList = const [],
    this.familyList = const [],
  });

  RegisterState copyWith({
    int? currentStep,
    int? personnelId,
    bool? isLoading,
    PersonnelBasicInfoVo? basicInfo,
    PersonnelEntryPlanVo? entryPlan,
    List<PersonnelResumeVo>? resumeList,
    List<PersonnelFamilyRelationVo>? familyList,
  }) {
    return RegisterState(
      currentStep: currentStep ?? this.currentStep,
      personnelId: personnelId ?? this.personnelId,
      isLoading: isLoading ?? this.isLoading,
      basicInfo: basicInfo ?? this.basicInfo,
      entryPlan: entryPlan ?? this.entryPlan,
      resumeList: resumeList ?? this.resumeList,
      familyList: familyList ?? this.familyList,
    );
  }
}

/// 注册流程管理 Notifier
class RegisterNotifier extends StateNotifier<RegisterState> {
  final Ref _ref;

  RegisterNotifier(this._ref) : super(const RegisterState());

  RegisterApi get _api => _ref.read(registerApiProvider);

  /// 设置人员ID (从 SharedPreferences 恢复或从 API 返回)
  Future<void> setPersonnelId(int id) async {
    state = state.copyWith(personnelId: id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('registerPersonnelId', id);
  }

  /// 恢复人员ID
  Future<void> restorePersonnelId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('registerPersonnelId');
    if (id != null) {
      state = state.copyWith(personnelId: id);
    }
  }

  /// 通过手机号查询人员信息
  Future<PersonnelBasicInfoVo?> queryByPhone(String phone) async {
    try {
      final res = await _api.getPersonnelInfoByPhone(phone);
      if (res.isSuccess && res.data != null) {
        state = state.copyWith(basicInfo: res.data);
        if (res.data!.id != null) {
          await setPersonnelId(res.data!.id!);
        }
        return res.data;
      }
    } catch (e) { debugPrint('[register_provider] Error: $e'); }
    return null;
  }

  /// 设置当前步骤
  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  /// 加载简历列表
  Future<void> loadResumeList() async {
    final pid = state.personnelId;
    if (pid == null) return;
    try {
      final res = await _api.getResumeList(personnelId: pid);
      if (res.isSuccess && res.rows != null) {
        state = state.copyWith(resumeList: res.rows!);
      }
    } catch (e) { debugPrint('[register_provider] Error: $e'); }
  }

  /// 加载家庭关系列表
  Future<void> loadFamilyList() async {
    final pid = state.personnelId;
    if (pid == null) return;
    try {
      final res = await _api.getFamilyList(personnelId: pid);
      if (res.isSuccess && res.rows != null) {
        state = state.copyWith(familyList: res.rows!);
      }
    } catch (e) { debugPrint('[register_provider] Error: $e'); }
  }

  /// 加载入职规划
  Future<void> loadEntryPlan() async {
    final pid = state.personnelId;
    if (pid == null) return;
    try {
      final res = await _api.getEntryPlanList(personnelId: pid);
      if (res.isSuccess && res.rows != null && res.rows!.isNotEmpty) {
        state = state.copyWith(entryPlan: res.rows!.first);
      }
    } catch (e) { debugPrint('[register_provider] Error: $e'); }
  }

  /// 清除注册状态
  Future<void> clear() async {
    state = const RegisterState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('registerPersonnelId');
  }
}

/// 注册流程 Provider
final registerProvider =
    StateNotifierProvider<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier(ref);
});
