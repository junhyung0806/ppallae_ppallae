import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: '빨래빨래 관리자',
  description: '빨래빨래 백오피스',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
