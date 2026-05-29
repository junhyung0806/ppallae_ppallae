import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export interface NoticeInput {
  title: string;
  content: string;
  isActive?: boolean;
  priority?: number;
  startAt?: string | null;
  endAt?: string | null;
}

export interface LaundryTypeUpdateInput {
  description?: string;
  examples?: string[];
  baseDryHoursMin?: number;
  baseDryHoursMax?: number;
  cautionText?: string | null;
  goodText?: string | null;
  badText?: string | null;
  isActive?: boolean;
}

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async dashboard() {
    const [regionCount, laundryTypeCount, noticeCount, latestWeather] =
      await Promise.all([
        this.prisma.region.count(),
        this.prisma.laundryType.count(),
        this.prisma.appNotice.count({ where: { isActive: true } }),
        this.prisma.weatherSnapshot.findFirst({
          orderBy: { createdAt: 'desc' },
          include: { region: true },
        }),
      ]);

    const recentSnapshots = await this.prisma.weatherSnapshot.groupBy({
      by: ['regionId'],
      _max: { observedAt: true },
    });

    const freshThreshold = new Date(Date.now() - 90 * 60 * 1000);
    const freshCount = recentSnapshots.filter(
      (s) => s._max.observedAt && s._max.observedAt > freshThreshold,
    ).length;

    return {
      regionCount,
      laundryTypeCount,
      activeNoticeCount: noticeCount,
      weatherCoverage: {
        regionsWithData: recentSnapshots.length,
        freshRegions: freshCount,
      },
      latestWeather: latestWeather
        ? {
            region: `${latestWeather.region.sido} ${latestWeather.region.sigungu}`,
            temperatureC: latestWeather.temperatureC,
            observedAt: latestWeather.observedAt,
            source: latestWeather.source,
          }
        : null,
    };
  }

  // ── 빨래 종류 ──

  listLaundryTypes() {
    return this.prisma.laundryType.findMany({ orderBy: { sortOrder: 'asc' } });
  }

  async updateLaundryType(code: string, input: LaundryTypeUpdateInput) {
    const exists = await this.prisma.laundryType.findUnique({ where: { code } });
    if (!exists) throw new NotFoundException(`LaundryType not found: ${code}`);
    return this.prisma.laundryType.update({ where: { code }, data: input });
  }

  // ── 공지 ──

  listNotices() {
    return this.prisma.appNotice.findMany({
      orderBy: [{ priority: 'desc' }, { createdAt: 'desc' }],
    });
  }

  createNotice(input: NoticeInput) {
    return this.prisma.appNotice.create({
      data: {
        title: input.title,
        content: input.content,
        isActive: input.isActive ?? true,
        priority: input.priority ?? 0,
        startAt: input.startAt ? new Date(input.startAt) : null,
        endAt: input.endAt ? new Date(input.endAt) : null,
      },
    });
  }

  async updateNotice(id: string, input: NoticeInput) {
    const exists = await this.prisma.appNotice.findUnique({ where: { id } });
    if (!exists) throw new NotFoundException(`Notice not found: ${id}`);
    return this.prisma.appNotice.update({
      where: { id },
      data: {
        title: input.title,
        content: input.content,
        isActive: input.isActive,
        priority: input.priority,
        startAt: input.startAt ? new Date(input.startAt) : null,
        endAt: input.endAt ? new Date(input.endAt) : null,
      },
    });
  }

  async deleteNotice(id: string) {
    const exists = await this.prisma.appNotice.findUnique({ where: { id } });
    if (!exists) throw new NotFoundException(`Notice not found: ${id}`);
    await this.prisma.appNotice.delete({ where: { id } });
    return { deleted: true };
  }

  // ── 앱 설정 ──

  listConfigs() {
    return this.prisma.appConfig.findMany({ orderBy: { key: 'asc' } });
  }

  upsertConfig(key: string, value: string, isPublic: boolean) {
    return this.prisma.appConfig.upsert({
      where: { key },
      update: { value, isPublic },
      create: { key, value, isPublic },
    });
  }

  // ── 감사 로그 ──

  async writeAuditLog(
    adminUserId: string,
    action: string,
    target?: string,
    detail?: Record<string, unknown>,
    ipAddress?: string,
  ) {
    await this.prisma.auditLog.create({
      data: {
        adminUserId,
        action,
        target,
        detail: detail as object,
        ipAddress,
      },
    });
  }

  listAuditLogs(limit = 50) {
    return this.prisma.auditLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: { adminUser: { select: { email: true, name: true } } },
    });
  }
}
