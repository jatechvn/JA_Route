import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'constants.dart';

/// Quản lý phân tích và so sánh số phiên bản SemVer (Semantic Versioning)
class SemanticVersion implements Comparable<SemanticVersion> {
  final int major;
  final int minor;
  final int patch;
  final int? build;
  final String raw;
  final String? prerelease;

  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.build,
    required this.raw,
    this.prerelease,
  });

  /// Phân tích cú pháp chuỗi phiên bản dạng: '1.1.0', 'v1.1.0', '1.1.0+2', '1.2.0-beta'
  static SemanticVersion? tryParse(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final clean = input.trim().toLowerCase().replaceAll(RegExp(r'^[vV]'), '');
    if (!RegExp(
      r'^\d+\.\d+(?:\.\d+)?(?:-[0-9a-z.-]+)?(?:\+\d+)?$',
    ).hasMatch(clean)) {
      return null;
    }
    final pre = RegExp(r'-([^+]+)').firstMatch(clean)?.group(1);

    // Bóc tách build number nếu có dấu +
    int? buildNum;
    String versionCore = clean;
    if (clean.contains('+')) {
      final parts = clean.split('+');
      versionCore = parts[0];
      buildNum = int.tryParse(parts[1]);
    }

    // Bỏ hậu tố tiền phát hành (như -beta, -rc1)
    if (versionCore.contains('-')) {
      versionCore = versionCore.split('-')[0];
    }

    final segments = versionCore.split('.');
    if (segments.isEmpty) return null;

    final major = int.tryParse(segments[0]);
    if (major == null) return null;
    final minor = segments.length > 1 ? int.tryParse(segments[1]) : 0;
    if (minor == null) return null;
    final patch = segments.length > 2 ? int.tryParse(segments[2]) : 0;
    if (patch == null) return null;

    return SemanticVersion(
      major: major,
      minor: minor,
      patch: patch,
      build: buildNum,
      raw: input.trim(),
      prerelease: pre,
    );
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    if (prerelease != other.prerelease) {
      if (prerelease == null) return 1;
      if (other.prerelease == null) return -1;
      final a = prerelease!.split('.');
      final b = other.prerelease!.split('.');
      for (var i = 0; i < a.length && i < b.length; i++) {
        final x = int.tryParse(a[i]);
        final y = int.tryParse(b[i]);
        final comparison = x != null && y != null
            ? x.compareTo(y)
            : x != null
            ? -1
            : y != null
            ? 1
            : a[i].compareTo(b[i]);
        if (comparison != 0) return comparison;
      }
      if (a.length != b.length) return a.length.compareTo(b.length);
    }
    final b1 = build ?? 0;
    final b2 = other.build ?? 0;
    return b1.compareTo(b2);
  }

  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator <(SemanticVersion other) => compareTo(other) < 0;
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SemanticVersion && compareTo(other) == 0;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch, build ?? 0, prerelease);

  @override
  String toString() {
    final base =
        '$major.$minor.$patch${prerelease == null ? '' : '-$prerelease'}';
    return build != null && build! > 0 ? '$base+$build' : base;
  }

  String get displayVersion => 'v$this';
}

/// Thông tin gói cập nhật phát hiện trên máy chủ
class UpdatePackageInfo {
  final SemanticVersion version;
  final String fileName;
  final String fullPath;
  final int fileSize;
  final String sha256;
  final String? releaseNotes;
  final DateTime? releaseDate;

  const UpdatePackageInfo({
    required this.version,
    required this.fileName,
    required this.fullPath,
    required this.fileSize,
    required this.sha256,
    this.releaseNotes,
    this.releaseDate,
  });

  String get formattedSize {
    if (fileSize <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = fileSize.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(i == 0 ? 0 : 2)} ${suffixes[i]}';
  }
}

/// Kết quả kiểm tra phiên bản mới
class UpdateCheckResult {
  final bool hasUpdate;
  final UpdatePackageInfo? packageInfo;
  final String currentVersion;
  final String? errorMessage;
  final bool isConnectionSuccess;

  const UpdateCheckResult({
    required this.hasUpdate,
    this.packageInfo,
    required this.currentVersion,
    this.errorMessage,
    this.isConnectionSuccess = true,
  });
}

/// Cấu hình cập nhật OTA lưu trong file JSON độc lập (update_config.json)
class OtaUpdateConfig {
  final String serverPath;
  final String username;
  final String checkInterval; // 'daily', 'weekly', 'monthly', 'off'
  final bool autoDownload;
  final DateTime? lastCheckTime;

  const OtaUpdateConfig({
    required this.serverPath,
    required this.username,
    this.checkInterval = 'daily',
    this.autoDownload = false,
    this.lastCheckTime,
  });

  factory OtaUpdateConfig.defaults() => const OtaUpdateConfig(
    serverPath: r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_Route',
    username: '',
    checkInterval: 'daily',
    autoDownload: false,
  );

  factory OtaUpdateConfig.fromJson(Map<String, dynamic> json) {
    DateTime? lastCheck;
    if (json['lastCheckTime'] != null) {
      try {
        lastCheck = DateTime.parse(json['lastCheckTime'] as String);
      } catch (_) {}
    }
    return OtaUpdateConfig(
      serverPath:
          json['serverPath'] as String? ??
          r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_Route',
      username: json['username'] as String? ?? '',
      checkInterval: json['checkInterval'] as String? ?? 'daily',
      autoDownload: json['autoDownload'] as bool? ?? false,
      lastCheckTime: lastCheck,
    );
  }

  Map<String, dynamic> toJson() => {
    'serverPath': serverPath,
    'username': username,
    'checkInterval': checkInterval,
    'autoDownload': autoDownload,
    if (lastCheckTime != null)
      'lastCheckTime': lastCheckTime!.toIso8601String(),
  };

  OtaUpdateConfig copyWith({
    String? serverPath,
    String? username,
    String? checkInterval,
    bool? autoDownload,
    DateTime? lastCheckTime,
  }) {
    return OtaUpdateConfig(
      serverPath: serverPath ?? this.serverPath,
      username: username ?? this.username,
      checkInterval: checkInterval ?? this.checkInterval,
      autoDownload: autoDownload ?? this.autoDownload,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
    );
  }
}

/// Dịch vụ quản lý kiểm tra và thực hiện cập nhật OTA qua mạng nội bộ LAN
class OtaUpdateService {
  static final _packageNamePattern = RegExp(
    r'^ja_route_[a-z0-9][a-z0-9_.+-]*\.zip$',
    caseSensitive: false,
  );
  static final _sha256Pattern = RegExp(r'^[a-f0-9]{64}$');

  static bool isValidPackageName(String name) =>
      _packageNamePattern.hasMatch(name) &&
      !name.contains('..') &&
      !name.contains(RegExp(r'[\\/]'));

  static bool isValidSha256(String? value) =>
      value != null && _sha256Pattern.hasMatch(value.trim().toLowerCase());

  /// Tính SHA-256 theo luồng để không nạp cả gói cập nhật vào bộ nhớ.
  static Future<String> calculateSha256(File file) async =>
      (await sha256.bind(file.openRead()).first).toString();

  static String _psLiteral(String value) => "'${value.replaceAll("'", "''")}'";

  static Future<ProcessResult> _runPowerShell(String script) {
    final encoded = base64Encode(
      script.codeUnits.expand((c) => [c & 255, c >> 8]).toList(),
    );
    return Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-EncodedCommand',
      encoded,
    ]);
  }

  bool _applying = false;
  static final OtaUpdateService _instance = OtaUpdateService._internal();
  factory OtaUpdateService() => _instance;
  OtaUpdateService._internal();

  File? _customConfigFileForTesting;
  Directory? _customServerDirForTesting;
  OtaUpdateConfig? _cachedConfig;

  @visibleForTesting
  void setCustomConfigFileForTesting(File? file) {
    _customConfigFileForTesting = file;
    _cachedConfig = null;
  }

  @visibleForTesting
  void setCustomServerDirForTesting(Directory? dir) {
    _customServerDirForTesting = dir;
  }

  File getConfigFile() {
    if (_customConfigFileForTesting != null) {
      return _customConfigFileForTesting!;
    }

    try {
      final exeDir = File(Platform.resolvedExecutable).parent;
      final exeConfig = File(
        '${exeDir.path}${Platform.pathSeparator}update_config.json',
      );
      if (exeConfig.existsSync()) {
        return exeConfig;
      }
    } catch (_) {}

    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      final dir = Directory('$appData\\JA_Route');
      if (!dir.existsSync()) {
        try {
          dir.createSync(recursive: true);
        } catch (_) {}
      }
      return File('${dir.path}\\update_config.json');
    }
    return File('update_config.json');
  }

  Future<OtaUpdateConfig> getConfig() => loadConfig();

  Future<OtaUpdateConfig> loadConfig() async {
    if (_cachedConfig != null) return _cachedConfig!;
    try {
      final file = getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final json = jsonDecode(content) as Map<String, dynamic>;
          _cachedConfig = OtaUpdateConfig.fromJson(json);
          return _cachedConfig!;
        }
      }
    } catch (e) {
      debugPrint('[OtaUpdateService] Load config error: $e');
    }
    _cachedConfig = OtaUpdateConfig.defaults();
    return _cachedConfig!;
  }

  Future<void> saveConfig(OtaUpdateConfig config) async {
    await _writeConfig(getConfigFile(), config);
    _cachedConfig = config;
  }

  Future<void> _writeConfig(File file, OtaUpdateConfig config) async {
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(config.toJson()), flush: true);
  }

  Future<void> saveSmbCredential({
    required String serverPath,
    required String username,
    required String password,
  }) async {
    if (!Platform.isWindows) {
      throw UnsupportedError('Windows Credential Manager requires Windows');
    }
    final target = extractSmbServerName(serverPath);
    if (target == null) {
      throw ArgumentError('SMB server path must be a valid UNC path');
    }
    if (username.trim().isEmpty || password.isEmpty) {
      throw ArgumentError(
        'Username and password are required to save credential',
      );
    }

    final process = await Process.start('cmdkey.exe', [
      '/add:$target',
      '/user:${username.trim()}',
    ]);
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    process.stdin.writeln(password);
    await process.stdin.close();
    final exitCode = await process.exitCode;
    final output = '${await stdoutFuture} ${await stderrFuture}'.trim();
    if (exitCode != 0) {
      throw StateError(
        'Cannot save SMB credential in Windows Credential Manager: $output',
      );
    }
  }

  bool shouldCheckForUpdates({
    required String interval,
    DateTime? lastCheckTime,
    DateTime? now,
  }) {
    if (interval == 'off') return false;
    if (lastCheckTime == null) return true;

    final currentTime = now ?? DateTime.now();
    final elapsed = currentTime.difference(lastCheckTime);

    switch (interval) {
      case 'daily':
        return elapsed.inHours >= 24;
      case 'weekly':
        return elapsed.inDays >= 7;
      case 'monthly':
        return elapsed.inDays >= 30;
      default:
        return elapsed.inHours >= 24;
    }
  }

  static String? extractSmbShareRoot(String uncPath) {
    final normalized = uncPath.replaceAll('/', '\\');
    if (!normalized.startsWith(r'\\')) return null;

    final parts = normalized.substring(2).split('\\');
    if (parts.length < 2) return null;
    return '\\\\${parts[0]}\\${parts[1]}';
  }

  static String? extractSmbServerName(String uncPath) {
    final normalized = uncPath.replaceAll('/', '\\');
    if (!normalized.startsWith(r'\\')) return null;
    final parts = normalized.substring(2).split('\\');
    return parts.isEmpty || parts.first.trim().isEmpty ? null : parts.first;
  }

  Future<bool> connectSmbShare({String? path}) async {
    if (_customServerDirForTesting != null) {
      return await _customServerDirForTesting!.exists();
    }

    final config = await loadConfig();
    final targetPath = path ?? config.serverPath;

    final normalized = targetPath.replaceAll('/', '\\');
    if (!normalized.startsWith(r'\\')) {
      return await Directory(targetPath).exists();
    }

    try {
      if (await Directory(targetPath).exists()) {
        return true;
      }
    } catch (_) {}

    final shareRoot = extractSmbShareRoot(targetPath);
    if (shareRoot != null && Platform.isWindows) {
      try {
        final result = await Process.run('net', [
          'use',
          shareRoot,
          '/persistent:no',
        ]);
        if (result.exitCode == 0) {
          return await Directory(targetPath).exists();
        }
      } catch (e) {
        debugPrint('[OtaUpdateService] net use error: $e');
      }
    }

    return await Directory(targetPath).exists();
  }

  Future<UpdateCheckResult> checkForUpdates({
    String? overrideServerPath,
    String? overrideCurrentVersion,
    bool isManual = false,
  }) async {
    final config = await loadConfig();
    final serverPath = overrideServerPath ?? config.serverPath;
    final currentVerStr = overrideCurrentVersion ?? appVersion;
    final currentSemVer =
        SemanticVersion.tryParse(currentVerStr) ??
        const SemanticVersion(major: 1, minor: 0, patch: 0, raw: '1.0.0');

    final connected = await connectSmbShare(path: serverPath);
    if (!connected) {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVerStr,
        isConnectionSuccess: false,
        errorMessage:
            'Không thể kết nối hoặc truy cập thư mục máy chủ: $serverPath',
      );
    }

    try {
      await saveConfig(config.copyWith(lastCheckTime: DateTime.now()));
    } catch (error) {
      debugPrint('[OtaUpdateService] Save last-check time error: $error');
    }

    final Directory dir = _customServerDirForTesting ?? Directory(serverPath);
    if (!await dir.exists()) {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVerStr,
        isConnectionSuccess: false,
        errorMessage: 'Thư mục cập nhật không tồn tại: $serverPath',
      );
    }

    final versionJsonFile = File(
      '${dir.path}${Platform.pathSeparator}version.json',
    );
    if (!await versionJsonFile.exists()) {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVerStr,
        errorMessage: 'Thiếu version.json có SHA-256 bắt buộc',
      );
    }

    try {
      final json = jsonDecode(await versionJsonFile.readAsString());
      if (json is! Map<String, dynamic>) {
        throw const FormatException('version.json must be an object');
      }
      final targetVerStr = json['version'] as String?;
      final fileName = json['fileName'] as String?;
      final expectedSha256 = json['sha256'] as String?;
      final notes = json['releaseNotes'] as String?;
      final targetSemVer = SemanticVersion.tryParse(targetVerStr);

      if (targetSemVer == null ||
          fileName == null ||
          !isValidPackageName(fileName) ||
          !isValidSha256(expectedSha256)) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVerStr,
          errorMessage: 'version.json không hợp lệ hoặc thiếu SHA-256',
        );
      }

      final pkgFile = File('${dir.path}${Platform.pathSeparator}$fileName');
      if (!await pkgFile.exists() || await pkgFile.length() <= 0) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVerStr,
          errorMessage:
              'Gói cập nhật trong version.json không tồn tại hoặc rỗng',
        );
      }

      return UpdateCheckResult(
        hasUpdate: targetSemVer > currentSemVer,
        currentVersion: currentVerStr,
        packageInfo: UpdatePackageInfo(
          version: targetSemVer,
          fileName: fileName,
          fullPath: pkgFile.path,
          fileSize: await pkgFile.length(),
          sha256: expectedSha256!.trim().toLowerCase(),
          releaseNotes: notes,
        ),
      );
    } catch (e) {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVerStr,
        isConnectionSuccess: false,
        errorMessage: 'Lỗi khi đọc version.json: $e',
      );
    }
  }

  Future<void> performUpdate(
    UpdatePackageInfo packageInfo, {
    void Function(double progress, String status)? onProgress,
  }) async {
    if (!Platform.isWindows) throw UnsupportedError('OTA requires Windows');
    if (_applying) throw StateError('An update is already running');
    _applying = true;
    try {
      await _performUpdate(packageInfo, onProgress: onProgress);
    } finally {
      _applying = false;
    }
  }

  Future<Directory> _performUpdate(
    UpdatePackageInfo packageInfo, {
    void Function(double progress, String status)? onProgress,
    bool prepareOnly = false,
  }) async {
    if (!isValidPackageName(packageInfo.fileName) ||
        !isValidSha256(packageInfo.sha256)) {
      throw StateError('Invalid update package manifest');
    }
    onProgress?.call(0.05, 'Khởi tạo thư mục tạm...');

    final tempBase = await Directory.systemTemp.createTemp('JA_Route_Update_');
    final localZipFile = File('${tempBase.path}/update.zip');
    final sourceZip = File(packageInfo.fullPath);
    final totalBytes = await sourceZip.length();
    if (totalBytes == 0 ||
        (packageInfo.fileSize > 0 && totalBytes != packageInfo.fileSize)) {
      throw StateError('Update package size changed; check for updates again');
    }
    final writer = localZipFile.openWrite();
    var copied = 0;
    try {
      await for (final chunk in sourceZip.openRead()) {
        writer.add(chunk);
        copied += chunk.length;
        onProgress?.call(
          (0.1 + copied / totalBytes * 0.5).clamp(0.1, 0.6),
          'Đang tải bản cập nhật...',
        );
      }
      await writer.flush();
    } finally {
      await writer.close();
    }
    if (copied != totalBytes) throw StateError('Incomplete update package');
    final actualSha256 = await calculateSha256(localZipFile);
    if (actualSha256.toLowerCase() != packageInfo.sha256.toLowerCase()) {
      throw StateError('Update package SHA-256 does not match version.json');
    }

    onProgress?.call(0.65, 'Đang giải nén gói cập nhật...');
    final extractDir = Directory('${tempBase.path}\\extracted');
    extractDir.createSync(recursive: true);

    final validation = await _runPowerShell("""
\$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
\$zip = [IO.Compression.ZipFile]::OpenRead(${_psLiteral(localZipFile.path)})
try {
  foreach (\$entry in \$zip.Entries) {
    \$parts = \$entry.FullName.Replace('\\', '/').Split('/')
    if (\$entry.FullName -match '^[\\/]' -or \$entry.FullName.Contains(':') -or \$parts -contains '..' -or ((\$entry.ExternalAttributes -shr 16) -band 61440) -eq 40960) { throw 'Unsafe archive entry' }
  }
  [IO.Compression.ZipFileExtensions]::ExtractToDirectory(\$zip, ${_psLiteral(extractDir.path)})
} finally { \$zip.Dispose() }
""");
    if (validation.exitCode != 0) {
      throw StateError('Invalid or unsafe update archive');
    }

    onProgress?.call(0.85, 'Đang chuẩn bị bàn giao cập nhật...');
    Directory payloadDir = extractDir;

    final subDirs = extractDir.listSync().whereType<Directory>().toList();
    if (subDirs.length == 1) {
      final testExe = File('${subDirs.first.path}\\ja_route.exe');
      if (testExe.existsSync()) {
        payloadDir = subDirs.first;
      }
    }

    for (final name in ['ja_route.exe', 'flutter_windows.dll', 'data']) {
      if (!await FileSystemEntity.isFile('${payloadDir.path}/$name') &&
          !await FileSystemEntity.isDirectory('${payloadDir.path}/$name')) {
        throw StateError('Incomplete Flutter update package: $name');
      }
    }

    if (prepareOnly) return payloadDir;

    final currentExe = File(Platform.resolvedExecutable);
    final targetAppDir = currentExe.parent;
    final currentPid = pid;

    final batFile = File('${tempBase.path}\\apply_update.bat');
    final batContent = generateApplyUpdateScript(
      oldPid: currentPid,
      sourceDir: payloadDir.path,
      targetDir: targetAppDir.path,
      exeName: currentExe.path.split(Platform.pathSeparator).last,
    );
    batFile.writeAsStringSync(batContent);

    onProgress?.call(1.0, 'Sẵn sàng áp dụng cập nhật! Khởi động lại ngay...');
    await Future.delayed(const Duration(milliseconds: 600));

    if (Platform.isWindows) {
      final launch = await _runPowerShell(
        "Start-Process -FilePath 'cmd.exe' -ArgumentList ${_psLiteral('/c ""${batFile.path}""')} -WindowStyle Hidden",
      );
      if (launch.exitCode != 0) {
        throw StateError('Cannot start update installer');
      }
      exit(0);
    }
    return payloadDir;
  }

  static String generateApplyUpdateScript({
    required int oldPid,
    required String sourceDir,
    required String targetDir,
    required String exeName,
  }) {
    for (final value in [sourceDir, targetDir, exeName]) {
      if (value.contains(RegExp(r'["%\r\n]'))) {
        throw ArgumentError('Unsupported updater path');
      }
    }
    if (oldPid <= 0 || exeName.contains(RegExp(r'[\\/]'))) {
      throw ArgumentError('Invalid updater target');
    }
    return '''@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
title JA_Route - Dang Cap Nhat Phien Ban Moi...

set "OLD_PID=$oldPid"
set "SRC_DIR=$sourceDir"
set "DST_DIR=$targetDir"
set "EXE_NAME=$exeName"
set "BACKUP_DIR=%~dp0backup"
if not exist "%SRC_DIR%\\%EXE_NAME%" exit /b 10
if not exist "%DST_DIR%\\%EXE_NAME%" exit /b 11
set /a WAIT_COUNT=0

echo ========================================================
echo   JA_ROUTE - DANG TIEN HANH CAP NHAT
echo ========================================================
echo.
echo [1/3] Dang cho tien trinh cu (PID %OLD_PID%) dong han...

:wait_loop
set /a WAIT_COUNT+=1
if %WAIT_COUNT% GEQ 60 exit /b 12
timeout /t 1 /nobreak >nul
tasklist /fi "PID eq %OLD_PID%" 2>nul | findstr /i "%OLD_PID%" >nul
if not errorlevel 1 goto wait_loop

timeout /t 1 /nobreak >nul

echo [2/3] Dang ghi de tep ung dung moi...
robocopy "%DST_DIR%" "%BACKUP_DIR%" /E /NP /R:2 /W:1 /XD logs backups /XF "%DST_DIR%\\update_config.json" "%DST_DIR%\\config.json" "%DST_DIR%\\config.ini" "%DST_DIR%\\data\\search_history.json" >"%~dp0backup.log"
if errorlevel 8 exit /b 13
robocopy "%SRC_DIR%" "%DST_DIR%" /E /IS /IT /NP /R:5 /W:2 /XD logs backups /XF "%SRC_DIR%\\update_config.json" "%SRC_DIR%\\config.json" "%SRC_DIR%\\config.ini" "%SRC_DIR%\\data\\search_history.json" >"%~dp0apply.log"
if errorlevel 8 goto rollback

echo [3/3] Khoi chay ung dung moi...
start "" "%DST_DIR%\\%EXE_NAME%"

timeout /t 2 /nobreak >nul
exit /b 0

:rollback
robocopy "%BACKUP_DIR%" "%DST_DIR%" /E /IS /IT /NP /R:2 /W:1 >"%~dp0rollback.log"
if errorlevel 8 exit /b 14
start "" "%DST_DIR%\\%EXE_NAME%"
exit /b 15
''';
  }
}
