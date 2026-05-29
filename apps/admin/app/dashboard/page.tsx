'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { clearToken, getToken } from '@/lib/api';
import { DashboardTab } from './tabs/DashboardTab';
import { NoticesTab } from './tabs/NoticesTab';
import { LaundryTypesTab } from './tabs/LaundryTypesTab';
import { ConfigsTab } from './tabs/ConfigsTab';
import { AuditTab } from './tabs/AuditTab';

const TABS = [
  { key: 'dashboard', label: '대시보드' },
  { key: 'notices', label: '공지 관리' },
  { key: 'laundry-types', label: '빨래 종류' },
  { key: 'configs', label: '앱 설정' },
  { key: 'audit', label: '감사 로그' },
] as const;

type TabKey = (typeof TABS)[number]['key'];

export default function DashboardPage() {
  const router = useRouter();
  const [tab, setTab] = useState<TabKey>('dashboard');
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!getToken()) {
      router.replace('/login');
    } else {
      setReady(true);
    }
  }, [router]);

  function logout() {
    clearToken();
    router.replace('/login');
  }

  if (!ready) return null;

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      <aside
        style={{
          width: 220,
          background: '#1a2230',
          color: '#fff',
          padding: '24px 0',
        }}
      >
        <div style={{ padding: '0 24px 24px', fontSize: 18, fontWeight: 700 }}>
          빨래빨래 🧺
        </div>
        <nav>
          {TABS.map((t) => (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              style={{
                display: 'block',
                width: '100%',
                textAlign: 'left',
                padding: '12px 24px',
                backgroundColor: tab === t.key ? '#2c3a52' : 'transparent',
                color: tab === t.key ? '#fff' : '#9aa7b5',
                border: 'none',
                fontSize: 14,
              }}
            >
              {t.label}
            </button>
          ))}
        </nav>
        <button
          onClick={logout}
          style={{
            margin: '24px',
            padding: '8px 16px',
            background: 'transparent',
            color: '#9aa7b5',
            border: '1px solid #3a4658',
            borderRadius: 6,
            fontSize: 13,
          }}
        >
          로그아웃
        </button>
      </aside>

      <main style={{ flex: 1, padding: 32, overflow: 'auto' }}>
        {tab === 'dashboard' && <DashboardTab />}
        {tab === 'notices' && <NoticesTab />}
        {tab === 'laundry-types' && <LaundryTypesTab />}
        {tab === 'configs' && <ConfigsTab />}
        {tab === 'audit' && <AuditTab />}
      </main>
    </div>
  );
}
