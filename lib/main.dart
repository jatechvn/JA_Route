// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'modules/build_info.dart';
import 'modules/constants.dart';
import 'modules/logger_config.dart';
import 'modules/logic.dart';
import 'modules/ui/main_window.dart';
import 'modules/ui/theme/language_provider.dart';
import 'modules/ui/theme/theme_provider.dart';
import 'modules/window_helper.dart';

const _themeChannel = MethodChannel('ja_route/theme');

Future<void> _updateNativeTitleBar(bool isDark) async {
  try {
    await _themeChannel.invokeMethod('updateTheme', {'isDark': isDark});
  } catch (_) {
    // Silently ignore if not supported or in test environment
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Explorer launches have no console. Keep diagnostics free of config values
  // and exception messages, which can contain credentials or network data.
  void recordStartup(String stage, [Object? error, StackTrace? stack]) {
    try {
      final directory = File(Platform.resolvedExecutable).parent;
      File('${directory.path}/startup_diagnostics.log').writeAsStringSync(
        '${DateTime.now().toIso8601String()} $stage'
        '${error == null ? '' : ' (${error.runtimeType})'}\n'
        '${stack ?? ''}\n',
        mode: FileMode.append,
      );
    } catch (_) {
      // Diagnostics must never prevent startup.
    }
  }

  FlutterError.onError = (details) {
    recordStartup('Flutter framework error', details.exception, details.stack);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    recordStartup('Unhandled asynchronous error', error, stack);
    return false;
  };
  recordStartup('Dart entrypoint');

  // Parse CLI debug flags (-debug, --debug, -d)
  if (args.contains('-debug') ||
      args.contains('--debug') ||
      args.contains('-d')) {
    BuildInfo.isCliDebug = true;
  }

  // Create logic controller (loads config from disk)
  final logic = RouteFixerLogic();
  recordStartup('Logic initialized');

  // Initialize central logging configuration with path from config
  LoggerConfig.initialize(logic.config.logFilePath);

  // Initialize Desktop Glass Window with min constraints
  await initGlassWindow(
    title: '$appName v$appVersion',
    size: const Size(1280, 800),
    minSize: const Size(760, 520),
  );
  recordStartup('Window initialized');

  runApp(MyApp(logic: logic));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    recordStartup('First Flutter frame completed');
  });
}

class MyApp extends StatelessWidget {
  final RouteFixerLogic logic;

  const MyApp({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: logic),
        ChangeNotifierProxyProvider<RouteFixerLogic, ThemeProvider>(
          create: (_) => ThemeProvider(
            initialMode: logic.config.themeMode,
            onThemeModeChanged: (mode) =>
                logic.saveConfig(logic.config.copyWith(themeMode: mode)),
          ),
          update: (_, controller, theme) {
            theme!.syncWithConfig(controller.config.themeMode);
            return theme;
          },
        ),
        ChangeNotifierProxyProvider<RouteFixerLogic, LanguageProvider>(
          create: (_) => LanguageProvider(initialCode: logic.config.language),
          update: (_, logicInstance, langProvider) {
            final provider =
                langProvider ??
                LanguageProvider(initialCode: logicInstance.config.language);
            provider.syncWithConfig(logicInstance.config.language);
            return provider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          final isDark = theme.isDark;

          // Sync native title bar with resolved theme
          _updateNativeTitleBar(isDark);

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: '$appName v$appVersion',
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: theme.colors.bgPrimary,
              fontFamily: 'Segoe UI',
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: theme.colors.bgPrimary,
              fontFamily: 'Segoe UI',
              useMaterial3: true,
            ),
            themeMode: theme.themeMode == 'system'
                ? ThemeMode.system
                : (theme.themeMode == 'light'
                      ? ThemeMode.light
                      : ThemeMode.dark),
            home: MainWindow(logic: logic),
          );
        },
      ),
    );
  }
}
