import '../../models/category_model.dart';
import '../../models/question_model.dart';
import '../../models/exam_record_model.dart';

abstract class DatabaseService {
  // Categories
  Future<List<CategoryModel>> getCategories();
  Future<void> addCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String categoryId);

  // Questions
  Future<List<QuestionModel>> getQuestions(String categoryId);
  Future<void> addQuestion(QuestionModel question);
  Future<void> updateQuestion(QuestionModel question);
  Future<void> deleteQuestion(String questionId);

  // Exam Records
  Future<void> saveExamRecord(ExamRecordModel record);
  Future<List<ExamRecordModel>> getExamRecords(String userId);
  Future<List<ExamRecordModel>> getAllExamRecords();

  // Leaderboard
  Future<List<ExamRecordModel>> getLeaderboard(String categoryId);
  Future<List<ExamRecordModel>> getGlobalLeaderboard();
}
