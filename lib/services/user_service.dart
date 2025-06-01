import 'package:basic_utils/basic_utils.dart';
import 'package:hive/hive.dart';
import 'package:project_tpm/utils/rsa_helper.dart';
import '../models/user.dart';

class UserService {
  final Box<User> userBox = Hive.box<User>('users');

  // ADD USER
  Future<bool> addUser(User user) async {
    // Cek jika username sudah ada
    final existingUser = userBox.values.where((u) => u.username == user.username);
    if (existingUser.isNotEmpty) return false;

    final publicKey = await RSAHelper.getPublicKey();
    if (publicKey == null) return false;

    final encryptedPassword = await RSAHelper.encrypt(user.password, publicKey);

    final newUser = User(
      username: user.username,
      password: encryptedPassword,
      gender: user.gender,
      dateOfBirth: user.dateOfBirth,
      publicKey: CryptoUtils.encodeRSAPublicKeyToPem(publicKey),
    );

    // Auto-increment ID: ambil id tertinggi lalu +1
    final maxId = userBox.keys
        .whereType<int>()
        .fold<int>(0, (prev, k) => k > prev ? k : prev);
    final newId = maxId + 1;
    newUser.id = newId;

    await userBox.put(newId, newUser);
    return true;
  }

  // LOGIN
  Future<bool> login(String username, String passwordInput) async {
    final matchingUsers = userBox.values.where((u) => u.username == username);
    if (matchingUsers.isEmpty) return false;

    final user = matchingUsers.first;

    final privateKey = await RSAHelper.getPrivateKey();
    if (privateKey == null) return false;

    final decryptedPassword = await RSAHelper.decrypt(user.password, privateKey);
    return decryptedPassword == passwordInput;
  }

  // UPDATE
  Future<bool> updateUser(int id, User updatedUser) async {
    try {
      await userBox.put(id, updatedUser);
      return true;
    } catch (e) {
      print("Error updating user: $e");
      return false;
    }
  }

  // DELETE
  Future<bool> deleteUser(int id) async {
    try {
      await userBox.delete(id);
      return true;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }

  // GET USER BY USERNAME
  Future<User?> getUserByUsername(String username) async {
    final matchingUsers = userBox.values.where((u) => u.username == username);
    return matchingUsers.isNotEmpty ? matchingUsers.first : null;
  }

  // GET USER BY ID
  Future<User?> getUserById(int id) async {
    return userBox.get(id);
  }
}