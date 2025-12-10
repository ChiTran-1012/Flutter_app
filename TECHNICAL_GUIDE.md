# Hướng Dẫn Kỹ Thuật - Ứng dụng Ghi chú Flutter

## 📖 Kiến trúc Ứng dụng

### Layer Architecture

```
┌─────────────────────────────────────┐
│         UI Layer (Widgets)          │
│  - NotesPage, AddNoteDialog, etc.   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Service Layer                  │
│  - ApiService                       │
│  - LocalStorageService              │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       Data Layer (Models)           │
│  - Note, NotePriority               │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│     External Services               │
│  - HTTP (API)                       │
│  - LocalStore (JSON Storage)        │
└─────────────────────────────────────┘
```

### Data Flow

```
User Interaction
    ↓
Widget (UI)
    ↓
State Management (setState)
    ↓
Service Layer (API/Local)
    ↓
Model Serialization (JSON)
    ↓
External Storage (Server/Device)
```

## 🔧 Các Thành phần Chính

### 1. Models (lib/models/note.dart)

```dart
class Note {
  final int id;                    // Unique identifier
  final String title;              // Note title
  final String content;            // Note content
  final DateTime createdAt;        // Creation timestamp
  final NotePriority priority;     // Priority level
  final bool isCompleted;          // Completion status
}

enum NotePriority { low, medium, high }
```

**Phương thức quan trọng:**
- `toJson()`: Serialization cho API
- `fromJson()`: Deserialization từ API
- `copyWith()`: Immutable updates
- `==`, `hashCode`: Equality comparison

### 2. Services

#### ApiService (lib/services/api_service.dart)

```dart
class ApiService {
  Future<Note> createNote(Note note) async
  Future<List<Note>> getNotes() async
  Future<Note> getNote(int id) async
  Future<Note> updateNote(Note note) async
  Future<void> deleteNote(int id) async
}
```

**Đặc điểm:**
- RESTful API calls
- Timeout: 10 giây
- Exception handling
- JSON encoding/decoding

#### LocalStorageService (lib/services/local_storage_service.dart)

```dart
class LocalStorageService {
  Future<void> saveNote(Note note) async
  Future<Note?> getNote(int id) async
  Future<List<Note>> getAllNotes() async
  Future<void> deleteNote(int id) async
  Future<int> countNotes() async
}
```

**Đặc điểm:**
- Sử dụng Localstore package
- JSON file storage
- Async operations
- Exception handling

### 3. UI Components (lib/main.dart)

#### NotesPage (Màn hình chính)

```dart
class NotesPage extends StatefulWidget {
  - notes: List<Note>
  - isLoading: bool
  - errorMessage: String?
  
  Methods:
  - _loadNotes()
  - _addNote()
  - _editNote(index)
  - _deleteNote(index)
  - _toggleComplete(index)
}
```

**Features:**
- Hiển thị danh sách ghi chú
- Pull-to-refresh (nút refresh)
- Error state handling
- Loading state
- Offline mode

#### AddNoteDialog

```dart
class AddNoteDialog extends StatefulWidget {
  - titleController: TextEditingController
  - contentController: TextEditingController
  - selectedDateTime: DateTime
  - selectedPriority: NotePriority
  
  Returns: Note?
}
```

#### EditNoteDialog

```dart
class EditNoteDialog extends StatefulWidget {
  - note: Note (initial value)
  - titleController: TextEditingController
  - contentController: TextEditingController
  - selectedDateTime: DateTime
  - selectedPriority: NotePriority
  
  Returns: Note?
}
```

## 🔄 CRUD Operations Flow

### CREATE (Tạo ghi chú)

```
User presses "+" button
    ↓
ShowDialog(AddNoteDialog)
    ↓
User fills form & presses "Thêm"
    ↓
Navigator.pop(context, Note)
    ↓
_addNote() receives Note
    ↓
Try: ApiService.createNote()
    ├─ Success: Save to local, update UI
    └─ Error: Save to local only, show message
    ↓
Add note to list
    ↓
Update UI with setState()
```

### READ (Đọc ghi chú)

```
App starts (initState)
    ↓
_loadNotes()
    ↓
Try: ApiService.getNotes()
    ├─ Success: Save to local, display
    └─ Error: Load from local, show offline mode
    ↓
Build ListView with notes
    ↓
Display with priority colors & dates
```

### UPDATE (Cập nhật ghi chú)

```
User taps note or edit menu
    ↓
ShowDialog(EditNoteDialog, initialValue: note)
    ↓
User modifies & presses "Lưu"
    ↓
Navigator.pop(context, updatedNote)
    ↓
_editNote() receives updatedNote
    ↓
Try: ApiService.updateNote()
    ├─ Success: Save to local, update UI
    └─ Error: Save to local only, show message
    ↓
Update notes[index]
    ↓
Update UI with setState()
```

### DELETE (Xóa ghi chú)

```
User taps delete menu
    ↓
ShowDialog(AlertDialog, confirm?)
    ↓
User confirms
    ↓
Try: ApiService.deleteNote()
    ├─ Success: Delete from local
    └─ Error: Delete from local anyway
    ↓
Remove from notes list
    ↓
Update UI with setState()
```

## 🧪 Testing

### Unit Tests (test/models/note_test.dart)

```dart
Test Suite:
  ✓ Create note with defaults
  ✓ Create note with custom priority
  ✓ JSON serialization/deserialization
  ✓ CopyWith method
  ✓ Equality comparison
  ✓ Priority string parsing
```

**Chạy tests:**
```bash
cd frontend
flutter test                    # Tất cả tests
flutter test test/models/      # Tests trong thư mục
flutter test --coverage        # Với coverage
```

## 🌐 API Integration

### Request Format

```json
POST /api/v1/notes
Content-Type: application/json

{
  "id": 1702214400000,
  "title": "Sample Note",
  "content": "Note content",
  "createdAt": "2025-12-10T10:30:00.000Z",
  "priority": "high",
  "isCompleted": false
}
```

### Response Format

```json
{
  "id": 1702214400000,
  "title": "Sample Note",
  "content": "Note content",
  "createdAt": "2025-12-10T10:30:00.000Z",
  "priority": "high",
  "isCompleted": false
}
```

### Error Handling

```dart
try {
  final response = await http.post(...);
  if (response.statusCode == 200) {
    // Success
    return Note.fromJson(jsonDecode(response.body));
  } else {
    throw ApiException('Error: ${response.statusCode}');
  }
} catch (e) {
  throw ApiException('Connection error: $e');
}
```

## 💾 Local Storage

### Directory Structure

```
/data/data/com.example.frontend/app_flutter/
├── localstore.db/
│   └── notes/
│       ├── 1702214400000.json
│       ├── 1702214400001.json
│       └── ...
```

### JSON Format

```json
{
  "1702214400000": {
    "id": 1702214400000,
    "title": "Note Title",
    "content": "Note content...",
    "createdAt": "2025-12-10T10:30:00.000Z",
    "priority": "medium",
    "isCompleted": false
  }
}
```

## ⚡ Performance Optimization

1. **List Building**: ListView.builder for efficient rendering
2. **Image Loading**: Consider caching if adding images
3. **API Calls**: Debounce search if added
4. **Local Storage**: Index by date for faster queries
5. **State Management**: Minimal setState() calls

## 🔒 Error Handling Strategy

### 3-Layer Error Handling

```
Layer 1: API Service
  ↓
  Try HTTP call
  Catch: Network error, Parse error, Timeout
  ↓

Layer 2: State Management
  ↓
  Try API Service call
  Catch: Fallback to Local Storage
  ↓

Layer 3: UI
  ↓
  Display error message to user
  Allow offline operations
```

## 🚀 Deployment

### Build APK
```bash
cd frontend
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build iOS
```bash
cd frontend
flutter build ios --release
```

### Build Web
```bash
cd frontend
flutter build web --release
```

## 📱 Platform-Specific Config

### Android (android/app/build.gradle)
- minSdkVersion: 21
- targetSdkVersion: 33

### iOS (ios/Podfile)
- platform: iOS, '12.0'

## 🔐 Security Considerations

1. ✅ Validate user input before sending to API
2. ✅ Use HTTPS in production
3. ⚠️ Implement authentication if needed
4. ⚠️ Add request signing/validation
5. ⚠️ Encrypt local storage if contains sensitive data

## 📊 Code Metrics

- **Total Lines**: ~1200 (main + models + services)
- **Classes**: 6
- **Methods**: 30+
- **Test Coverage**: Basic (expandable)

## 🔄 Future Enhancements

1. **Search**: Full-text search in notes
2. **Categories**: Organize notes by category
3. **Tags**: Add tagging system
4. **Sync**: Real-time sync with cloud
5. **Reminders**: Add notification system
6. **Rich Text**: Markdown/HTML formatting
7. **Attachments**: Add image/file support
8. **Authentication**: User login system
9. **Sharing**: Share notes with others
10. **Dark Mode**: Dark theme support

## 🐛 Debugging

### Enable Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Logs
```dart
print('Debug message');
debugPrint('Debug output');
```

### Network Inspection
- Use Charles Proxy or Fiddler
- Monitor HTTP/HTTPS requests

## 📚 Tài liệu Tham khảo

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [HTTP Package](https://pub.dev/packages/http)
- [Localstore Package](https://pub.dev/packages/localstore)

---

**Last Updated**: December 10, 2025  
**Version**: 1.0.0
