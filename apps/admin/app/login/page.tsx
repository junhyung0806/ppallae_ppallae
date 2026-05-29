'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { api, setToken } from '@/lib/api';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('admin@ppallae.dev');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = await api.login(email, password);
      setToken(res.accessToken);
      router.replace('/dashboard');
    } catch (err) {
      setError(err instanceof Error ? err.message : '로그인 실패');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <form
        onSubmit={handleSubmit}
        style={{
          background: '#fff',
          padding: 36,
          borderRadius: 16,
          width: 360,
          boxShadow: '0 8px 30px rgba(0,0,0,0.08)',
        }}
      >
        <h1 style={{ fontSize: 22, marginBottom: 4 }}>빨래빨래 관리자</h1>
        <p style={{ color: '#7a8699', fontSize: 14, marginBottom: 24 }}>
          백오피스 로그인
        </p>

        <label style={labelStyle}>이메일</label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          style={inputStyle}
          required
        />

        <label style={labelStyle}>비밀번호</label>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          style={inputStyle}
          required
        />

        {error && (
          <p style={{ color: '#d23b3b', fontSize: 13, marginBottom: 12 }}>
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={loading}
          style={{
            width: '100%',
            padding: 12,
            background: '#3a7bd5',
            color: '#fff',
            border: 'none',
            borderRadius: 8,
            fontSize: 15,
            fontWeight: 600,
            opacity: loading ? 0.6 : 1,
          }}
        >
          {loading ? '로그인 중...' : '로그인'}
        </button>
      </form>
    </div>
  );
}

const labelStyle: React.CSSProperties = {
  display: 'block',
  fontSize: 13,
  color: '#5a6677',
  marginBottom: 6,
};

const inputStyle: React.CSSProperties = {
  width: '100%',
  padding: 10,
  border: '1px solid #d7dee8',
  borderRadius: 8,
  marginBottom: 16,
  fontSize: 14,
};
