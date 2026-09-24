import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Repository managing persistent search history queries per category (e.g. 'routes', 'logs').
class SearchHistoryRepository {
  static final SearchHistoryRepository _instance =
      SearchHistoryRepository._internal();
  factory SearchHistoryRepository() => _instance;
  SearchHistoryRepository._internal();

  File? _customStorageFile;
  final Map<String, List<String>> _cache = {};
  bool _isLoaded = false;
  Future<void>? _loading;
  Future<void> _pendingSave = Future.value();
  static const int maxHistoryPerCategory = 10;

  void setStorageFileForTesting(File? file) {
    _customStorageFile = file;
    _isLoaded = false;
    _loading = null;
    _cache.clear();
  }

  File _getStorageFile() {
    if (_customStorageFile != null) return _customStorageFile!;
    final dataDir = Directory(p.join(Directory.current.path, 'data'));
    if (!dataDir.existsSync()) {
      try {
        dataDir.createSync(recursive: true);
      } catch (_) {}
    }
    return File(p.join(dataDir.path, 'search_history.json'));
  }

  Future<void> _load() {
    if (_isLoaded) return Future.value();
    return _loading ??= _loadOnce();
  }

  Future<void> _loadOnce() async {
    try {
      final file = _getStorageFile();
      if (await file.exists()) {
        final raw = await file.readAsString();
        if (raw.trim().isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            _cache.clear();
            for (final entry in decoded.entries) {
              if (entry.value is List) {
                _cache[entry.key] = (entry.value as List)
                    .map((e) => e.toString())
                    .where((s) => s.trim().isNotEmpty)
                    .toList();
              }
            }
          }
        }
      }
    } catch (_) {}

    _seedInitialData();
    _isLoaded = true;
  }

  void _seedInitialData() {
    if (!_cache.containsKey('routes')) {
      _cache['routes'] = ['10.0.0.0', '192.168.100.1', '172.21.168.1'];
    }
    if (!_cache.containsKey('logs')) {
      _cache['logs'] = ['ROUTE_ADD', 'PING', 'GATEWAY', 'DNS'];
    }
  }

  Future<void> _save() {
    final file = _getStorageFile();
    final snapshot = jsonEncode(_cache);
    return _pendingSave = _pendingSave.then((_) async {
      try {
        await file.writeAsString(snapshot);
      } catch (_) {}
    });
  }

  Future<List<String>> getHistory(String category) async {
    await _load();
    return List.unmodifiable(_cache[category] ?? []);
  }

  Future<void> addQuery(String category, String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    await _load();
    final list = _cache.putIfAbsent(category, () => []);
    list.remove(clean);
    list.insert(0, clean);
    if (list.length > maxHistoryPerCategory) {
      list.removeRange(maxHistoryPerCategory, list.length);
    }
    await _save();
  }

  Future<void> removeQuery(String category, String query) async {
    await _load();
    final list = _cache[category];
    if (list != null) {
      list.remove(query.trim());
      await _save();
    }
  }

  Future<void> clearHistory(String category) async {
    await _load();
    _cache[category]?.clear();
    await _save();
  }
}
