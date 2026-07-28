import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';
import '../models/exam_record_model.dart';
import '../services/service_locator.dart';

class AdminProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  List<ExamRecordModel> _studentLogs = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  List<ExamRecordModel> get studentLogs => _studentLogs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await locator.databaseService.getCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudentLogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _studentLogs = await locator.databaseService.getAllExamRecords();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory({
    required String name,
    required String description,
    required String iconName,
    required String colorHex,
    required int timeLimitMinutes,
  }) async {
    _isLoading = true;
    notifyListeners();

    final category = CategoryModel(
      id: 'cat_${const Uuid().v4().substring(0, 8)}',
      name: name,
      description: description,
      iconName: iconName,
      colorHex: colorHex,
      questionCount: 0,
      timeLimitMinutes: timeLimitMinutes,
    );

    try {
      await locator.databaseService.addCategory(category);
      await loadCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> editCategory(CategoryModel category) async {
    _isLoading = true;
    notifyListeners();

    try {
      await locator.databaseService.updateCategory(category);
      await loadCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeCategory(String categoryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await locator.databaseService.deleteCategory(categoryId);
      await loadCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<QuestionModel>> fetchQuestions(String categoryId) async {
    try {
      return await locator.databaseService.getQuestions(categoryId);
    } catch (e) {
      debugPrint("Error loading questions: $e");
      return [];
    }
  }

  Future<bool> createQuestion({
    required String categoryId,
    required String questionText,
    required List<String> options,
    required int correctOptionIndex,
    required String explanation,
    required String difficulty,
  }) async {
    final question = QuestionModel(
      id: 'q_${const Uuid().v4().substring(0, 8)}',
      categoryId: categoryId,
      questionText: questionText,
      options: options,
      correctOptionIndex: correctOptionIndex,
      explanation: explanation,
      difficulty: difficulty,
    );

    try {
      await locator.databaseService.addQuestion(question);
      await loadCategories(); // Reload to refresh question counts
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> editQuestion(QuestionModel question) async {
    try {
      await locator.databaseService.updateQuestion(question);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeQuestion(String questionId) async {
    try {
      await locator.databaseService.deleteQuestion(questionId);
      await loadCategories(); // Reload to refresh question counts
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
