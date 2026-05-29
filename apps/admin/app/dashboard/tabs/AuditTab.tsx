'use client';

import { useEffect, useState } from 'react';
import { api, AuditLog } from '@/lib/api';
import { Card, ErrorText, PageTitle } from '../ui';

export function AuditTab() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api.auditLogs().then(setLogs).catch((e) => setError(e.message));
  }, []);

  return (
    <div>
      <PageTitle>감사 로그</PageTitle>
      <ErrorText message={error} />
      <Card>
        {logs.length === 0 ? (
          <p style={{ color: '#7a8699' }}>기록이 없습니다.</p>
        ) : (
          logs.map((log) => (
            <div
              key={log.id}
              style={{
                display: 'flex',
                padding: '10px 0',
                borderBottom: '1px solid #eef2f7',
                fontSize: 13,
              }}
            >
              <div style={{ width: 160, color: '#7a8699' }}>
                {new Date(log.createdAt).toLocaleString('ko-KR')}
              </div>
              <div style={{ width: 160, fontWeight: 600 }}>{log.action}</div>
              <div style={{ flex: 1, color: '#3a4658' }}>
                {log.target ?? '-'}
              </div>
              <div style={{ color: '#7a8699' }}>{log.adminUser.email}</div>
            </div>
          ))
        )}
      </Card>
    </div>
  );
}
