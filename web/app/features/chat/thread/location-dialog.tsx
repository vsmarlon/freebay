import { useState } from 'react';
import { Dialog } from '../../../components';
import { LocationPicker } from '../../../components/location-picker';
import { useI18n } from '../../../core/locale';
import { chatCatalogs } from '../catalogs';
import { locationMessageMetadata } from '../model';

type LocationMetadata = NonNullable<ReturnType<typeof locationMessageMetadata>>;

export function LocationDialog({
  locale,
  pending,
  onClose,
  onSend,
}: {
  locale: string;
  pending: boolean;
  onClose: () => void;
  onSend: (metadata: LocationMetadata) => void;
}) {
  const { t } = useI18n(chatCatalogs);
  const [latitude, setLatitude] = useState('');
  const [longitude, setLongitude] = useState('');
  const [address, setAddress] = useState('');
  const [accuracy, setAccuracy] = useState<number>();
  const [capturedAt, setCapturedAt] = useState<string>();
  const [error, setError] = useState('');
  const metadata = locationMessageMetadata({
    latitude,
    longitude,
    address,
    // shortcut: map picks carry no measured accuracy, upgrade when the map adapter exposes it.
    accuracyMeters: accuracy ?? 0,
    capturedAt: capturedAt ?? new Date().toISOString(),
  });
  return (
    <Dialog open onClose={onClose} title={t('chat.location')}>
      <p className="mb-3 text-sm text-muted">{t('chat.mapPickHint')}</p>
      <p className="mb-3 text-xs text-muted">{t('chat.meetupNote')}</p>
      <LocationPicker
        key={`${latitude},${longitude}`}
        latitude={latitude}
        longitude={longitude}
        onPick={(point) => {
          setLatitude(point.latitude);
          setLongitude(point.longitude);
          setAccuracy(point.accuracyMeters);
          setCapturedAt(point.capturedAt);
          setError('');
        }}
        onGeolocationError={() => setError(t('chat.locationPermissionError'))}
        useCurrentLabel={t('chat.useCurrentLocation')}
      />
      <p className="mt-2 text-sm text-muted">{t('chat.locationMeasuredHint')}</p>
      {accuracy !== undefined && capturedAt ? (
        <p role="status" className="mt-2 text-sm text-muted">
          {t('chat.locationMeasurement', {
            accuracy,
            capturedAt: new Date(capturedAt).toLocaleString(locale),
          })}
        </p>
      ) : null}
      <label className="mt-2 grid gap-1">
        {t('chat.placeName')}
        <input
          className="min-h-11 bg-surface-high p-2"
          type="text"
          maxLength={500}
          value={address}
          onChange={(event) => {
            setAddress(event.currentTarget.value);
            setError('');
          }}
        />
      </label>
      {error ? (
        <p role="alert" className="mt-2 text-danger">
          {error}
        </p>
      ) : null}
      <button
        type="button"
        className="ui-button ui-primary mt-3"
        disabled={!metadata || pending}
        onClick={() => {
          if (metadata) onSend(metadata);
          else setError(t('chat.locationInvalid'));
        }}
      >
        {t('chat.sendLocation')}
      </button>
    </Dialog>
  );
}
