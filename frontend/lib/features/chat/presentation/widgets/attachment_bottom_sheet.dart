import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/services/upload_service.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

const _imageUploadMaxWidth = 1024.0;
const _imageUploadQuality = 85;

/// Result returned by the attachment bottom sheet.
class AttachmentResult {
  final String url;
  final MessageType type;

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
  bool returnRawFile = false,
  ValueChanged<XFile>? onRawImage,
  ValueChanged<XFile>? onRawVideo,
  VoidCallback? onLocationTap,
  VoidCallback? onProductTap,
  VoidCallback? onOfferTap,
  required ValueChanged<String> onError,
}) {
  return showBrutalistSheet(
    context: context,
    title: l10n(context).chatAddAttachment,
    builder: (ctx) => _AttachmentSheetBody(
      onMediaReady: onMediaReady,
      returnRawFile: returnRawFile,
      onRawImage: onRawImage,
      onRawVideo: onRawVideo,
      onLocationTap: onLocationTap,
      onProductTap: onProductTap,
      onOfferTap: onOfferTap,
      onError: onError,
    ),
  );
}

class _AttachmentSheetBody extends StatefulWidget {
  final ValueChanged<AttachmentResult> onMediaReady;
  final bool returnRawFile;
  final ValueChanged<XFile>? onRawImage;
  final ValueChanged<XFile>? onRawVideo;
  final VoidCallback? onLocationTap;
  final VoidCallback? onProductTap;
  final VoidCallback? onOfferTap;
  final ValueChanged<String> onError;

  const _AttachmentSheetBody({
    required this.onMediaReady,
    this.returnRawFile = false,
    this.onRawImage,
    this.onRawVideo,
    this.onLocationTap,
    this.onProductTap,
    this.onOfferTap,
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
      maxWidth: _imageUploadMaxWidth,
      imageQuality: _imageUploadQuality,
    );
    if (xfile == null) return;

    if (widget.returnRawFile) {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onRawImage?.call(xfile);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final result = await UploadService.uploadFile(File(xfile.path), 'chat');
      result.fold(
        (failure) {
          if (mounted) {
            widget.onError(localizedFailureMessage(context, failure));
          }
        },
        (url) {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onMediaReady(
              AttachmentResult(url: url, type: MessageType.image),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        widget.onError(l10n(context).errorUploadFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_isUploading) return;

    final xfile = await _picker.pickVideo(source: ImageSource.gallery);
    if (xfile == null) return;

    if (widget.returnRawFile && widget.onRawVideo != null) {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onRawVideo?.call(xfile);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final result = await UploadService.uploadFile(File(xfile.path), 'chat');
      result.fold(
        (failure) {
          if (mounted) {
            widget.onError(localizedFailureMessage(context, failure));
          }
        },
        (url) {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onMediaReady(
              AttachmentResult(url: url, type: MessageType.video),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        widget.onError(l10n(context).errorUploadFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
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
            label: strings.chatImageGif,
            onTap: _pickAndUploadImage,
          ),
          Spacing.vMd,
          _buildTile(
            icon: Icons.videocam_outlined,
            label: strings.chatVideo,
            onTap: _pickVideo,
          ),
          Spacing.vMd,
          _buildTile(
            icon: Icons.location_on_outlined,
            label: strings.chatSelectLocation,
            onTap: () {
              Navigator.of(context).pop();
              widget.onLocationTap?.call();
            },
          ),
          Spacing.vMd,
          _buildTile(
            icon: Icons.shopping_bag_outlined,
            label: strings.chatProduct,
            onTap: () {
              Navigator.of(context).pop();
              widget.onProductTap?.call();
            },
          ),
          Spacing.vMd,
          _buildTile(
            icon: Icons.local_offer_outlined,
            label: strings.chatMakeOffer,
            onTap: () {
              Navigator.of(context).pop();
              widget.onOfferTap?.call();
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
