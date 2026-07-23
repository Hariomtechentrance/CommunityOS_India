import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface GeoPoint {
  lat: number;
  lng: number;
}

/**
 * Best-effort geocoding of a free-text area name via Google's Geocoding API.
 * Never throws - a missing/placeholder key, network failure, or "no results"
 * all resolve to null so profile/post creation never fails because of this.
 */
@Injectable()
export class GeocodingService {
  private readonly logger = new Logger(GeocodingService.name);

  constructor(private readonly config: ConfigService) {}

  async geocode(area: string): Promise<GeoPoint | null> {
    const apiKey = this.config.get<string>('GOOGLE_MAPS_SERVER_API_KEY');
    if (!apiKey || apiKey.startsWith('REPLACE_WITH')) {
      return null;
    }

    try {
      const url = new URL('https://maps.googleapis.com/maps/api/geocode/json');
      url.searchParams.set('address', area);
      url.searchParams.set('key', apiKey);

      const res = await fetch(url.toString());
      const data = await res.json();

      if (data.status !== 'OK' || !data.results?.length) {
        this.logger.warn(`Geocoding "${area}" returned status ${data.status}`);
        return null;
      }

      const location = data.results[0].geometry.location;
      return { lat: location.lat, lng: location.lng };
    } catch (error) {
      this.logger.warn(`Geocoding "${area}" failed: ${error}`);
      return null;
    }
  }

  /** Reverse of `geocode` - turns a GPS point into a human-readable area name. */
  async reverseGeocode(lat: number, lng: number): Promise<string | null> {
    const apiKey = this.config.get<string>('GOOGLE_MAPS_SERVER_API_KEY');
    if (!apiKey || apiKey.startsWith('REPLACE_WITH')) {
      return null;
    }

    try {
      const url = new URL('https://maps.googleapis.com/maps/api/geocode/json');
      url.searchParams.set('latlng', `${lat},${lng}`);
      url.searchParams.set('key', apiKey);

      const res = await fetch(url.toString());
      const data = await res.json();

      if (data.status !== 'OK' || !data.results?.length) {
        this.logger.warn(`Reverse geocoding (${lat}, ${lng}) returned status ${data.status}`);
        return null;
      }

      const components = data.results[0].address_components as Array<{
        long_name: string;
        types: string[];
      }>;
      const findByType = (type: string) =>
        components.find((c) => c.types.includes(type))?.long_name;

      const neighbourhood =
        findByType('sublocality_level_1') ?? findByType('neighborhood');
      const city = findByType('locality') ?? findByType('administrative_area_level_2');

      const area = [neighbourhood, city].filter(Boolean).join(' ');
      return area || data.results[0].formatted_address;
    } catch (error) {
      this.logger.warn(`Reverse geocoding (${lat}, ${lng}) failed: ${error}`);
      return null;
    }
  }

  /** Same lookup as `reverseGeocode`, but also pulls out the postal code and
   * city separately - needed wherever a bare "locality name" string isn't
   * enough to dedupe/match against (e.g. LocationVisit rows keyed by pincode). */
  async reverseGeocodeDetailed(
    lat: number,
    lng: number,
  ): Promise<{ area: string | null; city: string | null; pincode: string | null }> {
    const apiKey = this.config.get<string>('GOOGLE_MAPS_SERVER_API_KEY');
    if (!apiKey || apiKey.startsWith('REPLACE_WITH')) {
      return { area: null, city: null, pincode: null };
    }

    try {
      const url = new URL('https://maps.googleapis.com/maps/api/geocode/json');
      url.searchParams.set('latlng', `${lat},${lng}`);
      url.searchParams.set('key', apiKey);

      const res = await fetch(url.toString());
      const data = await res.json();

      if (data.status !== 'OK' || !data.results?.length) {
        this.logger.warn(`Reverse geocoding (${lat}, ${lng}) returned status ${data.status}`);
        return { area: null, city: null, pincode: null };
      }

      const components = data.results[0].address_components as Array<{
        long_name: string;
        types: string[];
      }>;
      const findByType = (type: string) =>
        components.find((c) => c.types.includes(type))?.long_name;

      const neighbourhood = findByType('sublocality_level_1') ?? findByType('neighborhood');
      const city = findByType('locality') ?? findByType('administrative_area_level_2') ?? null;
      const pincode = findByType('postal_code') ?? null;

      const area = [neighbourhood, city].filter(Boolean).join(' ') || data.results[0].formatted_address;
      return { area, city, pincode };
    } catch (error) {
      this.logger.warn(`Reverse geocoding (${lat}, ${lng}) failed: ${error}`);
      return { area: null, city: null, pincode: null };
    }
  }
}
