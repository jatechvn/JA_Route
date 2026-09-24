---
name: backend-patterns
description: Backend patterns for this ecosystem's Rust native core (FFI service layer) and Python backend services — API/IPC design, caching, error handling, and structured logging. Use when designing or reviewing the non-UI layer of a Dart/Flutter app.
---

# Native Core & Backend Service Patterns

Backend-equivalent architecture patterns for this ecosystem, where "backend" means one of two things depending on the project: a **Rust native core** reached via FFI (see `rust-native-core`), or a **Python backend service** some apps run locally/embedded (PySide6 apps, or a Dart UI talking to a local Python process). Pick the section that matches the project.

## Part A — Rust Native Core (via FFI)

### Repository Pattern for the Native Bridge

```dart
// Abstract the FFI calls behind a Dart interface — callers never touch
// DynamicLibrary/Pointer directly (see flutter-app-blueprint's native_bridge.dart).
abstract class ComputeRepository {
  Future<List<double>> processAudio(List<double> samples);
}

class NativeComputeRepository implements ComputeRepository {
  NativeComputeRepository(this._bridge);
  final NativeBridge _bridge;

  @override
  Future<List<double>> processAudio(List<double> samples) async {
    // flutter_rust_bridge-generated call — see rust-native-core
    return _bridge.processAudioSamples(samples: samples);
  }
}
```

### Service Layer Separating Business Logic from the Bridge

```dart
// logic.dart — orchestrates, doesn't know about FFI details
class AudioService {
  AudioService(this._repo);
  final ComputeRepository _repo;

  Future<AudioResult> analyze(List<double> samples) async {
    if (samples.isEmpty) throw ArgumentError('samples must not be empty');
    final processed = await _repo.processAudio(samples);
    return AudioResult.fromProcessed(processed);
  }
}
```

### Rust-side: Never Panic Across the FFI Boundary

```rust
// ❌ BAD: a panic! crossing the FFI boundary is undefined behavior on the Dart side
#[no_mangle]
pub extern "C" fn process(ptr: *const f64, len: usize) -> f64 {
    let data = unsafe { std::slice::from_raw_parts(ptr, len) };
    data[0] / data[1] // panics on empty slice or div by zero
}

// ✅ GOOD: catch_unwind + return a Result-style error code, per rust-native-core
#[no_mangle]
pub extern "C" fn process(ptr: *const f64, len: usize, out_err: *mut i32) -> f64 {
    let result = std::panic::catch_unwind(|| {
        let data = unsafe { std::slice::from_raw_parts(ptr, len) };
        data[0] / data[1]
    });
    match result {
        Ok(v) => { unsafe { *out_err = 0 }; v }
        Err(_) => { unsafe { *out_err = 1 }; 0.0 }
    }
}
```

## Part B — Python Backend Service

For apps where Python is the backend (a local FastAPI/Flask server, or a subprocess the Dart UI drives) — see `python-project-rules` for coding-standard rules that apply to this code too.

### Minimal Local API (FastAPI)

```python
# ✅ Typed request/response models — catches shape mismatches before they hit the Dart side
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class BuildRequest(BaseModel):
    project_path: str
    compiler: str = "pyinstaller"  # or "nuitka"

class BuildResponse(BaseModel):
    success: bool
    output_path: str | None = None
    error: str | None = None

@app.post("/build", response_model=BuildResponse)
def build(req: BuildRequest) -> BuildResponse:
    try:
        output = run_build(req.project_path, req.compiler)
        return BuildResponse(success=True, output_path=output)
    except BuildError as e:
        raise HTTPException(status_code=400, detail=str(e))
```

### Dart ↔ Python Subprocess IPC (no HTTP server needed)

```dart
// For a bundled Python backend (PyInstaller-built .exe) launched as a child process,
// communicating over stdin/stdout JSON lines instead of a full HTTP server.
class PythonBackend {
  Process? _process;

  Future<void> start(String exePath) async {
    _process = await Process.start(exePath, []);
  }

  Future<Map<String, dynamic>> call(String method, Map<String, dynamic> params) async {
    final request = jsonEncode({'method': method, 'params': params});
    _process!.stdin.writeln(request);
    final line = await _process!.stdout.transform(utf8.decoder).transform(const LineSplitter()).first;
    return jsonDecode(line) as Map<String, dynamic>;
  }
}
```

## Caching Strategies (applies to either backend)

```dart
// Cache-aside pattern for expensive repeated calls (native compute or a Python endpoint)
class CachedComputeRepository implements ComputeRepository {
  CachedComputeRepository(this._inner);
  final ComputeRepository _inner;
  final _cache = <String, List<double>>{};

  @override
  Future<List<double>> processAudio(List<double> samples) async {
    final key = samples.join(',');
    final cached = _cache[key];
    if (cached != null) return cached;

    final result = await _inner.processAudio(samples);
    _cache[key] = result;
    return result;
  }
}
```

## Error Handling Patterns

```dart
// Centralized error type — mirrors the ApiError pattern, adapted for a local backend
class BackendError implements Exception {
  BackendError(this.message, {this.code = 'UNKNOWN'});
  final String message;
  final String code;
  @override
  String toString() => '[$code] $message';
}

// Retry with exponential backoff — for a flaky subprocess/HTTP call, not for a pure-compute FFI call
Future<T> retryWithBackoff<T>(Future<T> Function() fn, {int maxRetries = 3}) async {
  for (var i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(milliseconds: 1000 * (1 << i)));
    }
  }
  throw StateError('unreachable');
}
```

## Background Work (never block the UI thread)

```dart
// Long-running compute → Isolate, not the main isolate (see python-feature-scaffold's
// QThread/QRunnable equivalent for the Python side of this ecosystem)
Future<List<double>> processInBackground(List<double> samples) {
  return Isolate.run(() => heavyCompute(samples));
}
```

## Structured Logging

Reuse the project's existing logger split, don't invent a parallel logging system — see `flutter-app-blueprint`'s `logger_config.dart` (dispatches to `logger_debug.dart` in debug mode, `logger_release.dart` in release):

```dart
logger.info('Build started', context: {'project': path, 'compiler': compiler});
logger.error('Build failed', error: e, context: {'project': path});
```

**Remember**: pick Part A or Part B based on what the project actually has — don't introduce a Python backend into a project that only has a Rust native core, or vice versa.
