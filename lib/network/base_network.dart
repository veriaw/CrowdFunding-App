import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

class BaseNetwork {
  static const String baseUrl =
      'https://api-funding-928661779459.us-central1.run.app';

  // ✅ Get All Projects
  static Future<Map<String, dynamic>> getAllProjects() async {
    final response = await http.get(Uri.parse('$baseUrl/get-project'));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load projects');
    }
  }

  // ✅ Get All Projects
  static Future<Map<String, dynamic>> getLatestProject() async {
    final response = await http.get(Uri.parse('$baseUrl/get-latest-project'));
    print("latest project :${jsonDecode(response.body)}");
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load projects');
    }
  }

  // ✅ Get User Participated Projects
  static Future<Map<String, dynamic>> getProjectById(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/project'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'project_id': id}),
    );
    print("detail project :${jsonDecode(response.body)}");
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load participated projects');
    }
  }

  static Future<Map<String, dynamic>> getAllProjectByUserId(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/get-projects-by-user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': id}),
    );
    print("user project :${jsonDecode(response.body)}");
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load participated projects');
    }
  }

  // ✅ Get User Participated Projects
  static Future<Map<String, dynamic>> getUserParticipatedProjects(
      int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/participated-project'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load participated projects');
    }
  }

  // ✅ Donate to Project
  static Future<bool> donate(int userId, int projectId, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/donate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'project_id': projectId,
        'amount': amount,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('Donation successful: ${response.body}');
      return true;
    } else {
      print('Donation failed: ${response.body}');
      return false;
    }
  }

  // ✅ Get user donation to a specific project
  static Future<Map<String, dynamic>> getUserDonation(
      int userId, int projectId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/get-my-donation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'project_id': projectId,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get donation info');
    }
  }

  // ✅ Create Project with Image
  static Future<bool> createProjectWithImage({
    required File imageFile,
    required int userId,
    required String title,
    required String description,
    required double targetAmount,
    required String deadline,
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/create-project');

    var request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = userId.toString();
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['target_amount'] = targetAmount.toString();
    request.fields['deadline'] = deadline;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();

    var stream = http.ByteStream(imageFile.openRead());
    var length = await imageFile.length();

    String mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    var mimeSplit = mimeType.split('/');

    var multipartFile = http.MultipartFile(
      'image',
      stream,
      length,
      filename: basename(imageFile.path),
      contentType: MediaType(mimeSplit[0], mimeSplit[1]),
    );

    request.files.add(multipartFile);

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('Create response: $responseBody');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Create project error: $e');
      return false;
    }
  }

  // ✅ Update Project with Image
  static Future<bool> updateProjectWithImage({
    File? imageFile,
    required int userId,
    required int projectId,
    String? title,
    String? description,
    double? targetAmount,
    String? deadline,
    double? latitude,
    double? longitude,
    String? status,
  }) async {
    final uri = Uri.parse('$baseUrl/update-project');

    var request = http.MultipartRequest('PUT', uri);

    request.fields['user_id'] = userId.toString();
    request.fields['project_id'] = projectId.toString();

    if (title != null) request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;
    if (targetAmount != null)
      request.fields['target_amount'] = targetAmount.toString();
    if (deadline != null) request.fields['deadline'] = deadline;
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();
    if (status != null) request.fields['status'] = status;

    if (imageFile != null) {
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      final mimeType = lookupMimeType(imageFile.path);
      print('Detected mimeType: $mimeType');
      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: basename(imageFile.path),
        contentType: MediaType('image', mimeType?.split('/').last ?? 'jpeg'),
      );
      request.files.add(multipartFile);
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('Update response: $responseBody');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Update project error: $e');
      return false;
    }
  }

  static Future<bool> cancelProject({
    required int projectId,
    required int userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/projectCanceled'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'project_id': projectId,
        'user_id': userId,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('Cancel project successful: ${response.body}');
      return true;
    } else {
      print('Cancel project failed: ${response.body}');
      return false;
    }
  }
}
