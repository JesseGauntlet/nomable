import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl =
      'http://localhost:8000'; // Update with your FastAPI server URL

  static Future<List<Map<String, dynamic>>> getFeed() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/feed'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load feed: ${response.statusCode}');
      }
    } catch (e) {
      // For development, return mock data
      return [
        {
          'id': '1',
          'userId': 'user1',
          'videoUrl': 'https://example.com/video1.mp4',
          'description': 'Delicious homemade pasta! 🍝',
          'likes': 120,
          'comments': 15,
        },
        {
          'id': '2',
          'userId': 'user2',
          'videoUrl': 'https://example.com/video2.mp4',
          'description': 'Quick and easy breakfast recipe 🍳',
          'likes': 85,
          'comments': 8,
        },
      ];
    }
  }

  static Future<void> uploadVideo(String filePath) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
      request.files.add(await http.MultipartFile.fromPath('video', filePath));

      var response = await request.send();
      if (response.statusCode != 200) {
        throw Exception('Failed to upload video: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
