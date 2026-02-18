// 注册 Step 1: 个人基本信息 - 对应 src/pages/register/basic.vue

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../constants/register_constants.dart';
import '../../data/models/register_models.dart';
import '../../providers/register_provider.dart';
import '../widgets/step_bar.dart';
import '../widgets/form_widgets.dart';
import '../widgets/submit_button.dart';

class BasicPage extends ConsumerStatefulWidget {
  const BasicPage({super.key});

  @override
  ConsumerState<BasicPage> createState() => _BasicPageState();
}

class _BasicPageState extends ConsumerState<BasicPage> {
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _heightCtl = TextEditingController();
  final _weightCtl = TextEditingController();
  final _nativePlaceCtl = TextEditingController();
  final _picker = ImagePicker();

  String _gender = '';
  String _ethnicity = '';
  String _bloodType = '';
  String _politicalStatus = '';
  String _maritalStatus = '';
  String _birthday = '';
  String _specialty = '';
  String _disease = '否';
  String _nonCompete = '否';
  String? _personnelPhoto;

  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _hasExistingData = false;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    await ref.read(registerProvider.notifier).restorePersonnelId();
    final state = ref.read(registerProvider);
    if (state.personnelId != null) {
      try {
        final api = ref.read(registerApiProvider);
        final res = await api.getPersonnelInfo(state.personnelId!);
        if (res.isSuccess && res.data != null) {
          _fillForm(res.data!);
        }
      } catch (e) {
        debugPrint('[basic_page] Error: $e');
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _fillForm(PersonnelBasicInfoVo info) {
    setState(() {
      _hasExistingData = info.id != null;
      _nameCtl.text = info.name ?? '';
      _phoneCtl.text = info.phone ?? '';
      _emailCtl.text = info.email ?? '';
      _heightCtl.text = info.height != null ? info.height.toString() : '';
      _weightCtl.text = info.weight != null ? info.weight.toString() : '';
      _gender = info.genderText != '未知' ? info.genderText : '';
      _ethnicity = info.ethnicity ?? '';
      _bloodType = info.bloodType ?? '';
      _politicalStatus = info.politicalStatus ?? '';
      _maritalStatus =
          info.maritalStatusText != '未知' ? info.maritalStatusText : '';
      _birthday = info.birthDate ?? '';
      _nativePlaceCtl.text = info.nativePlace ?? '';
      _specialty = info.specialty ?? '';
      _disease = info.hasMajorDisease == 1 ? '是' : '否';
      _nonCompete = info.hasNonCompeteAgreement == 1 ? '是' : '否';
      _personnelPhoto = info.personnelPhoto;
    });
    if (info.id != null) {
      ref.read(registerProvider.notifier).setPersonnelId(info.id!);
    }
  }

  Future<void> _onPhoneBlur() async {
    final phone = _phoneCtl.text.trim();
    if (phone.length == 11 && !_hasExistingData) {
      final info =
          await ref.read(registerProvider.notifier).queryByPhone(phone);
      if (info != null) {
        _fillForm(info);
      }
    }
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    // 先显示本地预览
    setState(() => _personnelPhoto = image.path);

    try {
      final token = await SecureStorageService().getToken();
      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path, filename: image.name),
      });
      final response = await dio.post(
        '${ApiConstants.baseUrl}/resource/oss/upload',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'clientid': ApiConstants.clientId,
        }),
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : response.data is Map
              ? Map<String, dynamic>.from(response.data as Map)
              : <String, dynamic>{};
      if (data['code'] == 200 && data['data'] != null) {
        final ossData = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : Map<String, dynamic>.from(data['data'] as Map);
        final ossUrl = ossData['url'] as String? ?? image.path;
        if (mounted) setState(() => _personnelPhoto = ossUrl);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['msg']?.toString() ?? '上传失败')),
          );
        }
      }
    } catch (e) {
      debugPrint('[basic_page] Avatar upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像上传失败')),
        );
      }
    }
  }

  bool _validate() {
    final errors = <String, String>{};
    if (_nameCtl.text.trim().isEmpty) errors['name'] = '请填写姓名';
    if (_phoneCtl.text.trim().isEmpty) {
      errors['phone'] = '请填写手机号';
    } else if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(_phoneCtl.text.trim())) {
      errors['phone'] = '请输入正确的手机号';
    }
    if (_gender.isEmpty) errors['gender'] = '请选择性别';
    if (_birthday.isEmpty) errors['birthday'] = '请选择出生日期';

    setState(() => _fieldErrors = errors);
    return errors.isEmpty;
  }

  Future<void> _handleSubmit() async {
    if (!_validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(registerApiProvider);
      final data = PersonnelBasicInfoSubmit(
        name: _nameCtl.text.trim(),
        phone: _phoneCtl.text.trim(),
        email: _emailCtl.text.trim().isNotEmpty
            ? _emailCtl.text.trim()
            : null,
        gender: _gender == '男' ? 1 : (_gender == '女' ? 0 : null),
        birthDate: _birthday.isNotEmpty ? _birthday : null,
        ethnicity: _ethnicity.isNotEmpty ? _ethnicity : null,
        bloodType: _bloodType.isNotEmpty ? _bloodType : null,
        politicalStatus:
            _politicalStatus.isNotEmpty ? _politicalStatus : null,
        maritalStatus: _maritalStatus == '未婚'
            ? 0
            : (_maritalStatus == '已婚'
                ? 1
                : (_maritalStatus == '离异' ? 2 : null)),
        nativePlace: _nativePlaceCtl.text.trim().isNotEmpty
            ? _nativePlaceCtl.text.trim()
            : null,
        height: _heightCtl.text.trim().isNotEmpty
            ? int.tryParse(_heightCtl.text.trim())
            : null,
        weight: _weightCtl.text.trim().isNotEmpty
            ? int.tryParse(_weightCtl.text.trim())
            : null,
        specialty: _specialty.isNotEmpty ? _specialty : null,
        hasMajorDisease: _disease == '是' ? 1 : 0,
        hasNonCompeteAgreement: _nonCompete == '是' ? 1 : 0,
        personnelPhoto: _personnelPhoto,
      );

      final res = _hasExistingData
          ? await api.updatePersonnelInfo(data)
          : await api.createPersonnelInfo(data);

      if (res.isSuccess) {
        if (!_hasExistingData) {
          await ref
              .read(registerProvider.notifier)
              .queryByPhone(_phoneCtl.text.trim());
        }
        ref.read(registerProvider.notifier).setStep(2);
        if (mounted) context.push('/register/address');
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
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _emailCtl.dispose();
    _heightCtl.dispose();
    _weightCtl.dispose();
    _nativePlaceCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(title: const Text('入职登记')),
      body: Column(
        children: [
          const StepBar(current: 1, steps: RegisterConstants.stepLabels),
          Expanded(
            child: _isLoading
                ? const FormLoadingPlaceholder()
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        // -- 基本信息 (含头像) --
                        FormSection(title: '基本信息', children: [
                          // 头像区域 -- 第一栏
                          _buildAvatarRow(),
                          Divider(
                            height: 0.5,
                            thickness: 0.5,
                            indent: AppSpacing.pagePadding,
                            endIndent: AppSpacing.pagePadding,
                            color: AppColors.neutral200,
                          ),
                          _formField('姓名', required: true, error: 'name',
                              child: _textInput(_nameCtl, '请输入姓名')),
                          _formField('手机号', required: true, error: 'phone',
                              child: _textInput(_phoneCtl, '请输入手机号',
                                  keyboard: TextInputType.phone,
                                  onDone: _onPhoneBlur)),
                          _formField('性别', required: true, error: 'gender',
                              child: PickerField(
                                value: _gender,
                                options: RegisterConstants.genderOptions,
                                onChanged: (v) => setState(() => _gender = v),
                              )),
                          _formField('出生日期',
                              required: true,
                              error: 'birthday',
                              child: DatePickerField(
                                value: _birthday,
                                onChanged: (v) =>
                                    setState(() => _birthday = v),
                              )),
                          _formField('邮箱',
                              child: _textInput(_emailCtl, '请输入邮箱',
                                  keyboard: TextInputType.emailAddress)),
                          _formField('民族',
                              child: PickerField(
                                value: _ethnicity,
                                fieldName: '民族',
                                options: RegisterConstants.ethnicityOptions,
                                onChanged: (v) =>
                                    setState(() => _ethnicity = v),
                              )),
                          _formField('血型',
                              child: PickerField(
                                value: _bloodType,
                                options: RegisterConstants.bloodTypeOptions,
                                onChanged: (v) =>
                                    setState(() => _bloodType = v),
                              )),
                          _formField('政治面貌',
                              child: PickerField(
                                value: _politicalStatus,
                                options: RegisterConstants.politicalOptions,
                                onChanged: (v) =>
                                    setState(() => _politicalStatus = v),
                              )),
                          _formField('婚姻状况',
                              isLast: true,
                              child: PickerField(
                                value: _maritalStatus,
                                options: RegisterConstants.maritalOptions,
                                onChanged: (v) =>
                                    setState(() => _maritalStatus = v),
                              )),
                        ]),

                        // -- 身体信息 --
                        FormSection(title: '身体信息', children: [
                          _formField('身高(cm)',
                              child: _textInput(_heightCtl, '请输入',
                                  keyboard: TextInputType.number)),
                          _formField('体重(kg)',
                              child: _textInput(_weightCtl, '请输入',
                                  keyboard: TextInputType.number)),
                          _formField('特长',
                              isLast: true,
                              child: PickerField(
                                value: _specialty,
                                placeholder: '请选择',
                                options: RegisterConstants.specialtyOptions,
                                onChanged: (v) =>
                                    setState(() => _specialty = v),
                              )),
                        ]),

                        // -- 其他信息 --
                        FormSection(title: '其他信息', children: [
                          _formField('籍贯',
                              child:
                                  _textInput(_nativePlaceCtl, '请输入籍贯')),
                          _formField('有无疾病',
                              child: PickerField(
                                value: _disease,
                                options: RegisterConstants.yesNoOptions,
                                onChanged: (v) =>
                                    setState(() => _disease = v),
                              )),
                          _formField('有无竞业',
                              isLast: true,
                              child: PickerField(
                                value: _nonCompete,
                                options: RegisterConstants.yesNoOptions,
                                onChanged: (v) =>
                                    setState(() => _nonCompete = v),
                              )),
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

  // ---- 头像区域 ----
  Widget _buildAvatarRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.s16,
      ),
      child: Row(
        children: [
          Text(
            '个人照片',
            style: AppTypography.formField.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _pickAvatar,
            child: _buildAvatarWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget() {
    const size = 64.0;
    if (_personnelPhoto != null && _personnelPhoto!.isNotEmpty) {
      final isNetwork = _personnelPhoto!.startsWith('http');
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: isNetwork
                ? Image.network(
                    _personnelPhoto!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _avatarPlaceholder(size),
                  )
                : Image.file(
                    File(_personnelPhoto!),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _avatarPlaceholder(size),
                  ),
          ),
          // 编辑角标
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.backgroundPrimary,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
    return _avatarPlaceholder(size);
  }

  Widget _avatarPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.neutral300, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined,
              size: 22, color: AppColors.neutral400),
          const SizedBox(height: 2),
          Text(
            '上传',
            style: AppTypography.caption2.copyWith(
              color: AppColors.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  // ---- 表单行工厂方法 ----
  Widget _formField(
    String label, {
    bool required = false,
    String? error,
    bool isLast = false,
    required Widget child,
  }) {
    return FormRow(
      label: label,
      required: required,
      errorText: error != null ? _fieldErrors[error] : null,
      isLast: isLast,
      child: child,
    );
  }

  Widget _textInput(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboard,
    VoidCallback? onDone,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration.collapsed(
        hintText: hint,
        hintStyle: AppTypography.formField.copyWith(
          color: AppColors.textPlaceholder,
        ),
      ),
      textAlign: TextAlign.end,
      keyboardType: keyboard,
      style: AppTypography.formField,
      onEditingComplete: onDone,
    );
  }
}
