// 审批模块数据模型 - 对应 src/service/types.ts 中审批相关类型

/// 安全地将 JSON 值解析为 int?（兼容后端返回 String 或 num 的情况）
int? _safeInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// 安全地将 JSON 值解析为 num?
num? _safeNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

/// 审批流程 - 对应后端 ApprovalFlowVo
class ApprovalFlowVo {
  final int? id;
  final String? approvalObjectType; // 1=资金 2=工资 3=报销
  final int? objectId;
  final int? approverId;
  final int? nodeType; // 0=申请人 1=审批人
  final int? applicantId;
  final String? applicantName;
  final String? applicantAvatar;
  final String? approverName;
  final String? approverAvatar;
  final String? approvalTime;
  final String? approvalOpinion;
  final String? approvalRemark;
  final String? approvalAttachment;
  final int? nextApproverId;
  final String? nextApproverName;
  final String? nextApproverAvatar;
  final int? isFinalApproval;
  final String? status; // '0'待审批 '1'已通过 '2'已驳回
  final int? delFlag;
  final String? createTime;
  final String? updateTime;
  final String? displayStatus;

  const ApprovalFlowVo({
    this.id,
    this.approvalObjectType,
    this.objectId,
    this.approverId,
    this.nodeType,
    this.applicantId,
    this.applicantName,
    this.applicantAvatar,
    this.approverName,
    this.approverAvatar,
    this.approvalTime,
    this.approvalOpinion,
    this.approvalRemark,
    this.approvalAttachment,
    this.nextApproverId,
    this.nextApproverName,
    this.nextApproverAvatar,
    this.isFinalApproval,
    this.status,
    this.delFlag,
    this.createTime,
    this.updateTime,
    this.displayStatus,
  });

  factory ApprovalFlowVo.fromJson(Map<String, dynamic> json) {
    return ApprovalFlowVo(
      id: _safeInt(json['id']),
      approvalObjectType: json['approvalObjectType']?.toString(),
      objectId: _safeInt(json['objectId']),
      approverId: _safeInt(json['approverId']),
      nodeType: _safeInt(json['nodeType']),
      applicantId: _safeInt(json['applicantId']),
      applicantName: json['applicantName'] as String?,
      applicantAvatar: json['applicantAvatar'] as String?,
      approverName: json['approverName'] as String?,
      approverAvatar: json['approverAvatar'] as String?,
      approvalTime: json['approvalTime'] as String?,
      approvalOpinion: json['approvalOpinion'] as String?,
      approvalRemark: json['approvalRemark'] as String?,
      approvalAttachment: json['approvalAttachment'] as String?,
      nextApproverId: _safeInt(json['nextApproverId']),
      nextApproverName: json['nextApproverName'] as String?,
      nextApproverAvatar: json['nextApproverAvatar'] as String?,
      isFinalApproval: _safeInt(json['isFinalApproval']),
      status: json['status']?.toString(),
      delFlag: _safeInt(json['delFlag']),
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
      displayStatus: json['displayStatus'] as String?,
    );
  }

  bool get isDeleted => delFlag == 2;

  /// 创建副本，仅覆盖 displayStatus
  ApprovalFlowVo withDisplayStatus(String newDisplayStatus) {
    return ApprovalFlowVo(
      id: id,
      approvalObjectType: approvalObjectType,
      objectId: objectId,
      approverId: approverId,
      nodeType: nodeType,
      applicantId: applicantId,
      applicantName: applicantName,
      applicantAvatar: applicantAvatar,
      approverName: approverName,
      approverAvatar: approverAvatar,
      approvalTime: approvalTime,
      approvalOpinion: approvalOpinion,
      approvalRemark: approvalRemark,
      approvalAttachment: approvalAttachment,
      nextApproverId: nextApproverId,
      nextApproverName: nextApproverName,
      nextApproverAvatar: nextApproverAvatar,
      isFinalApproval: isFinalApproval,
      status: status,
      delFlag: delFlag,
      createTime: createTime,
      updateTime: updateTime,
      displayStatus: newDisplayStatus,
    );
  }
}

/// 审批提交请求体 - 对应后端 ApprovalFlowBo (EditGroup)
/// PUT /oa/approvalFlow 需要 id
class ApprovalFlowSubmit {
  final int? id;
  final String approvalObjectType;
  final int objectId;
  final int approverId;
  final String approvalOpinion;
  final String approvalRemark;
  final int nextApproverId;
  final int isFinalApproval;
  final String status;

  const ApprovalFlowSubmit({
    this.id,
    required this.approvalObjectType,
    required this.objectId,
    required this.approverId,
    required this.approvalOpinion,
    required this.approvalRemark,
    required this.nextApproverId,
    required this.isFinalApproval,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'approvalObjectType': approvalObjectType,
        'objectId': objectId,
        'approverId': approverId,
        'approvalOpinion': approvalOpinion,
        'approvalRemark': approvalRemark,
        'nextApproverId': nextApproverId,
        'isFinalApproval': isFinalApproval,
        'status': status,
      };
}

/// 资金申请 - 对应后端 FundApplicationVo
class FundApplicationVo {
  final int? id;
  final String? applyDepartment;
  final String? applicant;
  final int? applicantId;
  final num? applyAmount;
  final String? fundProject;
  final String? fundCostDesc;
  final String? accountName;
  final String? accountNumber;
  final String? bankName;
  final String? contactPerson;
  final String? attachment;
  final String? paymentVoucher;
  final String? applicantSignature;
  final String? status;
  final int? delFlag;
  final String? remark;
  final String? createTime;
  final String? updateTime;

  const FundApplicationVo({
    this.id,
    this.applyDepartment,
    this.applicant,
    this.applicantId,
    this.applyAmount,
    this.fundProject,
    this.fundCostDesc,
    this.accountName,
    this.accountNumber,
    this.bankName,
    this.contactPerson,
    this.attachment,
    this.paymentVoucher,
    this.applicantSignature,
    this.status,
    this.delFlag,
    this.remark,
    this.createTime,
    this.updateTime,
  });

  factory FundApplicationVo.fromJson(Map<String, dynamic> json) {
    return FundApplicationVo(
      id: _safeInt(json['id']),
      applyDepartment: json['applyDepartment'] as String?,
      applicant: json['applicant'] as String?,
      applicantId: _safeInt(json['applicantId']),
      applyAmount: _safeNum(json['applyAmount']),
      fundProject: json['fundProject'] as String?,
      fundCostDesc: json['fundCostDesc'] as String?,
      accountName: json['accountName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      bankName: json['bankName'] as String?,
      contactPerson: json['contactPerson'] as String?,
      attachment: json['attachment'] as String?,
      paymentVoucher: json['paymentVoucher'] as String?,
      applicantSignature: json['applicantSignature'] as String?,
      status: json['status']?.toString(),
      delFlag: _safeInt(json['delFlag']),
      remark: json['remark'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }
}

/// 资金申请明细 - 对应后端 FundApplicationDetailVo
class FundApplicationDetailVo {
  final int? id;
  final int? fundApplicationId;
  final String? applyDetail;
  final num? applyAmount;
  final String? status;
  final int? delFlag;

  const FundApplicationDetailVo({
    this.id,
    this.fundApplicationId,
    this.applyDetail,
    this.applyAmount,
    this.status,
    this.delFlag,
  });

  factory FundApplicationDetailVo.fromJson(Map<String, dynamic> json) {
    return FundApplicationDetailVo(
      id: _safeInt(json['id']),
      fundApplicationId: _safeInt(json['fundApplicationId']),
      applyDetail: json['applyDetail'] as String?,
      applyAmount: _safeNum(json['applyAmount']),
      status: json['status']?.toString(),
      delFlag: _safeInt(json['delFlag']),
    );
  }

  bool get isDeleted => delFlag == 2;
}

/// 资金申请提交请求体
class FundApplicationSubmit {
  final String applyDepartment;
  final String applicant;
  final num applyAmount;
  final String? applicantSignature;
  final String status;
  final String? fundProject;
  final String? fundCostDesc;
  final String? accountName;
  final String? accountNumber;
  final String? bankName;
  final String? contactPerson;
  final String? attachment;

  const FundApplicationSubmit({
    required this.applyDepartment,
    required this.applicant,
    required this.applyAmount,
    this.applicantSignature,
    this.status = '0',
    this.fundProject,
    this.fundCostDesc,
    this.accountName,
    this.accountNumber,
    this.bankName,
    this.contactPerson,
    this.attachment,
  });

  Map<String, dynamic> toJson() => {
        'applyDepartment': applyDepartment,
        'applicant': applicant,
        'applyAmount': applyAmount,
        'applicantSignature': ?applicantSignature,
        'status': status,
        'fundProject': ?fundProject,
        'fundCostDesc': ?fundCostDesc,
        'accountName': ?accountName,
        'accountNumber': ?accountNumber,
        'bankName': ?bankName,
        'contactPerson': ?contactPerson,
        'attachment': ?attachment,
      };
}

/// 报销申请 - 对应后端 ReimbursementVo
class ReimbursementVo {
  final int? id;
  final int? departmentId;
  final String? departmentName;
  final int? applicantId;
  final String? applicantName;
  final String? applyDate;
  final int? reimbursementProjectId;
  final String? reimbursementProjectName;
  final num? totalAmount;
  final String? status;
  final int? delFlag;
  final String? remark;
  final String? createTime;
  final String? updateTime;

  const ReimbursementVo({
    this.id,
    this.departmentId,
    this.departmentName,
    this.applicantId,
    this.applicantName,
    this.applyDate,
    this.reimbursementProjectId,
    this.reimbursementProjectName,
    this.totalAmount,
    this.status,
    this.delFlag,
    this.remark,
    this.createTime,
    this.updateTime,
  });

  factory ReimbursementVo.fromJson(Map<String, dynamic> json) {
    return ReimbursementVo(
      id: _safeInt(json['id']),
      departmentId: _safeInt(json['departmentId']),
      departmentName: json['departmentName'] as String?,
      applicantId: _safeInt(json['applicantId']),
      applicantName: json['applicantName'] as String?,
      applyDate: json['applyDate'] as String?,
      reimbursementProjectId: _safeInt(json['reimbursementProjectId']),
      reimbursementProjectName: json['reimbursementProjectName'] as String?,
      totalAmount: _safeNum(json['totalAmount']),
      status: json['status']?.toString(),
      delFlag: _safeInt(json['delFlag']),
      remark: json['remark'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }
}

/// 报销明细 - 对应后端 ReimbursementDetailVo
class ReimbursementDetailVo {
  final int? id;
  final int? reimbursementId;
  final String? reimbursementDetail;
  final String? reimbursementProof;
  final num? reimbursementAmount;
  final String? category;
  final String? status;
  final int? delFlag;
  final String? remark;
  final String? createTime;
  final String? updateTime;

  const ReimbursementDetailVo({
    this.id,
    this.reimbursementId,
    this.reimbursementDetail,
    this.reimbursementProof,
    this.reimbursementAmount,
    this.category,
    this.status,
    this.delFlag,
    this.remark,
    this.createTime,
    this.updateTime,
  });

  factory ReimbursementDetailVo.fromJson(Map<String, dynamic> json) {
    return ReimbursementDetailVo(
      id: _safeInt(json['id']),
      reimbursementId: _safeInt(json['reimbursementId']),
      reimbursementDetail: json['reimbursementDetail'] as String?,
      reimbursementProof: json['reimbursementProof'] as String?,
      reimbursementAmount: _safeNum(json['reimbursementAmount']),
      category: json['category'] as String?,
      status: json['status']?.toString(),
      delFlag: _safeInt(json['delFlag']),
      remark: json['remark'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  bool get isDeleted => delFlag == 2;
}

/// 工资信息
class SalaryInfoVo {
  final int? id;
  final String? salaryDate;
  final String? paymentDate;
  final num? basicSalaryTotal;
  final num? subsidyTotal;
  final num? insuranceFundTotal;
  final num? payableAmountTotal;
  final num? actualAmountTotal;
  final num? unpaidAmount;
  final String? status;
  final int? delFlag;

  const SalaryInfoVo({
    this.id,
    this.salaryDate,
    this.paymentDate,
    this.basicSalaryTotal,
    this.subsidyTotal,
    this.insuranceFundTotal,
    this.payableAmountTotal,
    this.actualAmountTotal,
    this.unpaidAmount,
    this.status,
    this.delFlag,
  });

  factory SalaryInfoVo.fromJson(Map<String, dynamic> json) {
    return SalaryInfoVo(
      id: _safeInt(json['id']),
      salaryDate: json['salaryDate'] as String?,
      paymentDate: json['paymentDate'] as String?,
      basicSalaryTotal: _safeNum(json['basicSalaryTotal']),
      subsidyTotal: _safeNum(json['subsidyTotal']),
      insuranceFundTotal: _safeNum(json['insuranceFundTotal']),
      payableAmountTotal: _safeNum(json['payableAmountTotal']),
      actualAmountTotal: _safeNum(json['actualAmountTotal']),
      unpaidAmount: _safeNum(json['unpaidAmount']),
      status: json['status']?.toString(),
      delFlag: _safeInt(json['delFlag']),
    );
  }
}

/// 工资明细
class SalaryDetailVo {
  final int? id;
  final int? salaryId;
  final int? employeeId;
  final String? salaryDate;
  final String? paymentDate;
  final String? employeeName;
  final String? employeePosition;
  final num? basicSalary;
  final num? positionSalary;
  final num? performanceSalary;
  final num? positionSubsidy;
  final num? computerSubsidy;
  final num? otherSubsidy;
  final num? housingSubsidy;
  final num? lunchSubsidy;
  final num? payableSalary;
  final num? socialSecurityDeduction;
  final num? attendanceDeduction;
  final num? housingFundDeduction;
  final num? personalTaxDeduction;
  final num? totalDeduction;
  final num? actualSalary;
  final String? salaryRemark;
  final String? status;
  final int? delFlag;

  const SalaryDetailVo({
    this.id,
    this.salaryId,
    this.employeeId,
    this.salaryDate,
    this.paymentDate,
    this.employeeName,
    this.employeePosition,
    this.basicSalary,
    this.positionSalary,
    this.performanceSalary,
    this.positionSubsidy,
    this.computerSubsidy,
    this.otherSubsidy,
    this.housingSubsidy,
    this.lunchSubsidy,
    this.payableSalary,
    this.socialSecurityDeduction,
    this.attendanceDeduction,
    this.housingFundDeduction,
    this.personalTaxDeduction,
    this.totalDeduction,
    this.actualSalary,
    this.salaryRemark,
    this.status,
    this.delFlag,
  });

  factory SalaryDetailVo.fromJson(Map<String, dynamic> json) {
    return SalaryDetailVo(
      id: _safeInt(json['id']),
      salaryId: _safeInt(json['salaryId']),
      employeeId: _safeInt(json['employeeId']),
      salaryDate: json['salaryDate'] as String?,
      paymentDate: json['paymentDate'] as String?,
      employeeName: json['employeeName'] as String?,
      employeePosition: json['employeePosition'] as String?,
      basicSalary: _safeNum(json['basicSalary']),
      positionSalary: _safeNum(json['positionSalary']),
      performanceSalary: _safeNum(json['performanceSalary']),
      positionSubsidy: _safeNum(json['positionSubsidy']),
      computerSubsidy: _safeNum(json['computerSubsidy']),
      otherSubsidy: _safeNum(json['otherSubsidy']),
      housingSubsidy: _safeNum(json['housingSubsidy']),
      lunchSubsidy: _safeNum(json['lunchSubsidy']),
      payableSalary: _safeNum(json['payableSalary']),
      socialSecurityDeduction: _safeNum(json['socialSecurityDeduction']),
      attendanceDeduction: _safeNum(json['attendanceDeduction']),
      housingFundDeduction: _safeNum(json['housingFundDeduction']),
      personalTaxDeduction: _safeNum(json['personalTaxDeduction']),
      totalDeduction: _safeNum(json['totalDeduction']),
      actualSalary: _safeNum(json['actualSalary']),
      salaryRemark: json['salaryRemark'] as String?,
      status: json['status']?.toString(),
      delFlag: _safeInt(json['delFlag']),
    );
  }

  bool get isDeleted => delFlag == 2;
}

/// 人员基本信息（用于下一审批人选择等）
class PersonnelBasicInfoVo {
  final int? id;
  final String? name;
  final String? department;
  final String? avatar;

  const PersonnelBasicInfoVo({
    this.id,
    this.name,
    this.department,
    this.avatar,
  });

  factory PersonnelBasicInfoVo.fromJson(Map<String, dynamic> json) {
    return PersonnelBasicInfoVo(
      id: _safeInt(json['id']),
      name: json['name'] as String?,
      department: json['department'] as String?,
      avatar: json['avatar'] as String?,
    );
  }
}
