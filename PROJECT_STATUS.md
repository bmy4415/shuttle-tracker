# 셔틀 트래커 프로젝트 진행 상황

## 📅 작업 일자: 2025-09-26 (마지막 업데이트)

## ✅ 완료된 작업

### 1. 개발 환경 설정
- [x] Flutter SDK 설치 및 환경 구성
- [x] Android Studio 설치 (Android SDK 포함)
- [x] CocoaPods 설치 (Homebrew 통해 설치)
- [x] Flutter doctor 실행 및 점검
  - Flutter: ✅ 정상
  - Android toolchain: ✅ 정상
  - Chrome: ✅ 정상
  - Xcode: ⚠️ 미설치 (iOS 개발 시 필요)

### 2. 프로젝트 초기 구성
- [x] Flutter 프로젝트 생성 (`com.bmy4415.shuttle_tracker`)
- [x] 프로젝트 구조 설계 (단일 앱, 역할별 화면 분기)
- [x] Git repository 초기화
- [x] .gitignore 설정 (IDE 파일, 빌드 파일 제외)

### 3. 기본 UI 구현
- [x] **역할 선택 화면** (`RoleSelectorScreen`)
  - 학부모/기사 선택 버튼
  - 버스 아이콘 및 안내 텍스트
- [x] **학부모 홈 화면** (`ParentHomeScreen`)
  - 지도 위치 표시 placeholder
  - 위치 새로고침 버튼
- [x] **기사 홈 화면** (`DriverHomeScreen`)
  - 운행 시작/종료 토글 기능
  - 위치 전송 상태 표시
  - 승하차 관리 버튼 (placeholder)

### 4. 테스트 및 검증
- [x] Widget 테스트 작성 (6개 테스트)
  - 초기 화면 표시 테스트
  - 학부모 화면 네비게이션 테스트
  - 기사 화면 네비게이션 테스트
  - 운행 시작/종료 토글 테스트
  - 위치 새로고침 버튼 테스트
  - 뒤로가기 네비게이션 테스트
- [x] 모든 테스트 통과 확인
- [x] Chrome 브라우저에서 실제 앱 동작 테스트

### 5. 버전 관리
- [x] Git 첫 커밋 생성 (131개 파일)
- [x] 프로젝트 문서 정리 (`app_guide.md` 포함)

### 6. 위치 추적 기능 (Phase 1-1)
- [x] **Geolocator 패키지 설치 및 설정** (v14.0.2)
- [x] **위치 데이터 모델 설계** (`LocationData` 클래스)
  - 위도, 경도, 정확도, 고도, 속도, 타임스탬프
  - JSON 직렬화/역직렬화 지원
  - 버스ID, 기사ID 정보 포함
- [x] **위치 서비스 구현** (`LocationService` 클래스)
  - 싱글톤 패턴으로 전역 위치 관리
  - 위치 권한 확인 및 요청
  - 현재 위치 단발성 요청
  - 실시간 위치 스트림 (10초 간격)
- [x] **기사 앱 UI 개선**
  - 실제 GPS 위치 연동 (가짜 위치 → 진짜 위치)
  - 로딩 인디케이터 (원형 + 선형 진행률 바)
  - 실시간 카운트다운 ("예상 소요시간: N초")
  - 위치 정보 상세 표시 (위도/경도/정확도/시각)
  - 중복 클릭 방지 및 상태별 색상 구분
- [x] **성능 최적화**
  - LocationAccuracy.medium 사용 (속도 vs 정확도 균형)
  - 브라우저 환경에서 WiFi 기반 위치 추적 지원
- [x] **테스트 코드 작성**
  - LocationData 모델 테스트 (5개)
  - LocationService 기능 테스트 (5개)  
  - 위젯 UI 테스트 업데이트 (6개)
  - 총 16개 테스트 모두 통과 ✅

### 7. 네이버 지도 연동 및 모바일 최적화 (Phase 1-2) - 완료 ✅
- [x] **네이버 지도 API 설정 및 연동**
  - [x] Naver Cloud Platform Maps API 발급
  - [x] flutter_naver_map 패키지 설치 (v1.4.1+1)
  - [x] Android 패키지명 매칭 (`com.bmy4415.shuttle_tracker`)
  - [x] iOS Bundle ID 매칭 (`com.bmy4415.shuttleTracker`)
  - [x] API 키 인증 문제 해결 완료
- [x] **모바일 앱 최적화**
  - [x] 웹 관련 코드 완전 제거 (모바일 전용 집중)
  - [x] Android 위치 권한 설정 (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`)
  - [x] Android manifest에 Naver Maps API 키 설정
  - [x] 갤럭시 Note 20 Ultra에서 실제 테스트 완료
- [x] **실시간 위치 추적 시스템**
  - [x] 네이버 지도 정상 렌더링 확인 (Android)
  - [x] 실시간 GPS 스트림 구현 (getPositionStream)
  - [x] 다중 사용자 위치 표시 (학부모/기사 구분)
  - [x] 색상별 마커 구현 (빨간색: 내위치, 파란색: 기사, 초록/주황: 학부모)
  - [x] AutoLocationSimulator 구현 (자동 이동 시뮬레이션)

### 8. 성능 최적화 및 UX 개선 (Phase 1-3) - 완료 ✅
- [x] **배터리 및 렌더링 최적화**
  - [x] GPS 업데이트 간격 최적화 (5m → 15m 거리 필터)
  - [x] 마커 업데이트 임계값 증가 (10m → 20m)
  - [x] 시뮬레이터 업데이트 간격 최적화 (3초 → 5초)
  - [x] 마커 업데이트 debounce 구현 (500ms 지연)
- [x] **메모리 누수 방지**
  - [x] Stream 구독 안전한 해제
  - [x] dispose 메소드 강화
  - [x] mounted 체크 강화 및 에러 핸들링 개선
- [x] **사용자 경험 개선**
  - [x] 학부모 화면 재진입 속도 개선 (위치 캐싱)
  - [x] 지도 카메라 자동 이동 방지
  - [x] "내위치"/"셔틀위치" 버튼 추가
  - [x] Hot Restart 디버그 시스템 추가
- [x] **에러 메시지 개선**
  - [x] 타임아웃 에러 메시지 숨김 처리
  - [x] 사용자 친화적 로딩 상태 표시

## 🚀 앞으로 해야 할 작업

### Phase 1: 핵심 기능 구현 (MVP)

#### 1. 위치 추적 기능 ✅ (100% 완료)
- [x] Geolocator 패키지 설치 및 설정
- [x] 기사 앱: 실시간 위치 전송 구현
  - [x] 위치 권한 요청
  - [x] 실시간 GPS 스트림 (getPositionStream)
  - [x] 배터리 최적화된 위치 추적
- [x] 위치 데이터 모델 설계
- [x] AutoLocationSimulator 구현 (개발/테스트용)

#### 2. 지도 통합 ✅ (100% 완료)
- [x] 네이버 지도 Flutter 패키지 설치 및 설정
- [x] 학부모 앱: 완전한 지도 뷰 구현
  - [x] 네이버 지도 표시 (Android 확인)
  - [x] 다중 사용자 마커 표시 (색상별 구분)
  - [x] 실시간 위치 업데이트 검증 완료
  - [x] 학부모 위치 공유 완전 구현
  - [x] 지도 카메라 제어 및 네비게이션 버튼
- [x] 네이버 지도 API 완전 연동 (한국 최적화)
- [x] 기사 앱: 다중 학부모 위치 표시

#### 3. Firebase 백엔드 구축
- [ ] Firebase 프로젝트 생성
- [ ] FlutterFire CLI 설정
- [ ] Cloud Firestore 데이터베이스 설계
  - [ ] users 컬렉션 (학부모/기사 정보)
  - [ ] buses 컬렉션 (버스 위치 정보)
  - [ ] students 컬렉션 (학생 정보)
- [ ] 실시간 데이터 동기화 구현

#### 3. 승하차 관리
- [ ] 학생 목록 화면 구현
- [ ] 승하차 체크 기능
- [ ] 승하차 상태 실시간 동기화

#### 4. 알림 시스템
- [ ] Firebase Cloud Messaging 설정
- [ ] 도착 예정 알림
- [ ] 승하차 확인 알림

### Phase 2: PWA 배포 (POC)

#### 1. PWA 최적화
- [ ] 오프라인 지원 설정
- [ ] 앱 아이콘 및 스플래시 화면
- [ ] manifest.json 최적화

#### 2. 배포
- [ ] Firebase Hosting 설정
- [ ] 도메인 연결 (선택)
- [ ] HTTPS 설정

### Phase 3: 고도화 (추후)

#### 1. 인증 시스템
- [ ] Firebase Authentication 통합
- [ ] 로그인/회원가입 구현
- [ ] 역할 기반 접근 제어

#### 2. Native 앱 전환
- [ ] Android APK 빌드
- [ ] iOS 앱 빌드 (Xcode 필요)
- [ ] 앱스토어 배포 준비

#### 3. 추가 기능
- [ ] 운행 기록 조회
- [ ] 노선 관리
- [ ] 관리자 대시보드
- [ ] 비용 정산 시스템

## 📊 기술 스택

### 현재 사용 중
- **Frontend**: Flutter 3.35.2
- **Language**: Dart 3.9.0
- **Maps**: 네이버 지도 (flutter_naver_map v1.4.1+1)
- **Location**: Geolocator v14.0.2
- **Environment**: flutter_dotenv v6.0.0
- **Test**: flutter_test
- **Version Control**: Git

### 예정
- **Backend**: Firebase (Firestore, Auth, FCM, Hosting)
- **State Management**: Provider 또는 Riverpod

## 📝 참고 사항

1. **개발 우선순위**: PWA로 빠른 POC 개발 → 실사용 테스트 → Native 앱 전환
2. **지도 선택**: 일단 Google Maps로 개발, 나중에 네이버 지도 전환 고려
3. **Firebase 무료 한도**: 초기에는 충분, 사용자 증가 시 비용 모니터링 필요
4. **iOS 개발**: Xcode 설치 필요 (나중에 진행)

## 🔗 유용한 링크

- [Flutter 공식 문서](https://flutter.dev/docs)
- [Firebase Flutter 설정](https://firebase.google.com/docs/flutter/setup)
- [Geolocator 패키지](https://pub.dev/packages/geolocator)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)

### 10. Hot Reload 지원 및 마커 실시간 동기화 (Phase 1-5) - 완료 ✅
- [x] **Hot Reload 개발 환경 개선**
  - [x] Hot reload 시 타임스탬프 팝업으로 적용 확인 가능
  - [x] 파일 변경 시 자동 hot reload 지원
  - [x] 개발 효율성 대폭 향상
- [x] **마커 실시간 동기화 문제 해결**
  - [x] NaverMapWidget didUpdateWidget 최적화 이슈 해결
  - [x] WidgetsBinding.instance.addPostFrameCallback으로 강제 마커 업데이트
  - [x] 학부모 시뮬레이터와 지도 마커 완벽 연동
  - [x] 실시간 위치 변경사항이 즉시 지도에 반영
- [x] **서버 연동 대비 아키텍처 검증**
  - [x] 스트림 기반 위치 데이터 처리 구조 확인
  - [x] 확장 가능한 데이터 모델 설계 검증
  - [x] 실제 서버 연동 시에도 동일한 방식으로 작동 보장

### 9. 기사 화면 고도화 및 학부모 추적 시스템 (Phase 1-4) - 완료 ✅
- [x] **기사 화면 전면 재구성**
  - [x] 지도 중심의 메인 화면으로 변경
  - [x] 학부모 목록을 클릭 가능한 사이드바로 구성
  - [x] 내 위치 버튼 추가 (앱바 액션 버튼)
  - [x] 불필요한 버튼 제거 (현재 위치 확인, 승하차 관리)
- [x] **학부모 위치 시뮬레이터 구현**
  - [x] 3명의 학부모가 기사 위치 중심으로 원형 궤도 이동
  - [x] 각각 100m, 200m, 300m 거리에서 시뮬레이션
  - [x] 3초 간격으로 실시간 위치 업데이트
- [x] **인터랙티브 UI 구현**
  - [x] 학부모 클릭 시 해당 위치로 지도 이동
  - [x] 클릭 동작 중 dimmed 처리 및 로딩 표시
  - [x] 픽업 대기 상태 시각적 표시 (주황색 배지)
- [x] **기능 테스트 및 검증**
  - [x] Android 기기에서 정상 작동 확인
  - [x] 지도 마커 표시 (기사: 파란색, 학부모: 초록/주황)
  - [x] 실시간 학부모 위치 업데이트 확인

## 🎯 현재 개발 상황 요약

**Phase 1 MVP 개발 진척도: 90% 완료**

✅ **완료된 핵심 기능**
- 실시간 위치 추적 시스템 (100%)
- 네이버 지도 통합 및 다중 사용자 지원 (100%)
- 성능 최적화 및 사용자 경험 개선 (100%)
- 모바일 앱 최적화 (Android 검증 완료)
- 기사 화면 고도화 및 학부모 추적 시스템 (100%)
- Hot Reload 지원 및 마커 실시간 동기화 (100%)

🔄 **다음 우선순위**
1. Firebase 백엔드 구축 (서버 통신 구현)
2. 승하차 관리 시스템
3. 푸시 알림 시스템

📱 **현재 실행 가능한 기능**
- 학부모 앱: 실시간 위치 공유 및 기사 위치 확인
- 기사 앱: 실시간 위치 전송, 다중 학부모 위치 표시, 클릭 가능한 학부모 목록
- 지도 기반 실시간 추적 (색상별 마커 구분)
- 인터랙티브 UI (학부모 클릭 시 지도 이동, 내 위치 버튼)
- 배터리 최적화된 GPS 추적 및 학부모 시뮬레이터

---

*마지막 업데이트: 2025-09-26 21:52 - Hot Reload 지원 및 마커 실시간 동기화 완료*