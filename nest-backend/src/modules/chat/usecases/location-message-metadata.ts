import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { MessageType } from '@prisma/client';

export type CanonicalLocationMetadata = {
  latitude: number;
  longitude: number;
  accuracyMeters: number;
  capturedAt: string;
  address?: string;
};

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

export const readCanonicalLocationMetadata = (
  value: unknown,
): CanonicalLocationMetadata | null => {
  if (!isRecord(value)) return null;
  const keys = new Set([
    'latitude',
    'longitude',
    'accuracyMeters',
    'capturedAt',
    'address',
  ]);
  if (Object.keys(value).some((key) => !keys.has(key))) return null;
  if (
    typeof value.latitude !== 'number' ||
    typeof value.longitude !== 'number' ||
    typeof value.accuracyMeters !== 'number' ||
    typeof value.capturedAt !== 'string'
  )
    return null;
  if (value.address != null && typeof value.address !== 'string') return null;
  return {
    latitude: value.latitude,
    longitude: value.longitude,
    accuracyMeters: value.accuracyMeters,
    capturedAt: value.capturedAt,
    ...(typeof value.address === 'string' ? { address: value.address } : {}),
  };
};

// ponytail: pure location validation shared by direct/order message flows.
export const validateLocationMetadata = (
  messageType: MessageType,
  metadata: Record<string, unknown> | undefined,
): Either<AppError, Record<string, unknown> | null> => {
  if (messageType !== 'LOCATION') return right(null);
  if (!metadata)
    return left(
      new BadRequestError('Metadados de localização são obrigatórios'),
    );

  const allowedKeys = new Set([
    'latitude',
    'longitude',
    'accuracyMeters',
    'capturedAt',
    'address',
  ]);
  if (Object.keys(metadata).some((key) => !allowedKeys.has(key))) {
    return left(new BadRequestError('Metadados de localização inválidos'));
  }

  const latitude = metadata.latitude;
  const longitude = metadata.longitude;
  const accuracyMeters = metadata.accuracyMeters;
  const capturedAt = metadata.capturedAt;
  const isFiniteNumber = (value: unknown): value is number =>
    typeof value === 'number' && Number.isFinite(value);

  if (!isFiniteNumber(latitude) || latitude < -90 || latitude > 90) {
    return left(new BadRequestError('Latitude inválida'));
  }
  if (!isFiniteNumber(longitude) || longitude < -180 || longitude > 180) {
    return left(new BadRequestError('Longitude inválida'));
  }
  if (
    !isFiniteNumber(accuracyMeters) ||
    accuracyMeters < 0 ||
    accuracyMeters > 100_000
  ) {
    return left(new BadRequestError('Precisão da localização inválida'));
  }
  const canonicalTimestamp =
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;
  const parsedTimestamp =
    typeof capturedAt === 'string' ? new Date(capturedAt) : null;
  if (
    typeof capturedAt !== 'string' ||
    !canonicalTimestamp.test(capturedAt) ||
    parsedTimestamp === null ||
    !Number.isFinite(parsedTimestamp.getTime()) ||
    parsedTimestamp.toISOString() !== capturedAt
  ) {
    return left(new BadRequestError('Data da localização inválida'));
  }
  if (
    metadata.address != null &&
    (typeof metadata.address !== 'string' ||
      metadata.address.trim().length === 0 ||
      metadata.address.length > 500)
  ) {
    return left(new BadRequestError('Endereço da localização inválido'));
  }
  return right({
    latitude,
    longitude,
    accuracyMeters,
    capturedAt,
    ...(typeof metadata.address === 'string'
      ? { address: metadata.address.trim() }
      : {}),
  });
};
