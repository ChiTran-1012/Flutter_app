import 'package:flutter/material.dart';
import 'package:frontend/models/note.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/local_storage_service.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ứng dụng Ghi chú',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF6366F1),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6366F1),
          foregroundColor: Colors.white,
        ),
      ),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late ApiService apiService;
  late LocalStorageService storageService;
  List<Note> notes = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    storageService = LocalStorageService();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Try to load from API first
      final apiNotes = await apiService.getNotes();
      
      // Save to local storage
      for (var note in apiNotes) {
        await storageService.saveNote(note);
      }
      
      setState(() {
        notes = apiNotes;
        isLoading = false;
      });
    } catch (e) {
      // If API fails, load from local storage
      try {
        final localNotes = await storageService.getAllNotes();
        setState(() {
          notes = localNotes;
          errorMessage = 'Offline mode: Hiển thị dữ liệu cục bộ';
          isLoading = false;
        });
      } catch (storageError) {
        setState(() {
          errorMessage = 'Lỗi: $storageError';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _addNote() async {
    final result = await showDialog<Note>(
      context: context,
      builder: (context) => const AddNoteDialog(),
    );

    if (result != null) {
      setState(() {
        isLoading = true;
      });

      try {
        // Create note with server
        final newNote = await apiService.createNote(result);
        
        // Save to local storage
        await storageService.saveNote(newNote);
        
        setState(() {
          notes.add(newNote);
          isLoading = false;
          errorMessage = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ghi chú đã được thêm')),
          );
        }
      } catch (e) {
        // Save locally if API fails
        try {
          await storageService.saveNote(result);
          setState(() {
            notes.add(result);
            isLoading = false;
            errorMessage = 'Ghi chú đã được lưu cục bộ (offline)';
          });
        } catch (storageError) {
          setState(() {
            errorMessage = 'Lỗi: $storageError';
            isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _editNote(int index) async {
    final note = notes[index];
    final result = await showDialog<Note>(
      context: context,
      builder: (context) => EditNoteDialog(note: note),
    );

    if (result != null) {
      setState(() {
        isLoading = true;
      });

      try {
        // Update on server
        final updatedNote = await apiService.updateNote(result);
        
        // Update local storage
        await storageService.saveNote(updatedNote);
        
        setState(() {
          notes[index] = updatedNote;
          isLoading = false;
          errorMessage = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ghi chú đã được cập nhật')),
          );
        }
      } catch (e) {
        // Update locally if API fails
        try {
          await storageService.saveNote(result);
          setState(() {
            notes[index] = result;
            isLoading = false;
            errorMessage = 'Ghi chú đã được cập nhật cục bộ (offline)';
          });
        } catch (storageError) {
          setState(() {
            errorMessage = 'Lỗi: $storageError';
            isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _deleteNote(int index) async {
    final note = notes[index];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                isLoading = true;
              });

              try {
                // Delete from server
                await apiService.deleteNote(note.id);
                
                // Delete from local storage
                await storageService.deleteNote(note.id);
                
                setState(() {
                  notes.removeAt(index);
                  isLoading = false;
                  errorMessage = null;
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ghi chú đã bị xóa')),
                  );
                }
              } catch (e) {
                // Delete locally if API fails
                try {
                  await storageService.deleteNote(note.id);
                  setState(() {
                    notes.removeAt(index);
                    isLoading = false;
                    errorMessage = 'Ghi chú đã bị xóa cục bộ (offline)';
                  });
                } catch (storageError) {
                  setState(() {
                    errorMessage = 'Lỗi: $storageError';
                    isLoading = false;
                  });
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleComplete(int index) async {
    final note = notes[index];
    final updatedNote = note.copyWith(isCompleted: !note.isCompleted);
    
    setState(() {
      notes[index] = updatedNote;
    });

    try {
      await apiService.updateNote(updatedNote);
      await storageService.saveNote(updatedNote);
    } catch (e) {
      try {
        await storageService.saveNote(updatedNote);
      } catch (storageError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $storageError')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ghi chú của tôi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotes,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            )
          : Column(
              children: [
                if (errorMessage != null)
                  Container(
                    color: errorMessage!.contains('offline')
                        ? Colors.orange[100]
                        : Colors.red[100],
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          errorMessage!.contains('offline')
                              ? Icons.cloud_off
                              : Icons.error,
                          color: errorMessage!.contains('offline')
                              ? Colors.orange[700]
                              : Colors.red[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: errorMessage!.contains('offline')
                                  ? Colors.orange[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              errorMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: notes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  Icons.note_outlined,
                                  size: 50,
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Chưa có ghi chú nào',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Nhấn nút + để tạo ghi chú mới',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.grey[50]!,
                                    ],
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(
                                              note.priority),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      Checkbox(
                                        value: note.isCompleted,
                                        onChanged: (_) =>
                                            _toggleComplete(index),
                                        activeColor: const Color(0xFF6366F1),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    note.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: const Color(0xFF1F2937),
                                      decoration: note.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        note.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          height: 1.4,
                                          decoration: note.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(note.createdAt),
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(
                                                      note.priority)
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _getPriorityLabel(
                                                  note.priority),
                                              style: TextStyle(
                                                color: _getPriorityColor(
                                                    note.priority),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey[600],
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editNote(index);
                                      } else if (value == 'delete') {
                                        _deleteNote(index);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 12),
                                            Text('Chỉnh sửa'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18,
                                                color: Colors.red),
                                            SizedBox(width: 12),
                                            Text(
                                              'Xóa',
                                              style: TextStyle(
                                                  color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _editNote(index),
                                ),
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Color _getPriorityColor(NotePriority priority) {
    switch (priority) {
      case NotePriority.high:
        return Colors.red;
      case NotePriority.medium:
        return Colors.orange;
      case NotePriority.low:
        return Colors.green;
    }
  }

  String _getPriorityLabel(NotePriority priority) {
    switch (priority) {
      case NotePriority.high:
        return 'Cao';
      case NotePriority.medium:
        return 'Trung bình';
      case NotePriority.low:
        return 'Thấp';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return 'Hôm nay lúc ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (noteDate == yesterday) {
      return 'Hôm qua lúc ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class AddNoteDialog extends StatefulWidget {
  const AddNoteDialog({super.key});

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  late DateTime selectedDateTime = DateTime.now();
  NotePriority selectedPriority = NotePriority.medium;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Ghi chú mới',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Tiêu đề',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Nội dung',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF9FAFB),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ưu tiên:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: NotePriority.values
                        .map((priority) => _buildPriorityButton(priority))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF9FAFB),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thời gian:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDateTime,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDateTime = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  selectedDateTime.hour,
                                  selectedDateTime.minute,
                                );
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFFD1D5DB)),
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${selectedDateTime.day.toString().padLeft(2, '0')}/${selectedDateTime.month.toString().padLeft(2, '0')}/${selectedDateTime.year}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.fromDateTime(selectedDateTime),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                selectedDateTime = DateTime(
                                  selectedDateTime.year,
                                  selectedDateTime.month,
                                  selectedDateTime.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFFD1D5DB)),
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (titleController.text.isNotEmpty ||
                contentController.text.isNotEmpty) {
              Navigator.pop(
                context,
                Note(
                  id: DateTime.now().millisecondsSinceEpoch,
                  title: titleController.text.isEmpty
                      ? 'Không có tiêu đề'
                      : titleController.text,
                  content: contentController.text,
                  createdAt: selectedDateTime,
                  priority: selectedPriority,
                  isCompleted: false,
                ),
              );
            }
          },
          child: const Text('Thêm'),
        ),
      ],
    );
  }

  Widget _buildPriorityButton(NotePriority priority) {
    final isSelected = selectedPriority == priority;
    String label;
    Color color;

    switch (priority) {
      case NotePriority.high:
        label = 'Cao';
        color = Colors.red;
        break;
      case NotePriority.medium:
        label = 'Trung bình';
        color = Colors.orange;
        break;
      case NotePriority.low:
        label = 'Thấp';
        color = Colors.green;
        break;
    }

    return InkWell(
      onTap: () {
        setState(() {
          selectedPriority = priority;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }
}

class EditNoteDialog extends StatefulWidget {
  final Note note;

  const EditNoteDialog({super.key, required this.note});

  @override
  State<EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<EditNoteDialog> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  late DateTime selectedDateTime;
  late NotePriority selectedPriority;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
    contentController = TextEditingController(text: widget.note.content);
    selectedDateTime = widget.note.createdAt;
    selectedPriority = widget.note.priority;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Chỉnh sửa ghi chú',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Tiêu đề',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Nội dung',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF9FAFB),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ưu tiên:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: NotePriority.values
                        .map((priority) => _buildPriorityButton(priority))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF9FAFB),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thời gian:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDateTime,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDateTime = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  selectedDateTime.hour,
                                  selectedDateTime.minute,
                                );
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFFD1D5DB)),
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${selectedDateTime.day.toString().padLeft(2, '0')}/${selectedDateTime.month.toString().padLeft(2, '0')}/${selectedDateTime.year}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.fromDateTime(selectedDateTime),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                selectedDateTime = DateTime(
                                  selectedDateTime.year,
                                  selectedDateTime.month,
                                  selectedDateTime.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFFD1D5DB)),
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              widget.note.copyWith(
                title: titleController.text.isEmpty
                    ? 'Không có tiêu đề'
                    : titleController.text,
                content: contentController.text,
                createdAt: selectedDateTime,
                priority: selectedPriority,
              ),
            );
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  Widget _buildPriorityButton(NotePriority priority) {
    final isSelected = selectedPriority == priority;
    String label;
    Color color;

    switch (priority) {
      case NotePriority.high:
        label = 'Cao';
        color = Colors.red;
        break;
      case NotePriority.medium:
        label = 'Trung bình';
        color = Colors.orange;
        break;
      case NotePriority.low:
        label = 'Thấp';
        color = Colors.green;
        break;
    }

    return InkWell(
      onTap: () {
        setState(() {
          selectedPriority = priority;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }
}
