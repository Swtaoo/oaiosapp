// 规章制度 API - 对应 src/api/regulation.ts

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/regulation_models.dart';

class RegulationApi {
  final Dio _dio;
  final SecureStorageService _storage;

  RegulationApi(this._dio, this._storage);

  /// 获取规章制度列表
  /// GET /oa/companyRegulation/list
  Future<PaginatedResponse<RegulationVo>> getList({
    int? regulationType,
    String? fileName,
    String? isAsc,
    int? pageNum,
    int? pageSize,
  }) async {
    final response = await _dio.get(
      '/oa/companyRegulation/list',
      queryParameters: {
        'regulationType': ?regulationType,
        'fileName': ?fileName,
        'isAsc': ?isAsc,
        'pageNum': ?pageNum,
        'pageSize': ?pageSize,
      },
    );
    return PaginatedResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => RegulationVo.fromJson(json as Map<String, dynamic>),
    );
  }

  /// AI 问制度
  /// POST /oa/ai/regulation/ask
  Future<ApiResponse<AiRegulationAnswer>> askRegulation(
    AiRegulationAskRequest request,
  ) async {
    final response = await _dio.post(
      '/oa/ai/regulation/ask',
      data: request.toJson(),
    );
    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (json) => AiRegulationAnswer.fromJson(json as Map<String, dynamic>),
    );
  }

  /// AI 问制度（流式）
  /// POST /oa/ai/regulation/ask/stream
  Stream<AiRegulationStreamChunk> askRegulationStream(
    AiRegulationAskRequest request,
  ) async* {
    final client = HttpClient();
    client.connectionTimeout = ApiConstants.connectTimeout;
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/oa/ai/regulation/ask/stream');
      final httpRequest = await client.postUrl(uri);
      final token = await _storage.getToken();

      httpRequest.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      httpRequest.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      httpRequest.headers.set('clientid', ApiConstants.clientId);
      if (token != null && token.isNotEmpty) {
        httpRequest.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      httpRequest.add(utf8.encode(jsonEncode(request.toJson())));
      final response = await httpRequest.close();
      if (response.statusCode != HttpStatus.ok) {
        final body = await utf8.decoder.bind(response).join();
        throw Exception(body.isEmpty ? '流式请求失败：${response.statusCode}' : body);
      }

      String? eventName;
      final dataLines = <String>[];
      await for (final line in utf8.decoder.bind(response).transform(const LineSplitter())) {
        if (line.isEmpty) {
          if (dataLines.isNotEmpty) {
            final data = dataLines.join('\n');
            yield AiRegulationStreamChunk.fromSse(eventName ?? 'message', data);
          }
          eventName = null;
          dataLines.clear();
          continue;
        }
        if (line.startsWith('event:')) {
          eventName = line.substring(6).trim();
          continue;
        }
        if (line.startsWith('data:')) {
          dataLines.add(line.substring(5).trim());
        }
      }
    } finally {
      client.close(force: true);
    }
  }
}
