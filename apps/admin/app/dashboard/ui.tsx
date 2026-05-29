import React from 'react';

export function Card({
  children,
  style,
}: {
  children: React.ReactNode;
  style?: React.CSSProperties;
}) {
  return (
    <div
      style={{
        background: '#fff',
        borderRadius: 12,
        padding: 20,
        boxShadow: '0 2px 10px rgba(0,0,0,0.05)',
        ...style,
      }}
    >
      {children}
    </div>
  );
}

export function PageTitle({ children }: { children: React.ReactNode }) {
  return (
    <h1 style={{ fontSize: 22, marginBottom: 20, fontWeight: 700 }}>
      {children}
    </h1>
  );
}

export function Button({
  children,
  onClick,
  variant = 'primary',
  type = 'button',
  disabled,
}: {
  children: React.ReactNode;
  onClick?: () => void;
  variant?: 'primary' | 'ghost' | 'danger';
  type?: 'button' | 'submit';
  disabled?: boolean;
}) {
  const colors = {
    primary: { bg: '#3a7bd5', fg: '#fff', border: 'none' },
    ghost: { bg: '#fff', fg: '#3a7bd5', border: '1px solid #c5d4ea' },
    danger: { bg: '#fff', fg: '#d23b3b', border: '1px solid #f0c0c0' },
  }[variant];
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      style={{
        padding: '8px 16px',
        borderRadius: 8,
        background: colors.bg,
        color: colors.fg,
        border: colors.border,
        fontSize: 14,
        fontWeight: 600,
        opacity: disabled ? 0.5 : 1,
      }}
    >
      {children}
    </button>
  );
}

export const inputStyle: React.CSSProperties = {
  width: '100%',
  padding: 10,
  border: '1px solid #d7dee8',
  borderRadius: 8,
  fontSize: 14,
  marginBottom: 12,
};

export function ErrorText({ message }: { message: string | null }) {
  if (!message) return null;
  return (
    <p style={{ color: '#d23b3b', fontSize: 13, margin: '8px 0' }}>{message}</p>
  );
}
