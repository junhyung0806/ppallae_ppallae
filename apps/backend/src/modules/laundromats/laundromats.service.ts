import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface NearbyLaundromat {
  name: string;
  address: string;
  distanceMeters: number;
  latitude: number;
  longitude: number;
  phone: string | null;
  placeUrl: string | null;
}

interface KakaoPlace {
  place_name?: string;
  road_address_name?: string;
  address_name?: string;
  distance?: string;
  x?: string;
  y?: string;
  phone?: string;
  place_url?: string;
}

@Injectable()
export class LaundromatsService {
  private readonly logger = new Logger(LaundromatsService.name);
  private readonly kakaoRestKey: string;

  constructor(config: ConfigService) {
    this.kakaoRestKey = config.get<string>('KAKAO_REST_API_KEY', '');
  }

  async nearby(
    lat: number,
    lng: number,
    radiusMeters = 2000,
  ): Promise<{ source: string; items: NearbyLaundromat[] }> {
    if (!this.kakaoRestKey.trim()) {
      return { source: 'mock', items: this.mock(lat, lng) };
    }
    try {
      const items = await this.searchKakao(lat, lng, radiusMeters);
      return { source: 'kakao_local', items };
    } catch (e) {
      this.logger.warn(`kakao local search failed: ${(e as Error).message}`);
      return { source: 'mock_fallback', items: this.mock(lat, lng) };
    }
  }

  private async searchKakao(
    lat: number,
    lng: number,
    radius: number,
  ): Promise<NearbyLaundromat[]> {
    const params = new URLSearchParams({
      query: '빨래방',
      x: String(lng),
      y: String(lat),
      radius: String(radius),
      sort: 'distance',
      size: '10',
    });
    const url = `https://dapi.kakao.com/v2/local/search/keyword.json?${params.toString()}`;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);
    let res: Response;
    try {
      res = await fetch(url, {
        headers: { Authorization: `KakaoAK ${this.kakaoRestKey}` },
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timeout);
    }
    if (!res.ok) {
      throw new Error(`kakao status ${res.status}`);
    }
    const body = (await res.json()) as { documents?: KakaoPlace[] };
    const docs = body.documents ?? [];
    return docs.map((d) => ({
      name: d.place_name ?? '빨래방',
      address: d.road_address_name || d.address_name || '',
      distanceMeters: Number.parseInt(d.distance ?? '0', 10) || 0,
      latitude: Number.parseFloat(d.y ?? '0'),
      longitude: Number.parseFloat(d.x ?? '0'),
      phone: d.phone || null,
      placeUrl: d.place_url || null,
    }));
  }

  // 키 없을 때 데모용 가짜 빨래방 (현재 위치 주변에 흩뿌림)
  private mock(lat: number, lng: number): NearbyLaundromat[] {
    const names = [
      '코인워시 24시',
      '워시앤조이 셀프빨래방',
      '동네 빨래방',
      '클린업 코인세탁',
      '버블버블 빨래방',
    ];
    return names.map((name, i) => {
      const dLat = (Math.sin(i * 1.7) * 8) / 1000;
      const dLng = (Math.cos(i * 2.3) * 8) / 1000;
      const latitude = lat + dLat;
      const longitude = lng + dLng;
      const distanceMeters = Math.round(
        Math.sqrt(dLat * dLat + dLng * dLng) * 111_000,
      );
      return {
        name,
        address: '데모 데이터 (카카오 REST 키 없음)',
        distanceMeters,
        latitude,
        longitude,
        phone: null,
        placeUrl: null,
      };
    }).sort((a, b) => a.distanceMeters - b.distanceMeters);
  }
}
