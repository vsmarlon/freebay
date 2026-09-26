import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';

void main() {
  test('parses story media metadata independently', () {
    final story = StoryEntity.fromJson({
      'id': 'story-1',
      'userId': 'user-1',
      'imageUrl': 'https://example.test/story.mp4',
      'mediaType': 'VIDEO',
      'caption': 'caption',
      'textBlocks': [
        {
          'id': 'block-1',
          'text': 'caption on media',
          'x': 0.5,
          'y': 0.5,
          'scale': 1.0,
          'rotation': 0.0,
          'color': 4294967295,
          'style': 'classic',
          'zIndex': 0,
        },
      ],
      'expiresAt': '2030-01-01T00:00:00.000Z',
      'createdAt': '2029-12-31T00:00:00.000Z',
      'user': {
        'id': 'user-1',
        'displayName': 'User',
        'avatarUrl': null,
        'isVerified': false,
      },
    });

    expect(story.mediaType, StoryMediaType.video);
    expect(story.caption, 'caption');
    expect(story.textBlocks!.single.text, 'caption on media');
    expect(story.textBlocks!.single.style, StoryTextStyle.classic);
  });

  test('round-trips text block position, style, color, and layer', () {
    const block = StoryTextBlockEntity(
      id: 'block-1',
      text: 'Overlay',
      x: 0.25,
      y: 0.75,
      scale: 1.5,
      rotation: -0.2,
      color: 0xff8a1083,
      style: StoryTextStyle.editorial,
      zIndex: 3,
    );

    final decoded = StoryTextBlockEntity.fromJson(block.toJson());

    expect(decoded, block);
  });
}
