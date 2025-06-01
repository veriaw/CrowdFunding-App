import 'package:hive/hive.dart';

part 'user.g.dart'; // Generated file

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String password;

  @HiveField(3)
  String? gender;

  @HiveField(4)
  DateTime? dateOfBirth;

  @HiveField(5)
  String? publicKey; // 🔑 Field baru

  User({
    required this.username,
    required this.password,
    this.gender,
    this.dateOfBirth,
    this.publicKey,
  });
}
