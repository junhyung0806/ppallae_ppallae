import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { RegionDto } from '../../common/dto/region.dto';
import { latLngToKmaGrid } from '../weather';

type RegionRow = {
  admCode: string;
  sido: string;
  sigungu: string;
  eupmyeondong: string;
  nx: number;
  ny: number;
};

export type RegionRecord = RegionRow & { id: string };

@Injectable()
export class RegionsService {
  constructor(private readonly prisma: PrismaService) {}

  async search(keyword: string, limit = 20): Promise<RegionDto[]> {
    const trimmed = keyword.trim();
    if (!trimmed) return [];

    const rows = await this.prisma.region.findMany({
      where: {
        OR: [
          { sido: { contains: trimmed } },
          { sigungu: { contains: trimmed } },
          { eupmyeondong: { contains: trimmed } },
        ],
      },
      orderBy: [{ sido: 'asc' }, { sigungu: 'asc' }],
      take: limit,
    });

    return rows.map(toRegionDto);
  }

  async findByCode(admCode: string): Promise<RegionRecord> {
    const region = await this.prisma.region.findUnique({ where: { admCode } });
    if (!region) {
      throw new NotFoundException(`Region not found: ${admCode}`);
    }
    return region;
  }

  async currentByLatLng(lat: number, lng: number): Promise<RegionDto> {
    const grid = latLngToKmaGrid(lat, lng);

    // 동일 격자 우선, 없으면 가장 가까운 격자 검색
    const exact = await this.prisma.region.findFirst({
      where: { nx: grid.nx, ny: grid.ny },
    });
    if (exact) return toRegionDto(exact);

    const all = await this.prisma.region.findMany({
      select: {
        admCode: true,
        sido: true,
        sigungu: true,
        eupmyeondong: true,
        nx: true,
        ny: true,
      },
    });
    if (all.length === 0) {
      throw new NotFoundException('No regions available');
    }

    let nearest = all[0];
    let minDist = gridDistance(grid.nx, grid.ny, nearest.nx, nearest.ny);
    for (const r of all) {
      const d = gridDistance(grid.nx, grid.ny, r.nx, r.ny);
      if (d < minDist) {
        minDist = d;
        nearest = r;
      }
    }
    return toRegionDto(nearest);
  }
}

function gridDistance(x1: number, y1: number, x2: number, y2: number): number {
  return (x1 - x2) ** 2 + (y1 - y2) ** 2;
}

function toRegionDto(r: RegionRow): RegionDto {
  return {
    admCode: r.admCode,
    sido: r.sido,
    sigungu: r.sigungu,
    eupmyeondong: r.eupmyeondong,
    nx: r.nx,
    ny: r.ny,
    displayName: `${r.sido} ${r.sigungu} ${r.eupmyeondong}`,
  };
}
