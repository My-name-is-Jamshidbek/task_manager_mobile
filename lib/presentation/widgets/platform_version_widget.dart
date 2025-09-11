import 'package:flutter/material.dart';
import '../../core/services/version_service.dart';

/// Widget that displays platform-specific version information
class PlatformVersionWidget extends StatefulWidget {
  final TextStyle? textStyle;
  final bool showIcon;
  final bool showPlatform;
  final bool showBuildNumber;

  const PlatformVersionWidget({
    super.key,
    this.textStyle,
    this.showIcon = true,
    this.showPlatform = true,
    this.showBuildNumber = true,
  });

  @override
  State<PlatformVersionWidget> createState() => _PlatformVersionWidgetState();
}

class _PlatformVersionWidgetState extends State<PlatformVersionWidget> {
  Map<String, dynamic>? _platformInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlatformInfo();
  }

  Future<void> _loadPlatformInfo() async {
    try {
      final info = await VersionService.getPlatformInfo();
      if (mounted) {
        setState(() {
          _platformInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.textStyle?.color ??
                Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }

    if (_platformInfo == null) {
      return Text('Version: Unknown', style: widget.textStyle);
    }

    final String versionText = _buildVersionText();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Text(
            _platformInfo!['icon'],
            style: TextStyle(
              fontSize: (widget.textStyle?.fontSize ?? 12) * 1.2,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(versionText, style: widget.textStyle),
      ],
    );
  }

  String _buildVersionText() {
    final platform = _platformInfo!['platform'] as String;
    final version = _platformInfo!['version'] as String;
    final buildNumber = _platformInfo!['buildNumber'] as int;

    final StringBuffer buffer = StringBuffer();

    if (widget.showPlatform) {
      buffer.write(platform);
      buffer.write(' ');
    }

    buffer.write('v');
    buffer.write(version);

    if (widget.showBuildNumber) {
      buffer.write(' (');
      buffer.write(buildNumber);
      buffer.write(')');
    }

    return buffer.toString();
  }
}

/// Simple version text widget for quick use
class SimpleVersionText extends StatelessWidget {
  final TextStyle? textStyle;

  const SimpleVersionText({super.key, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return PlatformVersionWidget(
      textStyle: textStyle,
      showIcon: false,
      showPlatform: false,
      showBuildNumber: true,
    );
  }
}

/// Full platform version widget with icon and platform name
class FullPlatformVersion extends StatelessWidget {
  final TextStyle? textStyle;

  const FullPlatformVersion({super.key, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return PlatformVersionWidget(
      textStyle: textStyle,
      showIcon: true,
      showPlatform: true,
      showBuildNumber: true,
    );
  }
}

/// Compact version widget for loading screens
class CompactVersionWidget extends StatelessWidget {
  final TextStyle? textStyle;

  const CompactVersionWidget({super.key, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return PlatformVersionWidget(
      textStyle: textStyle,
      showIcon: true,
      showPlatform: false,
      showBuildNumber: false,
    );
  }
}
