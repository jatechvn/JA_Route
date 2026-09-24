---
name: frontend-patterns
description: Flutter/Dart UI development patterns for widget composition, state management (Riverpod/Bloc), performance optimization, and accessibility. Use when designing or reviewing Flutter Desktop UI code.
---

# Flutter/Dart Frontend Development Patterns

Modern UI patterns for Flutter Desktop applications in this ecosystem (see `flutter-app-blueprint` for the baseline project structure, `flutter-project-rules` for the mandatory constraints these patterns must respect).

## Widget Composition Patterns

### Composition Over Deep Nesting

```dart
// ❌ BAD: everything inlined, 6+ levels deep
Widget build(BuildContext context) {
  return Container(
    child: Column(
      children: [
        Container(child: Row(children: [Icon(Icons.info), Text('Title')])),
        Container(child: Text('Body...')),
      ],
    ),
  );
}

// ✅ GOOD: extracted into small const widgets (see flutter-project-rules: max 4 levels)
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CardHeader(title: title),
        CardBody(body: body),
      ],
    );
  }
}

class CardHeader extends StatelessWidget {
  const CardHeader({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) =>
      Row(children: [const Icon(Icons.info), Text(title)]);
}
```

### Builder Pattern for Reusable Data-Driven Widgets

```dart
// A generic "loader" widget, parallel to a render-props pattern —
// the caller controls what's rendered for each state.
class AsyncBuilder<T> extends StatelessWidget {
  const AsyncBuilder({super.key, required this.future, required this.builder});
  final Future<T> future;
  final Widget Function(BuildContext, T? data, bool loading, Object? error) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) => builder(
        context,
        snapshot.data,
        snapshot.connectionState == ConnectionState.waiting,
        snapshot.error,
      ),
    );
  }
}

// Usage
AsyncBuilder<List<Project>>(
  future: scannerService.scanWorkspace(path),
  builder: (context, projects, loading, error) {
    if (loading) return const CircularProgressIndicator();
    if (error != null) return ErrorView(error: error);
    return ProjectList(projects: projects!);
  },
)
```

## State Management Patterns

Respect whichever pattern the project already uses (Riverpod, Bloc, or plain `ChangeNotifier`/Provider) — **do not switch patterns mid-project** (see `flutter-project-rules`).

### Riverpod: Notifier for a Screen's State

```dart
@riverpod
class WorkspaceScan extends _$WorkspaceScan {
  @override
  Future<List<Project>> build() => const [];

  Future<void> scan(String path, {int maxDepth = 3}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(scannerServiceProvider).scanWorkspace(path, maxDepth: maxDepth),
    );
  }
}

// Usage in a widget
final scanState = ref.watch(workspaceScanProvider);
scanState.when(
  data: (projects) => ProjectList(projects: projects),
  loading: () => const CircularProgressIndicator(),
  error: (e, st) => ErrorView(error: e),
);
```

### Bloc: Event → State for a Long-Running Operation

```dart
sealed class BuildEvent {}
class StartBuild extends BuildEvent {}

sealed class BuildState {}
class BuildIdle extends BuildState {}
class BuildRunning extends BuildState { final String logLine; BuildRunning(this.logLine); }
class BuildDone extends BuildState { final bool success; BuildDone(this.success); }

class BuildBloc extends Bloc<BuildEvent, BuildState> {
  BuildBloc(this._runner) : super(BuildIdle()) {
    on<StartBuild>((event, emit) async {
      await for (final line in _runner.run()) {
        emit(BuildRunning(line));
      }
      emit(BuildDone(_runner.lastExitCode == 0));
    });
  }
  final BuildRunner _runner;
}
```

## Custom Hooks Equivalent: Reusable Stateful Logic

Dart/Flutter doesn't have hooks, but the same "extract reusable stateful logic" goal applies via small `ChangeNotifier`/`ValueNotifier` helpers or `flutter_hooks` if the project already depends on it.

### Debounce (e.g. for a live search filter)

```dart
class Debouncer {
  Debouncer(this.delay);
  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}

// Usage
final _debouncer = Debouncer(const Duration(milliseconds: 300));
onChanged: (query) => _debouncer.run(() => performSearch(query)),
```

## Performance Optimization

```dart
// ✅ const constructors wherever the widget tree is static (see flutter-project-rules)
const InfoCard(title: 'Fixed', body: 'Never rebuilds unnecessarily');

// ✅ ListView.builder / ListView.separated for long lists — never Column+map for 100+ items
ListView.builder(
  itemCount: projects.length,
  itemBuilder: (context, i) => ProjectTile(project: projects[i]),
);

// ✅ Scope rebuilds with Consumer/Selector instead of watching the whole state at the top
Consumer(
  builder: (context, ref, _) {
    final count = ref.watch(workspaceScanProvider.select((s) => s.value?.length ?? 0));
    return Text('$count projects');
  },
);

// ✅ RepaintBoundary around expensive custom painters (charts, WebGL-style backgrounds)
RepaintBoundary(child: CustomPaint(painter: GlassmorphismPainter()));
```

## Form Handling Patterns

```dart
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose(); // always dispose controllers
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!value.contains('@')) return 'Enter a valid email';
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // proceed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: TextFormField(controller: _emailController, validator: _validateEmail),
    );
  }
}
```

## Error Boundary Equivalent

Flutter has no component-level error boundary like React, but `ErrorWidget.builder` gives a global fallback, and a local try/catch + fallback widget covers a specific subtree:

```dart
// Global fallback (set once in main())
ErrorWidget.builder = (details) => Material(
  child: Center(child: Text('Something went wrong: ${details.exception}')),
);

// Local fallback for one risky subtree (e.g. a custom painter or plugin view)
class SafeBuilder extends StatelessWidget {
  const SafeBuilder({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) {
    try {
      return builder(context);
    } catch (e) {
      return Text('Failed to render: $e');
    }
  }
}
```

## Animation Patterns

```dart
// ✅ Implicit animation for simple state-driven transitions (preferred — less boilerplate)
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  decoration: BoxDecoration(color: isActive ? c.accent : c.bgSecondary),
  child: child,
);

// ✅ Explicit AnimationController only when you need fine-grained control
// (e.g. the Glassmorphism blur/opacity sliders described in flutter-app-blueprint)
class BlurTransition extends StatefulWidget {
  const BlurTransition({super.key, required this.child});
  final Widget child;
  @override
  State<BlurTransition> createState() => _BlurTransitionState();
}

class _BlurTransitionState extends State<BlurTransition> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  @override
  void dispose() {
    _controller.dispose(); // always dispose AnimationControllers
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => widget.child;
}
```

## Accessibility Patterns

```dart
// ✅ Semantics for screen readers, even on a Desktop-only app — helps with Windows Narrator
Semantics(
  label: 'Start build',
  button: true,
  child: IconButton(icon: const Icon(Icons.play_arrow), onPressed: onStart),
);

// ✅ Keyboard navigation via FocusNode + Shortcuts/Actions, not just onTap
Shortcuts(
  shortcuts: {LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent()},
  child: Actions(
    actions: {DismissIntent: CallbackAction(onInvoke: (_) => Navigator.pop(context))},
    child: child,
  ),
);
```

**Remember**: choose the pattern that fits the project's existing architecture — consistency with what's already there beats introducing a "better" pattern mid-project.
