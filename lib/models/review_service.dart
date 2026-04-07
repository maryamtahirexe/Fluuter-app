import 'dart:convert';
import 'package:http/http.dart' as http;

class ReviewService {
  static const String _baseUrl = 'http://10.0.2.2:8000'; // For Android emulator

  static Future<List<Map<String, dynamic>>> analyzeReviews(List<Map<String, dynamic>> reviews) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reviews': reviews, // Send the complete review objects
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData.map((item) => item as Map<String, dynamic>).toList();
      } else {
        print('API Error - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to analyze reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Network Error: $e');
      throw Exception('Failed to connect to review service');
    }
  }
}