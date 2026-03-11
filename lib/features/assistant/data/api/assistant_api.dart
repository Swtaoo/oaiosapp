import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/assistant_models.dart';

class AssistantApi {
  final Dio _dio;

  AssistantApi(this._dio);

  Future<ApiResponse<AssistantGeneratedForm>> generateActionForm(
    AssistantFormGenerateRequest request,
  ) async {
    final response = await _dio.post(
      '/oa/ai/assistant/form/generate',
      data: request.toJson(),
      options: Options(receiveTimeout: const Duration(minutes: 3)),
    );

    return ApiResponse.fromJson(
      ensureJsonMap(response.data),
      (Object? json) =>
          AssistantGeneratedForm.fromJson(json as Map<String, dynamic>),
    );
  }
}
