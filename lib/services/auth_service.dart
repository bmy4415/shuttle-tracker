import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'local_storage_service.dart';

/// Authentication service interface
/// Can be replaced with Firebase Auth later
abstract class AuthService {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> createUser(UserRole role, {String? nickname});
  Future<void> updateUser(UserModel user);
  Future<void> logout();
}

/// Local authentication service implementation
class LocalAuthService implements AuthService {
  static const String _currentUserKey = 'current_user';
  final LocalStorageService _storage;

  LocalAuthService(this._storage);

  @override
  Future<UserModel?> getCurrentUser() async {
    final json = _storage.getJson(_currentUserKey);
    if (json == null) return null;
    return UserModel.fromJson(json);
  }

  @override
  Future<UserModel> createUser(UserRole role, {String? nickname}) async {
    const uuid = Uuid();
    final user = UserModel(
      id: uuid.v4(),
      nickname: nickname ?? _generateRandomNickname(),
      role: role,
      createdAt: DateTime.now(),
    );

    await _storage.saveJson(_currentUserKey, user.toJson());
    return user;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _storage.saveJson(_currentUserKey, user.toJson());
  }

  @override
  Future<void> logout() async {
    await _storage.remove(_currentUserKey);
  }

  /// Generate random nickname (Korean style)
  String _generateRandomNickname() {
    final adjectives = [
      '야생의', '용감한', '지혜로운', '빠른', '조용한',
      '활발한', '느긋한', '친절한', '명랑한', '씩씩한',
      '귀여운', '멋진', '강한', '날쌘', '똑똑한',
    ];

    final animals = [
      '코끼리', '사자', '호랑이', '토끼', '여우',
      '늑대', '곰', '독수리', '판다', '기린',
      '다람쥐', '펭귄', '돌고래', '고래', '사슴',
    ];

    final random = Random();
    final adjective = adjectives[random.nextInt(adjectives.length)];
    final animal = animals[random.nextInt(animals.length)];

    return '$adjective $animal';
  }
}

/// Factory to get auth service instance
class AuthServiceFactory {
  static AuthService? _instance;

  static Future<AuthService> getInstance() async {
    if (_instance == null) {
      final storage = await LocalStorageService.getInstance();
      _instance = LocalAuthService(storage);
    }
    return _instance!;
  }
}