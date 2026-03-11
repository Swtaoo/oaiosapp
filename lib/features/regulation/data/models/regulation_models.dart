import 'dart:convert';

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
      id: rawId is int
          ? rawId
          : (rawId is num
                ? rawId.toInt()
                : int.tryParse(rawId?.toString() ?? '')),
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

class AiRegulationAskRequest {
  final String question;
  final List<int>? regulationIds;
  final String? regulationType;
  final int? topK;
  final String? model;
  final bool? citationRequired;

  const AiRegulationAskRequest({
    required this.question,
    this.regulationIds,
    this.regulationType,
    this.topK,
    this.model,
    this.citationRequired,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'regulationIds': regulationIds,
    'regulationType': regulationType,
    'topK': topK,
    'model': model,
    'citationRequired': citationRequired,
  };
}

class AiRegulationReference {
  final String? citationId;
  final String? docId;
  final String? chunkId;
  final int? regulationId;
  final String? title;
  final String? snippet;
  final int? page;
  final double? score;
  final String? sourceUrl;

  const AiRegulationReference({
    this.citationId,
    this.docId,
    this.chunkId,
    this.regulationId,
    this.title,
    this.snippet,
    this.page,
    this.score,
    this.sourceUrl,
  });

  factory AiRegulationReference.fromJson(Map<String, dynamic> json) {
    final rawRegulationId = json['regulationId'];
    final rawPage = json['page'];
    final rawScore = json['score'];
    return AiRegulationReference(
      citationId: json['citationId']?.toString(),
      docId: json['docId']?.toString(),
      chunkId: json['chunkId']?.toString(),
      regulationId: rawRegulationId is int
          ? rawRegulationId
          : (rawRegulationId is num
                ? rawRegulationId.toInt()
                : int.tryParse(rawRegulationId?.toString() ?? '')),
      title: json['title']?.toString(),
      snippet: json['snippet']?.toString(),
      page: rawPage is int
          ? rawPage
          : (rawPage is num
                ? rawPage.toInt()
                : int.tryParse(rawPage?.toString() ?? '')),
      score: rawScore is double
          ? rawScore
          : (rawScore is num
                ? rawScore.toDouble()
                : double.tryParse(rawScore?.toString() ?? '')),
      sourceUrl: json['sourceUrl']?.toString(),
    );
  }
}

class AiRegulationAnswer {
  final String? answer;
  final String? model;
  final String? provider;
  final int? retrievedCount;
  final String? traceId;
  final bool? strictCitation;
  final List<AiRegulationReference> references;

  const AiRegulationAnswer({
    this.answer,
    this.model,
    this.provider,
    this.retrievedCount,
    this.traceId,
    this.strictCitation,
    this.references = const [],
  });

  factory AiRegulationAnswer.fromJson(Map<String, dynamic> json) {
    final rawRetrievedCount = json['retrievedCount'];
    return AiRegulationAnswer(
      answer: json['answer']?.toString(),
      model: json['model']?.toString(),
      provider: json['provider']?.toString(),
      retrievedCount: rawRetrievedCount is int
          ? rawRetrievedCount
          : (rawRetrievedCount is num
                ? rawRetrievedCount.toInt()
                : int.tryParse(rawRetrievedCount?.toString() ?? '')),
      traceId: json['traceId']?.toString(),
      strictCitation: json['strictCitation'] as bool?,
      references: (json['references'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                AiRegulationReference.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class AiRegulationStreamChunk {
  final String type;
  final String? text;
  final AiRegulationAnswer? answer;
  final String? message;

  const AiRegulationStreamChunk({
    required this.type,
    this.text,
    this.answer,
    this.message,
  });

  factory AiRegulationStreamChunk.fromSse(String event, String data) {
    final Map<String, dynamic> json = data.trim().isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(
            (const JsonDecoder().convert(data) as Map).cast<String, dynamic>(),
          );

    switch (event) {
      case 'meta':
        return AiRegulationStreamChunk(
          type: event,
          answer: AiRegulationAnswer(
            answer: '',
            model: json['model']?.toString(),
            provider: json['provider']?.toString(),
            retrievedCount: _toInt(json['retrievedCount']),
            traceId: json['traceId']?.toString(),
            strictCitation: json['strictCitation'] as bool?,
            references: const [],
          ),
        );
      case 'token':
        return AiRegulationStreamChunk(type: event, text: json['text']?.toString());
      case 'done':
        return AiRegulationStreamChunk(
          type: event,
          answer: AiRegulationAnswer.fromJson(json),
        );
      case 'error':
        return AiRegulationStreamChunk(
          type: event,
          message: json['message']?.toString(),
        );
      default:
        return AiRegulationStreamChunk(type: event);
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
