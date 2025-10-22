"use client";

import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import { useState } from "react";
import L, { LatLngTuple } from "leaflet";
import { MapPin } from "lucide-react";

// Create a custom Leaflet icon using Lucide's MapPin
const createCustomIcon = () =>
  L.divIcon({
    html: `
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
        <circle cx="12" cy="10" r="3"></circle>
      </svg>
    `,
    className: "custom-icon",
    iconSize: [24, 24],
    iconAnchor: [12, 24], // Anchor at the bottom center of the icon
    popupAnchor: [0, -24], // Popup offset from the icon
  });

interface MapSelectorProps {
  initialLatitude?: number;
  initialLongitude?: number;
  onSelect: (latitude: number, longitude: number) => void;
}

export function MapSelector({
  initialLatitude = 40.5,
  initialLongitude = 14.5,
  onSelect,
}: MapSelectorProps) {
  const [position, setPosition] = useState<LatLngTuple>([
    initialLatitude,
    initialLongitude,
  ]);

  // Handle map click events
  const MapClickHandler = () => {
    useMapEvents({
      click(event) {
        const { lat, lng } = event.latlng;
        const lat_fixed = parseFloat(lat.toFixed(1));
        const lon_fixed = parseFloat(lng.toFixed(1));
        setPosition([lat_fixed, lon_fixed]);
        onSelect(lat_fixed, lon_fixed);
      },
    });
    return null;
  };

  return (
    <div className="relative h-[400px] w-full rounded-md overflow-hidden bg-background">
      <MapContainer
        center={[initialLatitude, initialLongitude] as LatLngTuple}
        zoom={6}
        minZoom={6}
        maxBounds={[
          [32, 6],
          [49, 20],
        ]}
        className="h-full w-full relative"
      >
        <TileLayer
          url="http://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png"
          minZoom={0}
          maxZoom={20}
          attribution='© <a href="https://www.stadiamaps.com/" target="_blank">Stadia Maps</a> © <a href="https://openmaptiles.org/" target="_blank">OpenMapTiles</a> © <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        />

        <Marker position={position} icon={createCustomIcon()} />
        <MapClickHandler />
      </MapContainer>
    </div>
  );
}
