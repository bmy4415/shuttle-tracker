import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service using SharedPreferences
/// This can be easily replaced with Firebase or other backend later
class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;

  // Singleton pattern
  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Generic methods for storing/retrieving data

  /// Save a string value
  Future<bool> saveString(String key, String value) async {
    return await _prefs!.setString(key, value);
  }

  /// Get a string value
  String? getString(String key) {
    return _prefs!.getString(key);
  }

  /// Save an integer value
  Future<bool> saveInt(String key, int value) async {
    return await _prefs!.setInt(key, value);
  }

  /// Get an integer value
  int? getInt(String key) {
    return _prefs!.getInt(key);
  }

  /// Save a boolean value
  Future<bool> saveBool(String key, bool value) async {
    return await _prefs!.setBool(key, value);
  }

  /// Get a boolean value
  bool? getBool(String key) {
    return _prefs!.getBool(key);
  }

  /// Save a list of strings
  Future<bool> saveStringList(String key, List<String> value) async {
    return await _prefs!.setStringList(key, value);
  }

  /// Get a list of strings
  List<String>? getStringList(String key) {
    return _prefs!.getStringList(key);
  }

  /// Save a JSON object (serialized as string)
  Future<bool> saveJson(String key, Map<String, dynamic> json) async {
    final jsonString = jsonEncode(json);
    return await saveString(key, jsonString);
  }

  /// Get a JSON object (deserialized from string)
  Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Save a list of JSON objects
  Future<bool> saveJsonList(String key, List<Map<String, dynamic>> jsonList) async {
    final jsonString = jsonEncode(jsonList);
    return await saveString(key, jsonString);
  }

  /// Get a list of JSON objects
  List<Map<String, dynamic>>? getJsonList(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    try {
      final decoded = jsonDecode(jsonString) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Remove a key
  Future<bool> remove(String key) async {
    return await _prefs!.remove(key);
  }

  /// Clear all data
  Future<bool> clear() async {
    return await _prefs!.clear();
  }

  /// Check if a key exists
  bool containsKey(String key) {
    return _prefs!.containsKey(key);
  }

  /// Get all keys
  Set<String> getAllKeys() {
    return _prefs!.getKeys();
  }
}