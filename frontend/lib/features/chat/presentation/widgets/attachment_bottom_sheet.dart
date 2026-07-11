import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/shared/services/upload_service.dart';

/// Result returned by the attachment bottom sheet.
class AttachmentResult {
  final String url;
  final String type; // 'IMAGE' or 'GIF'

  const AttachmentResult({required this.url, required this.type});
}

/// Shows the attachment bottom sheet.
///
/// [onMediaReady] is called with an [AttachmentResult] after a successful
/// image pick + upload.
/// [onLocationTap] and [onProductTap] are placeholder callbacks for future
/// features.
/// [onError] is called when something goes wrong.
Future<void> showAttachmentSheet({
  required BuildContext context,
  required ValueChanged<AttachmentResult> onMediaReady,
  VoidCallback? onLocationTap,
  VoidCallback? onProductTap,
  required ValueChanged<String> onError,
}) {
  return showBrutalistSheet(
    context: context,
    title: 'ADICIONAR',
    builder: (ctx) => _AttachmentSheetBody(
      onMediaReady: onMediaReady,
      onLocationTap: onLocationTap,
      onProductTap: onProductTap,
      onError: onError,
    ),
  );
}

class _AttachmentSheetBody extends StatefulWidget {
  final ValueChanged<AttachmentResult> onMediaReady;
  final VoidCallback? onLocationTap;
  final VoidCallback? onProductTap;
  final ValueChanged<String> onError;

  const _AttachmentSheetBody({
    required this.onMediaReady,
    this.onLocationTap,
    this.onProductTap,
    required this.onError,
  });

  @override
  State<_AttachmentSheetBody> createState() => _AttachmentSheetBodyState();
}

class _AttachmentSheetBodyState extends State<_AttachmentSheetBody> {
  final _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    if (_isUploading) return;

    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (xfile == null) return;

    setState(() => _isUploading = true);

    try {
      final result = await UploadService.uploadFile(File(xfile.path), 'chat');
      result.fold(
        (failure) {
          if (mounted) {
            widget.onError(failure.message);
          }
        },
        (url) {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onMediaReady(AttachmentResult(url: url, type: 'IMAGE'));
          }
        },
      );
    } catch (e) {
      if (mounted) {
        widget.onError('Erro ao enviar imagem');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(
              color: AppColors.primaryContainer,
              strokeWidth: 2,
            ),
          )
        else ...[
          _buildTile(
            icon: Icons.image_outlined,
            label: 'IMAGEM / GIF',
            onTap: _pickAndUploadImage,
          ),
          Spacing.vMd,
          _buildTile(
            icon: Icons.location_on_outlined,
            label: 'LOCALIZAÇÃO',
            onTap: () {
              Navigator.of(context).pop();
              widget.onLocationTap?.call();
            },
          ),
          Spacing.vMd,
          _buildTile(
            icon: Icons.shopping_bag_outlined,
            label: 'PRODUTO',
            onTap: () {
              Navigator.of(context).pop();
              widget.onProductTap?.call();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor, width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: context.textPrimary),
              Spacing.hMd,
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
