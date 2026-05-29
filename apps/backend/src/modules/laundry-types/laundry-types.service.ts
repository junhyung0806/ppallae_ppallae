import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class LaundryTypesService {
  constructor(private readonly prisma: PrismaService) {}

  findActive() {
    return this.prisma.laundryType.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
      select: {
        code: true,
        nameKo: true,
        description: true,
        examples: true,
        baseDryHoursMin: true,
        baseDryHoursMax: true,
        sortOrder: true,
        cautionText: true,
      },
    });
  }
}
