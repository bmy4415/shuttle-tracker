import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter/services.dart';
import 'router/app_router.dart';
import 'config/firebase_config.dart';
import 'services/seed_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 로드
  await dotenv.load(fileName: ".env");

  // Firebase 초기화
  await FirebaseConfig.initialize();

  // Firebase 연결 테스트
  final isConnected = await FirebaseConfig.testConnection();
  if (!isConnected) {
    runApp(const FirebaseConnectionErrorApp());
    return;
  }

  // Initialize seed data for local development
  await SeedDataService.initialize();

  // 네이버 지도 초기화 (모바일에서만)
  if (!kIsWeb) {
    final clientId = dotenv.env['NAVER_MAPS_CLIENT_ID'];
    if (clientId != null && clientId != 'your_client_id_here') {
      await FlutterNaverMap().init(
        clientId: clientId,
        onAuthFailed: (ex) {
          print('Naver Map 인증 실패: ${ex.toString()}');
        },
      );
    }
  }

  runApp(const ShuttleTrackerApp());
}

class ShuttleTrackerApp extends StatelessWidget {
  const ShuttleTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '셔틀 트래커',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}

/// Firebase connection error screen
class FirebaseConnectionErrorApp extends StatelessWidget {
  const FirebaseConnectionErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Firebase 연결 실패',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Emulator에 연결할 수 없습니다.\n\n'
                  '확인사항:\n'
                  '1. Firebase Emulator가 실행 중인지 확인\n'
                  '2. 네트워크 연결 확인\n'
                  '3. 방화벽 설정 확인',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                if (!kIsWeb)
                  ElevatedButton.icon(
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('앱 종료'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                if (kIsWeb)
                  const Text(
                    '브라우저를 새로고침하거나 Firebase Emulator를 시작한 후 다시 시도하세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
