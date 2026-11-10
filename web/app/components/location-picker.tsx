import { useCallback } from 'react';
import type L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Icon } from './index';
import { useLatest } from '../core/use-latest';

type LatLng = { latitude: string; longitude: string };

function parsePoint(latitude: string, longitude: string): L.LatLngTuple | null {
  const lat = Number(latitude);
  const lng = Number(longitude);
  if (
    !Number.isFinite(lat) ||
    !Number.isFinite(lng) ||
    lat < -90 ||
    lat > 90 ||
    lng < -180 ||
    lng > 180
  )
    return null;
  return [lat, lng];
}

export function LocationPicker({
  latitude,
  longitude,
  onPick,
  onGeolocationError,
  useCurrentLabel,
}: {
  latitude: string;
  longitude: string;
  onPick: (point: LatLng & { accuracyMeters?: number; capturedAt?: string }) => void;
  onGeolocationError: () => void;
  useCurrentLabel: string;
}) {
  // Latest props via ref: the mount callback stays stable so the Leaflet map is created once (remount only via key).
  const latest = useLatest({ latitude, longitude, onPick });

  const mount = useCallback(
    (node: HTMLDivElement | null) => {
      if (!node) return;
      // ponytail: leaflet touches window at import time, so load it only in the browser.
      const { latitude: initialLat, longitude: initialLng, onPick: pick } = latest.current;
      const point = parsePoint(initialLat, initialLng);
      let map: L.Map | null = null;
      let observer: ResizeObserver | null = null;
      let cancelled = false;
      void import('leaflet').then(({ default: leaflet }) => {
        if (cancelled) return;
        const instance = leaflet
          .map(node, { attributionControl: false })
          .setView(point ?? [-23.5505, -46.6333], point ? 14 : 4);
        map = instance;
        leaflet
          .tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 })
          .addTo(instance);
        let marker: L.CircleMarker | null = point
          ? leaflet
              .circleMarker(point, {
                radius: 9,
                color: '#8a1083',
                fillColor: '#8a1083',
                fillOpacity: 1,
              })
              .addTo(instance)
          : null;
        instance.on('click', (event: L.LeafletMouseEvent) => {
          const next: L.LatLngTuple = [event.latlng.lat, event.latlng.lng];
          if (marker) marker.setLatLng(next);
          else
            marker = leaflet
              .circleMarker(next, {
                radius: 9,
                color: '#8a1083',
                fillColor: '#8a1083',
                fillOpacity: 1,
              })
              .addTo(instance);
          pick({ latitude: String(event.latlng.lat), longitude: String(event.latlng.lng) });
        });
        // The dialog content mounts hidden (0×0); recompute the tile size once it becomes visible.
        observer = new ResizeObserver(() => instance.invalidateSize());
        observer.observe(node);
      });
      return () => {
        cancelled = true;
        observer?.disconnect();
        map?.remove();
      };
    },
    [latest],
  );

  function pickCurrent() {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      ({ coords, timestamp }) => {
        if (Number.isFinite(coords.latitude) && Number.isFinite(coords.longitude)) {
          const capturedAt = new Date(timestamp);
          latest.current.onPick({
            latitude: String(coords.latitude),
            longitude: String(coords.longitude),
            ...(Number.isFinite(coords.accuracy) ? { accuracyMeters: coords.accuracy } : {}),
            ...(Number.isFinite(timestamp) && !Number.isNaN(capturedAt.getTime())
              ? { capturedAt: capturedAt.toISOString() }
              : {}),
          });
        }
      },
      () => onGeolocationError(),
      { enableHighAccuracy: true, timeout: 10000 },
    );
  }

  return (
    <div className="grid gap-2">
      <button type="button" className="ui-button ui-secondary self-start" onClick={pickCurrent}>
        <Icon name="pin" size={16} /> {useCurrentLabel}
      </button>
      <div className="location-map">
        <div ref={mount} style={{ height: '100%', width: '100%' }} />
      </div>
    </div>
  );
}
