// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_route/main.dart';
import 'package:ja_route/modules/build_info.dart';
import 'package:ja_route/modules/logic.dart';
import 'package:ja_route/modules/utils.dart';
import 'test_environment.dart';

void main() {
  useIsolatedEnvironment();
  test('Route spec parser supports mask and CIDR input', () {
    final cidr = parseRouteSpec('10.10.0.0/16');
    expect(cidr?.destination, '10.10.0.0');
    expect(cidr?.mask, '255.255.0.0');

    final mask = parseRouteSpec('10.20.0.0 255.255.0.0');
    expect(mask?.configValue, '10.20.0.0/255.255.0.0');

    expect(parseRouteSpec('10.20.0.0/33'), isNull);
    expect(parseRouteSpec('999.20.0.0/24'), isNull);
    expect(normalizeRouteSpec('10.0.0.0/8'), '10.0.0.0/255.0.0.0');
  });

  test('AppConfig import falls back to an existing profile safely', () {
    final cfg = AppConfig.fromJson({
      'activeProfile': 'Missing',
      'profiles': {
        'Office': {
          'internetGateway': '192.168.50.1',
          'lanGateway': '172.21.168.1',
          'customLanRoutes': ['10.10.0.0/16'],
        },
      },
    });

    expect(cfg.activeProfile, 'Office');
    expect(cfg.internetGateway, '192.168.50.1');
    expect(cfg.customLanRoutes, ['10.10.0.0/255.255.0.0']);
    expect(cfg.logFilePath, isNotEmpty);
  });

  testWidgets('App structural render test', (WidgetTester tester) async {
    // Set screen size to standard Windows desktop size in test environment
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    // Instantiate logic controller
    final logic = RouteFixerLogic();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(logic: logic));

    // Verify that JA_Route title is shown in the header.
    expect(find.text('JA_Route'), findsWidgets);

    // Clean up
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Debug mode badge render test', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    // Enable CLI debug
    BuildInfo.isCliDebug = true;
    expect(BuildInfo.isDebug, isTrue);

    final logic = RouteFixerLogic();
    await tester.pumpWidget(MyApp(logic: logic));

    // Verify DEBUG badge appears in header
    expect(find.text('DEBUG'), findsWidgets);

    // Reset CLI debug
    BuildInfo.isCliDebug = false;
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Language switcher & detection test', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    final logic = RouteFixerLogic();

    // Verify system language detection
    final sysLang = AppConfig.detectSystemLanguage();
    expect(['vi', 'en', 'zh'].contains(sysLang), isTrue);

    // Switch to English
    logic.setLanguage('en');
    await tester.pumpWidget(MyApp(logic: logic));
    expect(find.text('EN'), findsWidgets);
    expect(find.text('START FIX'), findsWidgets);

    // Switch to Vietnamese
    logic.setLanguage('vi');
    await tester.pumpWidget(MyApp(logic: logic));
    expect(find.text('VI'), findsWidgets);
    expect(find.text('BẮT ĐẦU FIX'), findsWidgets);

    // Clean up
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Language QuickButton 1-click cycle test', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    final logic = RouteFixerLogic();
    logic.setLanguage('vi');
    await tester.pumpWidget(MyApp(logic: logic));

    // Initially VI
    expect(find.text('VI'), findsOneWidget);
    expect(find.text('BẮT ĐẦU FIX'), findsOneWidget);

    // 1-Click quick toggle -> switches to EN
    await tester.tap(find.text('VI'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(logic.config.language, 'en');
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('START FIX'), findsOneWidget);

    // 1-Click quick toggle -> switches to ZH
    await tester.tap(find.text('EN'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(logic.config.language, 'zh');
    expect(find.text('ZH'), findsOneWidget);
    expect(find.text('开始修复'), findsOneWidget);

    // 1-Click quick toggle -> cycles back to VI
    await tester.tap(find.text('ZH'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(logic.config.language, 'vi');
    expect(find.text('VI'), findsOneWidget);
    expect(find.text('BẮT ĐẦU FIX'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
