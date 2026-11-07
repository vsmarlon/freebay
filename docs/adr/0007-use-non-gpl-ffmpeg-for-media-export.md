# Use non-GPL FFmpeg for media export

The complete editor requires one deterministic image/video composition model for speed changes, mixed clips, timed overlays, voiceover, GIF, and advanced filters. FreeBay will use the non-GPL `ffmpeg_kit_flutter_new_video` variant across Android and iOS instead of duplicating those capabilities in Media3 and AVFoundation; this raises the supported floor to Android API 24 and iOS 14 and increases binary size, while avoiding GPL codecs and keeping hardware H.264 encoding with a non-GPL fallback.
