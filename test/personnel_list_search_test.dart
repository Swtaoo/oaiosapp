import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oa_flutter/core/network/api_response.dart';
import 'package:oa_flutter/features/home/presentation/pages/personnel_list_page.dart';
import 'package:oa_flutter/features/register/data/api/register_api.dart';
import 'package:oa_flutter/features/register/data/models/register_models.dart';
import 'package:oa_flutter/features/register/providers/register_provider.dart';

class _FakeRegisterApi extends RegisterApi {
  final List<PersonnelBasicInfoVo> list;

  _FakeRegisterApi(this.list) : super(Dio());

  @override
  Future<PaginatedResponse<PersonnelBasicInfoVo>> getPersonnelList({
    int? personnelId,
  }) async {
    return PaginatedResponse<PersonnelBasicInfoVo>(
      code: 0,
      total: list.length,
      rows: list,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('人员列表：搜索框可过滤/清空', (tester) async {
    final api = _FakeRegisterApi(const [
      PersonnelBasicInfoVo(
        id: 1,
        name: '张三',
        phone: '13800000000',
        department: '研发',
        actualPosition: '工程师',
      ),
      PersonnelBasicInfoVo(
        id: 2,
        name: '李四',
        phone: '13900000000',
        department: '人事',
        actualPosition: 'HR',
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          registerApiProvider.overrideWithValue(api),
        ],
        child: const MaterialApp(home: PersonnelListPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 初始：两条都显示
    expect(find.text('张三'), findsOneWidget);
    expect(find.text('李四'), findsOneWidget);

    // 搜索：按姓名过滤
    await tester.enterText(find.byType(TextField), '张');
    await tester.pumpAndSettle();
    expect(find.text('张三'), findsOneWidget);
    expect(find.text('李四'), findsNothing);

    // 搜索：无结果提示
    await tester.enterText(find.byType(TextField), '不存在');
    await tester.pumpAndSettle();
    expect(find.text('未找到相关人员'), findsOneWidget);

    // 清空：恢复显示
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('张三'), findsOneWidget);
    expect(find.text('李四'), findsOneWidget);
  });
}

