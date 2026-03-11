// 注册 Step 1: 个人基本信息 - 对应 src/pages/register/basic.vue

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
  final _addressDetailCtl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _picker = ImagePicker();

  String _gender = '';
  String _ethnicity = '';
  String _bloodType = '';
  String _politicalStatus = '';
  String _maritalStatus = '';
  String _birthday = '';
  String _entryDate = '';
  String _nativePlace = '';
  String _addressArea = '';
  Set<String> _selectedSpecialties = {};
  String? _personnelPhoto;
  bool? _hasMajorDisease;
  bool? _hasNonCompete;

  int? _existingId;
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _isPhoneQuerying = false;
  bool _hasExistingData = false;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_onPhoneFocusChange);
    _loadExistingData();
  }

  void _onPhoneFocusChange() {
    if (!_phoneFocus.hasFocus) {
      _onPhoneBlur();
    }
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
      _existingId = info.id;
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
      _entryDate = info.entryDate ?? '';
      _personnelPhoto = info.personnelPhoto;

      // 籍贯
      _nativePlace = info.nativePlace ?? '';

      // 居住地址: 尝试拆分区域/详细
      final addr = info.residenceAddress ?? '';
      if (addr.isNotEmpty) {
        // 如果地址包含空格分隔的省市区前缀，尝试拆分
        final spaceCount = ' '.allMatches(addr).length;
        if (spaceCount >= 2) {
          // 找到第三个空格位置后的内容作为详细地址
          int idx = 0;
          int found = 0;
          for (int i = 0; i < addr.length; i++) {
            if (addr[i] == ' ') {
              found++;
              if (found == 3) {
                idx = i;
                break;
              }
            }
          }
          if (idx > 0) {
            _addressArea = addr.substring(0, idx);
            _addressDetailCtl.text = addr.substring(idx + 1);
          } else {
            _addressArea = addr;
          }
        } else {
          _addressDetailCtl.text = addr;
        }
      }

      // 特长: 逗号分割
      final specialty = info.specialty ?? '';
      if (specialty.isNotEmpty) {
        _selectedSpecialties = specialty.split(',').toSet();
      }

      // 疾病/竞业: 0/1 -> bool
      _hasMajorDisease = info.hasMajorDisease == 1;
      _hasNonCompete = info.hasNonCompeteAgreement == 1;
    });
    if (info.id != null) {
      ref.read(registerProvider.notifier).setPersonnelId(info.id!);
    }
  }

  Future<void> _onPhoneBlur() async {
    final phone = _phoneCtl.text.trim();
    if (phone.length == 11 && !_hasExistingData && !_isPhoneQuerying) {
      setState(() => _isPhoneQuerying = true);
      final info =
          await ref.read(registerProvider.notifier).queryByPhone(phone);
      if (mounted) {
        setState(() => _isPhoneQuerying = false);
        if (info != null) _fillForm(info);
      }
    }
  }

  void _onPhoneChanged(String value) {
    if (value.trim().length == 11 && !_hasExistingData && !_isPhoneQuerying) {
      _onPhoneBlur();
    }
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

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
      errors['phone'] = '请填写联系电话';
    } else if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(_phoneCtl.text.trim())) {
      errors['phone'] = '请输入正确的手机号';
    }
    if (_emailCtl.text.trim().isEmpty) {
      errors['email'] = '请填写邮箱';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(_emailCtl.text.trim())) {
      errors['email'] = '请输入正确的邮箱格式';
    }
    if (_gender.isEmpty) errors['gender'] = '请选择性别';
    if (_ethnicity.isEmpty) errors['ethnicity'] = '请选择民族';
    if (_heightCtl.text.trim().isEmpty) errors['height'] = '请填写身高体重';
    if (_weightCtl.text.trim().isEmpty) {
      errors['height'] ??= '请填写身高体重';
    }
    if (_entryDate.isEmpty) errors['entryDate'] = '请选择入职时间';
    if (_nativePlace.isEmpty) errors['nativePlace'] = '请选择籍贯';
    if (_addressArea.isEmpty) errors['address'] = '请选择居住地址区域';
    if (_hasMajorDisease == null) errors['disease'] = '请选择疾病情况';
    if (_hasNonCompete == null) {
      errors['nonCompete'] = '请选择竞业情况';
    }

    setState(() => _fieldErrors = errors);
    return errors.isEmpty;
  }

  Future<void> _handleSubmit() async {
    if (!_validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      // 新填写时，先按手机号查询是否有历史数据，有则回填并中止，让用户确认
      if (!_hasExistingData) {
        final phone = _phoneCtl.text.trim();
        if (phone.length == 11) {
          final info =
              await ref.read(registerProvider.notifier).queryByPhone(phone);
          if (info != null && mounted) {
            _fillForm(info);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已找到您之前填写的资料，请确认后继续')),
            );
            return;
          }
        }
      }

      final api = ref.read(registerApiProvider);

      // 疾病/竞业: bool -> 0/1
      final hasMajorDisease = (_hasMajorDisease ?? false) ? 1 : 0;
      final hasNonCompete = (_hasNonCompete ?? false) ? 1 : 0;

      // 拼接居住地址
      final residenceAddress = _addressArea.isNotEmpty
          ? '$_addressArea ${_addressDetailCtl.text.trim()}'.trim()
          : _addressDetailCtl.text.trim();

      final data = PersonnelBasicInfoSubmit(
        id: _existingId,
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
                : (_maritalStatus == '离异'
                    ? 2
                    : (_maritalStatus == '丧偶' ? 3 : null))),
        nativePlace: _nativePlace.isNotEmpty ? _nativePlace : null,
        height: _heightCtl.text.trim().isNotEmpty
            ? int.tryParse(_heightCtl.text.trim())
            : null,
        weight: _weightCtl.text.trim().isNotEmpty
            ? int.tryParse(_weightCtl.text.trim())
            : null,
        entryDate: _entryDate.isNotEmpty ? _entryDate : null,
        specialty: _selectedSpecialties.isNotEmpty
            ? _selectedSpecialties.join(',')
            : null,
        hasMajorDisease: hasMajorDisease,
        hasNonCompeteAgreement: hasNonCompete,
        residenceAddress:
            residenceAddress.isNotEmpty ? residenceAddress : null,
        personnelPhoto: _personnelPhoto,
      );

      final res = _hasExistingData
          ? await api.updatePersonnelInfo(data)
          : await api.createPersonnelInfo(data);

      if (res.isSuccess) {
        await ref
            .read(registerProvider.notifier)
            .queryByPhone(_phoneCtl.text.trim());
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
    _phoneFocus.removeListener(_onPhoneFocusChange);
    _phoneFocus.dispose();
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _emailCtl.dispose();
    _heightCtl.dispose();
    _weightCtl.dispose();
    _addressDetailCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(title: const Text('基本信息表')),
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
                        // -- 1. 个人照片 --
                        PhotoUploadCard(
                          photoUrl: _personnelPhoto,
                          onTap: _pickAvatar,
                          onRemove: _personnelPhoto != null
                              ? () =>
                                  setState(() => _personnelPhoto = null)
                              : null,
                        ),

                        // -- 2. 基本信息 --
                        FormSection(title: '基本信息', children: [
                          _formField('姓名', required: true, error: 'name',
                              child: _textInput(_nameCtl, '请输入姓名')),
                          _formField('性别', required: true, error: 'gender',
                              child: PickerField(
                                value: _gender,
                                options: RegisterConstants.genderOptions,
                                onChanged: (v) =>
                                    setState(() => _gender = v),
                              )),
                          _formField('民族',
                              required: true,
                              error: 'ethnicity',
                              child: PickerField(
                                value: _ethnicity,
                                fieldName: '民族',
                                options: RegisterConstants.ethnicityOptions,
                                onChanged: (v) =>
                                    setState(() => _ethnicity = v),
                              )),
                          _formField('政治面貌',
                              child: PickerField(
                                value: _politicalStatus,
                                options: RegisterConstants.politicalOptions,
                                onChanged: (v) =>
                                    setState(() => _politicalStatus = v),
                              )),
                          _formField('婚姻状况',
                              child: PickerField(
                                value: _maritalStatus,
                                options: RegisterConstants.maritalOptions,
                                onChanged: (v) =>
                                    setState(() => _maritalStatus = v),
                              )),
                          _formField('出生日期',
                              isLast: true,
                              child: DatePickerField(
                                value: _birthday,
                                onChanged: (v) =>
                                    setState(() => _birthday = v),
                              )),
                        ]),

                        // -- 3. 联系方式 --
                        FormSection(title: '联系方式', children: [
                          _formField('联系电话',
                              required: true,
                              error: 'phone',
                              child: TextField(
                                controller: _phoneCtl,
                                focusNode: _phoneFocus,
                                decoration: formInputDecoration(
                                  hint: '请输入联系电话',
                                  suffixIcon: _isPhoneQuerying
                                      ? Padding(
                                          padding: const EdgeInsets.all(
                                              AppSpacing.s12),
                                          child: SizedBox(
                                            width: 14,
                                            height: 14,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: AppColors.neutral400,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                keyboardType: TextInputType.phone,
                                textAlign: TextAlign.end,
                                style: AppTypography.formField,
                                onChanged: _onPhoneChanged,
                              )),
                          _formField('邮箱',
                              required: true,
                              error: 'email',
                              isLast: true,
                              child: _textInput(_emailCtl, '请输入邮箱',
                                  keyboard: TextInputType.emailAddress)),
                        ]),

                        // -- 4. 籍贯与住址 --
                        FormSection(title: '籍贯与住址', children: [
                          _formField('籍贯',
                              required: true,
                              error: 'nativePlace',
                              isLast: true,
                              child: AreaPickerField(
                                value: _nativePlace,
                                onChanged: (v) =>
                                    setState(() => _nativePlace = v),
                              )),
                        ]),
                        FormSection(children: [
                          FormBlockField(
                            label: '居住地址',
                            required: true,
                            errorText: _fieldErrors['address'],
                            child: Column(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _showAddressAreaPicker(),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.s12,
                                      vertical: AppSpacing.s13,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.neutral200),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _addressArea.isNotEmpty
                                                ? _addressArea
                                                : '请选择省/市/区',
                                            style: AppTypography.formField
                                                .copyWith(
                                              color: _addressArea.isNotEmpty
                                                  ? AppColors.textPrimary
                                                  : AppColors
                                                      .textPlaceholder,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: AppColors.neutral300,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s8),
                                FormTextArea(
                                  controller: _addressDetailCtl,
                                  hint: '请输入详细地址',
                                  maxLines: 3,
                                  minLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ]),

                        // -- 5. 身体信息 --
                        FormSection(title: '身体信息', children: [
                          InlineFieldRow(
                            errorText: _fieldErrors['height'],
                            items: [
                              InlineFieldItem(
                                label: '身高',
                                required: true,
                                unit: 'cm',
                                child: _inlineInput(_heightCtl, '请输入'),
                              ),
                              InlineFieldItem(
                                label: '体重',
                                required: true,
                                unit: 'kg',
                                child: _inlineInput(_weightCtl, '请输入'),
                              ),
                            ],
                          ),
                          _formField('血型',
                              isLast: true,
                              child: PickerField(
                                value: _bloodType,
                                options:
                                    RegisterConstants.bloodTypeOptions,
                                onChanged: (v) =>
                                    setState(() => _bloodType = v),
                              )),
                        ]),

                        // -- 6. 入职信息 --
                        FormSection(title: '入职信息', children: [
                          _formField('入职时间',
                              required: true,
                              error: 'entryDate',
                              isLast: true,
                              child: DatePickerField(
                                value: _entryDate,
                                onChanged: (v) =>
                                    setState(() => _entryDate = v),
                              )),
                        ]),

                        // -- 7. 个人特长 --
                        CheckboxGridSection(
                          title: '个人特长',
                          hint: '请至少选择一项',
                          options: RegisterConstants
                              .specialtyCheckboxOptions,
                          selectedValues: _selectedSpecialties,
                          onChanged: (v) =>
                              setState(() => _selectedSpecialties = v),
                        ),

                        // -- 8. 健康与协议 --
                        FormSection(title: '健康与协议', children: [
                          _formField('有无重大疾病',
                              required: true,
                              error: 'disease',
                              isLast: false,
                              child: _yesNoToggle(
                                value: _hasMajorDisease,
                                onChanged: (v) =>
                                    setState(() => _hasMajorDisease = v),
                              )),
                          _formField('有无竞业协议',
                              required: true,
                              error: 'nonCompete',
                              isLast: true,
                              child: _yesNoToggle(
                                value: _hasNonCompete,
                                onChanged: (v) =>
                                    setState(() => _hasNonCompete = v),
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

  void _showAddressAreaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return AreaPickerSheet(
          initialValue: _addressArea,
          onConfirm: (province, city, district) {
            setState(() => _addressArea = '$province $city $district');
            Navigator.pop(ctx);
          },
          onCancel: () => Navigator.pop(ctx),
        );
      },
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
      decoration: formInputDecoration(hint: hint),
      textAlign: TextAlign.end,
      keyboardType: keyboard,
      style: AppTypography.formField,
      onEditingComplete: onDone,
    );
  }

  Widget _inlineInput(
    TextEditingController controller,
    String hint,
  ) {
    return TextField(
      controller: controller,
      decoration: formInputDecoration(hint: hint),
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: AppTypography.formField,
    );
  }

  Widget _yesNoToggle({
    required bool? value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleChip(label: '是', selected: value == true,
              onTap: () => onChanged(true)),
          const SizedBox(width: AppSpacing.s8),
          _toggleChip(label: '否', selected: value == false,
              onTap: () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s20,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutral200,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.callout.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
