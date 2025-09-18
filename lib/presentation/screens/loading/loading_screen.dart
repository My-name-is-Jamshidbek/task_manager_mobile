import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
// Removed platform version display for cleaner minimal loading UI
import '../../widgets/animated_fade_lottie_loader.dart';
// ...existing imports...

/// Minimal loading screen with a whole-screen fade-in (and graceful fade-out when disposed)
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  bool _fadingOut = false;

  @override
  void initState() {
    super.initState();
    // Start fade in on next frame to avoid build jank.
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  // Try to catch removal from tree to animate out.
  @override
  void deactivate() {
    // If we're still mounted and not already fading out, start reverse.
    if (!_fadingOut && _controller.isCompleted) {
      _fadingOut = true;
      _controller.reverse();
    }
    super.deactivate();
  }

  // Optionally expose a static method to trigger fade out before navigation if needed later.
  Future<void> fadeOutIfMounted({Duration? duration}) async {
    if (!mounted || _fadingOut) return;
    _fadingOut = true;
    if (duration != null) _controller.duration = duration;
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Keep localization reference (unused now) for future micro-copy
    // ignore: unused_local_variable
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: AnimatedBuilder(
        animation: _opacity,
        builder: (context, child) =>
            Opacity(opacity: _opacity.value, child: child),
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shortestSide = MediaQuery.of(context).size.shortestSide;
                final double size = (shortestSide * 0.42).clamp(180, 260);
                return AnimatedFadeLottieLoader(visible: true, size: size);
              },
            ),
          ),
        ),
      ),
    );
  }
}
