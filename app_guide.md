

# **학부모 및 셔틀버스 기사용 실시간 위치 추적 애플리케이션 개발 전략 보고서**

## **보고서 요약 및 핵심 권고사항**

본 보고서는 학부모와 셔틀버스 기사를 위한 실시간 위치 추적 애플리케이션 개발에 대한 포괄적인 전략을 제시합니다. 사용자의 요구사항을 면밀히 분석하고, 시장의 유사 서비스 및 기술 동향을 심층적으로 검토한 결과, 최소 기능 제품(MVP)을 구현하기 위한 가장 효율적이고 전략적인 기술 스택 및 개발 로드맵을 다음과 같이 권고합니다.

**핵심 제언:** 애플리케이션의 프론트엔드는 Flutter 프레임워크를, 백엔드는 Firebase 플랫폼을 활용하여 MVP를 개발하는 것을 강력히 권장합니다.

**주요 권고사항에 대한 근거 요약:**

* **프론트엔드 (Flutter):** Flutter는 단일 코드베이스로 iOS와 Android 두 플랫폼의 앱을 동시에 구축할 수 있어 개발 시간과 리소스를 획기적으로 절감합니다. Windows와 macOS 개발 환경을 모두 지원하며, Hot Reload와 같은 효율적인 개발 기능은 Claude Code와 같은 AI 도구와의 시너지를 극대화하여 학습 및 개발 곡선을 최소화하는 데 최적의 선택입니다.  
* **백엔드 (Firebase):** Firebase는 서버 구축 및 관리에 대한 부담을 제거하는 BaaS(Backend as a Service) 솔루션입니다. 특히 Cloud Firestore는 실시간 데이터 동기화 기능이 뛰어나 셔틀버스 위치 정보와 같은 실시간 데이터 처리에 완벽하게 부합합니다. MVP 단계에서 백엔드 개발의 복잡성을 최소화하고 프론트엔드 기능 구현에 집중할 수 있도록 돕습니다.  
* **MVP 접근법:** MVP를 통해 핵심 기능인 '실시간 위치 추적'과 '도착 알림', '승하차 확인'에 집중하여 시장의 초기 반응을 빠르게 확인하고, 향후 '운행 관리', '비용 정산', '안전 관리' 등 B2B SaaS 모델로의 확장을 위한 기반을 마련하는 전략을 제안합니다.

본 보고서의 내용은 단순한 기술적 권고를 넘어, 사용자님의 아이디어를 시장성 있는 서비스로 발전시키기 위한 비즈니스 및 기술적 의사결정 과정을 상세히 담고 있습니다.

## **1단계: 최소 기능 제품(MVP) 정의 및 사용자 경험 설계**

성공적인 서비스 개발의 첫걸음은 불필요한 기능을 과감히 배제하고 시장에서 가장 절실한 문제를 해결하는 핵심 기능에 집중하는 것입니다. 이를 위해 학부모와 셔틀버스 기사라는 두 사용자 그룹의 고유한 요구사항을 중심으로 MVP(Minimum Viable Product)를 정의했습니다.

### **1.1. 학부모 앱: 핵심 기능 및 사용자 흐름**

학부모는 아이의 등하원 시 셔틀버스가 어디에 있는지 파악하여 불필요한 대기 시간을 줄이고 싶어 합니다. 이는 단순한 위치 확인을 넘어, ‘언제 나가야 아이를 바로 태울 수 있을지'에 대한 예측 가능성을 제공하는 것이 본질적인 가치입니다.

* **핵심 기능 (MVP):**  
  * **실시간 셔틀버스 위치 확인:** 지도상에서 배정된 셔틀버스의 현재 위치를 실시간으로 추적하는 기능이 가장 핵심적입니다.1 경쟁 서비스인 '셔틀나우', '스쿨붕붕이', '라이드' 등이 공통적으로 제공하는 기능으로, 학부모의 가장 기본적인 불편을 해소합니다.  
  * **도착 예상 시간 및 알림:** 단순 위치 마커를 넘어, 버스가 지정된 정류장에 도착하기까지 남은 시간을 예측하여 알려주는 기능은 학부모의 대기 시간을 최소화하는 데 결정적인 역할을 합니다.4 '버스 도착 5분 전', '도착 완료'와 같은 푸시 알림을 제공함으로써 학부모가 앱을 계속 주시하지 않아도 되도록 사용자 편의성을 극대화할 수 있습니다.5  
  * **탑승/하차 확인 알림:** 아이가 버스에 탑승하거나 하차했을 때 학부모에게 자동으로 푸시 알림을 보내는 기능은 아이의 안전을 확인하고 안심시키는 중요한 요소입니다.7  
* **MVP 사용자 흐름:**  
  1. **로그인:** 서비스 운영사(예: 유치원, 학원)가 발급한 계정으로 앱에 로그인합니다.3  
  2. **버스 선택:** 등/하원할 버스 노선을 선택합니다.  
  3. **위치 확인:** 지도 화면에서 버스의 실시간 위치와 예상 도착 시간을 확인합니다.  
  4. **알림 수신:** 버스가 정류장에 근접하거나 아이가 승/하차할 때 알림을 받습니다.

### **1.2. 셔틀버스 기사 앱: 핵심 기능 및 사용자 흐름**

사용자 질의에서 명확히 제시된 것처럼, 셔틀버스 기사에게 어떤 기능이 필요한지에 대한 깊은 고민이 필요합니다. 동종 서비스 분석에 따르면, 기사 앱은 단순 위치 정보 전송을 넘어 기사의 운행 업무를 보조하고, 학부모와의 소통 부담을 경감시키는 '운행 매니저' 역할을 수행해야 합니다.3

* **핵심 기능 (MVP):**  
  * **위치정보 전송 시작/종료:** 기사가 운행을 시작할 때 버튼을 눌러 자신의 위치 정보를 시스템에 전송하고, 운행 종료 시 전송을 중단하는 기능이 필수적입니다. 이 기능은 학부모 앱에 버스 위치를 표시하는 핵심 트리거 역할을 합니다.11  
  * **승하차 확인:** 각 정류장에서 아이가 승하차할 때, 기사가 앱의 간단한 인터페이스를 통해 탑승 여부를 체크할 수 있도록 합니다. 이 작업은 백엔드 시스템에 즉시 기록되어 학부모에게 자동 알림을 보내는 기반이 됩니다.7 이로써 운전 중 학부모에게 일일이 전화나 메시지를 보내야 했던 기존의 불편과 불안 요소를 제거할 수 있습니다.3  
* **MVP 사용자 흐름:**  
  1. **로그인:** 배정된 운행 정보와 연동된 계정으로 로그인합니다.  
  2. **운행 시작:** '운행 시작' 버튼을 누르면 위치 전송이 시작되고, 해당 노선을 이용하는 학부모 앱에 버스 위치가 표시됩니다.  
  3. **등하원 관리:** 각 정류장에서 아이들의 승하차 여부를 버튼 하나로 간편하게 체크합니다.  
  4. **운행 종료:** 마지막 운행이 끝난 후 '운행 종료' 버튼을 눌러 위치 전송을 중단합니다.

### **1.3. MVP 기능 및 사용자 유형별 요구사항 비교**

아래 표는 학부모와 셔틀버스 기사 양측의 주요 요구사항을 통합하여 MVP에 포함될 핵심 기능을 명확히 정리한 것입니다. 이는 개발 우선순위를 설정하고 양면적 사용자 그룹의 니즈를 동시에 충족시키는 데 필수적인 지침이 됩니다.

| 사용자 유형 | 필수 기능 (MVP) | 기능의 목적 | 근거 |
| :---- | :---- | :---- | :---- |
| **학부모** | 실시간 위치 확인 (지도) | 버스의 현재 위치 파악 | 1 |
|  | 도착 예상 시간 및 알림 | 대기 시간 최소화 | 4 |
|  | 아이 탑승/하차 확인 알림 | 아이의 안전 확인 및 안심 | 7 |
| **기사** | 위치정보 전송 제어 | 학부모 앱의 위치 정보 활성화 | 11 |
|  | 승하차 확인 기록 | 학부모 자동 알림 트리거 | 3 |

## **2단계: 기술 스택 및 개발 환경 추천**

두 가지 상이한 개발 환경(Windows, macOS)에서 iOS와 Android 앱을 모두 지원해야 하는 요구사항을 충족시키려면 '크로스 플랫폼' 개발이 가장 합리적인 해결책입니다.12 이는 단일 코드베이스로 두 플랫폼을 모두 커버하여 개발 시간과 비용을 획기적으로 절감할 수 있기 때문입니다. 주요 후보군인

Flutter와 React Native에 대한 심층 분석을 통해 최적의 기술 스택을 제안합니다.

### **2.1. 프론트엔드/모바일 개발 환경 및 프레임워크 선택**

#### **2.1.1. Flutter: 크로스 플랫폼 개발을 위한 최적의 선택지**

Flutter는 Google이 개발한 UI 툴킷으로, 단일 코드베이스로 네이티브 컴파일 앱을 만들 수 있는 강력한 프레임워크입니다.12

* **뛰어난 성능:** Flutter는 자체 렌더링 엔진인 Skia를 사용하므로, React Native의 JavaScript Bridge와 같은 중간 과정을 거치지 않습니다. 이는 위치 추적과 같이 실시간으로 UI가 갱신되어야 하는 애플리케이션에서 네이티브에 가까운 부드러운 성능과 애니메이션을 보장합니다.14  
* **러닝 커브 최소화 및 AI 시너지:** Flutter는 Dart라는 새로운 언어를 사용해야 하지만, UI 구성 방식이 직관적인 위젯(Widget) 기반이라 학습이 용이합니다.15 특히, 공식 문서가 매우 체계적으로 잘 정리되어 있어 14  
  Claude Code와 같은 AI 모델이 정확하고 상세한 코드 예시를 생성하기에 최적의 환경을 제공합니다. 개발 초보자가 가장 어려워하는 환경 설정 및 오류 해결 과정에서도 flutter doctor 명령을 통해 누락된 구성 요소를 쉽게 파악하고, AI의 도움을 받아 문제 해결 단계를 간소화할 수 있습니다.16  
* **효율적인 개발 환경:** Flutter는 Windows와 macOS에서 동일한 CLI(명령줄 인터페이스)를 통해 개발 환경을 손쉽게 구축할 수 있습니다. 또한, 코드를 수정하면 앱에 즉시 변경사항을 반영하는 강력한 Hot Reload 기능은 개발 속도를 획기적으로 가속화합니다.14

#### **2.1.2. React Native: 대안으로서의 장단점 분석**

React Native는 Facebook이 개발한 프레임워크로, 웹 개발자에게 매우 친숙한 JavaScript 기반의 크로스 플랫폼 개발 환경을 제공합니다.15

* **장점:** JavaScript/TypeScript에 익숙하다면 빠르게 적응할 수 있으며 15,  
  NPM 기반의 방대한 패키지 생태계를 활용할 수 있다는 장점이 있습니다.15 또한, 앱 스토어 심사 없이  
  JavaScript 코드를 업데이트할 수 있는 CodePush 기능은 버그에 대한 신속한 대응을 가능하게 합니다.19  
* **단점:** JavaScript Bridge를 통해 네이티브 코드와 통신하므로 Flutter 대비 성능 저하 가능성이 있습니다.14 플랫폼별 UI가 미묘하게 달라 추가적인 스타일 작업이 필요할 수 있으며 20, 복잡한 네이티브 기능 디버깅이 까다롭다는 단점이 있습니다.15

#### **2.1.3. 최종 권고: Flutter 선택의 정당성**

MVP 구현에 있어 가장 중요한 가치는 개발 효율성과 사용자에게 제공하는 핵심 경험의 안정성입니다. Flutter는 단일 코드베이스의 효율성, 뛰어난 성능, 그리고 AI 도구와의 시너지를 통해 이 두 가지 가치를 모두 충족시킵니다. React Native의 CodePush 기능은 매력적이지만, 복잡한 UI나 애니메이션이 적은 MVP 단계에서는 Flutter의 성능적, 구조적 장점이 더 부각됩니다.

### **2.2. 백엔드 아키텍처 및 데이터베이스 선택**

MVP 단계에서는 서버 인프라 구축 및 관리에 소요되는 시간과 비용을 최소화하는 것이 중요합니다. 따라서 백엔드 개발의 복잡성을 줄여주는 BaaS(Backend as a Service) 솔루션이 가장 적합합니다.

#### **2.2.1. BaaS (Backend as a Service) 솔루션: Firebase**

Google의 Firebase는 사용자 인증, 실시간 데이터베이스, 파일 스토리지 등 모바일 앱 개발에 필요한 모든 백엔드 기능을 제공하는 플랫폼입니다.

* **실시간 데이터 동기화:** Firebase의 Cloud Firestore 데이터베이스는 실시간 리스너를 통해 데이터가 변경될 때마다 연결된 모든 클라이언트 앱에 자동으로 동기화됩니다.21 이는 기사 앱이 전송하는 버스의 실시간 위치 정보를 학부모 앱에 즉각적으로 반영하는 데 완벽하게 부합합니다.  
* **서버리스 아키텍처:** 개발자는 서버를 직접 구축하거나 관리할 필요 없이, Firebase가 제공하는 관리형 서비스를 통해 백엔드 기능을 구현할 수 있습니다. 이는 개발 초기 단계의 인프라 운영 부담을 없애고, 프론트엔드 기능 개발에 집중할 수 있게 합니다.23  
* **Flutter와의 원활한 통합:** Firebase는 FlutterFire CLI를 통해 Flutter 프로젝트와의 연동을 매우 간편하게 지원합니다.25 몇 가지 명령어만으로 모든 설정이 완료되어 개발 효율성을 극대화할 수 있습니다.

#### **2.2.2. 백엔드 프레임워크 대안: Node.js, Django**

장기적으로 서비스가 성장하고 복잡한 커스텀 비즈니스 로직이 필요해질 경우, Node.js와 Django는 좋은 대안이 될 수 있습니다.

* **Node.js:** JavaScript 기반의 런타임 환경으로, 비동기 I/O 모델을 통해 실시간 데이터 처리 및 동시 접속 처리에 매우 강력한 성능을 보여줍니다.26  
  Flutter의 Dart 언어와 JavaScript는 문법적 유사성이 있어 개발자 풀 확보에 유리합니다.  
* **Django:** Python 기반의 프레임워크로, 안정성과 보안이 뛰어나며 복잡한 데이터 모델링과 관리자 기능을 손쉽게 구현할 수 있습니다.28

#### **2.2.3. 데이터베이스 설계: Cloud Firestore를 중심으로**

실시간 위치 정보는 수많은 데이터 포인트가 연속적으로 발생하는 스트림 형태의 데이터입니다. 이러한 특성상 관계형 데이터베이스(RDBMS)보다 NoSQL 데이터베이스가 더 효율적입니다. Cloud Firestore는 문서 기반의 NoSQL 데이터베이스로, 비정형 데이터를 효율적으로 저장하고 쿼리하는 데 유리합니다.22

* **MVP 데이터 모델 (초안):**  
  * **users 컬렉션:** 사용자 계정 정보(학부모, 기사).  
  * **buses 컬렉션:** 각 버스의 실시간 위치(location 필드), 운행 상태(status), 담당 기사 정보(driver\_id) 등을 문서 형태로 저장합니다.  
  * **routes 컬렉션:** 노선 정보(경로, 정류장 목록).  
  * **students 컬렉션:** 아이 정보(탑승 버스, 등하원 상태).  
* **BaaS의 양날의 검:** Firebase는 MVP 개발에 최적의 솔루션이지만, 서비스가 성공하여 수만 명의 사용자가 동시 접속하게 되면 위치 데이터의 읽기/쓰기 횟수가 기하급수적으로 증가하게 됩니다. 이 때 Firebase의 종량제 비용은 예상보다 훨씬 커질 수 있으며 24, 복잡하고 세밀한 비즈니스 로직 구현에 제약이 따를 수 있습니다. 따라서  
  Firebase는 MVP를 위한 전략적 선택으로, 장기적으로는 Node.js와 같은 커스텀 백엔드로의 전환 가능성을 열어두는 것이 현명합니다.

### **2.3. 풀 스택 기술 스택 종합 권장사항**

| 역할 | 기술 스택 | 세부 사항 |
| :---- | :---- | :---- |
| **개발 환경** | Windows & macOS | 두 환경 모두에서 개발 가능 |
| **모바일 OS** | iOS & Android | 단일 코드베이스로 두 플랫폼 동시 지원 |
| **프론트엔드** | Flutter | 강력한 성능, 빠른 개발, 러닝 커브 최소화 |
| **백엔드** | Firebase | 서버 관리 부담 해소, 빠른 MVP 구축 |
| **데이터베이스** | Cloud Firestore | 실시간 데이터 동기화에 최적화된 NoSQL DB |

## **3단계: 개발 및 운영 전략 제안**

MVP 개발은 단순히 기술 스택을 선택하는 것을 넘어, 안정적인 서비스 운영을 위한 구체적인 구현 방안과 장기적인 비즈니스 로드맵을 함께 고민해야 합니다.

### **3.1. 개발 환경 구축 상세 가이드**

권고된 기술 스택을 기반으로 Windows와 macOS 환경에서 개발 환경을 구축하는 절차는 다음과 같습니다.

* **필수 소프트웨어:**  
  * Flutter SDK: Flutter 공식 웹사이트에서 다운로드하여 설치합니다.  
  * Android Studio: Android 앱 개발 및 에뮬레이터 구동을 위해 필수적입니다.  
  * Xcode (macOS 전용): iOS 앱을 빌드하고 시뮬레이터를 사용하기 위해 반드시 설치해야 합니다.16  
  * Visual Studio Code: 가볍고 강력한 에디터로, Flutter 확장팩을 설치하여 개발할 수 있습니다.  
* **환경 변수 설정:** Windows에서는 '시스템 환경 변수 편집' 메뉴를 통해, macOS에서는 \~/.zshrc 또는 \~/.bash\_profile 파일을 편집하여 Flutter SDK 경로를 등록해야 합니다.16  
* **환경 점검:** 터미널에서 flutter doctor 명령을 실행하여 설치된 구성 요소와 누락된 항목을 점검하고, 필요한 도구(Android licenses, Xcode CLI tools 등)를 추가로 설치합니다.16  
* **Firebase 연동:** Firebase CLI와 FlutterFire CLI를 전역 설치한 후, flutterfire configure 명령을 통해 Flutter 프로젝트를 Firebase 프로젝트와 쉽게 연결할 수 있습니다.25

### **3.2. 위치정보 시스템(RTLS) 구현 방안**

셔틀버스 위치 정보는 GPS(Global Positioning System) 기술을 기반으로 구현됩니다. 기사 앱은 GPS 신호를 활용하여 차량의 위치를 파악하고, 이 정보를 백엔드 시스템에 전송합니다.

* **위치정보 획득:** 기사 앱은 Android의 FusedLocationProviderClient 또는 iOS의 Core Location 서비스와 같은 플랫폼별 위치 정보 제공자를 통해 GPS 좌표를 얻습니다.33  
* **백엔드 통신:** 획득한 위치 데이터(위도, 경도)를 5\~10초 간격으로 Cloud Firestore의 해당 버스 문서에 업데이트합니다.  
* **실시간 동기화:** 학부모 앱은 해당 버스 문서에 대한 실시간 리스너를 설정하여, 위치 정보가 업데이트될 때마다 자동으로 지도상의 버스 마커를 이동시킵니다.

**위치정보의 '신뢰성' 확보 문제:** 쿠팡 셔틀 앱의 사용자 후기에서 '앱이 나가있으면 시간이 흐르지 않는다'는 지적이 있었습니다.6 이는 앱이 백그라운드에서 실행될 때 OS의 배터리 최적화 정책 등으로 인해 위치 정보 전송이 원활하지 않을 수 있음을 시사합니다. 이러한 상황은 학부모에게 부정확한 정보를 제공하여 서비스 신뢰도를 떨어뜨릴 수 있습니다. 따라서 MVP 단계부터 백그라운드 위치 서비스 권한을 명시적으로 요청하고,

Firebase Cloud Functions와 같은 서버리스 기능을 활용하여 일정 시간 위치 업데이트가 없을 시 기사에게 푸시 알림을 보내는 등의 예외 처리 로직을 설계해야 합니다. 이는 단순히 기능 구현을 넘어 서비스의 안정성과 신뢰성을 확보하는 데 필수적인 요소입니다.

### **3.3. 향후 로드맵: MVP를 넘어선 서비스 확장 방안**

MVP가 시장 검증에 성공하면, 다음과 같은 단계적인 로드맵을 통해 서비스를 고도화하고 B2B SaaS(Software as a Service) 모델로 확장할 수 있습니다.

1. **Phase 1 (MVP):** 실시간 위치 추적, 도착/승하차 알림 등 핵심 기능 구현에 집중합니다.  
2. **Phase 2 (기능 고도화):**  
   * **통합 관리자 웹 대시보드:** 유치원이나 학원 운영자가 버스 운행 현황, 승하차 이력, 운행 일지 등을 웹에서 한눈에 모니터링할 수 있는 대시보드를 구축합니다.4  
   * **운행 스케줄 관리:** 버스 노선, 기사, 학생 명단을 관리하고, AI 기반의 최적 경로 추천 기능을 도입하여 운행 효율성을 높입니다.4  
   * **알림 기능 확장:** 날씨나 도로 상황으로 인한 운행 지연/결행 공지를 등록하고 학부모에게 일괄 푸시 알림을 보내는 기능을 추가합니다.5  
   * **커뮤니케이션 채널:** 앱 내 채팅 기능을 통해 기사-학부모-관리자 간의 소통을 원활하게 합니다.2  
3. **Phase 3 (비즈니스 모델 확장):**  
   * **차량비 정산 시스템:** 학생별 탑승 횟수를 자동 기록하고, 이를 기반으로 차량비를 정확하게 정산하여 학부모에게 안내하는 기능을 도입합니다.4  
   * **안전 관리 시스템:** 운전자의 운행 습관에 따른 안전 운행 지수를 산출하여 관리자에게 제공하고, 차량 내 센서(안전벨트 착용 확인, 문 끼임 방지 등)와 연동하여 안전성을 강화합니다.4  
   * **수요응답형 교통 (DRT) 모델 도입:** 정해진 노선이 아닌, 실시간 호출에 대응하는 기업 통근 셔틀 등으로 서비스 영역을 확장하여 새로운 수익 모델을 창출합니다.34

## **결론 및 최종 제언**

사용자의 아이디어는 학부모와 셔틀버스 기사 양측의 명확한 불편을 해소하는 동시에, 학교/학원 운영사의 효율성까지 개선하는 혁신적인 잠재력을 지니고 있습니다. 성공적인 서비스 개발을 위해서는 기술적 선택뿐만 아니라, 사용자의 진정한 불편함을 해결하는 기능적 고민과 장기적인 비즈니스 모델을 염두에 두는 전략적 사고가 중요합니다.

Flutter와 Firebase를 활용한 MVP 개발은 아이디어를 현실로 구현하는 가장 빠르고 효율적인 전략입니다. 이 기술 스택은 두 가지 개발 환경과 두 개의 모바일 플랫폼을 모두 지원하며, Claude Code와의 시너지를 통해 개발 효율성을 극대화합니다. 본 보고서에 제시된 MVP 로드맵을 기반으로, 핵심 기능에 집중하여 시장의 반응을 확인하고, 사용자의 피드백을 반영하며 점진적으로 서비스를 고도화해 나갈 것을 권고합니다.

#### **참고 자료**

1. Citymapper \- Google Play 앱, 8월 29, 2025에 액세스, [https://play.google.com/store/apps/details?id=com.citymapper.app.release\&hl=ko](https://play.google.com/store/apps/details?id=com.citymapper.app.release&hl=ko)  
2. App Store에서 제공하는 셔틀나우 \- 통근/통학버스 위치확인 \- Apple, 8월 29, 2025에 액세스, [https://apps.apple.com/kr/app/%EC%85%94%ED%8B%80%EB%82%98%EC%9A%B0-%ED%86%B5%EA%B7%BC-%ED%86%B5%ED%95%99%EB%B2%84%EC%8A%A4-%EC%9C%84%EC%B9%98%ED%99%95%EC%9D%B8/id1446534080](https://apps.apple.com/kr/app/%EC%85%94%ED%8B%80%EB%82%98%EC%9A%B0-%ED%86%B5%EA%B7%BC-%ED%86%B5%ED%95%99%EB%B2%84%EC%8A%A4-%EC%9C%84%EC%B9%98%ED%99%95%EC%9D%B8/id1446534080)  
3. App Store에서 제공하는 스쿨붕붕이 \- Apple, 8월 29, 2025에 액세스, [https://apps.apple.com/kr/app/%EC%8A%A4%EC%BF%A8%EB%B6%95%EB%B6%95%EC%9D%B4/id1153942530](https://apps.apple.com/kr/app/%EC%8A%A4%EC%BF%A8%EB%B6%95%EB%B6%95%EC%9D%B4/id1153942530)  
4. 라이드(RIDE) \- 스마트한 통학 차량 관리 서비스, 8월 29, 2025에 액세스, [https://www.ride.bz/](https://www.ride.bz/)  
5. 부모님 \- 버스가 온다, 8월 29, 2025에 액세스, [https://herecomesthebus.com/ko/%EB%B6%80%EB%AA%A8%EB%8B%98/](https://herecomesthebus.com/ko/%EB%B6%80%EB%AA%A8%EB%8B%98/)  
6. App Store에서 제공하는 쿠팡 셔틀, 8월 29, 2025에 액세스, [https://apps.apple.com/kr/app/%EC%BF%A0%ED%8C%A1-%EC%85%94%ED%8B%80/id1465877881](https://apps.apple.com/kr/app/%EC%BF%A0%ED%8C%A1-%EC%85%94%ED%8B%80/id1465877881)  
7. 컴온버스 \- 셔틀버스 도착 알림 서비스, 8월 29, 2025에 액세스, [http://comeonbus.co.kr/](http://comeonbus.co.kr/)  
8. \[국민의 기업\] '어린이 안심 통학버스 서비스' 개편 … 앱으로 우리 아이 승·하차 정보 확인, 8월 29, 2025에 액세스, [https://www.joongang.co.kr/article/22218925](https://www.joongang.co.kr/article/22218925)  
9. 스쿨버스 – 안전한 통학 차량 서비스, 8월 29, 2025에 액세스, [https://www.safeschoolbus.net/](https://www.safeschoolbus.net/)  
10. \[스케일업\] 스쿨버스 \[1\] “우리 아이들의 안전한 통학을 책임집니다” \- Daum, 8월 29, 2025에 액세스, [https://v.daum.net/v/20230721184808689](https://v.daum.net/v/20230721184808689)  
11. 실시간 위치추적 시스템(RTLS)란? :: ORBRO 블로그, 8월 29, 2025에 액세스, [https://orbro.io/blog/rtls](https://orbro.io/blog/rtls)  
12. 네이티브와 크로스 플랫폼 어플리케이션 그리고 하이브리드 앱, 8월 29, 2025에 액세스, [https://klmhyeonwooo.tistory.com/120](https://klmhyeonwooo.tistory.com/120)  
13. Xamarin vs. 네이티브 개발 vs. 기타 하이브리드 및 크로스 플랫폼 프레임 워크, 8월 29, 2025에 액세스, [http://prosenic.com/xamarin-vs-native-development-vs-other-hybrid-and-cross-platform-frameworks-9.html](http://prosenic.com/xamarin-vs-native-development-vs-other-hybrid-and-cross-platform-frameworks-9.html)  
14. 플러터(Flutter) 개발자가 된 이유 \- Medium, 8월 29, 2025에 액세스, [https://medium.com/@khkong/flutter-%EA%B0%9C%EB%B0%9C%EC%9E%90%EA%B0%80-%EB%90%9C-%EC%9D%B4%EC%9C%A0-eade34bc027](https://medium.com/@khkong/flutter-%EA%B0%9C%EB%B0%9C%EC%9E%90%EA%B0%80-%EB%90%9C-%EC%9D%B4%EC%9C%A0-eade34bc027)  
15. React Native vs Flutter: 어떤 것을 선택해야 할까? \- DEV Community, 8월 29, 2025에 액세스, [https://dev.to/solleedata/react-native-vs-flutter-eoddeon-geoseul-seontaeghaeya-halgga-12cn](https://dev.to/solleedata/react-native-vs-flutter-eoddeon-geoseul-seontaeghaeya-halgga-12cn)  
16. Flutter 설치와 개발환경 셋팅 2025 (윈도우 / 맥) \- 코딩애플 온라인 강좌, 8월 29, 2025에 액세스, [https://codingapple.com/unit/flutter-install-on-windows-and-mac/](https://codingapple.com/unit/flutter-install-on-windows-and-mac/)  
17. 플러터 환경 설정 하기(윈도우) \- 책덕후 개발자 \- 티스토리, 8월 29, 2025에 액세스, [https://javaclick.tistory.com/38](https://javaclick.tistory.com/38)  
18. \[Flutter\] 플러터 개발환경 세팅 (MAC/VSCode) \- 숨참고 CODE DIVE \- 티스토리, 8월 29, 2025에 액세스, [https://breath-codedive.tistory.com/entry/Flutter-%ED%94%8C%EB%9F%AC%ED%84%B0-%EA%B0%9C%EB%B0%9C%ED%99%98%EA%B2%BD-%EC%84%B8%ED%8C%85-MACVSCode](https://breath-codedive.tistory.com/entry/Flutter-%ED%94%8C%EB%9F%AC%ED%84%B0-%EA%B0%9C%EB%B0%9C%ED%99%98%EA%B2%BD-%EC%84%B8%ED%8C%85-MACVSCode)  
19. \[RN\] React-Native의 장단점은? \- Medium, 8월 29, 2025에 액세스, [https://medium.com/@jang.wangsu/rn-react-native%EC%9D%98-%EC%9E%A5%EB%8B%A8%EC%A0%90%EC%9D%80-6e8a2396eea1](https://medium.com/@jang.wangsu/rn-react-native%EC%9D%98-%EC%9E%A5%EB%8B%A8%EC%A0%90%EC%9D%80-6e8a2396eea1)  
20. React Native 장단점과 CLI, Expo 비교와 후기 \- LasBe's Upgrade \- 티스토리, 8월 29, 2025에 액세스, [https://lasbe.tistory.com/171](https://lasbe.tistory.com/171)  
21. Firestore | Firebase \- Google, 8월 29, 2025에 액세스, [https://firebase.google.com/docs/firestore](https://firebase.google.com/docs/firestore)  
22. Difference between realtime and firestore database \- Firebase \- Reddit, 8월 29, 2025에 액세스, [https://www.reddit.com/r/Firebase/comments/19819et/difference\_between\_realtime\_and\_firestore\_database/](https://www.reddit.com/r/Firebase/comments/19819et/difference_between_realtime_and_firestore_database/)  
23. Choosing the Right Backend Framework for Flutter Apps: Performance, Scalability, and Security \- TRooTech, 8월 29, 2025에 액세스, [https://www.trootech.com/blog/backend-framekwork-flutter-app-guide](https://www.trootech.com/blog/backend-framekwork-flutter-app-guide)  
24. Choosing between Amazon Amplify and Firebase for Flutter Apps \- Walturn, 8월 29, 2025에 액세스, [https://www.walturn.com/insights/choosing-between-amazon-amplify-and-firebase-for-flutter-apps](https://www.walturn.com/insights/choosing-between-amazon-amplify-and-firebase-for-flutter-apps)  
25. Add Firebase to your Flutter app, 8월 29, 2025에 액세스, [https://firebase.google.com/docs/flutter/setup](https://firebase.google.com/docs/flutter/setup)  
26. Node js Mobile Development: Guide to Building Scalable Apps \- Soft Suave, 8월 29, 2025에 액세스, [https://www.softsuave.com/blog/node-js-mobile-development/](https://www.softsuave.com/blog/node-js-mobile-development/)  
27. Complete Guide to Node JS for mobile apps development, 8월 29, 2025에 액세스, [https://www.aphelia.co/blogs/node-js-for-mobile-apps](https://www.aphelia.co/blogs/node-js-for-mobile-apps)  
28. Building a Full-Stack App with Django and React Native \- Scope Technical, 8월 29, 2025에 액세스, [https://scopetechnical.com/recruiting-blog/f/building-a-full-stack-app-with-django-and-react-native](https://scopetechnical.com/recruiting-blog/f/building-a-full-stack-app-with-django-and-react-native)  
29. React Native and Django for Beginners \- Crowdbotics, 8월 29, 2025에 액세스, [https://crowdbotics.com/posts/blog/react-native-django-for-beginners/](https://crowdbotics.com/posts/blog/react-native-django-for-beginners/)  
30. NoSQL 데이타 모델링 \#1-데이타모델과, 모델링 절차 \- 조대협 \- 티스토리, 8월 29, 2025에 액세스, [https://bcho.tistory.com/665](https://bcho.tistory.com/665)  
31. Amplify vs. Firebase: Which Is Best Suited for Your Project? \- BairesDev, 8월 29, 2025에 액세스, [https://www.bairesdev.com/blog/amplify-vs-firebase-which-one-is-best/](https://www.bairesdev.com/blog/amplify-vs-firebase-which-one-is-best/)  
32. \[Flutter\] 개발 환경 세팅 \- macOS, 8월 29, 2025에 액세스, [https://jutole.tistory.com/153](https://jutole.tistory.com/153)  
33. 마지막으로 알려진 위치 가져오기 | Sensors and location \- Android Developers, 8월 29, 2025에 액세스, [https://developer.android.com/develop/sensors-and-location/location/retrieve-current?hl=ko](https://developer.android.com/develop/sensors-and-location/location/retrieve-current?hl=ko)  
34. 씨엘모빌리티, 삼성전자에 수요응답 셔틀버스 플랫폼 공급, 8월 29, 2025에 액세스, [https://www.aitimes.com/news/articleView.html?idxno=155799](https://www.aitimes.com/news/articleView.html?idxno=155799)  
35. 씨엘모빌리티, 수요응답형 셔틀버스 플랫폼 공급 \- 정보통신신문, 8월 29, 2025에 액세스, [https://www.koit.co.kr/news/articleView.html?idxno=119111](https://www.koit.co.kr/news/articleView.html?idxno=119111)