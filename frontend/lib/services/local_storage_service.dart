import 'package:localstore/localstore.dart';
import 'package:frontend/models/note.dart';

class LocalStorageService {
  static const String _collectionName = 'notes';
  final _db = Localstore.instance;

  Future<void> saveNote(Note note) async {
    try {
      await _db.collection(_collectionName).doc(note.id.toString()).set(
            note.toJson(),
          );
    } catch (e) {
      throw StorageException('Lỗi khi lưu ghi chú: $e');
    }
  }

  Future<Note?> getNote(int id) async {
    try {
      final data = await _db.collection(_collectionName).doc(id.toString()).get();
      if (data == null) return null;
      return Note.fromJson(data);
    } catch (e) {
      throw StorageException('Lỗi khi tải ghi chú: $e');
    }
  }

  Future<List<Note>> getAllNotes() async {
    try {
      final items = await _db.collection(_collectionName).get();
      if (items == null) return [];
      return (items as Map).entries
          .map((e) => Note.fromJson(Map<String, dynamic>.from(e.value)))
          .toList();
    } catch (e) {
      throw StorageException('Lỗi khi tải danh sách ghi chú: $e');
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _db.collection(_collectionName).doc(id.toString()).delete();
    } catch (e) {
      throw StorageException('Lỗi khi xóa ghi chú: $e');
    }
  }

  Future<void> deleteAllNotes() async {
    try {
      await _db.collection(_collectionName).delete();
    } catch (e) {
      throw StorageException('Lỗi khi xóa tất cả ghi chú: $e');
    }
  }

  Future<int> countNotes() async {
    try {
      final items = await _db.collection(_collectionName).get();
      if (items == null) return 0;
      return (items as Map).length;
    } catch (e) {
      throw StorageException('Lỗi khi đếm ghi chú: $e');
    }
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => message;
}
