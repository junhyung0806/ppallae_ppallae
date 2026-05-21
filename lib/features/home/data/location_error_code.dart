enum LocationErrorCode {
  loc001('LOC-001'),
  loc002('LOC-002'),
  loc003('LOC-003'),
  loc004('LOC-004'),
  geo001('GEO-001'),
  geo002('GEO-002'),
  geo003('GEO-003'),
  geo004('GEO-004'),
  geo101('GEO-101'),
  geo102('GEO-102'),
  geo103('GEO-103'),
  geo104('GEO-104'),
  geo105('GEO-105'),
  geo106('GEO-106'),
  geo107('GEO-107'),
  geo108('GEO-108'),
  ui001('UI-001');

  const LocationErrorCode(this.code);

  final String code;
}
