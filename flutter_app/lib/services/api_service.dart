import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl =
      'http://localhost:8000'; // Update with your FastAPI server URL

  /// Fetches feed items with pagination support
  /// [page] - The page number (0-based)
  /// [limit] - Number of items per page
  static Future<List<Map<String, dynamic>>> getFeed({
    int page = 0,
    int limit = 10,
  }) async {
    print('ApiService: getFeed called with page=$page, limit=$limit');

    // Mock data with more items for better pagination testing
    final mockData = [
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
      {
        'id': '3',
        'userId': 'user3',
        'videoUrl': 'https://example.com/video3.mp4',
        'description': 'Best burger in town! 🍔',
        'likes': 200,
        'comments': 25,
      },
      {
        'id': '4',
        'userId': 'user4',
        'videoUrl': 'https://example.com/video4.mp4',
        'description': 'Healthy smoothie bowl 🥝',
        'likes': 150,
        'comments': 12,
      },
      {
        'id': '5',
        'userId': 'user5',
        'videoUrl': 'https://example.com/video5.mp4',
        'description': 'Amazing sunset view 🌅',
        'likes': 300,
        'comments': 30,
      },
    ];

    // Simulate pagination
    final startIndex = page * limit;

    // Return empty list if we've reached the end of the data
    if (startIndex >= mockData.length) {
      return [];
    }

    final endIndex = (startIndex + limit).clamp(0, mockData.length);
    final paginatedData = mockData.sublist(startIndex, endIndex);

    print('ApiService: Returning ${paginatedData.length} mock items');

    // Simulate network delay
    return Future.delayed(
      const Duration(milliseconds: 500),
      () => paginatedData,
    );
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
