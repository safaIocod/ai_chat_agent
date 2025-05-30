import 'dart:convert';
import 'dart:developer';
import 'package:ai_chat_agent/models/chat_history_response.dart';
import 'package:ai_chat_agent/models/conversation_response.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiServices {
  static const String _baseUrl =
      'http://13.49.46.208/api'; // Replace with your base URL

  /// Helper method to get token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Login User
  static Future<bool> login(String email, String password) async {
    final url = Uri.parse('http://13.49.46.208/api/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {'email': email, 'password': password},
    );

    log('Response status: ${response.statusCode}');
    log('Response body: ${response.body}');

    try {
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['status'] == true) {
          final token = data['data']['token'];
          final name = data['data']['name'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('username', name);

          return true;
        } else {
          final errorMessage = data['message'] ?? '';
          throw ('Login failed: $errorMessage');
        }
      } else {
        final errorMessage = data['message'] ?? '';
        throw ('Login failed: $errorMessage');
      }
    } catch (e) {
      throw '$e';
    }
  }

  /// Sign Up User
  static Future<bool> signUp(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    final url = Uri.parse('$_baseUrl/sign-up');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
        },
      );

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['status'] == true) {
          final token = data['data']['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('username', data['data']['name']);
          return true;
        } else {
          final errorMessage = data['message'] ?? '';
          throw ('Signup failed: $errorMessage');
        }
      } else {
        final errorMessage = data['message'] ?? '';
        throw ('Signup failed: $errorMessage');
      }
    } catch (e) {
      throw (' ${e.toString()}');
    }
  }

  static Future<ConversationsResponse> fetchConversations() async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found. Please log in.');

    final response = await http.get(
      Uri.parse('$_baseUrl/get-conversations'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    log('Response status: ${response.statusCode}');
    log('Response body: ${response.body}');
    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return ConversationsResponse.fromJson(jsonBody);
    } else {
      throw Exception('Failed to fetch conversations');
    }
  }

  static Future<ChatHistoryResponse> fetchChatHistory(
    String conversationId,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found. Please log in.');

    final url = '$_baseUrl/get-messages?conversation_id=$conversationId';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    log('Chat history status: ${response.statusCode}');
    log('Chat history body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      final data = jsonBody['data'];
      return ChatHistoryResponse.fromJson(data);
    } else {
      throw Exception('Failed to fetch chat history');
    }
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
  }
}
