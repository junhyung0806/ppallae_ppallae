import { KmaGridPoint } from './types';

const RE = 6371.00877;
const GRID = 5.0;
const SLAT1 = 30.0;
const SLAT2 = 60.0;
const OLON = 126.0;
const OLAT = 38.0;
const XO = 43.0;
const YO = 136.0;

const DEG_TO_RAD = Math.PI / 180.0;

export function latLngToKmaGrid(latitude: number, longitude: number): KmaGridPoint {
  const reScaled = RE / GRID;
  const slat1Rad = SLAT1 * DEG_TO_RAD;
  const slat2Rad = SLAT2 * DEG_TO_RAD;
  const olonRad = OLON * DEG_TO_RAD;
  const olatRad = OLAT * DEG_TO_RAD;

  let sn =
    Math.tan(Math.PI * 0.25 + slat2Rad * 0.5) /
    Math.tan(Math.PI * 0.25 + slat1Rad * 0.5);
  sn = Math.log(Math.cos(slat1Rad) / Math.cos(slat2Rad)) / Math.log(sn);

  let sf = Math.tan(Math.PI * 0.25 + slat1Rad * 0.5);
  sf = (Math.pow(sf, sn) * Math.cos(slat1Rad)) / sn;

  let ro = Math.tan(Math.PI * 0.25 + olatRad * 0.5);
  ro = (reScaled * sf) / Math.pow(ro, sn);

  let ra = Math.tan(Math.PI * 0.25 + latitude * DEG_TO_RAD * 0.5);
  ra = (reScaled * sf) / Math.pow(ra, sn);

  let theta = longitude * DEG_TO_RAD - olonRad;
  if (theta > Math.PI) theta -= 2.0 * Math.PI;
  if (theta < -Math.PI) theta += 2.0 * Math.PI;
  theta *= sn;

  const nx = Math.floor(ra * Math.sin(theta) + XO + 0.5);
  const ny = Math.floor(ro - ra * Math.cos(theta) + YO + 0.5);
  return { nx, ny };
}
