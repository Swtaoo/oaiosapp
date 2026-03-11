// 项目模型 - 对应 service/types.ts ProjectInfoVo, ProjectStaffVo, ChatRecordVo

class ProjectInfoVo {
  final int? id;
  final String? projectName;
  final String? projectDescription;
  final String? projectCreateTime;
  final String? expectedDeliveryTime;
  final String? actualDeliveryTime;
  final String? projectStatus;
  final int? delFlag;
  final String? createTime;
  final String? updateTime;

  const ProjectInfoVo({
    this.id,
    this.projectName,
    this.projectDescription,
    this.projectCreateTime,
    this.expectedDeliveryTime,
    this.actualDeliveryTime,
    this.projectStatus,
    this.delFlag,
    this.createTime,
    this.updateTime,
  });

  factory ProjectInfoVo.fromJson(Map<String, dynamic> json) {
    return ProjectInfoVo(
      id: json['id'] as int?,
      projectName: json['projectName'] as String?,
      projectDescription: json['projectDescription'] as String?,
      projectCreateTime: json['projectCreateTime'] as String?,
      expectedDeliveryTime: json['expectedDeliveryTime'] as String?,
      actualDeliveryTime: json['actualDeliveryTime'] as String?,
      projectStatus: json['projectStatus'] as String?,
      delFlag: json['delFlag'] as int?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }
}

class ProjectStaffVo {
  final int? id;
  final int? projectId;
  final int? personnelId;
  final String? name;
  final String? avatar;
  final int? isProjectManager;
  final String? employeeRole;
  final String? projectDuty;
  final int? delFlag;
  final String? createTime;
  final String? updateTime;

  const ProjectStaffVo({
    this.id,
    this.projectId,
    this.personnelId,
    this.name,
    this.avatar,
    this.isProjectManager,
    this.employeeRole,
    this.projectDuty,
    this.delFlag,
    this.createTime,
    this.updateTime,
  });

  factory ProjectStaffVo.fromJson(Map<String, dynamic> json) {
    return ProjectStaffVo(
      id: json['id'] as int?,
      projectId: json['projectId'] as int?,
      personnelId: json['personnelId'] as int?,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      isProjectManager: json['isProjectManager'] as int?,
      employeeRole: json['employeeRole'] as String?,
      projectDuty: json['projectDuty'] as String?,
      delFlag: json['delFlag'] as int?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }
}

class ChatRecordVo {
  final int? id;
  final int? projectId;
  final int? personnelId;
  final String? personnelName;
  final String? chatContent;
  final int? replyId;
  final String? replyContent;
  final String? replyUserName;
  final int? replyFileType;
  final String? fileUrl;
  final String? imageUrl;
  final int? fileType;
  final String? fileName;
  final int? fileSize;
  final String? atPersonnelIds;
  final int? delFlag;
  final String? createTime;
  final String? updateTime;

  /// 本地临时 ID，用于乐观发送时标识消息
  final String? localTempId;

  const ChatRecordVo({
    this.id,
    this.projectId,
    this.personnelId,
    this.personnelName,
    this.chatContent,
    this.replyId,
    this.replyContent,
    this.replyUserName,
    this.replyFileType,
    this.fileUrl,
    this.imageUrl,
    this.fileType,
    this.fileName,
    this.fileSize,
    this.atPersonnelIds,
    this.delFlag,
    this.createTime,
    this.updateTime,
    this.localTempId,
  });

  ChatRecordVo copyWith({
    int? id,
    int? projectId,
    int? personnelId,
    String? personnelName,
    String? chatContent,
    int? replyId,
    String? replyContent,
    String? replyUserName,
    int? replyFileType,
    String? fileUrl,
    String? imageUrl,
    int? fileType,
    String? fileName,
    int? fileSize,
    String? atPersonnelIds,
    int? delFlag,
    String? createTime,
    String? updateTime,
    String? localTempId,
  }) {
    return ChatRecordVo(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      personnelId: personnelId ?? this.personnelId,
      personnelName: personnelName ?? this.personnelName,
      chatContent: chatContent ?? this.chatContent,
      replyId: replyId ?? this.replyId,
      replyContent: replyContent ?? this.replyContent,
      replyUserName: replyUserName ?? this.replyUserName,
      replyFileType: replyFileType ?? this.replyFileType,
      fileUrl: fileUrl ?? this.fileUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      fileType: fileType ?? this.fileType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      atPersonnelIds: atPersonnelIds ?? this.atPersonnelIds,
      delFlag: delFlag ?? this.delFlag,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      localTempId: localTempId ?? this.localTempId,
    );
  }

  factory ChatRecordVo.fromJson(Map<String, dynamic> json) {
    return ChatRecordVo(
      id: json['id'] as int?,
      projectId: json['projectId'] as int?,
      personnelId: json['personnelId'] as int?,
      personnelName: json['personnelName'] as String?,
      chatContent: json['chatContent'] as String?,
      replyId: json['replyId'] as int?,
      replyContent: json['replyContent'] as String?,
      replyUserName: json['replyUserName'] as String?,
      replyFileType: json['replyFileType'] as int?,
      fileUrl: json['fileUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      fileType: json['fileType'] as int?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      atPersonnelIds: json['atPersonnelIds'] as String?,
      delFlag: json['delFlag'] as int?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }
}
