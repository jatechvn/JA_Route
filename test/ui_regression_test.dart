import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ja_route/main.dart';
import 'package:ja_route/modules/logic.dart';
import 'package:ja_route/modules/ota_update_service.dart';
import 'package:ja_route/modules/ui/main_window.dart';
import 'package:ja_route/modules/ui/theme/theme_provider.dart';
import 'package:ja_route/modules/ui/widgets/glass_widgets.dart';

import 'test_environment.dart';

void main() {
  useIsolatedEnvironment();

  for (final cores in [2, 4, 8]) {
    test('Auto uses detected tier for $cores cores, including reset', () {
      final theme = ThemeProvider(cpuCoresOverride: cores);
      addTearDown(theme.dispose);
      final expected = switch (cores) {
        2 => (HardwareTier.lite, 0.0, 0.75, 8.0, 0.95, 0.0, 0.98),
        4 when !theme.isWin11 => (
          HardwareTier.balanced,
          14.0,
          0.35,
          16.0,
          0.92,
          14.0,
          0.96,
        ),
        _ => (HardwareTier.ultra, 20.0, 0.25, 20.0, 0.85, 20.0, 0.96),
      };
      void verify() {
        expect(theme.effectiveTier, expected.$1);
        expect(
          [
            theme.cardBlur,
            theme.cardOpacity,
            theme.dialogBlur,
            theme.dialogOpacity,
            theme.dropdownBlur,
            theme.dropdownOpacity,
          ],
          [
            expected.$2,
            expected.$3,
            expected.$4,
            expected.$5,
            expected.$6,
            expected.$7,
          ],
        );
      }

      verify();
      theme.setPerfTierMode(PerfTierMode.ultra);
      theme.setPerfTierMode(PerfTierMode.auto);
      verify();
      theme.setLiveGlassmorphism(cardBlur: 33);
      theme.resetToDefaults();
      verify();
    });
  }

  testWidgets('Idle and failed runs never claim active dual routing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final logic = RouteFixerLogic();
    await tester.pumpWidget(MyApp(logic: logic));
    expect(find.text('STANDBY'), findsOneWidget);
    expect(find.text('DUAL ROUTE ACTIVE'), findsNothing);
    expect(
      tester
          .widget<DynamicIslandCapsule>(find.byType(DynamicIslandCapsule))
          .isRunning,
      isFalse,
    );
    logic.isRunning = true;
    logic.notifyListeners();
    await tester.pump();
    expect(find.text('FIXING...'), findsOneWidget);
    logic.isRunning = false;
    logic.steps.first.status = StepStatus.error;
    logic.notifyListeners();
    await tester.pump();
    expect(find.text('STANDBY'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    logic.dispose();
  });

  testWidgets('Theme toggle persists on disk and config changes sync back', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final logic = RouteFixerLogic();
    logic.saveConfig(logic.config.copyWith(themeMode: 'light'));
    await tester.pumpWidget(MyApp(logic: logic));
    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pump();
    expect(logic.config.themeMode, 'dark');
    expect(
      jsonDecode(File('config.json').readAsStringSync())['themeMode'],
      'dark',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    logic.dispose();
    final restarted = RouteFixerLogic();
    await tester.pumpWidget(MyApp(logic: restarted));
    ThemeProvider theme() =>
        tester.element(find.byType(MainWindow)).read<ThemeProvider>();
    expect(theme().themeMode, 'dark');
    restarted.saveConfig(restarted.config.copyWith(themeMode: 'light'));
    await tester.pump();
    expect(theme().themeMode, 'light');
    theme().toggleTheme();
    await tester.pump();
    expect(restarted.config.themeMode, 'dark');
    await tester.pumpWidget(const SizedBox.shrink());
    restarted.dispose();
  });

  test(
    'OTA copies Flutter data, backs it up and preserves user files',
    () async {
      final root = Directory.current.path;
      final source = '$root\\source files';
      final target = '$root\\target files';
      final backup = '$root\\backup files';
      void put(String base, String name, String text) {
        final file = File('$base/$name');
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(text);
      }

      const payload = [
        'ja_route.exe',
        'data/app.so',
        'data/flutter_assets/config.json',
      ];
      const userFiles = [
        'config.json',
        'config.ini',
        'update_config.json',
        'data/search_history.json',
      ];
      for (final name in [...payload, ...userFiles]) {
        put(source, name, 'new content');
        put(target, name, 'old');
      }
      final script = OtaUpdateService.generateApplyUpdateScript(
        oldPid: 12345,
        sourceDir: source,
        targetDir: target,
        exeName: 'ja_route.exe',
      );
      final commands = script
          .split('\n')
          .where((line) => line.startsWith('robocopy '))
          .toList();
      Future<void> runCopy(String command) async {
        // Run only the generated copy commands; never launch the installer or app.
        File('$root/copy_step.bat').writeAsStringSync(
          '@echo off\r\n${command.split(' >').first}\r\nexit /b %errorlevel%\r\n',
        );
        final result = await Process.run(
          'cmd.exe',
          ['/d', '/c', 'copy_step.bat'],
          workingDirectory: root,
          environment: {
            'SRC_DIR': source,
            'DST_DIR': target,
            'BACKUP_DIR': backup,
          },
        );
        expect(
          result.exitCode,
          lessThan(8),
          reason: '${result.stdout}\n${result.stderr}',
        );
      }

      await runCopy(commands[0]);
      await runCopy(commands[1]);
      for (final name in payload) {
        expect(File('$target/$name').readAsStringSync(), 'new content');
        expect(File('$backup/$name').readAsStringSync(), 'old');
      }
      for (final name in userFiles) {
        expect(File('$target/$name').readAsStringSync(), 'old');
        expect(File('$backup/$name').existsSync(), isFalse);
      }
      await runCopy(commands[2]);
      for (final name in [...payload, ...userFiles]) {
        expect(File('$target/$name').readAsStringSync(), 'old');
      }
    },
    skip: !Platform.isWindows,
  );
}
