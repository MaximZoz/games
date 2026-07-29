import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';

/// Локализованное меню источника фото (вместо системного sheet браузера/iOS).
Future<ImageSource?> showChatImageSourceSheet(BuildContext context) {
  final l10n = context.l10n;
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.pickPhotoGallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.pickPhotoCamera),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l10n.commonCancel),
              onTap: () => Navigator.of(ctx).pop(),
            ),
            const SizedBox(height: 4),
          ],
        ),
      );
    },
  );
}
