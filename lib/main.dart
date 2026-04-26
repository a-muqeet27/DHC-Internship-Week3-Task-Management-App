import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TaskApp());
}

/// ======================
/// ROOT APP
/// ======================
class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const HomeScreen(),
    );
  }
}

/// ======================
/// TASK MODEL (PURE DART)
/// ======================
class Task {
  final String title;
  final bool done;

  const Task({
    required this.title,
    this.done = false,
  });

  Task copyWith({String? title, bool? done}) {
    return Task(
      title: title ?? this.title,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'done': done,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      done: json['done'],
    );
  }
}

/// ======================
/// HOME SCREEN
/// ======================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  List<Task> _tasks = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const String storageKey = "tasks";

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();
    _loadTasks();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  /// ======================
  /// LOCAL STORAGE
  /// ======================
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(storageKey) ?? [];

    setState(() {
      _tasks = data
          .map((e) => Task.fromJson(jsonDecode(e)))
          .toList();
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      storageKey,
      _tasks.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  /// ======================
  /// TASK ACTIONS
  /// ======================
  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _tasks.add(Task(title: text));
    });

    _controller.clear();
    _saveTasks();
    Navigator.pop(context);
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });

    _saveTasks();
  }

  void _toggleTask(int index) {
    setState(() {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(done: !task.done);
    });

    _saveTasks();
  }

  /// ======================
  /// UI DIALOG
  /// ======================
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Add Task"),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: "Enter task title",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _addTask,
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  /// ======================
  /// UI BUILD
  /// ======================
  @override
  Widget build(BuildContext context) {
    final completed = _tasks.where((t) => t.done).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          "My Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_task),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Task"),
      ),

      body: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B67F1), Color(0xFF7D8BFF)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  "$completed of ${_tasks.length} tasks completed",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// TASK LIST
              Expanded(
                child: _tasks.isEmpty
                    ? const Center(child: Text("No tasks yet"))
                    : ListView.builder(
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];

                          return Card(
                            child: ListTile(
                              leading: Checkbox(
                                value: task.done,
                                onChanged: (_) => _toggleTask(index),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteTask(index),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}