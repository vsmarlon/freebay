import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showAppImageViewer(BuildContext context, String imageUrl) async {
  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: AppMotion.forContext(context, AppMotion.enter),
      pageBuilder: (_, _, _) => _AppImageViewer(imageUrl: imageUrl),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _AppImageViewer extends StatelessWidget {
  final String imageUrl;

  const _AppImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Dismissible(
              key: const Key('image_viewer'),
              direction: DismissDirection.vertical,
              onDismissed: (_) => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: isPrivateMedia(imageUrl)
                      ? Image.network(
                          imageUrl,
                          headers: mediaAuthHeaders(imageUrl),
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          httpHeaders: mediaAuthHeaders(imageUrl),
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 64,
                          ),
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: Row(
                children: [
                  if (!isPrivateMedia(imageUrl))
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(imageUrl)),
                      child: Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 8),
                        color: context.surfaceColor,
                        child: Icon(Icons.download, color: context.textPrimary),
                      ),
                    ),
                  GestureDetector(
                    onTap: Navigator.of(context).pop,
                    child: Container(
                      width: 48,
                      height: 48,
                      color: context.surfaceColor,
                      child: Icon(Icons.close, color: context.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
