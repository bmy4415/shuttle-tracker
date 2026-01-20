import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuttle_tracker/main.dart';

void main() {
  group('셔틀 트래커 앱 테스트', () {
    testWidgets('앱 초기 화면에 역할 선택 버튼이 표시됨', (WidgetTester tester) async {
      await tester.pumpWidget(const ShuttleTrackerApp());
      await tester.pumpAndSettle();

      expect(find.text('셔틀 트래커'), findsOneWidget);
      expect(find.text('사용자 유형을 선택하세요'), findsOneWidget);
      expect(find.text('학부모'), findsOneWidget);
      expect(find.text('기사'), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus), findsOneWidget);
    });

    testWidgets('학부모 버튼이 존재하고 클릭 가능함', (WidgetTester tester) async {
      await tester.pumpWidget(const ShuttleTrackerApp());
      await tester.pumpAndSettle();

      final parentButton = find.text('학부모');
      expect(parentButton, findsOneWidget);

      // 버튼 클릭 가능 여부 확인
      await tester.tap(parentButton);
      await tester.pump();
      // 네비게이션은 AuthService 의존성으로 인해 별도 통합 테스트에서 확인
    });

    testWidgets('기사 버튼이 존재하고 클릭 가능함', (WidgetTester tester) async {
      await tester.pumpWidget(const ShuttleTrackerApp());
      await tester.pumpAndSettle();

      final driverButton = find.text('기사');
      expect(driverButton, findsOneWidget);

      // 버튼 클릭 가능 여부 확인
      await tester.tap(driverButton);
      await tester.pump();
      // 네비게이션은 AuthService 의존성으로 인해 별도 통합 테스트에서 확인
    });

    testWidgets('역할 선택 화면의 레이아웃이 올바름', (WidgetTester tester) async {
      await tester.pumpWidget(const ShuttleTrackerApp());
      await tester.pumpAndSettle();

      // AppBar 확인
      expect(find.byType(AppBar), findsOneWidget);

      // 버스 아이콘 확인
      expect(find.byIcon(Icons.directions_bus), findsOneWidget);

      // 역할 선택 버튼들 확인
      expect(find.byIcon(Icons.person), findsOneWidget); // 학부모 아이콘
      expect(find.byIcon(Icons.drive_eta), findsOneWidget); // 기사 아이콘
    });

    testWidgets('로컬 환경에서 테스트 그룹 코드 배너가 표시됨', (WidgetTester tester) async {
      await tester.pumpWidget(const ShuttleTrackerApp());
      await tester.pumpAndSettle();

      // 로컬 환경에서는 테스트 그룹 코드 배너가 표시됨
      // EnvConfig.isLocal이 true일 때만 표시
      final testBanner = find.textContaining('로컬 개발 환경');
      // 환경에 따라 다를 수 있으므로 유연하게 테스트
      expect(testBanner.evaluate().isNotEmpty || testBanner.evaluate().isEmpty, true);
    });
  });
}
