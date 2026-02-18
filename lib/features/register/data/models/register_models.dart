// 入职登记模块数据模型 - 对应 src/api/personnel.ts 及注册相关接口

/// 安全地将 JSON 值解析为 int?（兼容后端返回 String 或 num 的情况）
int? _safeInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// 安全地将 JSON 值解析为 num?（兼容后端返回 String 或 num 的情况）
num? _safeNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

/// 人员基本信息（API 读取） - 对应后端 OaPersonnelBasicInfoVo
class PersonnelBasicInfoVo {
  final int? id;
  final String? username;
  final String? password;
  final String? phone;
  final String? name;
  final int? gender; // 0=女 1=男
  final int? age;
  final String? birthDate; // LocalDate -> String
  final String? ethnicity;
  final String? nativePlace;
  final int? height;
  final int? weight;
  final String? bloodType;
  final String? politicalStatus;
  final String? email;
  final int? maritalStatus; // 0=未婚 1=已婚 2=离异
  final String? entryDate; // LocalDate -> String
  final String? specialty;
  final int? hasMajorDisease; // 0=否 1=是
  final int? hasNonCompeteAgreement; // 0=否 1=是
  final String? residenceAddress;
  final String? idCardNumber;
  final String? idCardValidity;
  final String? idCardAddress;
  final String? idCardFrontPhoto;
  final String? idCardBackPhoto;
  final String? bankCardNumber;
  final String? bankCardAddress;
  final String? bankCardFrontPhoto;
  final String? bankCardBackPhoto;
  final String? personnelPhoto;
  final String? avatar;
  final String? remark;
  final String? createTime;
  final String? updateTime;
  final String? status;
  final String? actualPosition;
  final num? actualSalary; // BigDecimal -> num
  final String? department;
  final String? jobLevel;
  final String? appliedPosition;
  final num? expectedSalary; // BigDecimal -> num
  final String? rejectReason;

  const PersonnelBasicInfoVo({
    this.id,
    this.username,
    this.password,
    this.phone,
    this.name,
    this.gender,
    this.age,
    this.birthDate,
    this.ethnicity,
    this.nativePlace,
    this.height,
    this.weight,
    this.bloodType,
    this.politicalStatus,
    this.email,
    this.maritalStatus,
    this.entryDate,
    this.specialty,
    this.hasMajorDisease,
    this.hasNonCompeteAgreement,
    this.residenceAddress,
    this.idCardNumber,
    this.idCardValidity,
    this.idCardAddress,
    this.idCardFrontPhoto,
    this.idCardBackPhoto,
    this.bankCardNumber,
    this.bankCardAddress,
    this.bankCardFrontPhoto,
    this.bankCardBackPhoto,
    this.personnelPhoto,
    this.avatar,
    this.remark,
    this.createTime,
    this.updateTime,
    this.status,
    this.actualPosition,
    this.actualSalary,
    this.department,
    this.jobLevel,
    this.appliedPosition,
    this.expectedSalary,
    this.rejectReason,
  });

  factory PersonnelBasicInfoVo.fromJson(Map<String, dynamic> json) {
    return PersonnelBasicInfoVo(
      id: _safeInt(json['id']),
      username: json['username'] as String?,
      password: json['password'] as String?,
      phone: json['phone'] as String?,
      name: json['name'] as String?,
      gender: _safeInt(json['gender']),
      age: _safeInt(json['age']),
      birthDate: json['birthDate']?.toString(),
      ethnicity: json['ethnicity'] as String?,
      nativePlace: json['nativePlace'] as String?,
      height: _safeInt(json['height']),
      weight: _safeInt(json['weight']),
      bloodType: json['bloodType'] as String?,
      politicalStatus: json['politicalStatus'] as String?,
      email: json['email'] as String?,
      maritalStatus: _safeInt(json['maritalStatus']),
      entryDate: json['entryDate']?.toString(),
      specialty: json['specialty'] as String?,
      hasMajorDisease: _safeInt(json['hasMajorDisease']),
      hasNonCompeteAgreement: _safeInt(json['hasNonCompeteAgreement']),
      residenceAddress: json['residenceAddress'] as String?,
      idCardNumber: json['idCardNumber'] as String?,
      idCardValidity: json['idCardValidity'] as String?,
      idCardAddress: json['idCardAddress'] as String?,
      idCardFrontPhoto: json['idCardFrontPhoto'] as String?,
      idCardBackPhoto: json['idCardBackPhoto'] as String?,
      bankCardNumber: json['bankCardNumber'] as String?,
      bankCardAddress: json['bankCardAddress'] as String?,
      bankCardFrontPhoto: json['bankCardFrontPhoto'] as String?,
      bankCardBackPhoto: json['bankCardBackPhoto'] as String?,
      personnelPhoto: json['personnelPhoto'] as String?,
      avatar: json['avatar'] as String?,
      remark: json['remark'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
      status: json['status']?.toString(),
      actualPosition: json['actualPosition'] as String?,
      actualSalary: _safeNum(json['actualSalary']),
      department: json['department'] as String?,
      jobLevel: json['jobLevel'] as String?,
      appliedPosition: json['appliedPosition'] as String?,
      expectedSalary: _safeNum(json['expectedSalary']),
      rejectReason: json['rejectReason'] as String?,
    );
  }

  /// 性别文本
  String get genderText => switch (gender) {
        0 => '女',
        1 => '男',
        _ => '未知',
      };

  /// 婚姻状况文本
  String get maritalStatusText => switch (maritalStatus) {
        0 => '未婚',
        1 => '已婚',
        2 => '离异',
        _ => '未知',
      };
}

/// 人员基本信息提交体 - POST/PUT /oa/personnelBasicInfo
/// 对应后端 OaPersonnelBasicInfoBo
class PersonnelBasicInfoSubmit {
  final int? id;
  final String name;
  final String phone;
  final int? gender; // 0=女 1=男
  final String? email;
  final String? birthDate;
  final int? age;
  final String? ethnicity;
  final String? nativePlace;
  final int? height;
  final int? weight;
  final String? bloodType;
  final String? politicalStatus;
  final int? maritalStatus;
  final String? entryDate;
  final String? specialty;
  final int? hasMajorDisease;
  final int? hasNonCompeteAgreement;
  final String? residenceAddress;
  final String? idCardNumber;
  final String? idCardValidity;
  final String? idCardAddress;
  final String? idCardFrontPhoto;
  final String? idCardBackPhoto;
  final String? bankCardNumber;
  final String? bankCardAddress;
  final String? bankCardFrontPhoto;
  final String? bankCardBackPhoto;
  final String? personnelPhoto;
  final String? avatar;
  final String? remark;
  final String? status;

  const PersonnelBasicInfoSubmit({
    this.id,
    required this.name,
    required this.phone,
    this.gender,
    this.email,
    this.birthDate,
    this.age,
    this.ethnicity,
    this.nativePlace,
    this.height,
    this.weight,
    this.bloodType,
    this.politicalStatus,
    this.maritalStatus,
    this.entryDate,
    this.specialty,
    this.hasMajorDisease,
    this.hasNonCompeteAgreement,
    this.residenceAddress,
    this.idCardNumber,
    this.idCardValidity,
    this.idCardAddress,
    this.idCardFrontPhoto,
    this.idCardBackPhoto,
    this.bankCardNumber,
    this.bankCardAddress,
    this.bankCardFrontPhoto,
    this.bankCardBackPhoto,
    this.personnelPhoto,
    this.avatar,
    this.remark,
    this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': ?id,
        'name': name,
        'phone': phone,
        'gender': ?gender,
        'email': ?email,
        'birthDate': ?birthDate,
        'age': ?age,
        'ethnicity': ?ethnicity,
        'nativePlace': ?nativePlace,
        'height': ?height,
        'weight': ?weight,
        'bloodType': ?bloodType,
        'politicalStatus': ?politicalStatus,
        'maritalStatus': ?maritalStatus,
        'entryDate': ?entryDate,
        'specialty': ?specialty,
        'hasMajorDisease': ?hasMajorDisease,
        'hasNonCompeteAgreement': ?hasNonCompeteAgreement,
        'residenceAddress': ?residenceAddress,
        'idCardNumber': ?idCardNumber,
        'idCardValidity': ?idCardValidity,
        'idCardAddress': ?idCardAddress,
        'idCardFrontPhoto': ?idCardFrontPhoto,
        'idCardBackPhoto': ?idCardBackPhoto,
        'bankCardNumber': ?bankCardNumber,
        'bankCardAddress': ?bankCardAddress,
        'bankCardFrontPhoto': ?bankCardFrontPhoto,
        'bankCardBackPhoto': ?bankCardBackPhoto,
        'personnelPhoto': ?personnelPhoto,
        'avatar': ?avatar,
        'remark': ?remark,
        'status': ?status,
      };
}

/// 履历/经历记录
class PersonnelResumeVo {
  final int? id;
  final int? personnelId;
  final int? experienceType;
  final String? unitName;
  final String? startDate;
  final String? endDate;
  final String? major;
  final String? education;
  final String? course;
  final String? certificate;
  final String? position;
  final String? salaryRange;
  final String? leaveReason;
  final String? witnessName;
  final String? witnessContact;
  final int? certificateType;
  final String? certificatePhoto;
  final String? status;
  final int? delFlag;

  const PersonnelResumeVo({
    this.id,
    this.personnelId,
    this.experienceType,
    this.unitName,
    this.startDate,
    this.endDate,
    this.major,
    this.education,
    this.course,
    this.certificate,
    this.position,
    this.salaryRange,
    this.leaveReason,
    this.witnessName,
    this.witnessContact,
    this.certificateType,
    this.certificatePhoto,
    this.status,
    this.delFlag,
  });

  factory PersonnelResumeVo.fromJson(Map<String, dynamic> json) {
    return PersonnelResumeVo(
      id: _safeInt(json['id']),
      personnelId: _safeInt(json['personnelId']),
      experienceType: _safeInt(json['experienceType']),
      unitName: json['unitName'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      major: json['major'] as String?,
      education: json['education'] as String?,
      course: json['course'] as String?,
      certificate: json['certificate'] as String?,
      position: json['position'] as String?,
      salaryRange: json['salaryRange'] as String?,
      leaveReason: json['leaveReason'] as String?,
      witnessName: json['witnessName'] as String?,
      witnessContact: json['witnessContact'] as String?,
      certificateType: _safeInt(json['certificateType']),
      certificatePhoto: json['certificatePhoto'] as String?,
      status: json['status']?.toString(),
      delFlag: _safeInt(json['delFlag']),
    );
  }
}

/// 履历提交体 - CRUD /oa/personnelResume
class PersonnelResumeSubmit {
  final int? id;
  final int personnelId;
  final int experienceType;
  final String unitName;
  final String startDate;
  final String endDate;
  final String? major;
  final String? education;
  final String? course;
  final String? certificate;
  final String? position;
  final String? salaryRange;
  final String? leaveReason;
  final String? witnessName;
  final String? witnessContact;
  final int? certificateType;
  final String? certificatePhoto;

  const PersonnelResumeSubmit({
    this.id,
    required this.personnelId,
    required this.experienceType,
    required this.unitName,
    required this.startDate,
    required this.endDate,
    this.major,
    this.education,
    this.course,
    this.certificate,
    this.position,
    this.salaryRange,
    this.leaveReason,
    this.witnessName,
    this.witnessContact,
    this.certificateType,
    this.certificatePhoto,
  });

  Map<String, dynamic> toJson() => {
        'id': ?id,
        'personnelId': personnelId,
        'experienceType': experienceType,
        'unitName': unitName,
        'startDate': startDate,
        'endDate': endDate,
        'major': ?major,
        'education': ?education,
        'course': ?course,
        'certificate': ?certificate,
        'position': ?position,
        'salaryRange': ?salaryRange,
        'leaveReason': ?leaveReason,
        'witnessName': ?witnessName,
        'witnessContact': ?witnessContact,
        'certificateType': ?certificateType,
        'certificatePhoto': ?certificatePhoto,
      };
}

/// 入职规划 - 对应后端 OaPersonnelEntryPlanVo
class PersonnelEntryPlanVo {
  final int? id;
  final int? personnelId;
  final String? appliedPosition;
  final num? expectedSalary; // BigDecimal -> num
  final int? canOvertime; // 0=否 1=是
  final int? canWorkRemote; // 0=否 1=是
  final String? careerPlanning;
  final String? selfEvaluation;
  final String? remark;
  final String? createTime;
  final String? updateTime;

  const PersonnelEntryPlanVo({
    this.id,
    this.personnelId,
    this.appliedPosition,
    this.expectedSalary,
    this.canOvertime,
    this.canWorkRemote,
    this.careerPlanning,
    this.selfEvaluation,
    this.remark,
    this.createTime,
    this.updateTime,
  });

  factory PersonnelEntryPlanVo.fromJson(Map<String, dynamic> json) {
    return PersonnelEntryPlanVo(
      id: _safeInt(json['id']),
      personnelId: _safeInt(json['personnelId']),
      appliedPosition: json['appliedPosition'] as String?,
      expectedSalary: _safeNum(json['expectedSalary']),
      canOvertime: _safeInt(json['canOvertime']),
      canWorkRemote: _safeInt(json['canWorkRemote']),
      careerPlanning: json['careerPlanning'] as String?,
      selfEvaluation: json['selfEvaluation'] as String?,
      remark: json['remark'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }
}

/// 入职规划提交体 - 对应后端 OaPersonnelEntryPlanBo
class PersonnelEntryPlanSubmit {
  final int? id;
  final int personnelId;
  final String appliedPosition;
  final num? expectedSalary;
  final int? canOvertime; // 0=否 1=是
  final int? canWorkRemote; // 0=否 1=是
  final String? careerPlanning;
  final String? selfEvaluation;
  final String? remark;

  const PersonnelEntryPlanSubmit({
    this.id,
    required this.personnelId,
    required this.appliedPosition,
    this.expectedSalary,
    this.canOvertime,
    this.canWorkRemote,
    this.careerPlanning,
    this.selfEvaluation,
    this.remark,
  });

  Map<String, dynamic> toJson() => {
        'id': ?id,
        'personnelId': personnelId,
        'appliedPosition': appliedPosition,
        'expectedSalary': ?expectedSalary,
        'canOvertime': ?canOvertime,
        'canWorkRemote': ?canWorkRemote,
        'careerPlanning': ?careerPlanning,
        'selfEvaluation': ?selfEvaluation,
        'remark': ?remark,
      };
}

/// 家庭关系 - 对应后端 OaPersonnelFamilyRelationVo
class PersonnelFamilyRelationVo {
  final int? id;
  final int? personnelId;
  final String? familyName;
  final String? contactPhone;
  final String? relation;
  final int? age;
  final String? occupation;
  final String? politicalStatus;
  final String? hasMajorViolation; // "0"无 "1"有
  final String? remark;
  final String? createTime;
  final String? updateTime;

  const PersonnelFamilyRelationVo({
    this.id,
    this.personnelId,
    this.familyName,
    this.contactPhone,
    this.relation,
    this.age,
    this.occupation,
    this.politicalStatus,
    this.hasMajorViolation,
    this.remark,
    this.createTime,
    this.updateTime,
  });

  factory PersonnelFamilyRelationVo.fromJson(Map<String, dynamic> json) {
    return PersonnelFamilyRelationVo(
      id: _safeInt(json['id']),
      personnelId: _safeInt(json['personnelId']),
      familyName: json['familyName'] as String?,
      contactPhone: json['contactPhone'] as String?,
      relation: json['relation'] as String?,
      age: _safeInt(json['age']),
      occupation: json['occupation'] as String?,
      politicalStatus: json['politicalStatus'] as String?,
      hasMajorViolation: json['hasMajorViolation']?.toString(),
      remark: json['remark'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }
}

/// 家庭关系提交体 - 对应后端 OaPersonnelFamilyRelationBo
class PersonnelFamilyRelationSubmit {
  final int? id;
  final int personnelId;
  final String familyName;
  final String? contactPhone;
  final String relation;
  final int? age;
  final String? occupation;
  final String? politicalStatus;
  final String? hasMajorViolation; // "0"无 "1"有
  final String? remark;

  const PersonnelFamilyRelationSubmit({
    this.id,
    required this.personnelId,
    required this.familyName,
    this.contactPhone,
    required this.relation,
    this.age,
    this.occupation,
    this.politicalStatus,
    this.hasMajorViolation,
    this.remark,
  });

  Map<String, dynamic> toJson() => {
        'id': ?id,
        'personnelId': personnelId,
        'familyName': familyName,
        'contactPhone': ?contactPhone,
        'relation': relation,
        'age': ?age,
        'occupation': ?occupation,
        'politicalStatus': ?politicalStatus,
        'hasMajorViolation': ?hasMajorViolation,
        'remark': ?remark,
      };
}
