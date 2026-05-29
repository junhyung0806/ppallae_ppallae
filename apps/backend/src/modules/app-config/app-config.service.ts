import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AppConfigService {
  constructor(private readonly prisma: PrismaService) {}

  async getPublicConfig(): Promise<Record<string, string>> {
    const rows = await this.prisma.appConfig.findMany({
      where: { isPublic: true },
      select: { key: true, value: true },
    });
    return Object.fromEntries(rows.map((r) => [r.key, r.value]));
  }
}
