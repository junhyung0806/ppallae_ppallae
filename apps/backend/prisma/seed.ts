import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { regions } from './regions.seed';

const prisma = new PrismaClient();

const laundryTypes = [
  {
    code: 'LIGHT',
    nameKo: '얇음',
    description: '가볍고 빨리 마르는 빨래',
    examples: ['속옷', '양말', '얇은 티셔츠', '셔츠', '운동복'],
    baseDryHoursMin: 1.0,
    baseDryHoursMax: 3.0,
    sortOrder: 1,
    cautionText: '직사광선에 오래 노출 시 변색 주의',
    goodText: '가벼운 빨래는 금방 말라요!',
    badText: '습도가 높아 얇은 빨래도 잘 안 마를 수 있어요',
  },
  {
    code: 'MEDIUM',
    nameKo: '중간',
    description: '일반적인 두께의 빨래',
    examples: ['긴팔', '맨투맨', '면바지', '수건', '니트', '침대 시트'],
    baseDryHoursMin: 3.0,
    baseDryHoursMax: 5.0,
    sortOrder: 2,
    cautionText: '두꺼운 부분이 있으면 뒤집어서 널면 좋아요',
    goodText: '일반 빨래도 무난하게 마를 날이에요',
    badText: '일반 빨래가 오늘 안에 마르기 어려울 수 있어요',
  },
  {
    code: 'HEAVY',
    nameKo: '두꺼움',
    description: '두껍고 오래 걸리는 빨래',
    examples: ['청바지', '후드티', '얇은 이불', '두꺼운 이불', '패딩'],
    baseDryHoursMin: 5.0,
    baseDryHoursMax: 14.0,
    sortOrder: 3,
    cautionText: '중간에 한 번 뒤집어주면 골고루 마릅니다. 건조기 사용도 고려해보세요',
    goodText: '두꺼운 빨래에 도전해볼 만한 날이에요!',
    badText: '두꺼운 빨래는 오늘 날씨로는 마르기 어려워요. 건조기를 추천합니다',
  },
];

async function main() {
  console.log('Seeding laundry types (3 categories)...');

  for (const lt of laundryTypes) {
    await prisma.laundryType.upsert({
      where: { code: lt.code },
      update: lt,
      create: lt,
    });
  }

  // 기존 16종 데이터 정리
  await prisma.laundryType.deleteMany({
    where: {
      code: { notIn: laundryTypes.map((lt) => lt.code) },
    },
  });

  console.log(`Seeded ${laundryTypes.length} laundry types`);

  console.log('Seeding regions...');
  for (const r of regions) {
    await prisma.region.upsert({
      where: { admCode: r.admCode },
      update: r,
      create: r,
    });
  }
  // 기존 테스트 지역 + 종속 레코드 정리
  const testRegions = await prisma.region.findMany({
    where: { admCode: { startsWith: 'TEST-' } },
    select: { id: true },
  });
  if (testRegions.length > 0) {
    const ids = testRegions.map((r) => r.id);
    await prisma.weatherSnapshot.deleteMany({ where: { regionId: { in: ids } } });
    await prisma.weatherForecastHourly.deleteMany({ where: { regionId: { in: ids } } });
    await prisma.airQualitySnapshot.deleteMany({ where: { regionId: { in: ids } } });
    await prisma.laundryScoreResult.deleteMany({ where: { regionId: { in: ids } } });
    await prisma.region.deleteMany({ where: { id: { in: ids } } });
  }
  console.log(`Seeded ${regions.length} regions`);

  // 관리자 계정
  const adminEmail = process.env.ADMIN_SEED_EMAIL ?? 'admin@ppallae.dev';
  const adminPassword = process.env.ADMIN_SEED_PASSWORD ?? 'admin1234';
  const passwordHash = await bcrypt.hash(adminPassword, 10);
  await prisma.adminUser.upsert({
    where: { email: adminEmail },
    update: {},
    create: {
      email: adminEmail,
      passwordHash,
      name: '관리자',
      role: 'SUPER_ADMIN',
    },
  });
  console.log(`Seeded admin user: ${adminEmail}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
