# CLAUDE.md

Claude Code와 함께 작업할 때 따라야 할 프로젝트 규칙과 가이드입니다.

## 프로젝트 개요

**셔틀 트래커**: 학부모와 셔틀버스 기사를 위한 실시간 위치 추적 애플리케이션
- Flutter 기반 크로스플랫폼 앱 (Web, iOS, Android)
- PWA 우선 개발 → Native 앱 전환 전략

## 개발 규칙

### 코드 스타일
- Dart 공식 스타일 가이드 준수
- 코드 주석은 영어로 작성
- UI 텍스트는 한글 사용
- 의미 있는 변수명과 함수명 사용

### Git 커밋 규칙
```
feat: 새로운 기능 추가
fix: 버그 수정
docs: 문서 수정
style: 코드 포맷팅
refactor: 코드 리팩토링
test: 테스트 코드
chore: 빌드 업무, 패키지 매니저 수정
```

### 테스트
- 새 기능 추가 시 반드시 테스트 코드 작성
- `flutter test` 통과 확인 후 커밋
- UI 변경 시 Widget 테스트 업데이트

## 개발 명령어

```bash
# 개발
flutter run -d chrome        # 웹 브라우저 실행
flutter run -d macos         # macOS 앱 실행
flutter test                 # 테스트 실행

# Hot Restart (Flutter 앱 실행 중)
R                            # Hot Restart (앱 완전 재시작, 상태 초기화)
q                            # 앱 종료

# 빌드
flutter build web           # PWA 빌드
flutter build apk           # Android APK
flutter build ios           # iOS (Xcode 필요)

# 패키지
flutter pub add [package]   # 패키지 추가
flutter pub get             # 의존성 설치
```

## 작업 프로세스

1. **작업 시작**
   - `PROJECT_STATUS.md` 확인하여 현재 상황 파악
   - TodoWrite 도구로 작업 계획 수립

2. **개발 중**
   - 기능 구현 → 테스트 작성 → 실행 확인
   - 의미 있는 단위로 커밋

3. **작업 완료**
   - `PROJECT_STATUS.md` 업데이트 (완료 작업 체크, 다음 작업 계획)
   - 의미 있는 기능 완성 시 커밋
   - **자동 Hot Restart**: 작업 완료 후 반드시 `R` (Hot Restart) 실행
   - **중요**: 커밋할 때마다 `PROJECT_STATUS.md`도 함께 커밋하기

## 개발 및 디버깅

### Hot Restart 규칙
- **작업 완료 후 필수**: 모든 기능 구현 완료 시 `R` (Hot Restart) 실행
- **디버그 팝업**: 앱 시작시 타임스탬프 팝업으로 리스타트 확인
- **배포시 정리**: `TODO: 배포시 삭제` 주석이 있는 디버그 코드 제거

### 팝업 확인
- 앱 시작시 "🔥 Hot Restart 완료" 팝업이 뜨면 정상 작동
- 팝업에 표시된 시간으로 리스타트 시점 확인 가능

## 보안 및 주의사항

- **절대 커밋 금지**
  - API 키, 비밀번호, 토큰
  - `.env` 파일
  - Firebase 서비스 계정 키

- **권한 처리**
  - 위치 권한은 사용자 동의 필수
  - 백그라운드 권한은 별도 요청
  - 권한 거부 시 대체 동작 구현

## 기술 스택

- **Frontend**: Flutter 3.35.2
- **Language**: Dart 3.9.0
- **Package Manager**: pub
- **Version Control**: Git

## 프로젝트 문서

- **진행 상황**: `PROJECT_STATUS.md` - 작업할 때마다 업데이트
- **기획 문서**: `app_guide.md` - 프로젝트 요구사항과 분석

---

*이 문서는 프로젝트 전반의 규칙을 정의합니다. 진행 상황은 PROJECT_STATUS.md를 참조하세요.*