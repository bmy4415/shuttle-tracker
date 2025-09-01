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
      await tester.pump();

      // 상태 변경 확인
      expect(find.text('위치 전송 중...'), findsOneWidget);
      expect(find.text('운행 종료'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);

      // 운행 종료 버튼 클릭
      await tester.tap(find.text('운행 종료'));
      await tester.pump();

      // 원래 상태로 돌아왔는지 확인
      expect(find.text('위치 전송 중지됨'), findsOneWidget);
      expect(find.text('운행 시작'), findsOneWidget);
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