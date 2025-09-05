import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'shimmer.dart';

/// Reusable avatar widget with shimmer loading + error + initials fallback.
class NetworkAvatar extends StatefulWidget {
  final String? imageUrl;
  final double size;
  final String? initials;
  final Color? backgroundColor;
  final TextStyle? initialsStyle;
  final Widget? overlay; // e.g. camera or refresh icon

  const NetworkAvatar({
    super.key,
    required this.imageUrl,
    required this.size,
    this.initials,
    this.backgroundColor,
    this.initialsStyle,
    this.overlay,
  });

  @override
  State<NetworkAvatar> createState() => _NetworkAvatarState();
}

class _NetworkAvatarState extends State<NetworkAvatar> {
  Widget _buildFallback(BuildContext context) {
    final bg = widget.backgroundColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Color.alphaBlend(bg.withAlpha(40), Colors.white),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: widget.initials != null && widget.initials!.isNotEmpty
            ? Text(
                widget.initials!,
                style:
                    widget.initialsStyle ??
                    TextStyle(
                      fontSize: widget.size * 0.36,
                      fontWeight: FontWeight.bold,
                      color: bg,
                    ),
              )
            : Icon(Icons.person, size: widget.size * 0.5, color: bg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // No URL -> immediate fallback
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          _buildFallback(context),
          if (widget.overlay != null)
            Positioned(bottom: 0, right: 0, child: widget.overlay!),
        ],
      );
    }

    final avatar = ClipOval(
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        placeholder: (_, __) => Shimmer(
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: const BoxDecoration(
              color: Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _buildFallback(context),
        fadeInDuration: const Duration(milliseconds: 250),
        memCacheWidth: (widget.size * MediaQuery.of(context).devicePixelRatio)
            .round(),
        memCacheHeight: (widget.size * MediaQuery.of(context).devicePixelRatio)
            .round(),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (widget.overlay != null)
          Positioned(bottom: 0, right: 0, child: widget.overlay!),
      ],
    );
  }
}
