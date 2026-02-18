// 规章制度模型 - 对应后端 OaCompanyRegulationVo

class RegulationVo {
  final int? id;
  final String? regulationType;
  final String? regulationTypeName;
  final String? regulationDetail;
  final String? fileName;
  final String? scope;
  final String? effectiveDate;
  final String? expiryDate;
  final String? status; // draft/reviewing/published/abolished
  final String? createTime;
  final String? updateTime;
  final String? remark;
  final String? delFlag;

  const RegulationVo({
    this.id,
    this.regulationType,
    this.regulationTypeName,
    this.regulationDetail,
    this.fileName,
    this.scope,
    this.effectiveDate,
    this.expiryDate,
    this.status,
    this.createTime,
    this.updateTime,
    this.remark,
    this.delFlag,
  });

  factory RegulationVo.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return RegulationVo(
      id: rawId is int ? rawId : (rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '')),
      regulationType: json['regulationType']?.toString(),
      regulationTypeName: json['regulationTypeName'] as String?,
      regulationDetail: json['regulationDetail'] as String?,
      fileName: json['fileName'] as String?,
      scope: json['scope'] as String?,
      effectiveDate: json['effectiveDate'] as String?,
      expiryDate: json['expiryDate'] as String?,
      status: json['status']?.toString(),
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
      remark: json['remark'] as String?,
      delFlag: json['delFlag']?.toString(),
    );
  }
}
