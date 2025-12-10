import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/models/note.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  
  // For Android emulator
  static const String androidEmulatorUrl = 'http://10.0.2.2:8080/api/v1';

  final String _baseUrl;

  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? ApiService.baseUrl;

  // Create a new note
  Future<Note> createNote(Note note) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(note.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Note.fromJson(data);
      } else {
        throw ApiException(
            'Lỗi tạo ghi chú: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw ApiException('Lỗi kết nối: $e');
    }
  }

  // Get all notes
  Future<List<Note>> getNotes() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notes'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Note.fromJson(item)).toList();
      } else {
        throw ApiException(
            'Lỗi tải ghi chú: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw ApiException('Lỗi kết nối: $e');
    }
  }

  // Get a single note
  Future<Note> getNote(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notes/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Note.fromJson(data);
      } else {
        throw ApiException(
            'Lỗi tải ghi chú: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw ApiException('Lỗi kết nối: $e');
    }
  }

  // Update a note
  Future<Note> updateNote(Note note) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notes/${note.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(note.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Note.fromJson(data);
      } else {
        throw ApiException(
            'Lỗi cập nhật ghi chú: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw ApiException('Lỗi kết nối: $e');
    }
  }

  // Delete a note
  Future<void> deleteNote(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/notes/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
            'Lỗi xóa ghi chú: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw ApiException('Lỗi kết nối: $e');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
