import 'package:shared_preferences/shared_preferences.dart';

class UserProfileManager {
  static const _keyId = 'user_id';
  static const _keyUsername = 'user_username';
  static const _keyPassword = 'user_password'; // key baru untuk password
  static const _keyBirthdate = 'user_birthdate'; // disimpan string ISO8601
  static const _keyGender = 'user_gender';
  static const _keyPublicKey = 'user_public_key';
  static const _keyIsLoggedIn = 'user_is_logged_in'; // key status login

  Future<void> saveUserProfile({
    required int id,
    required String username,
    required DateTime? birthdate,
    required String? gender,
    required String? publicKey,
    required bool isLoggedIn,
    String? password,  // parameter password opsional
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyId, id);
    await prefs.setString(_keyUsername, username);

    if (password != null) {
      await prefs.setString(_keyPassword, password);
    } else {
      await prefs.remove(_keyPassword);
    }

    if (birthdate != null) {
      await prefs.setString(_keyBirthdate, birthdate.toIso8601String());
    } else {
      await prefs.remove(_keyBirthdate);
    }

    if (gender != null) {
      await prefs.setString(_keyGender, gender);
    } else {
      await prefs.remove(_keyGender);
    }

    if (publicKey != null) {
      await prefs.setString(_keyPublicKey, publicKey);
    } else {
      await prefs.remove(_keyPublicKey);
    }

    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getInt(_keyId);
    final username = prefs.getString(_keyUsername);
    final password = prefs.getString(_keyPassword);
    final birthdateString = prefs.getString(_keyBirthdate);
    final gender = prefs.getString(_keyGender);
    final publicKey = prefs.getString(_keyPublicKey);
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

    if (id != null && username != null) {
      DateTime? birthdate;
      if (birthdateString != null) {
        birthdate = DateTime.tryParse(birthdateString);
      }
      return {
        'id': id,
        'username': username,
        'password': password,
        'birthdate': birthdate,
        'gender': gender,
        'publicKey': publicKey,
        'isLoggedIn': isLoggedIn,
      };
    }
    return null;
  }

  Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyBirthdate);
    await prefs.remove(_keyGender);
    await prefs.remove(_keyPublicKey);
    await prefs.remove(_keyIsLoggedIn);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }
}