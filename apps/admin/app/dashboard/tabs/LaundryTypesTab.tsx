'use client';

import { useEffect, useState } from 'react';
import { api, LaundryType } from '@/lib/api';
import { Button, Card, ErrorText, PageTitle, inputStyle } from '../ui';

export function LaundryTypesTab() {
  const [types, setTypes] = useState<LaundryType[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [editing, setEditing] = useState<Record<string, { min: number; max: number }>>(
    {},
  );

  async function load() {
    try {
      const list = await api.listLaundryTypes();
      setTypes(list);
      setEditing(
        Object.fromEntries(
          list.map((t) => [
            t.code,
            { min: t.baseDryHoursMin, max: t.baseDryHoursMax },
          ]),
        ),
      );
    } catch (e) {
      setError(e instanceof Error ? e.message : '불러오기 실패');
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function save(code: string) {
    const edit = editing[code];
    setError(null);
    try {
      await api.updateLaundryType(code, {
        baseDryHoursMin: edit.min,
        baseDryHoursMax: edit.max,
      });
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : '저장 실패');
    }
  }

  return (
    <div>
      <PageTitle>빨래 종류 관리</PageTitle>
      <ErrorText message={error} />
      <div style={{ display: 'grid', gap: 16 }}>
        {types.map((t) => (
          <Card key={t.code}>
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 17, fontWeight: 700 }}>
                  {t.nameKo}{' '}
                  <span style={{ fontSize: 12, color: '#a0aab8' }}>
                    ({t.code})
                  </span>
                </div>
                <div style={{ fontSize: 13, color: '#7a8699', marginTop: 4 }}>
                  {t.examples.join(', ')}
                </div>
              </div>
            </div>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 10,
                marginTop: 14,
              }}
            >
              <label style={{ fontSize: 13, color: '#5a6677' }}>
                기준 건조시간
              </label>
              <input
                type="number"
                step="0.5"
                value={editing[t.code]?.min ?? 0}
                onChange={(e) =>
                  setEditing((prev) => ({
                    ...prev,
                    [t.code]: { ...prev[t.code], min: Number(e.target.value) },
                  }))
                }
                style={{ ...inputStyle, width: 80, marginBottom: 0 }}
              />
              <span>~</span>
              <input
                type="number"
                step="0.5"
                value={editing[t.code]?.max ?? 0}
                onChange={(e) =>
                  setEditing((prev) => ({
                    ...prev,
                    [t.code]: { ...prev[t.code], max: Number(e.target.value) },
                  }))
                }
                style={{ ...inputStyle, width: 80, marginBottom: 0 }}
              />
              <span style={{ fontSize: 13, color: '#7a8699' }}>시간</span>
              <div style={{ flex: 1 }} />
              <Button onClick={() => save(t.code)}>저장</Button>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
