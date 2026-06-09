import 'package:flutter_test/flutter_test.dart';

import 'package:rebudget/main.dart';

void main() {
  testWidgets('Rebudget app shows bottom navigation items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RebudgetApp());

    expect(find.text('首页'), findsWidgets);
    expect(find.text('账单'), findsWidgets);
    expect(find.text('预算'), findsWidgets);
    expect(find.text('统计'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
  });
}
