// 认证数据模型 - 对应 OaPersonnelAuthController

/// 登录请求 - 对应 OaPersonnelLoginBo
class LoginRequest {
  final String phone;
  final String password;

  const LoginRequest({required this.phone, required this.password});

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'password': password,
      };
}

/// 登录响应 - 对应 OaPersonnelLoginVo
/// 后端返回: {accessToken, expireIn, personnelId, name, phone, gender, email, entryDate, tenantId}
class LoginResponse {
  final String? accessToken;
  final int? expireIn;

  const LoginResponse({
    this.accessToken,
    this.expireIn,
  });

  /// 获取实际可用的 token
  String? get validToken => accessToken;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String?,
      expireIn: json['expireIn'] as int?,
    );
  }
}

/// 用户信息 - 对应 OaPersonnelLoginVo (getInfo 返回)
/// 后端 /oa/auth/getInfo 返回: {personnelId, name, phone, gender, email, entryDate, tenantId}
class UserInfo {
  final int? personnelId;
  final String? name;
  final String? phone;
  final int? gender;
  final String? email;
  final String? entryDate;
  final String? tenantId;

  const UserInfo({
    this.personnelId,
    this.name,
    this.phone,
    this.gender,
    this.email,
    this.entryDate,
    this.tenantId,
  });

  /// 获取实际 userId
  int get effectiveUserId => personnelId ?? -1;

  /// 获取显示名
  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!;
    if (phone != null && phone!.trim().isNotEmpty) return phone!;
    return '';
  }

  /// 获取显示头像 (后端 getInfo 不返回 avatar，使用默认)
  String get displayAvatar => '/static/images/default-avatar.png';

  /// 性别文本
  String get genderText {
    switch (gender) {
      case 0:
        return '女';
      case 1:
        return '男';
      default:
        return '未设置';
    }
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      personnelId: json['personnelId'] as int?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as int?,
      email: json['email'] as String?,
      entryDate: json['entryDate'] as String?,
      tenantId: json['tenantId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'personnelId': personnelId,
        'name': name,
        'phone': phone,
        'gender': gender,
        'email': email,
        'entryDate': entryDate,
        'tenantId': tenantId,
      };
}

/// 修改密码请求 - 对应 OaPersonnelPasswordBo
/// 后端只需要 oldPassword 和 newPassword
class UpdatePasswordRequest {
  final String oldPassword;
  final String newPassword;

  const UpdatePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      };
}
