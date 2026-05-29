import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class NoticesService {
  constructor(private readonly prisma: PrismaService) {}

  findActive() {
    const now = new Date();
    return this.prisma.appNotice.findMany({
      where: {
        isActive: true,
        AND: [
          { OR: [{ startAt: null }, { startAt: { lte: now } }] },
          { OR: [{ endAt: null }, { endAt: { gte: now } }] },
        ],
      },
      orderBy: [{ priority: 'desc' }, { createdAt: 'desc' }],
      select: {
        id: true,
        title: true,
        content: true,
        priority: true,
        createdAt: true,
      },
    });
  }
}
