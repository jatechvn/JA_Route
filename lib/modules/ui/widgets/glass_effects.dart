part of 'glass_widgets.dart';

class BorderBeam extends StatefulWidget {
  const BorderBeam({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.colors = const [
      Color(0xFF00D2FF),
      Color(0xFF0066FF),
      Color(0xFFA855F7),
    ],
    this.strokeWidth = 1.5,
    this.duration = const Duration(seconds: 5),
    this.glowBlur = 4.0,
  });

  final Widget child;
  final double borderRadius;
  final List<Color> colors;
  final double strokeWidth;
  final Duration duration;
  final double glowBlur;

  @override
  State<BorderBeam> createState() => _BorderBeamState();
}

class _BorderBeamState extends State<BorderBeam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        switch (state) {
          case AppLifecycleState.hidden:
          case AppLifecycleState.paused:
            _controller.stop();
          case AppLifecycleState.resumed:
            _controller.repeat();
          case AppLifecycleState.inactive:
          case AppLifecycleState.detached:
            break;
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            foregroundPainter: _BorderBeamPainter(
              progress: _controller.value,
              borderRadius: widget.borderRadius,
              colors: widget.colors,
              strokeWidth: widget.strokeWidth,
              glowBlur: widget.glowBlur,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _BorderBeamPainter extends CustomPainter {
  _BorderBeamPainter({
    required this.progress,
    required this.borderRadius,
    required this.colors,
    required this.strokeWidth,
    required this.glowBlur,
  });

  final double progress;
  final double borderRadius;
  final List<Color> colors;
  final double strokeWidth;
  final double glowBlur;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );

    final gradient = SweepGradient(
      colors: [...colors, colors.first],
      stops: List.generate(colors.length + 1, (i) => i / colors.length),
      transform: GradientRotation(progress * 2 * math.pi),
    );

    final shader = gradient.createShader(Offset.zero & size);

    if (glowBlur > 0) {
      final glowPaint = Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.2
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur);
      canvas.drawRRect(rrect, glowPaint);
    }

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _BorderBeamPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.borderRadius != borderRadius ||
      !listEquals(oldDelegate.colors, colors) ||
      oldDelegate.glowBlur != glowBlur ||
      oldDelegate.strokeWidth != strokeWidth;
}

// ── Rotating Glow Border ────────────────────────────────────────────────────

/// A widget that paints an animated rotating glowing light beam around its perimeter
/// with a specular white core head, vibrant neon trail, and soft outer bloom.
/// Ideal for drawing strong visual attention to selected cards, active status, or featured UI.
class RotatingGlowBorder extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color color;
  final double borderRadius;
  final double borderWidth;
  final double glowBlur;
  final Duration duration;

  const RotatingGlowBorder({
    super.key,
    required this.child,
    this.isActive = true,
    required this.color,
    this.borderRadius = 20.0,
    this.borderWidth = 2.0,
    this.glowBlur = 6.0,
    this.duration = const Duration(milliseconds: 3000),
  });

  @override
  State<RotatingGlowBorder> createState() => _RotatingGlowBorderState();
}

class _RotatingGlowBorderState extends State<RotatingGlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    if (widget.isActive) {
      _controller.repeat();
    }

    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        if (!mounted || !widget.isActive) return;
        switch (state) {
          case AppLifecycleState.hidden:
          case AppLifecycleState.paused:
            _controller.stop();
          case AppLifecycleState.resumed:
            _controller.repeat();
          case AppLifecycleState.inactive:
          case AppLifecycleState.detached:
            break;
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant RotatingGlowBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
      if (_controller.isAnimating) _controller.repeat();
    }
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        final state = WidgetsBinding.instance.lifecycleState;
        if (state != AppLifecycleState.hidden &&
            state != AppLifecycleState.paused) {
          _controller.repeat();
        }
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return RepaintBoundary(
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: RotatingGlowBorderPainter(
                      animationProgress: _controller.value,
                      color: widget.color,
                      borderRadius: widget.borderRadius,
                      borderWidth: widget.borderWidth,
                      glowBlur: widget.glowBlur,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RotatingGlowBorderPainter extends CustomPainter {
  final double animationProgress;
  final Color color;
  final double borderRadius;
  final double borderWidth;
  final double glowBlur;

  RotatingGlowBorderPainter({
    required this.animationProgress,
    required this.color,
    required this.borderRadius,
    required this.borderWidth,
    required this.glowBlur,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final halfWidth = borderWidth / 2.0;
    final rect = Rect.fromLTWH(
      halfWidth,
      halfWidth,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(math.max(0.0, borderRadius - halfWidth)),
    );

    final angle = animationProgress * 2 * math.pi;

    final sweepGradient = SweepGradient(
      center: Alignment.center,
      transform: GradientRotation(angle),
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.85),
        Colors.white,
        color,
        color.withValues(alpha: 0.65),
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.05, 0.12, 0.16, 0.20, 0.26, 0.34, 1.0],
    );

    // 1. Diffuse outer neon bloom
    if (glowBlur > 0) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth * 2.2
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur)
        ..shader = sweepGradient.createShader(rect);
      canvas.drawRRect(rrect, glowPaint);
    }

    // 2. Crisp stroke for the bright core beam
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = sweepGradient.createShader(rect);
    canvas.drawRRect(rrect, corePaint);
  }

  @override
  bool shouldRepaint(covariant RotatingGlowBorderPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.glowBlur != glowBlur;
  }
}

/// Mouse-follow spotlight glow — wrap a card's child to add a soft radial
/// highlight that tracks the cursor on hover.
class SpotlightGlow extends StatefulWidget {
  const SpotlightGlow({
    super.key,
    required this.colors,
    required this.child,
    this.borderRadius = 20,
    this.glowColor,
  });

  final AppColors colors;
  final Widget child;
  final double borderRadius;
  final Color? glowColor;

  @override
  State<SpotlightGlow> createState() => _SpotlightGlowState();
}

class _SpotlightGlowState extends State<SpotlightGlow> {
  // ValueNotifier instead of setState: mouse-move on Windows can fire far
  // more often than the frame rate, and setState would rebuild `child`
  // on every single event. Scoping the rebuild to a ValueListenableBuilder
  // around just the glow overlay is the Flutter equivalent of the
  // rAF-pending-flag throttle UI_DESIGN_Sample.html uses for its cursor
  // spotlight (`handleCardMouseMoveThrottled` / `_rafPending`).
  final ValueNotifier<Offset?> _localPosition = ValueNotifier(null);

  @override
  void dispose() {
    _localPosition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? widget.colors.accentColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return MouseRegion(
            onHover: (event) => _localPosition.value = event.localPosition,
            onExit: (_) => _localPosition.value = null,
            child: Stack(
              children: [
                widget.child,
                if (w > 0 && h > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: ValueListenableBuilder<Offset?>(
                          valueListenable: _localPosition,
                          builder: (context, position, _) {
                            if (position == null) {
                              return const SizedBox.shrink();
                            }
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment(
                                    (position.dx / w) * 2 - 1,
                                    (position.dy / h) * 2 - 1,
                                  ),
                                  radius: 0.9,
                                  colors: [
                                    glow.withValues(alpha: 0.12),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
