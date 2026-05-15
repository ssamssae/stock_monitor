# stock_monitor

관심종목 한국 주식 모니터링 Flutter 앱 (`com.daejongkang.stock_monitor`).

관심종목 목록 + 종목별 현재가 / 일봉 차트 화면. Yahoo Finance `.KS` 엔드포인트로 실시간 시세 조회.

## 주요 기능

- 관심종목 CRUD (추가 / 삭제)
- 종목별 현재가 + 등락률 표시
- 일봉 차트 (fl_chart)
- 로컬 저장 (`shared_preferences`)

## 데이터 소스

Yahoo Finance `query1.finance.yahoo.com` 의 `.KS` (KOSPI/KOSDAQ) 엔드포인트. 별도 API key 없이 HTTP 호출.
공공 API 안정성에 의존 — 차단되면 KRX 공공데이터 또는 다른 백엔드로 교체 필요 (BACKLOG 참조).

## 개발

```bash
flutter pub get
flutter run
```

분석:

```bash
flutter analyze
flutter test
```

## 의존성

- `http` ^1.2 — Yahoo Finance HTTP 호출
- `shared_preferences` ^2.3 — 관심종목 로컬 저장
- `fl_chart` ^0.70 — 일봉 차트
- Flutter SDK ^3.11.5

## 패키지 정보

- 패키지 ID: `com.daejongkang.stock_monitor`
- 플랫폼: Android / iOS / macOS / Linux (Flutter 멀티 타깃)
- 출시 상태: scaffold (스토어 등록 X)

## 라이선스

Private project. `publish_to: 'none'`.
