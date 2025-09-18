import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A reusable loader that fades in when [visible] becomes true and
/// fades out when false. Uses a Lottie animation asset.
///
/// Provide a lightweight animation JSON under assets/animation/.
class AnimatedFadeLottieLoader extends StatefulWidget {
  final bool visible;
  final String asset;
  final double size;
  final Duration fadeDuration;
  final BoxFit fit;
  final EdgeInsetsGeometry padding;

  const AnimatedFadeLottieLoader({
    super.key,
    required this.visible,
    this.asset = 'assets/animation/loading.json',
    this.size = 140,
    this.fadeDuration = const Duration(milliseconds: 480),
    this.fit = BoxFit.contain,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  State<AnimatedFadeLottieLoader> createState() =>
      _AnimatedFadeLottieLoaderState();
}

class _AnimatedFadeLottieLoaderState extends State<AnimatedFadeLottieLoader>
    with SingleTickerProviderStateMixin {
  bool _shouldRender = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _shouldRender = true;
  }

  @override
  void didUpdateWidget(covariant AnimatedFadeLottieLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !_shouldRender) {
      setState(() => _shouldRender = true);
    }
  }

  void _handleFadeStatus(AnimationStatus status) {
    if (!widget.visible && status == AnimationStatus.dismissed) {
      // After fade out completes remove from tree
      if (mounted && _shouldRender) {
        setState(() => _shouldRender = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_shouldRender && !widget.visible) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: widget.fadeDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: widget.visible
          ? _FadeWrapper(
              key: const ValueKey('lottie-visible'),
              duration: widget.fadeDuration,
              onStatus: _handleFadeStatus,
              child: Padding(
                padding: widget.padding,
                child: SizedBox(
                  height: widget.size,
                  width: widget.size,
                  child: Lottie.asset(
                    widget.asset,
                    fit: widget.fit,
                    frameRate: FrameRate.max,
                    delegates: LottieDelegates(
                      values: [
                        // Example color override mapping if animation uses placeholders
                        ValueDelegate.colorFilter(
                          const ['**', 'spinner', '**'],
                          value: ColorFilter.mode(
                            theme.colorScheme.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _FadeWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final void Function(AnimationStatus) onStatus;

  const _FadeWrapper({
    super.key,
    required this.child,
    required this.duration,
    required this.onStatus,
  });

  @override
  State<_FadeWrapper> createState() => _FadeWrapperState();
}

class _FadeWrapperState extends State<_FadeWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(widget.onStatus);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(widget.onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}
