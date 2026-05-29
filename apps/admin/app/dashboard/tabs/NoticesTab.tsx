'use client';

import { useEffect, useState } from 'react';
import { api, Notice } from '@/lib/api';
import { Button, Card, ErrorText, PageTitle, inputStyle } from '../ui';

export function NoticesTab() {
  const [notices, setNotices] = useState<Notice[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [priority, setPriority] = useState(0);
  const [saving, setSaving] = useState(false);

  async function load() {
    try {
      setNotices(await api.listNotices());
    } catch (e) {
      setError(e instanceof Error ? e.message : '불러오기 실패');
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function create() {
    if (!title.trim() || !content.trim()) return;
    setSaving(true);
    setError(null);
    try {
      await api.createNotice({ title, content, priority });
      setTitle('');
      setContent('');
      setPriority(0);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : '생성 실패');
    } finally {
      setSaving(false);
    }
  }

  async function toggleActive(n: Notice) {
    await api.updateNotice(n.id, {
      title: n.title,
      content: n.content,
      isActive: !n.isActive,
      priority: n.priority,
    });
    await load();
  }

  async function remove(id: string) {
    if (!confirm('이 공지를 삭제할까요?')) return;
    await api.deleteNotice(id);
    await load();
  }

  return (
    <div>
      <PageTitle>공지 관리</PageTitle>

      <Card style={{ marginBottom: 24 }}>
        <h3 style={{ marginBottom: 12, fontSize: 16 }}>새 공지 작성</h3>
        <input
          placeholder="제목"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          style={inputStyle}
        />
        <textarea
          placeholder="내용"
          value={content}
          onChange={(e) => setContent(e.target.value)}
          style={{ ...inputStyle, minHeight: 80, resize: 'vertical' }}
        />
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <label style={{ fontSize: 13, color: '#5a6677' }}>우선순위</label>
          <input
            type="number"
            value={priority}
            onChange={(e) => setPriority(Number(e.target.value))}
            style={{ ...inputStyle, width: 80, marginBottom: 0 }}
          />
          <div style={{ flex: 1 }} />
          <Button onClick={create} disabled={saving}>
            {saving ? '저장 중...' : '공지 추가'}
          </Button>
        </div>
        <ErrorText message={error} />
      </Card>

      <Card>
        {notices.length === 0 ? (
          <p style={{ color: '#7a8699' }}>등록된 공지가 없습니다.</p>
        ) : (
          notices.map((n) => (
            <div
              key={n.id}
              style={{
                display: 'flex',
                alignItems: 'center',
                padding: '12px 0',
                borderBottom: '1px solid #eef2f7',
              }}
            >
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600 }}>
                  {n.title}{' '}
                  <span
                    style={{
                      fontSize: 12,
                      color: n.isActive ? '#1fa463' : '#a0aab8',
                      marginLeft: 6,
                    }}
                  >
                    {n.isActive ? '● 활성' : '○ 비활성'}
                  </span>
                </div>
                <div style={{ fontSize: 13, color: '#7a8699', marginTop: 2 }}>
                  {n.content}
                </div>
              </div>
              <div style={{ display: 'flex', gap: 8 }}>
                <Button variant="ghost" onClick={() => toggleActive(n)}>
                  {n.isActive ? '비활성화' : '활성화'}
                </Button>
                <Button variant="danger" onClick={() => remove(n.id)}>
                  삭제
                </Button>
              </div>
            </div>
          ))
        )}
      </Card>
    </div>
  );
}
