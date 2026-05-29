const API_BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api/v1';

const TOKEN_KEY = 'ppallae_admin_token';

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return window.localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string) {
  window.localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken() {
  window.localStorage.removeItem(TOKEN_KEY);
}

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
  ) {
    super(message);
  }
}

async function request<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const token = getToken();
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (!res.ok) {
    let message = `요청 실패 (${res.status})`;
    try {
      const body = await res.json();
      if (body.message) message = Array.isArray(body.message) ? body.message.join(', ') : body.message;
    } catch {
      // ignore
    }
    throw new ApiError(message, res.status);
  }

  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

export const api = {
  login: (email: string, password: string) =>
    request<{ accessToken: string; admin: { email: string; name: string; role: string } }>(
      '/admin/auth/login',
      { method: 'POST', body: JSON.stringify({ email, password }) },
    ),
  dashboard: () => request<DashboardData>('/admin/dashboard'),
  listLaundryTypes: () => request<LaundryType[]>('/admin/laundry-types'),
  updateLaundryType: (code: string, data: Partial<LaundryType>) =>
    request<LaundryType>(`/admin/laundry-types/${code}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),
  listNotices: () => request<Notice[]>('/admin/notices'),
  createNotice: (data: NoticeInput) =>
    request<Notice>('/admin/notices', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  updateNotice: (id: string, data: NoticeInput) =>
    request<Notice>(`/admin/notices/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),
  deleteNotice: (id: string) =>
    request<{ deleted: boolean }>(`/admin/notices/${id}`, { method: 'DELETE' }),
  listConfigs: () => request<AppConfig[]>('/admin/configs'),
  upsertConfig: (key: string, value: string, isPublic: boolean) =>
    request<AppConfig>('/admin/configs', {
      method: 'PUT',
      body: JSON.stringify({ key, value, isPublic }),
    }),
  auditLogs: () => request<AuditLog[]>('/admin/audit-logs?limit=30'),
};

export interface DashboardData {
  regionCount: number;
  laundryTypeCount: number;
  activeNoticeCount: number;
  weatherCoverage: { regionsWithData: number; freshRegions: number };
  latestWeather: {
    region: string;
    temperatureC: number;
    observedAt: string;
    source: string;
  } | null;
}

export interface LaundryType {
  code: string;
  nameKo: string;
  description: string;
  examples: string[];
  baseDryHoursMin: number;
  baseDryHoursMax: number;
  cautionText: string | null;
  isActive: boolean;
}

export interface Notice {
  id: string;
  title: string;
  content: string;
  isActive: boolean;
  priority: number;
  createdAt: string;
}

export interface NoticeInput {
  title: string;
  content: string;
  isActive?: boolean;
  priority?: number;
}

export interface AppConfig {
  key: string;
  value: string;
  isPublic: boolean;
}

export interface AuditLog {
  id: string;
  action: string;
  target: string | null;
  createdAt: string;
  adminUser: { email: string; name: string };
}
