import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oa_flutter/app.dart';

void main() {
  testWidgets('App starts with login page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: App()),
    );
    await tester.pumpAndSettle();

    // 未登录状态下应该显示登录页
    expect(find.text('OA'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
  });
}
