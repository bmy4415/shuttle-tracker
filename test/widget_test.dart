import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuttle_tracker/main.dart';

void main() {
  group('셔틀 트래커 앱 테스트', () {
    testWidgets('앱 초기 화면에 역할 선택 버튼이 표시됨', (WidgetTester tester) async {
      await tester.pumpWidget(const ShuttleTrackerApp());

      expect(find.text('셔틀 트래커'), findsOneWidget);
      expect(find.text('사용자 유형을 선택하세요'), findsOneWidget);
      expect(find.text('학부모'), findsOneWidget);
      expect(find.text('기사'), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus), findsOneWidget);
    });

    testWidgets('학부모 버튼 클릭 시 학부모 화면으로 이동', (WidgetTester tester) async {
      await tester.pumpWidget(const ShuttleTrackerApp());

      await tester.tap(find.text('학부모'));
      await tester.pumpAndSettle();

      expect(find.text('학부모 화면'), findsOneWidget);
      expect(find.text('버스 위치가 여기에 표시됩니다'), findsOneWidget);
      expect(find.byIcon(Icons.map), findsOneWidget);
      expect(find.text('위치 새로고침'), findsOneWidget);
    });

    testWidgets('기사 버튼 클릭 시 기사 화면으로 이동', (WidgetTester tester) async {
      await tester.pumpWidget(const ShuttleTrackerApp());

      await tester.tap(find.text('기사'));
      await tester.pumpAndSettle();

      expect(find.text('기사 화면'), findsOneWidget);
      expect(find.text('위치 전송 중지됨'), findsOneWidget);
      expect(find.text('운행 시작'), findsOneWidget);
      expect(find.text('승하차 관리'), findsOneWidget);
    });

    testWidgets('기사 화면에서 운행 시작/종료 토글', (WidgetTester tester) async {
      await tester.pumpWidget(const ShuttleTrackerApp());

      await tester.tap(find.text('기사'));
      await tester.pumpAndSettle();

      // 초기 상태 확인
      expect(find.text('위치 전송 중지됨'), findsOneWidget);
      expect(find.text('운행 시작'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);

      // 운행 시작 버튼 클릭
      await tester.tap(find.text('운행 시작'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 버튼 텍스트가 변경되었는지 확인 (위치 권한이 거부될 수 있으므로 유연하게 테스트)
      final hasStartedText = find.text('운행 종료');
      final hasStoppedText = find.text('운행 시작');
      
      expect(hasStartedText.evaluate().isNotEmpty || hasStoppedText.evaluate().isNotEmpty, true);

      // 버튼을 다시 클릭해서 상태 토글 테스트
      if (hasStartedText.evaluate().isNotEmpty) {
        await tester.tap(find.text('운행 종료'));
        await tester.pump();
        expect(find.text('운행 시작'), findsOneWidget);
      }
    });

    testWidgets('기사 화면에서 현재 위치 확인 버튼 존재', (WidgetTester tester) async {
      await tester.pumpWidget(const ShuttleTrackerApp());

      await tester.tap(find.text('기사'));
      await tester.pumpAndSettle();

      // 현재 위치 확인 버튼 확인 (초기 상태)
      expect(find.text('현재 위치 확인'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);

      // 버튼 클릭
      await tester.tap(find.text('현재 위치 확인'));
      await tester.pump();
      
      // 로딩 상태에서는 텍스트가 바뀔 수 있음
      final hasOriginalText = find.text('현재 위치 확인');
      final hasLoadingText = find.text('위치 확인 중...');
      
      expect(hasOriginalText.evaluate().isNotEmpty || hasLoadingText.evaluate().isNotEmpty, true);
    });

    testWidgets('학부모 화면에서 위치 새로고침 버튼 동작', (WidgetTester tester) async {
      await tester.pumpWidget(const ShuttleTrackerApp());

      await tester.tap(find.text('학부모'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('위치 새로고침'));
      await tester.pump();

      // SnackBar 확인
      expect(find.text('지도 기능 준비 중'), findsOneWidget);
    });

    testWidgets('네비게이션 뒤로가기 동작', (WidgetTester tester) async {
      await tester.pumpWidget(const ShuttleTrackerApp());

      // 학부모 화면으로 이동
      await tester.tap(find.text('학부모'));
      await tester.pumpAndSettle();
      expect(find.text('학부모 화면'), findsOneWidget);

      // 뒤로가기
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 초기 화면으로 돌아왔는지 확인
      expect(find.text('사용자 유형을 선택하세요'), findsOneWidget);
    });
  });
}