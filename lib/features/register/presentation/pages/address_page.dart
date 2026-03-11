// 注册 Step 2: 证件与银行卡信息 - 对应 src/pages/register/address.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../constants/register_constants.dart';
import '../../data/models/register_models.dart';
import '../../providers/register_provider.dart';
import '../widgets/step_bar.dart';
import '../widgets/form_widgets.dart';
import '../widgets/oss_upload.dart';
import '../widgets/submit_button.dart';

class AddressPage extends ConsumerStatefulWidget {
  const AddressPage({super.key});

  @override
  ConsumerState<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends ConsumerState<AddressPage> {
  final _idCardCtl = TextEditingController();
  final _idCardAddressCtl = TextEditingController();
  final _bankCardCtl = TextEditingController();
  final _bankCardAddressCtl = TextEditingController();
  final _residenceAddressCtl = TextEditingController();

  String? _idCardFrontPhoto;
  String? _idCardBackPhoto;
  String? _bankCardFrontPhoto;
  String? _bankCardBackPhoto;

  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final state = ref.read(registerProvider);
    final pid = state.personnelId;
    if (pid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final api = ref.read(registerApiProvider);
      final res = await api.getPersonnelInfo(pid);
      if (res.isSuccess && res.data != null) {
        final info = res.data!;
        setState(() {
          _idCardCtl.text = info.idCardNumber ?? '';
          _idCardAddressCtl.text = info.idCardAddress ?? '';
          _bankCardCtl.text = info.bankCardNumber ?? '';
          _bankCardAddressCtl.text = info.bankCardAddress ?? '';
          _residenceAddressCtl.text = info.residenceAddress ?? '';
          _idCardFrontPhoto = info.idCardFrontPhoto;
          _idCardBackPhoto = info.idCardBackPhoto;
          _bankCardFrontPhoto = info.bankCardFrontPhoto;
          _bankCardBackPhoto = info.bankCardBackPhoto;
        });
      }
    } catch (e) {
      debugPrint('[address_page] Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  bool _validate() {
    if (_idCardCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写身份证号')),
      );
      return false;
    }
    final idCard = _idCardCtl.text.trim();
    if (!RegExp(r'^\d{17}[\dXx]$').hasMatch(idCard)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('身份证号格式不正确')),
      );
      return false;
    }
    return true;
  }

  Future<void> _handleSubmit() async {
    if (!_validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final regState = ref.read(registerProvider);
      final pid = regState.personnelId;
      if (pid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未获取到人员信息，请返回重试')),
        );
        return;
      }

      // basicInfo 可能因 App 重启后未恢复而为 null，重新从 API 拉取
      final api = ref.read(registerApiProvider);
      PersonnelBasicInfoVo? basicInfo = regState.basicInfo;
      if (basicInfo == null) {
        final infoRes = await api.getPersonnelInfo(pid);
        if (infoRes.isSuccess && infoRes.data != null) {
          basicInfo = infoRes.data;
        }
      }

      final data = PersonnelBasicInfoSubmit(
        id: pid,
        name: basicInfo?.name ?? '',
        phone: basicInfo?.phone ?? '',
        idCardNumber: _idCardCtl.text.trim(),
        idCardAddress: _idCardAddressCtl.text.trim().isNotEmpty
            ? _idCardAddressCtl.text.trim()
            : null,
        bankCardNumber: _bankCardCtl.text.trim().isNotEmpty
            ? _bankCardCtl.text.trim()
            : null,
        bankCardAddress: _bankCardAddressCtl.text.trim().isNotEmpty
            ? _bankCardAddressCtl.text.trim()
            : null,
        residenceAddress: _residenceAddressCtl.text.trim().isNotEmpty
            ? _residenceAddressCtl.text.trim()
            : null,
        idCardFrontPhoto: _idCardFrontPhoto,
        idCardBackPhoto: _idCardBackPhoto,
        bankCardFrontPhoto: _bankCardFrontPhoto,
        bankCardBackPhoto: _bankCardBackPhoto,
      );

      final res = await api.updatePersonnelInfo(data);

      if (res.isSuccess) {
        ref.read(registerProvider.notifier).setStep(3);
        if (mounted) context.push('/register/plan');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请稍后重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _idCardCtl.dispose();
    _idCardAddressCtl.dispose();
    _bankCardCtl.dispose();
    _bankCardAddressCtl.dispose();
    _residenceAddressCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(title: const Text('证件信息')),
      body: Column(
        children: [
          const StepBar(current: 2, steps: RegisterConstants.stepLabels),
          Expanded(
            child: _isLoading
                ? const FormLoadingPlaceholder()
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: [
                        FormSection(title: '身份证信息', children: [
                          FormRow(
                            label: '身份证号',
                            required: true,
                            child: TextField(
                              controller: _idCardCtl,
                              decoration: formInputDecoration(hint: '请输入身份证号'),
                              textAlign: TextAlign.end,
                              style: AppTypography.formField,
                            ),
                          ),
                          FormRow(
                            label: '身份证地址',
                            isLast: true,
                            child: TextField(
                              controller: _idCardAddressCtl,
                              decoration: formInputDecoration(hint: '请输入身份证地址'),
                              textAlign: TextAlign.end,
                              style: AppTypography.formField,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '身份证正面照',
                              style: AppTypography.footnote.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: OssUpload(
                              maxCount: 1,
                              initialFiles: _idCardFrontPhoto != null
                                  ? [
                                      UploadFileItem(
                                        uid: _idCardFrontPhoto!,
                                        url: _idCardFrontPhoto!,
                                      ),
                                    ]
                                  : [],
                              onSuccess: (data) =>
                                  setState(() => _idCardFrontPhoto = data.url),
                              onRemove: (_) =>
                                  setState(() => _idCardFrontPhoto = null),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '身份证反面照',
                              style: AppTypography.footnote.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: OssUpload(
                              maxCount: 1,
                              initialFiles: _idCardBackPhoto != null
                                  ? [
                                      UploadFileItem(
                                        uid: _idCardBackPhoto!,
                                        url: _idCardBackPhoto!,
                                      ),
                                    ]
                                  : [],
                              onSuccess: (data) =>
                                  setState(() => _idCardBackPhoto = data.url),
                              onRemove: (_) =>
                                  setState(() => _idCardBackPhoto = null),
                            ),
                          ),
                        ]),
                        FormSection(title: '地址信息', children: [
                          FormRow(
                            label: '居住地址',
                            isLast: true,
                            child: TextField(
                              controller: _residenceAddressCtl,
                              decoration: formInputDecoration(hint: '请输入居住地址'),
                              textAlign: TextAlign.end,
                              style: AppTypography.formField,
                            ),
                          ),
                        ]),
                        FormSection(title: '银行卡信息', children: [
                          FormRow(
                            label: '银行卡号',
                            child: TextField(
                              controller: _bankCardCtl,
                              decoration: formInputDecoration(hint: '请输入银行卡号'),
                              textAlign: TextAlign.end,
                              keyboardType: TextInputType.number,
                              style: AppTypography.formField,
                            ),
                          ),
                          FormRow(
                            label: '开户行地址',
                            isLast: true,
                            child: TextField(
                              controller: _bankCardAddressCtl,
                              decoration: formInputDecoration(hint: '请输入开户行地址'),
                              textAlign: TextAlign.end,
                              style: AppTypography.formField,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '银行卡正面照',
                              style: AppTypography.footnote.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: OssUpload(
                              maxCount: 1,
                              initialFiles: _bankCardFrontPhoto != null
                                  ? [
                                      UploadFileItem(
                                        uid: _bankCardFrontPhoto!,
                                        url: _bankCardFrontPhoto!,
                                      ),
                                    ]
                                  : [],
                              onSuccess: (data) =>
                                  setState(() => _bankCardFrontPhoto = data.url),
                              onRemove: (_) =>
                                  setState(() => _bankCardFrontPhoto = null),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '银行卡反面照',
                              style: AppTypography.footnote.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: OssUpload(
                              maxCount: 1,
                              initialFiles: _bankCardBackPhoto != null
                                  ? [
                                      UploadFileItem(
                                        uid: _bankCardBackPhoto!,
                                        url: _bankCardBackPhoto!,
                                      ),
                                    ]
                                  : [],
                              onSuccess: (data) =>
                                  setState(() => _bankCardBackPhoto = data.url),
                              onRemove: (_) =>
                                  setState(() => _bankCardBackPhoto = null),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SubmitButton(
        onPressed: _handleSubmit,
        isSubmitting: _isSubmitting,
      ),
    );
  }
}
