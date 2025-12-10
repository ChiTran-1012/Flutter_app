# Ứng dụng Ghi chú Flutter - Thực hiện Yêu cầu CRUD

## 📋 Tổng quan

Ứng dụng này là một ứng dụng ghi chú full-stack được xây dựng bằng Flutter, thực hiện đầy đủ các yêu cầu CRUD (Create, Read, Update, Delete) với tích hợp backend API và lưu trữ cục bộ.

## ✅ Các Tính năng Đã Thực hiện

### 1. Chức năng CRUD Hoàn chỉnh

- ✅ **Create (Tạo)**: Người dùng có thể tạo ghi chú mới với:
  - Tiêu đề (title)
  - Nội dung (content)
  - Thời gian tùy chỉnh (ngày/giờ)
  - Mức độ ưu tiên (Low, Medium, High)
  - Trạng thái hoàn thành (isCompleted)

- ✅ **Read (Đọc)**: Hiển thị danh sách tất cả ghi chú với:
  - Liệt kê ghi chú với thông tin cơ bản
  - Chi tiết ghi chú đầy đủ
  - Trạng thái online/offline

- ✅ **Update (Cập nhật)**: Chỉnh sửa ghi chú đã tồn tại:
  - Cập nhật tiêu đề, nội dung
  - Thay đổi mức độ ưu tiên
  - Thay đổi thời gian
  - Đánh dấu hoàn thành/chưa hoàn thành

- ✅ **Delete (Xóa)**: Xóa ghi chú với:
  - Xác nhận trước khi xóa
  - Xóa khỏi server và lưu trữ cục bộ

### 2. Data Model

```dart
class Note {
  final int id;                        // Định danh duy nhất
  final String title;                  // Mô tả ngắn gọn
  final String content;                // Nội dung chi tiết
  final DateTime createdAt;            // Thời gian tạo
  final NotePriority priority;         // Ưu tiên: low, medium, high
  final bool isCompleted;              // Trạng thái hoàn thành
}

enum NotePriority { low, medium, high }
```

**Các phương thức:**
- `toJson()`: Chuyển đổi sang JSON
- `fromJson()`: Tạo từ JSON
- `copyWith()`: Tạo bản sao với các trường cập nhật
- `==` và `hashCode`: So sánh bằng

### 3. Giao diện Người dùng

#### Màn hình Danh sách
- Hiển thị danh sách ghi chú với:
  - Tiêu đề và nội dung tóm tắt
  - Thời gian tạo (định dạng: Hôm nay, Hôm qua, hoặc ngày cụ thể)
  - Mức độ ưu tiên (màu sắc: Đỏ=Cao, Cam=Trung bình, Xanh=Thấp)
  - Checkbox đánh dấu hoàn thành
  - Menu tùy chọn (Chỉnh sửa, Xóa)
  
#### Màn hình Tạo/Chỉnh sửa
- TextField cho tiêu đề
- TextField cho nội dung (multi-line)
- Chọn mức độ ưu tiên (3 nút radio)
- Chọn ngày (DatePicker)
- Chọn giờ (TimePicker)

#### Thiết kế
- **Màu chính**: Tím Indigo (#6366F1)
- **Nền**: Xám nhạt (#F8F9FA)
- **Card**: Gradient từ trắng sang xám
- **Border tròn**: 8-12px radius
- **Typography**: Font size và weight hợp lý

### 4. Tích hợp API

**File**: `lib/services/api_service.dart`

Thực hiện các endpoint:
- `POST /api/v1/notes` - Tạo ghi chú mới
- `GET /api/v1/notes` - Lấy tất cả ghi chú
- `GET /api/v1/notes/{id}` - Lấy ghi chú theo ID
- `PUT /api/v1/notes/{id}` - Cập nhật ghi chú
- `DELETE /api/v1/notes/{id}` - Xóa ghi chú

**Xử lý lỗi:**
- Timeout: 10 giây
- Custom exception: `ApiException`
- Hiển thị thông báo lỗi cho người dùng

### 5. Lưu trữ Cục bộ (Local Storage)

**File**: `lib/services/local_storage_service.dart`

Sử dụng `localstore` để lưu dữ liệu JSON cục bộ:
- `saveNote()`: Lưu ghi chú
- `getNote()`: Lấy ghi chú theo ID
- `getAllNotes()`: Lấy tất cả ghi chú
- `deleteNote()`: Xóa ghi chú
- `countNotes()`: Đếm ghi chú

**Chế độ Offline:**
- Nếu API thất bại, tự động load từ local storage
- Hiển thị thông báo "Offline mode"
- Vẫn có thể tạo, sửa, xóa ghi chú offline

### 6. Xử lý Lỗi

- Try-catch blocks cho API calls
- Fallback to local storage khi API thất bại
- Thông báo lỗi thân thiện cho người dùng
- Snackbar để xác nhận hành động
- Loading spinner trong khi xử lý

### 7. Kiểm thử Tự động

**File**: `test/models/note_test.dart`

Các bài test:
- ✅ Tạo ghi chú với giá trị mặc định
- ✅ Tạo ghi chú với ưu tiên tùy chỉnh
- ✅ Chuyển đổi JSON (toJson/fromJson)
- ✅ CopyWith method
- ✅ So sánh equality
- ✅ Phân tích priority từ string

**Chạy tests:**
```bash
cd frontend
flutter test
```

## 📚 Công nghệ & Thư viện Sử dụng

| Công nghệ | Mục đích |
|-----------|---------|
| **Flutter** | Framework xây dựng UI |
| **http** | Gọi API HTTP |
| **localstore** | Lưu trữ dữ liệu cục bộ (JSON) |
| **intl** | Định dạng ngôn ngữ (sẵn sàng) |
| **flutter_test** | Viết unit test |
| **dart:convert** | Encoding/Decoding JSON |

## 🏗️ Cấu trúc Dự án

```
frontend/
├── lib/
│   ├── main.dart                 # Entry point & UI chính
│   ├── models/
│   │   └── note.dart             # Note data model
│   └── services/
│       ├── api_service.dart      # API integration
│       └── local_storage_service.dart  # Local storage
├── test/
│   └── models/
│       └── note_test.dart        # Unit tests
└── pubspec.yaml                  # Dependencies
```

## 🚀 Cách Chạy Ứng dụng

### Prerequisites
- Flutter SDK >= 3.5.1
- Dart SDK >= 3.5.1

### Setup
```bash
# 1. Lấy dependencies
cd frontend
flutter pub get

# 2. Chạy ứng dụng
flutter run

# 3. Chạy tests
flutter test
```

### Cấu hình Backend
Mặc định, ứng dụng kết nối tới:
- **Web**: `http://localhost:8080`
- **Android Emulator**: `http://10.0.2.2:8080`

Thay đổi URL trong `lib/services/api_service.dart` nếu cần.

## 📝 API Endpoints

```
Base URL: http://localhost:8080/api/v1

POST   /notes              - Tạo ghi chú mới
GET    /notes              - Lấy tất cả ghi chú
GET    /notes/{id}         - Lấy ghi chú theo ID
PUT    /notes/{id}         - Cập nhật ghi chú
DELETE /notes/{id}         - Xóa ghi chú
```

## 🔐 Xử lý Lỗi

Ứng dụng xử lý các trường hợp lỗi sau:
- ❌ Kết nối API thất bại → Dùng local storage
- ❌ Timeout (10 giây) → Hiển thị lỗi
- ❌ Response không hợp lệ → Custom exception
- ❌ Lỗi local storage → Thông báo cho người dùng

## 🎯 Các Tính năng Nâng cao

1. **Offline-First**: Dữ liệu được lưu cục bộ, sync khi online
2. **Priority Levels**: Ghi chú có 3 mức độ ưu tiên với màu sắc khác nhau
3. **Completion Tracking**: Đánh dấu ghi chú đã hoàn thành
4. **Custom Datetime**: Đặt thời gian tùy chỉnh cho ghi chú
5. **Error Recovery**: Tự động fallback khi API lỗi
6. **User Feedback**: Snackbar, loading spinner, error messages

## 📊 Thống kê

- **Dòng mã**: ~1200 lines (main + models + services)
- **Classes**: 6 (Note, NotePriority, ApiService, LocalStorageService, AddNoteDialog, EditNoteDialog)
- **Screens**: 3 (List, Create, Edit)
- **Tests**: 6 unit tests

## 🔄 CI/CD Ready

Ứng dụng sẵn sàng để:
- Chạy tests tự động trên GitHub Actions
- Build APK/iOS binary
- Deploy lên App Store/Play Store

## 📄 Giấy phép

MIT

---

**Phát triển bởi**: AI Assistant  
**Ngày**: December 10, 2025  
**Version**: 1.0.0
