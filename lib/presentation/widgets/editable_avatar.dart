import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'network_avatar.dart';
import 'success_toast.dart';

/// Editable avatar widget encapsulating pick + upload logic.
class EditableAvatar extends StatefulWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final bool enabled;
  final VoidCallback? onStartUpload;
  final void Function(String? newUrl)? onUploaded;

  const EditableAvatar({
    super.key,
    required this.imageUrl,
    required this.initials,
    this.size = 96,
    this.enabled = true,
    this.onStartUpload,
    this.onUploaded,
  });

  @override
  State<EditableAvatar> createState() => _EditableAvatarState();
}

class _EditableAvatarState extends State<EditableAvatar> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    if (!widget.enabled || _uploading) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(loc.translate('profile.chooseFromGallery')),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(loc.translate('profile.takePhoto')),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploading = true);
      widget.onStartUpload?.call();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.updateAvatar(picked.path);

      if (!mounted) return;
      setState(() => _uploading = false);

      if (result.success) {
        widget.onUploaded?.call(authProvider.currentUser?.avatar);
        AppToast.showSuccess(
          context,
          message: AppLocalizations.of(
            context,
          ).translate('profile.avatarUpdated'),
        );
      } else if (authProvider.error != null) {
        _showError(authProvider.error!);
      } else {
        _showError('Upload failed');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _showError('Image selection failed');
    }
  }

  void _showError(String message) {
    final loc = AppLocalizations.of(context);
    final lower = message.toLowerCase();
    String key = 'profile.avatarUploadFailed';
    if (lower.contains('large') ||
        lower.contains('size') ||
        lower.contains('too big')) {
      key = 'profile.avatarTooLarge';
    } else if (lower.contains('type') || lower.contains('format')) {
      key = 'profile.avatarInvalidType';
    } else if (lower.contains('upload')) {
      key = 'profile.avatarUploadFailed';
    }
    final localized = loc.translate(key);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(localized.isEmpty ? message : localized)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _pickAndUpload,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          NetworkAvatar(
            imageUrl: widget.imageUrl,
            size: widget.size,
            initials: widget.initials,
            overlay: null,
          ),
          Positioned(
            bottom: -4,
            right: -4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _uploading
                    ? Colors.grey.shade500
                    : theme.colorScheme.secondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _uploading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onSecondary,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: theme.colorScheme.onSecondary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
