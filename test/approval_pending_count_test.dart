import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oa_flutter/core/network/api_response.dart';
import 'package:oa_flutter/features/approval/data/api/approval_api.dart';
import 'package:oa_flutter/features/approval/data/models/approval_models.dart';
import 'package:oa_flutter/features/approval/providers/approval_provider.dart';
import 'package:oa_flutter/features/auth/data/models/auth_models.dart';
import 'package:oa_flutter/features/auth/providers/auth_provider.dart';

class _FakeApprovalApi extends ApprovalApi {
  final PaginatedResponse<ApprovalFlowVo> response;
  int callCount = 0;

  _FakeApprovalApi(this.response) : super(Dio());

  @override
  Future<PaginatedResponse<ApprovalFlowVo>> getMyPending({
    String? filterType,
    String? applicantName,
    int pageNum = 1,
    int pageSize = 10,
    String orderByColumn = 'createTime',
    String isAsc = 'desc',
  }) async {
    callCount++;
    return response;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('myPendingCountProvider：非审批人直接返回 0', () async {
    final api = _FakeApprovalApi(
      const PaginatedResponse<ApprovalFlowVo>(code: 0, total: 9, rows: []),
    );

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(const UserInfo(personnelId: 1)),
        isAdminProvider.overrideWithValue(false),
        approvalApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);

    final count = await container.read(myPendingCountProvider.future);
    expect(count, 0);
    expect(api.callCount, 0);
  });

  test('myPendingCountProvider：审批人返回后端 total', () async {
    final api = _FakeApprovalApi(
      const PaginatedResponse<ApprovalFlowVo>(code: 0, total: 7, rows: []),
    );

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(const UserInfo(personnelId: 1)),
        isAdminProvider.overrideWithValue(true),
        approvalApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);

    final count = await container.read(myPendingCountProvider.future);
    expect(count, 7);
    expect(api.callCount, 1);
  });
}

