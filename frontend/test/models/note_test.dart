import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/note.dart';

void main() {
  group('Note Model Tests', () {
    test('Create a note with default values', () {
      final note = Note(
        id: 1,
        title: 'Test Note',
        content: 'Test content',
        createdAt: DateTime.now(),
      );

      expect(note.id, 1);
      expect(note.title, 'Test Note');
      expect(note.content, 'Test content');
      expect(note.priority, NotePriority.medium);
      expect(note.isCompleted, false);
    });

    test('Create a note with custom priority', () {
      final note = Note(
        id: 2,
        title: 'Important Note',
        content: 'Important content',
        createdAt: DateTime.now(),
        priority: NotePriority.high,
        isCompleted: false,
      );

      expect(note.priority, NotePriority.high);
      expect(note.isCompleted, false);
    });

    test('Convert note to JSON and back', () {
      final originalNote = Note(
        id: 3,
        title: 'JSON Test',
        content: 'Testing JSON serialization',
        createdAt: DateTime(2025, 12, 10),
        priority: NotePriority.low,
        isCompleted: true,
      );

      final json = originalNote.toJson();
      final restoredNote = Note.fromJson(json);

      expect(restoredNote.id, originalNote.id);
      expect(restoredNote.title, originalNote.title);
      expect(restoredNote.content, originalNote.content);
      expect(restoredNote.priority, originalNote.priority);
      expect(restoredNote.isCompleted, originalNote.isCompleted);
    });

    test('Copy note with updated fields', () {
      final note = Note(
        id: 4,
        title: 'Original',
        content: 'Original content',
        createdAt: DateTime.now(),
        priority: NotePriority.medium,
        isCompleted: false,
      );

      final updatedNote = note.copyWith(
        title: 'Updated',
        isCompleted: true,
      );

      expect(updatedNote.id, note.id);
      expect(updatedNote.title, 'Updated');
      expect(updatedNote.content, note.content);
      expect(updatedNote.isCompleted, true);
      expect(updatedNote.priority, note.priority);
    });

    test('Compare two notes for equality', () {
      final date = DateTime(2025, 12, 10);
      final note1 = Note(
        id: 5,
        title: 'Compare',
        content: 'Same content',
        createdAt: date,
        priority: NotePriority.high,
        isCompleted: true,
      );

      final note2 = Note(
        id: 5,
        title: 'Compare',
        content: 'Same content',
        createdAt: date,
        priority: NotePriority.high,
        isCompleted: true,
      );

      expect(note1, note2);
      expect(note1.hashCode, note2.hashCode);
    });

    test('Priority from string', () {
      expect(Note.fromJson({'priority': 'high'}).priority, NotePriority.high);
      expect(Note.fromJson({'priority': 'medium'}).priority, NotePriority.medium);
      expect(Note.fromJson({'priority': 'low'}).priority, NotePriority.low);
      expect(Note.fromJson({'priority': 'invalid'}).priority, NotePriority.medium);
    });
  });
}
