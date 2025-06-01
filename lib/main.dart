import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:project_tpm/models/user.dart';
import 'package:project_tpm/screens/Login.dart';
import 'package:project_tpm/utils/rsa_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());

  await Hive.openBox<User>('users');

  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('privateKey')) {
    await RSAHelper.generateAndStoreKeys();
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage()
    );
  }
}
