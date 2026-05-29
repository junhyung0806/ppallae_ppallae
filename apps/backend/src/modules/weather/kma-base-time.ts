// KMA API base date/time 계산 헬퍼

export function formatKmaDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}${month}${day}`;
}

export function formatKmaTime(date: Date): string {
  const hour = String(date.getHours()).padStart(2, '0');
  const minute = String(date.getMinutes()).padStart(2, '0');
  return `${hour}${minute}`;
}

export function latestUltraNcstBase(now: Date): Date {
  const aligned = new Date(now);
  aligned.setMinutes(0, 0, 0);
  if (now.getMinutes() < 45) {
    aligned.setHours(aligned.getHours() - 1);
  }
  return aligned;
}

export function latestUltraFcstBase(now: Date): Date {
  const aligned = new Date(now);
  aligned.setMinutes(30, 0, 0);
  if (now.getMinutes() < 45) {
    aligned.setHours(aligned.getHours() - 1);
  }
  return aligned;
}

export function latestVillageFcstBase(now: Date): Date {
  const candidates = [23, 20, 17, 14, 11, 8, 5, 2];
  const adjusted = new Date(now);
  if (now.getMinutes() < 10) {
    adjusted.setHours(adjusted.getHours() - 1);
  }
  for (const hour of candidates) {
    if (
      adjusted.getHours() > hour ||
      (adjusted.getHours() === hour && adjusted.getMinutes() >= 10)
    ) {
      const result = new Date(adjusted);
      result.setHours(hour, 0, 0, 0);
      return result;
    }
  }
  const previousDay = new Date(adjusted);
  previousDay.setDate(previousDay.getDate() - 1);
  previousDay.setHours(23, 0, 0, 0);
  return previousDay;
}
