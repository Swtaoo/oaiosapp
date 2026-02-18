// 合同模型 - 对应后端 OaContractVo

class ContractVo {
  final int? id;
  final int? personnelId;
  final String? personnelName;
  final String? contractFile;
  final String? contractExpiryDate;
  final String? createTime;
  final String? updateTime;
  final String? position;
  final String? contractType;
  final String? signCompany;
  final num? salary; // BigDecimal -> num
  final String? startDate;

  const ContractVo({
    this.id,
    this.personnelId,
    this.personnelName,
    this.contractFile,
    this.contractExpiryDate,
    this.createTime,
    this.updateTime,
    this.position,
    this.contractType,
    this.signCompany,
    this.salary,
    this.startDate,
  });

  factory ContractVo.fromJson(Map<String, dynamic> json) {
    return ContractVo(
      id: json['id'] as int?,
      personnelId: json['personnelId'] as int?,
      personnelName: json['personnelName'] as String?,
      contractFile: json['contractFile'] as String?,
      contractExpiryDate: json['contractExpiryDate'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
      position: json['position'] as String?,
      contractType: json['contractType'] as String?,
      signCompany: json['signCompany'] as String?,
      salary: json['salary'] as num?,
      startDate: json['startDate'] as String?,
    );
  }
}

/// 合同到期状态
enum ExpiryType { expired, today, urgent, warning, normal }

/// 到期信息
class ExpiryInfo {
  final String text;
  final int days;
  final ExpiryType type;

  const ExpiryInfo({required this.text, required this.days, required this.type});
}
