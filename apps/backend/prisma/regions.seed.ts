// 주요 행정구역 시드 데이터 (기상청 nx/ny 격자 포함)
// admCode는 행정표준코드(법정동/행정동 기준 10자리)

export interface RegionSeed {
  admCode: string;
  sido: string;
  sigungu: string;
  eupmyeondong: string;
  nx: number;
  ny: number;
}

export const regions: RegionSeed[] = [
  // 서울
  { admCode: '1168010100', sido: '서울특별시', sigungu: '강남구', eupmyeondong: '역삼동', nx: 61, ny: 126 },
  { admCode: '1174010100', sido: '서울특별시', sigungu: '강동구', eupmyeondong: '명일동', nx: 62, ny: 126 },
  { admCode: '1130510100', sido: '서울특별시', sigungu: '강북구', eupmyeondong: '미아동', nx: 61, ny: 128 },
  { admCode: '1150010100', sido: '서울특별시', sigungu: '강서구', eupmyeondong: '화곡동', nx: 58, ny: 126 },
  { admCode: '1162010100', sido: '서울특별시', sigungu: '관악구', eupmyeondong: '봉천동', nx: 59, ny: 125 },
  { admCode: '1121510100', sido: '서울특별시', sigungu: '광진구', eupmyeondong: '구의동', nx: 62, ny: 126 },
  { admCode: '1153010100', sido: '서울특별시', sigungu: '구로구', eupmyeondong: '구로동', nx: 58, ny: 125 },
  { admCode: '1154510100', sido: '서울특별시', sigungu: '금천구', eupmyeondong: '시흥동', nx: 59, ny: 124 },
  { admCode: '1135010100', sido: '서울특별시', sigungu: '노원구', eupmyeondong: '상계동', nx: 61, ny: 129 },
  { admCode: '1132010100', sido: '서울특별시', sigungu: '도봉구', eupmyeondong: '쌍문동', nx: 61, ny: 129 },
  { admCode: '1123010100', sido: '서울특별시', sigungu: '동대문구', eupmyeondong: '전농동', nx: 62, ny: 127 },
  { admCode: '1159010100', sido: '서울특별시', sigungu: '동작구', eupmyeondong: '노량진동', nx: 59, ny: 125 },
  { admCode: '1144010100', sido: '서울특별시', sigungu: '마포구', eupmyeondong: '아현동', nx: 59, ny: 127 },
  { admCode: '1141010100', sido: '서울특별시', sigungu: '서대문구', eupmyeondong: '충정로', nx: 59, ny: 127 },
  { admCode: '1165010100', sido: '서울특별시', sigungu: '서초구', eupmyeondong: '서초동', nx: 61, ny: 125 },
  { admCode: '1120510100', sido: '서울특별시', sigungu: '성동구', eupmyeondong: '왕십리', nx: 61, ny: 127 },
  { admCode: '1129010100', sido: '서울특별시', sigungu: '성북구', eupmyeondong: '동선동', nx: 61, ny: 127 },
  { admCode: '1171010100', sido: '서울특별시', sigungu: '송파구', eupmyeondong: '잠실동', nx: 62, ny: 126 },
  { admCode: '1147010100', sido: '서울특별시', sigungu: '양천구', eupmyeondong: '목동', nx: 58, ny: 126 },
  { admCode: '1156010100', sido: '서울특별시', sigungu: '영등포구', eupmyeondong: '영등포동', nx: 58, ny: 126 },
  { admCode: '1117010100', sido: '서울특별시', sigungu: '용산구', eupmyeondong: '한강로', nx: 60, ny: 126 },
  { admCode: '1126010100', sido: '서울특별시', sigungu: '중랑구', eupmyeondong: '면목동', nx: 62, ny: 127 },
  { admCode: '1111010100', sido: '서울특별시', sigungu: '종로구', eupmyeondong: '청운동', nx: 60, ny: 127 },
  { admCode: '1114010100', sido: '서울특별시', sigungu: '중구', eupmyeondong: '명동', nx: 60, ny: 127 },

  // 광역시
  { admCode: '2611010100', sido: '부산광역시', sigungu: '중구', eupmyeondong: '중앙동', nx: 98, ny: 76 },
  { admCode: '2647010100', sido: '부산광역시', sigungu: '해운대구', eupmyeondong: '우동', nx: 99, ny: 75 },
  { admCode: '2711010100', sido: '대구광역시', sigungu: '중구', eupmyeondong: '동인동', nx: 89, ny: 90 },
  { admCode: '2811010100', sido: '인천광역시', sigungu: '중구', eupmyeondong: '신포동', nx: 54, ny: 124 },
  { admCode: '2911010100', sido: '광주광역시', sigungu: '동구', eupmyeondong: '충장동', nx: 58, ny: 74 },
  { admCode: '3011010100', sido: '대전광역시', sigungu: '동구', eupmyeondong: '중앙동', nx: 67, ny: 100 },
  { admCode: '3111010100', sido: '울산광역시', sigungu: '중구', eupmyeondong: '학성동', nx: 102, ny: 84 },
  { admCode: '3611010100', sido: '세종특별자치시', sigungu: '세종시', eupmyeondong: '한솔동', nx: 66, ny: 103 },

  // 경기 주요
  { admCode: '4111010100', sido: '경기도', sigungu: '수원시', eupmyeondong: '팔달구', nx: 60, ny: 121 },
  { admCode: '4113010100', sido: '경기도', sigungu: '성남시', eupmyeondong: '분당구', nx: 62, ny: 123 },
  { admCode: '4119010100', sido: '경기도', sigungu: '안양시', eupmyeondong: '만안구', nx: 59, ny: 123 },
  { admCode: '4128010100', sido: '경기도', sigungu: '고양시', eupmyeondong: '일산동구', nx: 57, ny: 129 },
  { admCode: '4146010100', sido: '경기도', sigungu: '용인시', eupmyeondong: '처인구', nx: 64, ny: 119 },

  // 강원/충청/전라/경상/제주 대표
  { admCode: '5111010100', sido: '강원특별자치도', sigungu: '춘천시', eupmyeondong: '교동', nx: 73, ny: 134 },
  { admCode: '5113010100', sido: '강원특별자치도', sigungu: '강릉시', eupmyeondong: '교동', nx: 92, ny: 131 },
  { admCode: '4311010100', sido: '충청북도', sigungu: '청주시', eupmyeondong: '상당구', nx: 69, ny: 106 },
  { admCode: '4413010100', sido: '충청남도', sigungu: '천안시', eupmyeondong: '동남구', nx: 63, ny: 110 },
  { admCode: '4711010100', sido: '경상북도', sigungu: '포항시', eupmyeondong: '남구', nx: 102, ny: 94 },
  { admCode: '4817010100', sido: '경상남도', sigungu: '창원시', eupmyeondong: '의창구', nx: 90, ny: 77 },
  { admCode: '5211010100', sido: '전북특별자치도', sigungu: '전주시', eupmyeondong: '완산구', nx: 63, ny: 89 },
  { admCode: '4611010100', sido: '전라남도', sigungu: '목포시', eupmyeondong: '용당동', nx: 50, ny: 67 },
  { admCode: '5011010100', sido: '제주특별자치도', sigungu: '제주시', eupmyeondong: '일도동', nx: 53, ny: 38 },
  { admCode: '5013010100', sido: '제주특별자치도', sigungu: '서귀포시', eupmyeondong: '서귀동', nx: 52, ny: 33 },
];
