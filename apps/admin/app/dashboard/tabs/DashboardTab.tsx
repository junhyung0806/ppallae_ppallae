'use client';

import { useEffect, useState } from 'react';
import { api, DashboardData } from '@/lib/api';
import { Card, PageTitle, ErrorText } from '../ui';

export function DashboardTab() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api.dashboard().then(setData).catch((e) => setError(e.message));
  }, []);

  if (error) return <ErrorText message={error} />;
  if (!data) return <p>불러오는 중...</p>;

  const stats = [
    { label: '등록 지역', value: data.regionCount },
    { label: '빨래 종류', value: data.laundryTypeCount },
    { label: '활성 공지', value: data.activeNoticeCount },
    {
      label: '날씨 수집 지역',
      value: `${data.weatherCoverage.freshRegions}/${data.weatherCoverage.regionsWithData}`,
    },
  ];

  return (
    <div>
      <PageTitle>대시보드</PageTitle>
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(4, 1fr)',
          gap: 16,
          marginBottom: 24,
        }}
      >
        {stats.map((s) => (
          <Card key={s.label}>
            <div style={{ fontSize: 13, color: '#7a8699' }}>{s.label}</div>
            <div style={{ fontSize: 30, fontWeight: 700, marginTop: 8 }}>
              {s.value}
            </div>
          </Card>
        ))}
      </div>

      <Card>
        <h3 style={{ marginBottom: 12, fontSize: 16 }}>최근 날씨 수집</h3>
        {data.latestWeather ? (
          <div style={{ fontSize: 14, color: '#3a4658', lineHeight: 1.8 }}>
            <div>지역: {data.latestWeather.region}</div>
            <div>기온: {data.latestWeather.temperatureC}°C</div>
            <div>출처: {data.latestWeather.source}</div>
            <div>
              관측 시각:{' '}
              {new Date(data.latestWeather.observedAt).toLocaleString('ko-KR')}
            </div>
          </div>
        ) : (
          <p style={{ color: '#7a8699' }}>아직 수집된 날씨 데이터가 없습니다.</p>
        )}
      </Card>
    </div>
  );
}
