import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RSAHelper {
  static const _privateKeyKey = 'privateKey';
  static const _publicKeyKey = 'publicKey';

  static Future<void> generateAndStoreKeys() async {
    final keyPair = CryptoUtils.generateRSAKeyPair();

    final publicPem = CryptoUtils.encodeRSAPublicKeyToPem(keyPair.publicKey as RSAPublicKey);
    final privatePem = CryptoUtils.encodeRSAPrivateKeyToPem(keyPair.privateKey as RSAPrivateKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_privateKeyKey, privatePem);
    await prefs.setString(_publicKeyKey, publicPem);
  }

  static Future<RSAPublicKey?> getPublicKey() async {
    final prefs = await SharedPreferences.getInstance();
    final pem = prefs.getString(_publicKeyKey);
    if (pem == null) return null;
    return CryptoUtils.rsaPublicKeyFromPem(pem);
  }

  static Future<RSAPrivateKey?> getPrivateKey() async {
    final prefs = await SharedPreferences.getInstance();
    final pem = prefs.getString(_privateKeyKey);
    if (pem == null) return null;
    return CryptoUtils.rsaPrivateKeyFromPem(pem);
  }

  static Future<String> encrypt(String plain, RSAPublicKey publicKey) async {
    return CryptoUtils.rsaEncrypt(plain, publicKey);
  }

  static Future<String> decrypt(String cipher, RSAPrivateKey privateKey) async {
    return CryptoUtils.rsaDecrypt(cipher, privateKey);
  }
}