'use client';

import { useEffect, useState } from 'react';
import { api, AppConfig } from '@/lib/api';
import { Button, Card, ErrorText, PageTitle, inputStyle } from '../ui';

export function ConfigsTab() {
  const [configs, setConfigs] = useState<AppConfig[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [key, setKey] = useState('');
  const [value, setValue] = useState('');
  const [isPublic, setIsPublic] = useState(true);

  async function load() {
    try {
      setConfigs(await api.listConfigs());
    } catch (e) {
      setError(e instanceof Error ? e.message : '불러오기 실패');
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function save() {
    if (!key.trim()) return;
    setError(null);
    try {
      await api.upsertConfig(key, value, isPublic);
      setKey('');
      setValue('');
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : '저장 실패');
    }
  }

  return (
    <div>
      <PageTitle>앱 설정</PageTitle>
      <Card style={{ marginBottom: 24 }}>
        <h3 style={{ marginBottom: 12, fontSize: 16 }}>설정 추가/수정</h3>
        <div style={{ display: 'flex', gap: 12 }}>
          <input
            placeholder="key"
            value={key}
            onChange={(e) => setKey(e.target.value)}
            style={{ ...inputStyle, flex: 1 }}
          />
          <input
            placeholder="value"
            value={value}
            onChange={(e) => setValue(e.target.value)}
            style={{ ...inputStyle, flex: 2 }}
          />
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <label style={{ fontSize: 13, color: '#5a6677' }}>
            <input
              type="checkbox"
              checked={isPublic}
              onChange={(e) => setIsPublic(e.target.checked)}
              style={{ marginRight: 6 }}
            />
            앱에 공개 (public)
          </label>
          <div style={{ flex: 1 }} />
          <Button onClick={save}>저장</Button>
        </div>
        <ErrorText message={error} />
      </Card>

      <Card>
        {configs.length === 0 ? (
          <p style={{ color: '#7a8699' }}>등록된 설정이 없습니다.</p>
        ) : (
          configs.map((c) => (
            <div
              key={c.key}
              style={{
                display: 'flex',
                padding: '10px 0',
                borderBottom: '1px solid #eef2f7',
                fontSize: 14,
              }}
            >
              <div style={{ width: 220, fontWeight: 600 }}>{c.key}</div>
              <div style={{ flex: 1, color: '#3a4658' }}>{c.value}</div>
              <div
                style={{
                  fontSize: 12,
                  color: c.isPublic ? '#1fa463' : '#a0aab8',
                }}
              >
                {c.isPublic ? 'public' : 'private'}
              </div>
            </div>
          ))
        )}
      </Card>
    </div>
  );
}
