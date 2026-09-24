// lib/modules/logger_config.dart
import 'dart:io';
import 'package:logging/logging.dart';

final List<String> logMessages = [];
final List<Function(String)> logListeners = [];

void addLogListener(Function(String) listener) {
  logListeners.add(listener);
}

void removeLogListener(Function(String) listener) {
  logListeners.remove(listener);
}

void logToSystem(String message) {
  final formatted =
      '${DateTime.now().toLocal().toString().split('.').first} - $message';
  logMessages.add(formatted);
  if (logMessages.length > 2000) {
    logMessages.removeAt(0);
  }
  for (final listener in logListeners) {
    try {
      listener(formatted);
    } catch (_) {}
  }
}

class LoggerConfig {
  static File? _logFile;

  static void initialize(String logFilePath) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final msg = '[${record.level.name}] ${record.message}';

      // Print to stdout/stderr
      stdout.writeln('${record.time}: $msg');

      // Add to UI log system
      logToSystem(msg);

      // Write to file
      try {
        if (_logFile != null) {
          _logFile!.writeAsStringSync(
            '${record.time} - $msg\n',
            mode: FileMode.append,
          );
        }
      } catch (e) {
        stderr.writeln('Error writing to file log: $e');
      }
    });

    updateLogFile(logFilePath);
  }

  static void updateLogFile(String logFilePath) {
    try {
      if (logFilePath.isEmpty) {
        _logFile = null;
        return;
      }
      final file = File(logFilePath);
      final parentDir = file.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }
      _logFile = file;
    } catch (e) {
      stderr.writeln('Failed to set up log file $logFilePath: $e');
      if (logFilePath.startsWith('D:\\') || logFilePath.startsWith('d:\\')) {
        final fallbackPath =
            '${Directory.current.path}\\logs\\fix_dual_network_full_v6_dhcp_proof.log';
        stdout.writeln('Attempting fallback log path: $fallbackPath');
        try {
          final fallbackFile = File(fallbackPath);
          final fallbackParent = fallbackFile.parent;
          if (!fallbackParent.existsSync()) {
            fallbackParent.createSync(recursive: true);
          }
          _logFile = fallbackFile;
        } catch (ex) {
          stderr.writeln('Fallback log path also failed: $ex');
          _logFile = null;
        }
      } else {
        _logFile = null;
      }
    }
  }
}
