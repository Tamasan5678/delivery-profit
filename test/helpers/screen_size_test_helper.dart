import 'package:delivery_profit_v2/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ScreenTestSize {
  const ScreenTestSize(this.name, this.size);

  final String name;
  final Size size;
}

const portraitTestSizes = <ScreenTestSize>[
  ScreenTestSize('360dp', Size(360, 640)),
  ScreenTestSize('411dp', Size(411, 891)),
  ScreenTestSize('480dp', Size(480, 960)),
];

Future<void> pumpAtSize(
  WidgetTester tester, {
  required Widget home,
  required ScreenTestSize screen,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(screen.size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: KeyedSubtree(key: UniqueKey(), child: home),
    ),
  );
  await tester.pumpAndSettle();
  expectNoLayoutErrors(tester, '${screen.name}, textScale=$textScale');
}

void expectNoLayoutErrors(WidgetTester tester, String context) {
  final errors = <Object>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    errors.add(error!);
  }
  expect(
    errors,
    isEmpty,
    reason: '$context produced layout/framework errors:\n${errors.join('\n')}',
  );
  expect(find.byType(ErrorWidget), findsNothing, reason: context);
}

Future<void> ensureReachable(
  WidgetTester tester,
  Finder finder,
  String context,
) async {
  expect(finder, findsAtLeastNWidgets(1), reason: context);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  expectNoLayoutErrors(tester, context);
}
