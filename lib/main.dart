import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'router/app_router.dart';
import 'config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 로드
  await dotenv.load(fileName: ".env");

  // Firebase 초기화
  await FirebaseConfig.initialize();

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
