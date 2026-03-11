// 投标信息模型 - 对应后端 OaBiddingVo

class BiddingVo {
  final int? id;
  final String? biddingName;
  final String? biddingUrl;
  final String? biddingType;
  final String? biddingTime;
  final String? createTime;
  final String? updateTime;

  const BiddingVo({
    this.id,
    this.biddingName,
    this.biddingUrl,
    this.biddingType,
    this.biddingTime,
    this.createTime,
    this.updateTime,
  });

  factory BiddingVo.fromJson(Map<String, dynamic> json) {
    return BiddingVo(
      id: json['id'] as int?,
      biddingName: json['biddingName'] as String?,
      biddingUrl: json['biddingUrl'] as String?,
      biddingType: json['biddingType'] as String?,
      biddingTime: json['biddingTime'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }
}
