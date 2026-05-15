# stock_monitor

관심종목 한국 주식 모니터링 Flutter 앱 (`com.daejongkang.stock_monitor`).

KRX (data.krx.co.kr) OTP 기반 현재가 + 일봉 차트. 관심종목 + 목표가 알림 + 포트폴리오 요약 위젯.

## 주요 기능

- 관심종목 CRUD (추가 / 삭제 / 목표가 설정)
- 실시간 현재가 + 등락률 (KRX OTP API, 전일대비 FLUC_RT 기준)
- KOSPI/KOSDAQ 지수 헤더
- 일봉 차트 (fl_chart)
- 포트폴리오 요약 위젯
- 목표가 알림 배지
- 로컬 저장 (`shared_preferences`)

## 데이터 소스

1차: KRX `data.krx.co.kr` OTP API (`/comm/bldAttendant/getJsonData.cmd` + `executeSearch.cmd`)
폴백: Yahoo Finance `query1.finance.yahoo.com` `.KS` 엔드포인트
최종 실패: mock 데이터

KRX 우선이지만 OTP 흐름이 불안정한 케이스 대비 Yahoo Finance 자동 폴백.

## 개발

```bash
flutter pub get
flutter run
```

분석 / 테스트:

```bash
flutter analyze
flutter test
```

## 의존성

- `http` ^1.2 — KRX/Yahoo HTTP 호출
- `shared_preferences` ^2.3 — 관심종목 로컬 저장
- `fl_chart` ^0.70 — 일봉 차트
- Flutter SDK ^3.11.5

## 구조

- `lib/services/krx_service.dart` — KRX OTP 기반 1차 데이터
- `lib/services/stock_service.dart` — 데이터 추상화
- `lib/services/watchlist_service.dart` — 관심종목 + 목표가 저장
- `lib/widgets/portfolio_summary_widget.dart` — 포트폴리오 요약
- `lib/screens/home_screen.dart` — 관심종목 목록
- `lib/screens/detail_screen.dart` — 종목 상세 + 차트

## 패키지 정보

- 패키지 ID: `com.daejongkang.stock_monitor`
- 플랫폼: Android / iOS / macOS / Linux (Flutter 멀티 타깃)
- 출시 상태: scaffold (스토어 등록 X)

## 라이선스

Private project. `publish_to: 'none'`.
