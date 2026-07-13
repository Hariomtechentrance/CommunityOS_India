import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface NearbyPlace {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  address: string | null;
  types: string[];
  rating: number | null;
}

export const PLACE_CATEGORIES = ['All', 'Cafes', 'Stores', 'Medical', 'Salons'] as const;
export type PlaceCategory = (typeof PLACE_CATEGORIES)[number];

/** Included-type sets per category chip - kept to types that have been
 * stable across Places API revisions to avoid an INVALID_ARGUMENT error. */
const CATEGORY_TYPES: Record<PlaceCategory, string[]> = {
  All: ['cafe', 'restaurant', 'store', 'supermarket', 'pharmacy', 'hospital', 'beauty_salon', 'hair_care'],
  Cafes: ['cafe', 'bakery'],
  Stores: ['store', 'supermarket', 'convenience_store', 'clothing_store'],
  Medical: ['pharmacy', 'hospital', 'doctor', 'dentist'],
  Salons: ['beauty_salon', 'hair_care', 'spa'],
};

const SEARCH_RADIUS_METERS = 2000;
const CACHE_TTL_MS = 10 * 60 * 1000;

/**
 * Server-side proxy for Google's Places API (New) Nearby Search - never
 * called directly from the client, both to keep the server API key off the
 * client and to let us cache results (this is a paid, per-request API,
 * unlike Geocoding's generous free tier - caching matters here).
 */
@Injectable()
export class PlacesService {
  private readonly logger = new Logger(PlacesService.name);
  private readonly cache = new Map<string, { expiresAt: number; places: NearbyPlace[] }>();

  constructor(private readonly config: ConfigService) {}

  async nearby(lat: number, lng: number, category: PlaceCategory): Promise<NearbyPlace[]> {
    const cacheKey = `${lat.toFixed(3)},${lng.toFixed(3)},${category}`;
    const cached = this.cache.get(cacheKey);
    if (cached && cached.expiresAt > Date.now()) {
      return cached.places;
    }

    const apiKey = this.config.get<string>('GOOGLE_MAPS_SERVER_API_KEY');
    if (!apiKey || apiKey.startsWith('REPLACE_WITH')) {
      return [];
    }

    try {
      const res = await fetch('https://places.googleapis.com/v1/places:searchNearby', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask':
            'places.id,places.displayName,places.location,places.formattedAddress,places.types,places.rating',
        },
        body: JSON.stringify({
          includedTypes: CATEGORY_TYPES[category],
          maxResultCount: 20,
          locationRestriction: {
            circle: { center: { latitude: lat, longitude: lng }, radius: SEARCH_RADIUS_METERS },
          },
        }),
      });

      if (!res.ok) {
        const body = await res.text();
        this.logger.warn(`Places nearby search failed (${res.status}): ${body}`);
        return [];
      }

      const data = (await res.json()) as {
        places?: Array<{
          id: string;
          displayName?: { text: string };
          location?: { latitude: number; longitude: number };
          formattedAddress?: string;
          types?: string[];
          rating?: number;
        }>;
      };

      const places: NearbyPlace[] = (data.places ?? [])
        .filter((p) => p.location)
        .map((p) => ({
          id: p.id,
          name: p.displayName?.text ?? 'Unnamed place',
          latitude: p.location!.latitude,
          longitude: p.location!.longitude,
          address: p.formattedAddress ?? null,
          types: p.types ?? [],
          rating: p.rating ?? null,
        }));

      this.cache.set(cacheKey, { expiresAt: Date.now() + CACHE_TTL_MS, places });
      return places;
    } catch (error) {
      this.logger.warn(`Places nearby search errored: ${error}`);
      return [];
    }
  }
}
