import 'package:flutter/material.dart';

/// 핀 꼬리를 그리는 커스텀 페인터
class PinTailPainter extends CustomPainter {
  final Color color;

  PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(0, 0); // 왼쪽 위
    path.lineTo(size.width, 0); // 오른쪽 위
    path.lineTo(size.width / 2, size.height); // 중앙 아래(뛰족한 끝)
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 커스텀 마커 위젯들을 생성하는 헬퍼 클래스
class CustomMarkerWidgets {

  /// 기사 마커 (핀 모양 - 파란색 버스)
  static Widget driverMarker({String? label}) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 라벨 (위에 표시)
            if (label != null)
              Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            // 핀 몸체 (원형)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 20,
              ),
            ),
            // 핀 꼬리 (삼각형) - 끝이 아래로
            CustomPaint(
              size: const Size(10, 15),
              painter: PinTailPainter(color: Colors.blue.shade600),
            ),
          ],
        ),
      ],
    );
  }

  /// 학부모 마커 (핀 모양 - 상태별 색상)
  static Widget parentMarker({
    required String name,
    required bool isWaitingForPickup,
  }) {
    final MaterialColor primaryColor = isWaitingForPickup ? Colors.orange : Colors.green;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 이름 라벨 (위에 표시)
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.shade600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // 핀 몸체 (원형)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isWaitingForPickup ? Icons.front_hand : Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
            // 핀 꼬리 (삼각형) - 끝이 아래로
            CustomPaint(
              size: const Size(10, 15),
              painter: PinTailPainter(color: primaryColor.shade600),
            ),
          ],
        ),
      ],
    );
  }

  /// 현재 사용자 마커 (핀 모양 - 내 위치)
  static Widget currentUserMarker({required bool isDriver}) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "내 위치" 라벨
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Text(
                '내 위치',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // 핀 몸체 (원형) - 빨간색으로 강조
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isDriver ? Icons.directions_bus : Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
            // 핀 꼬리 (삼각형) - 끝이 아래로
            CustomPaint(
              size: const Size(10, 15),
              painter: PinTailPainter(color: Colors.red.shade600),
            ),
          ],
        ),
      ],
    );
  }

  /// 펄스 애니메이션 효과가 있는 현재 사용자 마커
  static Widget animatedCurrentUserMarker({required bool isDriver}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 펄스 효과 (바깥쪽 원)
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.2),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.4),
          ),
        ),
        // 메인 마커
        currentUserMarker(isDriver: isDriver),
      ],
    );
  }

  /// 학부모 상태별 배지
  static Widget statusBadge({required bool isWaitingForPickup}) {
    if (!isWaitingForPickup) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade600,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '픽업 대기',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}