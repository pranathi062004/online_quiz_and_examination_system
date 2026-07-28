import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';
import '../models/exam_record_model.dart';
import '../services/service_locator.dart';

class ExamProvider extends ChangeNotifier {
  CategoryModel? _activeCategory;
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  
  // Maps question index -> selected option index
  final Map<int, int> _selectedAnswers = {};
  
  // Set of flagged question indices
  final Set<int> _flaggedQuestions = {};

  int _timeLeftSeconds = 0;
  Timer? _timer;
  bool _isExamInProgress = false;
  bool _isLoadingQuestions = false;
  
  String _userId = '';
  String _userName = '';

  ExamRecordModel? _lastRecord;
  List<ExamRecordModel> _userRecords = [];
  List<ExamRecordModel> _globalLeaderboard = [];
  bool _isLoadingRecords = false;

  // Getters
  CategoryModel? get activeCategory => _activeCategory;
  List<QuestionModel> get questions => _questions;
  int get currentIndex => _currentIndex;
  Map<int, int> get selectedAnswers => _selectedAnswers;
  Set<int> get flaggedQuestions => _flaggedQuestions;
  int get timeLeftSeconds => _timeLeftSeconds;
  bool get isExamInProgress => _isExamInProgress;
  bool get isLoadingQuestions => _isLoadingQuestions;
  ExamRecordModel? get lastRecord => _lastRecord;
  List<ExamRecordModel> get userRecords => _userRecords;
  List<ExamRecordModel> get globalLeaderboard => _globalLeaderboard;
  bool get isLoadingRecords => _isLoadingRecords;

  int get totalQuestions => _questions.length;
  int get answeredCount => _selectedAnswers.length;

  Future<void> fetchUserRecords(String userId) async {
    _isLoadingRecords = true;
    notifyListeners();
    try {
      _userRecords = await locator.databaseService.getExamRecords(userId);
    } catch (e) {
      debugPrint("Error fetching records: $e");
    } finally {
      _isLoadingRecords = false;
      notifyListeners();
    }
  }

  Future<void> fetchGlobalLeaderboard() async {
    _isLoadingRecords = true;
    notifyListeners();
    try {
      _globalLeaderboard = await locator.databaseService.getGlobalLeaderboard();
    } catch (e) {
      debugPrint("Error fetching leaderboard: $e");
    } finally {
      _isLoadingRecords = false;
      notifyListeners();
    }
  }

  Future<void> startExam(CategoryModel category, String userId, String userName) async {
    _activeCategory = category;
    _userId = userId;
    _userName = userName;
    _isLoadingQuestions = true;
    _currentIndex = 0;
    _selectedAnswers.clear;
    _selectedAnswers.clear();
    _flaggedQuestions.clear();
    _isExamInProgress = true;
    _lastRecord = null;
    notifyListeners();

    try {
      _questions = await locator.databaseService.getQuestions(category.id);
      _timeLeftSeconds = category.timeLimitMinutes * 60;
      _isLoadingQuestions = false;
      notifyListeners();
      
      _startTimer();
    } catch (e) {
      _isLoadingQuestions = false;
      _isExamInProgress = false;
      notifyListeners();
      rethrow;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftSeconds > 0) {
        _timeLeftSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _isExamInProgress = false;
        notifyListeners();
      }
    });
  }

  void selectAnswer(int questionIndex, int optionIndex) {
    _selectedAnswers[questionIndex] = optionIndex;
    notifyListeners();
  }

  void toggleFlagQuestion(int questionIndex) {
    if (_flaggedQuestions.contains(questionIndex)) {
      _flaggedQuestions.remove(questionIndex);
    } else {
      _flaggedQuestions.add(questionIndex);
    }
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  Future<ExamRecordModel> submitExam() async {
    _timer?.cancel();
    _isExamInProgress = false;
    notifyListeners();

    int correctAnswers = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctOptionIndex) {
        correctAnswers++;
      }
    }

    final totalQ = _questions.length;
    final int scorePercentage = totalQ > 0 ? ((correctAnswers / totalQ) * 100).round() : 0;
    final timeTaken = (_activeCategory!.timeLimitMinutes * 60) - _timeLeftSeconds;

    // Generate certificate if passed (e.g. >= 60%)
    String certId = '';
    if (scorePercentage >= 60) {
      certId = 'CERT-${_activeCategory!.id.replaceAll('cat_', '').toUpperCase()}-${const Uuid().v4().substring(0, 6).toUpperCase()}';
    }

    final record = ExamRecordModel(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      userId: _userId,
      userName: _userName,
      categoryId: _activeCategory!.id,
      categoryName: _activeCategory!.name,
      score: scorePercentage,
      totalQuestions: totalQ,
      correctAnswers: correctAnswers,
      timeTakenSeconds: timeTaken,
      completedAt: DateTime.now(),
      certificateId: certId,
    );

    try {
      await locator.databaseService.saveExamRecord(record);
      _lastRecord = record;
      // Refresh local caches
      await fetchUserRecords(_userId);
      await fetchGlobalLeaderboard();
    } catch (e) {
      debugPrint("Error saving exam record: $e");
    }

    notifyListeners();
    return record;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
