import { latLngToKmaGrid } from './kma-grid';

describe('latLngToKmaGrid', () => {
  it('서울 시청 (37.5665, 126.9780) → (60, 127)', () => {
    const result = latLngToKmaGrid(37.5665, 126.978);
    expect(result.nx).toBe(60);
    expect(result.ny).toBe(127);
  });

  it('부산 시청 (35.1796, 129.0756) → (98, 76)', () => {
    const result = latLngToKmaGrid(35.1796, 129.0756);
    expect(result.nx).toBe(98);
    expect(result.ny).toBe(76);
  });

  it('제주공항 (33.5067, 126.4943) → 격자값이 정수', () => {
    const result = latLngToKmaGrid(33.5067, 126.4943);
    expect(Number.isInteger(result.nx)).toBe(true);
    expect(Number.isInteger(result.ny)).toBe(true);
  });

  it('서울 강남구 (37.5172, 127.0473)', () => {
    const result = latLngToKmaGrid(37.5172, 127.0473);
    expect(result.nx).toBe(61);
    expect(result.ny).toBe(126);
  });
});
