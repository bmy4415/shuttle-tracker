# 셔틀 트래커 프로젝트 진행 상황

## 📅 작업 일자: 2025-09-01

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

## 🚀 앞으로 해야 할 작업

### Phase 1: 핵심 기능 구현 (MVP)

#### 1. 위치 추적 기능
- [ ] Geolocator 패키지 설치 및 설정
- [ ] 기사 앱: 실시간 위치 전송 구현
  - [ ] 위치 권한 요청
  - [ ] 5-10초 간격 위치 업데이트
  - [ ] 백그라운드 위치 추적
- [ ] 위치 데이터 모델 설계

#### 2. 지도 통합
- [ ] Google Maps Flutter 패키지 설치
- [ ] 학부모 앱: 지도 뷰 구현
  - [ ] 지도 표시
  - [ ] 버스 위치 마커
  - [ ] 실시간 위치 업데이트
- [ ] 네이버 지도 대안 검토 (한국 최적화)

#### 3. Firebase 백엔드 구축
- [ ] Firebase 프로젝트 생성
- [ ] FlutterFire CLI 설정
- [ ] Cloud Firestore 데이터베이스 설계
  - [ ] users 컬렉션 (학부모/기사 정보)
  - [ ] buses 컬렉션 (버스 위치 정보)
  - [ ] students 컬렉션 (학생 정보)
- [ ] 실시간 데이터 동기화 구현

#### 4. 승하차 관리
- [ ] 학생 목록 화면 구현
- [ ] 승하차 체크 기능
- [ ] 승하차 상태 실시간 동기화

#### 5. 알림 시스템
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
- **Test**: flutter_test
- **Version Control**: Git

### 예정
- **Maps**: Google Maps Flutter (또는 네이버 지도)
- **Backend**: Firebase (Firestore, Auth, FCM, Hosting)
- **Location**: Geolocator
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

---

*마지막 업데이트: 2025-09-01 23:40*