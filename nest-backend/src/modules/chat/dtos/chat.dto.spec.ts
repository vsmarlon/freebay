import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { ChatTheme } from '@prisma/client';
import { SetMessagePinDTO, UpdatePreferenceDTO, ViewOnceOpeningDTO } from './chat.dto';
import { createValidationPipe } from '@/shared/http/validation-pipe.factory';

describe('chat request DTO contracts', () => {
  it.each([true, false])('preserves the JSON pin boolean %p under the actual validation pipe', async (pinned) => {
    const result: unknown = await createValidationPipe().transform({ pinned }, { type: 'body', metatype: SetMessagePinDTO });
    expect(result).toEqual({ pinned });
  });

  it.each(['true', 'false', 1, 0, '', null, {}, []])('rejects non-boolean JSON pin state %p under the actual validation pipe', async (pinned) => {
    await expect(createValidationPipe().transform({ pinned }, { type: 'body', metatype: SetMessagePinDTO })).rejects.toMatchObject({ status: 400 });
  });

  it('accepts theme and mute patches, but rejects empty or malformed preference patches', async () => {
    const theme = plainToInstance(UpdatePreferenceDTO, { theme: ChatTheme.COBALT });
    const mute = plainToInstance(UpdatePreferenceDTO, { muted: true });
    const empty = plainToInstance(UpdatePreferenceDTO, {});
    const malformed = plainToInstance(UpdatePreferenceDTO, { muted: 'true' });

    expect(await validate(theme)).toHaveLength(0);
    expect(await validate(mute)).toHaveLength(0);
    expect(await validate(empty)).not.toHaveLength(0);
    expect(await validate(malformed)).not.toHaveLength(0);
  });

  it('requires UUID v4 opening keys', async () => {
    const valid = plainToInstance(ViewOnceOpeningDTO, { openingKey: '550e8400-e29b-41d4-a716-446655440000' });
    const invalid = plainToInstance(ViewOnceOpeningDTO, { openingKey: 'not-a-uuid' });

    expect(await validate(valid)).toHaveLength(0);
    expect(await validate(invalid)).not.toHaveLength(0);
  });
});
