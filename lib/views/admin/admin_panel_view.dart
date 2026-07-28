import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/icon_helper.dart';
import '../../models/category_model.dart';
import '../../models/question_model.dart';
import '../../state/admin_provider.dart';

class AdminPanelView extends StatefulWidget {
  const AdminPanelView({super.key});

  @override
  State<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends State<AdminPanelView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategoryForQuestions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      admin.loadCategories().then((_) {
        if (admin.categories.isNotEmpty) {
          setState(() {
            _selectedCategoryForQuestions = admin.categories.first.id;
          });
        }
      });
      admin.loadStudentLogs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Category Dialogs & Actions ---
  void _showCategoryDialog([CategoryModel? category]) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name);
    final descController = TextEditingController(text: category?.description);
    final limitController = TextEditingController(text: category?.timeLimitMinutes.toString() ?? '10');
    
    String selectedIcon = category?.iconName ?? 'code';
    String selectedColor = category?.colorHex ?? '#6366F1';

    final colors = ['#6366F1', '#0D9488', '#D97706', '#0284C7', '#EC4899', '#10B981'];
    final icons = ['code', 'phone_android', 'web', 'analytics', 'cloud_queue', 'storage', 'security'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.darkBorder),
              ),
              title: Text(isEdit ? 'Edit Category' : 'Create Category', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Flutter Basics'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description', hintText: 'Write a brief description...'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: limitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Time Limit (Minutes)', hintText: 'e.g. 15'),
                    ),
                    const SizedBox(height: 20),
                    // Icon Selector
                    const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: icons.map((ic) {
                        final isSel = selectedIcon == ic;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedIcon = ic),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
                              border: Border.all(color: isSel ? AppColors.primary : AppColors.darkBorder),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(IconHelper.getIcon(ic), size: 20, color: isSel ? AppColors.primary : AppColors.textSecondary),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Color Selector
                    const Text('Select Color Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: colors.map((col) {
                        final isSel = selectedColor == col;
                        final c = AppColors.fromHex(col);
                        return InkWell(
                          onTap: () => setDialogState(() => selectedColor = col),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || descController.text.isEmpty) return;
                    final limit = int.tryParse(limitController.text) ?? 10;
                    final admin = Provider.of<AdminProvider>(context, listen: false);
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    
                    bool success;
                    if (isEdit) {
                      success = await admin.editCategory(category.copyWith(
                        name: nameController.text,
                        description: descController.text,
                        timeLimitMinutes: limit,
                        iconName: selectedIcon,
                        colorHex: selectedColor,
                      ));
                    } else {
                      success = await admin.createCategory(
                        name: nameController.text,
                        description: descController.text,
                        timeLimitMinutes: limit,
                        iconName: selectedIcon,
                        colorHex: selectedColor,
                      );
                    }

                    if (mounted) {
                      nav.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(success 
                              ? (isEdit ? 'Category updated!' : 'Category created!') 
                              : 'Operation failed: ${admin.error}'),
                          backgroundColor: success ? AppColors.success : AppColors.danger,
                        ),
                      );
                    }
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        title: const Text('Delete Category?'),
        content: const Text('This will delete the category and all questions in it. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      final success = await admin.removeCategory(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Category deleted!' : 'Failed: ${admin.error}'),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }

  // --- Question Dialogs & Actions ---
  void _showQuestionDialog([QuestionModel? question]) {
    final isEdit = question != null;
    final catId = _selectedCategoryForQuestions ?? '';
    
    if (catId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a category first'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final qController = TextEditingController(text: question?.questionText);
    final optControllers = List.generate(4, (i) => TextEditingController(
      text: question != null && question.options.length > i ? question.options[i] : '',
    ));
    final expController = TextEditingController(text: question?.explanation);
    
    int correctIdx = question?.correctOptionIndex ?? 0;
    String difficulty = question?.difficulty ?? 'medium';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.darkBorder),
              ),
              title: Text(isEdit ? 'Edit Question' : 'Create Question', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: qController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Question Text', hintText: 'Enter question here...'),
                    ),
                    const SizedBox(height: 16),
                    // Options text fields with radio selectors
                    const Text('Answer Options & Mark Correct', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: i,
                              groupValue: correctIdx,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setDialogState(() => correctIdx = val!),
                            ),
                            Expanded(
                              child: TextField(
                                controller: optControllers[i],
                                decoration: InputDecoration(
                                  labelText: 'Option ${String.fromCharCode(65 + i)}',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // Difficulty Selector
                    Row(
                      children: [
                        const Text('Difficulty: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: difficulty,
                          dropdownColor: AppColors.darkSurface,
                          items: ['easy', 'medium', 'hard'].map((d) {
                            return DropdownMenuItem<String>(
                              value: d,
                              child: Text(d.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) => setDialogState(() => difficulty = val!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: expController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Explanation', hintText: 'Explain why the correct answer is right...'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (qController.text.isEmpty || optControllers.any((c) => c.text.isEmpty)) return;
                    final options = optControllers.map((c) => c.text).toList();
                    final admin = Provider.of<AdminProvider>(context, listen: false);
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);

                    bool success;
                    if (isEdit) {
                      success = await admin.editQuestion(question.copyWith(
                        questionText: qController.text,
                        options: options,
                        correctOptionIndex: correctIdx,
                        explanation: expController.text,
                        difficulty: difficulty,
                      ));
                    } else {
                      success = await admin.createQuestion(
                        categoryId: catId,
                        questionText: qController.text,
                        options: options,
                        correctOptionIndex: correctIdx,
                        explanation: expController.text,
                        difficulty: difficulty,
                      );
                    }

                    if (mounted) {
                      nav.pop();
                      setState(() {}); // refresh the question list future
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(success 
                              ? (isEdit ? 'Question updated!' : 'Question added!') 
                              : 'Operation failed: ${admin.error}'),
                          backgroundColor: success ? AppColors.success : AppColors.danger,
                        ),
                      );
                    }
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Add Question'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteQuestion(String qId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        title: const Text('Delete Question?'),
        content: const Text('Are you sure you want to remove this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      final success = await admin.removeQuestion(qId);
      if (mounted) {
        setState(() {}); // refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Question deleted!' : 'Failed: ${admin.error}'),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }

  // --- Tabs rendering ---
  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Panel', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Categories', icon: Icon(Icons.category_outlined)),
            Tab(text: 'Questions', icon: Icon(Icons.help_outline)),
            Tab(text: 'Student Logs', icon: Icon(Icons.assessment_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(admin),
          _buildQuestionsTab(admin),
          _buildLogsTab(admin),
        ],
      ),
    );
  }

  // Categories Tab
  Widget _buildCategoriesTab(AdminProvider admin) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCategoryDialog(),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: admin.categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final cat = admin.categories[idx];
          final color = AppColors.fromHex(cat.colorHex);
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(IconHelper.getIcon(cat.iconName), color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(cat.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        'Time: ${cat.timeLimitMinutes}m • Qs: ${cat.questionCount}',
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                  onPressed: () => _showCategoryDialog(cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                  onPressed: () => _deleteCategory(cat.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Questions Tab
  Widget _buildQuestionsTab(AdminProvider admin) {
    if (admin.categories.isEmpty) {
      return const Center(child: Text('Create a category first to add questions.'));
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showQuestionDialog(),
      ),
      body: Column(
        children: [
          // Filter Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Text('Select Category: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategoryForQuestions,
                    isExpanded: true,
                    dropdownColor: AppColors.darkSurface,
                    items: admin.categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryForQuestions = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Question List FutureBuilder
          Expanded(
            child: _selectedCategoryForQuestions == null
                ? const SizedBox.shrink()
                : FutureBuilder<List<QuestionModel>>(
                    future: admin.fetchQuestions(_selectedCategoryForQuestions!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
                      }
                      final qList = snapshot.data ?? [];
                      if (qList.isEmpty) {
                        return const Center(child: Text('No questions inside this category. Press + to add some!'));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: qList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final q = qList[idx];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurfaceCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Q${idx + 1} • ${q.difficulty.toUpperCase()}', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showQuestionDialog(q),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _deleteQuestion(q.id),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 12),
                                // Display Options list
                                ...List.generate(q.options.length, (optIdx) {
                                  final isCorrect = q.correctOptionIndex == optIdx;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCorrect ? Icons.check_circle_outline : Icons.radio_button_off,
                                          color: isCorrect ? AppColors.success : AppColors.textMuted,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            q.options[optIdx],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isCorrect ? AppColors.success : AppColors.textSecondary,
                                              fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Student Logs Tab
  Widget _buildLogsTab(AdminProvider admin) {
    if (admin.studentLogs.isEmpty) {
      return const Center(child: Text('No student records found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: admin.studentLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final rec = admin.studentLogs[idx];
        final isPassed = rec.score >= 60;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: (isPassed ? AppColors.success : AppColors.danger).withValues(alpha: 0.12),
                child: Icon(
                  isPassed ? Icons.check : Icons.close,
                  color: isPassed ? AppColors.success : AppColors.danger,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      'Exam: ${rec.categoryName.split('(').first.trim()}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Date: ${rec.completedAt.toString().substring(0, 16)} • Time taken: ${(rec.timeTakenSeconds / 60).floor()}m ${rec.timeTakenSeconds % 60}s',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    )
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${rec.score}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isPassed ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  Text(
                    isPassed ? 'PASSED' : 'FAILED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isPassed ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
