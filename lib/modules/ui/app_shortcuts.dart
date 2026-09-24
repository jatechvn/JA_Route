import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppCommand {
  overview,
  config,
  diagnostics,
  logs,
  about,
  settings,
  theme,
  search,
  clear,
}

class AppCommandIntent extends Intent {
  const AppCommandIntent(this.command);
  final AppCommand command;
}

class AppShortcuts extends StatefulWidget {
  const AppShortcuts({super.key, required this.commands, required this.child});
  final Map<AppCommand, VoidCallback> commands;
  final Widget child;

  static const keys = {
    AppCommand.overview: LogicalKeyboardKey.digit1,
    AppCommand.config: LogicalKeyboardKey.digit2,
    AppCommand.diagnostics: LogicalKeyboardKey.digit3,
    AppCommand.logs: LogicalKeyboardKey.digit4,
    AppCommand.about: LogicalKeyboardKey.digit5,
    AppCommand.settings: LogicalKeyboardKey.comma,
    AppCommand.theme: LogicalKeyboardKey.keyL,
    AppCommand.search: LogicalKeyboardKey.keyF,
    AppCommand.clear: LogicalKeyboardKey.keyL,
  };

  static SingleActivator primary(LogicalKeyboardKey key, {bool shift = false}) {
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    return SingleActivator(
      key,
      control: !mac,
      meta: mac,
      shift: shift,
      includeRepeats: false,
    );
  }

  static String label(String key) =>
      '${defaultTargetPlatform == TargetPlatform.macOS ? 'Cmd' : 'Ctrl'}+$key';

  @override
  State<AppShortcuts> createState() => _AppShortcutsState();
}

class _AppShortcutsState extends State<AppShortcuts> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          !_focusNode.hasFocus &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: {
      for (final command in widget.commands.keys)
        AppShortcuts.primary(
          AppShortcuts.keys[command]!,
          shift: command == AppCommand.theme,
        ): AppCommandIntent(
          command,
        ),
    },
    child: Actions(
      actions: {
        AppCommandIntent: CallbackAction<AppCommandIntent>(
          onInvoke: (intent) {
            final callback = widget.commands[intent.command];
            if (callback == null) return Actions.maybeInvoke(context, intent);
            callback();
            return null;
          },
        ),
      },
      child: Focus(focusNode: _focusNode, child: widget.child),
    ),
  );
}
