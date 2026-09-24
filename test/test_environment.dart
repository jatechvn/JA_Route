import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_route/modules/logic.dart';
import 'package:ja_route/modules/native_bridge.dart';
import 'package:ja_route/modules/ota_update_service.dart';

void useIsolatedEnvironment() {
  final originalDirectory = Directory.current;
  final originalEngine = nativeBridge.engine;
  setUp(() async {
    Directory.current = Directory.systemTemp.createTempSync('ja_route_test_');
    nativeBridge.engine = null;
    File('config.json').writeAsStringSync(
      jsonEncode(AppConfig.defaultConfig().copyWith(logFilePath: '').toJson()),
    );
    OtaUpdateService().setCustomConfigFileForTesting(
      File('${Directory.current.path}/update_config.json'),
    );
    await OtaUpdateService().saveConfig(
      OtaUpdateConfig.defaults().copyWith(checkInterval: 'off'),
    );
  });
  tearDown(() {
    Directory.current = originalDirectory;
    nativeBridge.engine = originalEngine;
    OtaUpdateService().setCustomConfigFileForTesting(null);
  });
}
