import 'dart:async';
import '../../models/category_model.dart';
import '../../models/question_model.dart';
import '../../models/exam_record_model.dart';
import 'database_service.dart';

class MockDatabaseService implements DatabaseService {
  // In-memory categories
  final List<CategoryModel> _categories = [];
  
  // In-memory questions
  final List<QuestionModel> _questions = [];

  // In-memory exam records
  final List<ExamRecordModel> _examRecords = [];

  MockDatabaseService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // 1. Categories
    _categories.addAll([
      CategoryModel(
        id: 'cat_flutter',
        name: 'Mobile Development (Flutter & Dart)',
        description: 'Test your knowledge on widgets, state management, Dart basics, and lifecycle methods.',
        iconName: 'phone_android',
        colorHex: '#6366F1', // Indigo
        questionCount: 5,
        timeLimitMinutes: 5,
      ),
      CategoryModel(
        id: 'cat_web',
        name: 'Web Engineering (JavaScript & React)',
        description: 'Examine concepts like closures, DOM manipulation, React hooks, and asynchronous JS.',
        iconName: 'web',
        colorHex: '#0D9488', // Teal
        questionCount: 5,
        timeLimitMinutes: 5,
      ),
      CategoryModel(
        id: 'cat_python',
        name: 'Python & Data Analytics',
        description: 'Covers Python fundamentals, data structures, list comprehensions, NumPy, and Pandas.',
        iconName: 'analytics',
        colorHex: '#D97706', // Amber
        questionCount: 5,
        timeLimitMinutes: 5,
      ),
      CategoryModel(
        id: 'cat_cloud',
        name: 'Cloud Computing & DevOps',
        description: 'Assess understanding of virtualization, serverless architectures, storage, CI/CD pipelines, and IAM.',
        iconName: 'cloud_queue',
        colorHex: '#0284C7', // Sky Blue
        questionCount: 5,
        timeLimitMinutes: 5,
      ),
    ]);

    // 2. Questions for Flutter
    _questions.addAll([
      QuestionModel(
        id: 'q_fl_1',
        categoryId: 'cat_flutter',
        questionText: 'Which widget in Flutter is used to layout its children in a vertical array?',
        options: ['Row', 'Column', 'Stack', 'ListView'],
        correctOptionIndex: 1,
        explanation: 'The Column widget displays its children in a vertical array. Row is for horizontal layout, Stack is for overlapping widgets, and ListView is for scrollable vertical lists.',
        difficulty: 'easy',
      ),
      QuestionModel(
        id: 'q_fl_2',
        categoryId: 'cat_flutter',
        questionText: 'What is the purpose of the pubspec.yaml file in a Flutter project?',
        options: [
          'To write the app UI logic',
          'To define assets, dependencies, and project metadata',
          'To compile Dart code to native binary',
          'To manage Android Gradle settings only'
        ],
        correctOptionIndex: 1,
        explanation: 'The pubspec.yaml file is the configuration file of a Flutter project. It defines project dependencies, assets like images and fonts, and packages.',
        difficulty: 'easy',
      ),
      QuestionModel(
        id: 'q_fl_3',
        categoryId: 'cat_flutter',
        questionText: 'What is the difference between StatefulWidget and StatelessWidget?',
        options: [
          'StatefulWidget is faster than StatelessWidget',
          'StatefulWidget has mutable state that can trigger rebuilds, while StatelessWidget is immutable',
          'StatelessWidget can change dynamically but StatefulWidget cannot',
          'Only StatelessWidget supports animations'
        ],
        correctOptionIndex: 1,
        explanation: 'StatefulWidget maintains state that can change over time. When state is updated via setState(), the widget rebuilds. StatelessWidget is immutable and cannot trigger rebuilds programmatically.',
        difficulty: 'medium',
      ),
      QuestionModel(
        id: 'q_fl_4',
        categoryId: 'cat_flutter',
        questionText: 'Which programming language is used to build Flutter apps?',
        options: ['Kotlin', 'Java', 'Dart', 'Swift'],
        correctOptionIndex: 2,
        explanation: 'Flutter applications are written in Dart, which is a client-optimized programming language created by Google.',
        difficulty: 'easy',
      ),
      QuestionModel(
        id: 'q_fl_5',
        categoryId: 'cat_flutter',
        questionText: 'What does the "BuildContext" object represent in Flutter?',
        options: [
          'The state of the system memory',
          'The widget tree structure in JSON format',
          'A handle to the location of a widget in the widget tree',
          'A helper class to compile graphics'
        ],
        correctOptionIndex: 2,
        explanation: 'BuildContext is a handle to the location of a widget in the widget tree. Each widget has its own BuildContext, which becomes the parent of the widget returned by the build method.',
        difficulty: 'hard',
      ),
    ]);

    // Questions for Web
    _questions.addAll([
      QuestionModel(
        id: 'q_web_1',
        categoryId: 'cat_web',
        questionText: 'Which of the following is NOT a hook in React?',
        options: ['useState', 'useEffect', 'useFetch', 'useContext'],
        correctOptionIndex: 2,
        explanation: 'useState, useEffect, and useContext are built-in React hooks. useFetch is not a built-in React hook; it is a common custom hook name.',
        difficulty: 'easy',
      ),
      QuestionModel(
        id: 'q_web_2',
        categoryId: 'cat_web',
        questionText: 'What is a Javascript closure?',
        options: [
          'A way to close browser tabs using script',
          'A function along with its lexical scope environment containing outer scope variables',
          'An error that occurs when a loop never terminates',
          'The official term for writing code in curly braces {}'
        ],
        correctOptionIndex: 1,
        explanation: 'A closure is the combination of a function bundled together (enclosed) with references to its surrounding state (the lexical environment). closures allow an inner function to access the scope of an outer function.',
        difficulty: 'medium',
      ),
      QuestionModel(
        id: 'q_web_3',
        categoryId: 'cat_web',
        questionText: 'What is the correct syntax for declaring a variable that cannot be reassigned?',
        options: ['var x = 5;', 'let x = 5;', 'const x = 5;', 'val x = 5;'],
        correctOptionIndex: 2,
        explanation: 'The "const" keyword declares a block-scoped local variable whose value cannot be changed through reassignment.',
        difficulty: 'easy',
      ),
      QuestionModel(
        id: 'q_web_4',
        categoryId: 'cat_web',
        questionText: 'What is the purpose of the Virtual DOM in React?',
        options: [
          'To securely run scripts in a sandboxed browser environment',
          'To bypass the standard browser rendering pipeline',
          'To keep a lightweight representation of the UI in memory and batch updates for better performance',
          'To store user login session variables'
        ],
        correctOptionIndex: 2,
        explanation: 'The Virtual DOM is React\'s local representation of the real DOM. When state changes, React updates the Virtual DOM first, computes differences (diffing), and then applies optimal changes to the real DOM.',
        difficulty: 'medium',
      ),
      QuestionModel(
        id: 'q_web_5',
        categoryId: 'cat_web',
        questionText: 'What will "console.log(typeof NaN)" output?',
        options: ['"nan"', '"undefined"', '"number"', '"object"'],
        correctOptionIndex: 2,
        explanation: 'In JavaScript, NaN (Not-a-Number) is technically a numeric data type, so typeof NaN evaluates to "number".',
        difficulty: 'hard',
      ),
    ]);

    // Questions for Python
    _questions.addAll([
      QuestionModel(
        id: 'q_py_1',
        categoryId: 'cat_python',
        questionText: 'Which collection type in Python is ordered, mutable, and allows duplicate members?',
        options: ['Set', 'List', 'Tuple', 'Dictionary'],
        correctOptionIndex: 1,
        explanation: 'Lists are ordered, mutable, and allow duplicate items. Sets are unordered, immutable (elements), and do not allow duplicates. Tuples are ordered and immutable. Dictionaries are key-value mappings.',
        difficulty: 'easy',
      ),
      QuestionModel(
        id: 'q_py_2',
        categoryId: 'cat_python',
        questionText: 'How do you create a generator in Python?',
        options: [
          'Using the "generator" keyword before a function',
          'Using the "yield" keyword instead of "return" inside a function',
          'By enclosing a list in brackets []',
          'Using the "new" keyword'
        ],
        correctOptionIndex: 1,
        explanation: 'A generator function is defined like a normal function, but whenever it needs to generate a value, it uses the "yield" keyword rather than "return".',
        difficulty: 'medium',
      ),
      QuestionModel(
        id: 'q_py_3',
        categoryId: 'cat_python',
        questionText: 'In Pandas, how do you select a specific column from a DataFrame named "df"?',
        options: ['df.get_col("name")', 'df["name"]', 'df.select("name")', 'df.column["name"]'],
        correctOptionIndex: 1,
        explanation: 'You select a column from a Pandas DataFrame by slicing it with the column name in brackets, i.e., df["name"] or via dot notation like df.name.',
        difficulty: 'easy',
      ),
      QuestionModel(
        id: 'q_py_4',
        categoryId: 'cat_python',
        questionText: 'What is the output of the expression: [x**2 for x in range(4) if x % 2 == 0]?',
        options: ['[0, 4]', '[0, 2]', '[0, 4, 16]', '[1, 9]'],
        correctOptionIndex: 0,
        explanation: 'This is a list comprehension. The range(4) generates 0, 1, 2, 3. The condition "if x % 2 == 0" filters in only 0 and 2. Squaring them yields [0, 4].',
        difficulty: 'medium',
      ),
      QuestionModel(
        id: 'q_py_5',
        categoryId: 'cat_python',
        questionText: 'What is the time complexity of looking up a key in a standard Python dictionary in the average case?',
        options: ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'],
        correctOptionIndex: 0,
        explanation: 'Python dictionaries are implemented using hash tables. Therefore, searching/retrieving a key takes O(1) constant time on average.',
        difficulty: 'hard',
      ),
    ]);

    // Questions for Cloud
    _questions.addAll([
      QuestionModel(
        id: 'q_cl_1',
        categoryId: 'cat_cloud',
        questionText: 'What is a core benefit of Serverless Computing?',
        options: [
          'No servers are involved in running your code',
          'Developers are freed from managing or provisioning physical/virtual server instances',
          'It is always cheaper for all workloads regardless of scale',
          'It executes code faster than dedicated bare-metal servers'
        ],
        correctOptionIndex: 1,
        explanation: 'Serverless does not mean there are no servers; it means the cloud provider dynamically manages the server infrastructure, scaling, and provisioning, freeing developers from those operations.',
        difficulty: 'easy',
      ),
      QuestionModel(
        id: 'q_cl_2',
        categoryId: 'cat_cloud',
        questionText: 'What does "IAM" stand for in cloud security?',
        options: [
          'Information Access Method',
          'Identity and Access Management',
          'Intelligent Asset Monitoring',
          'Infrastructure Assessment Manager'
        ],
        correctOptionIndex: 1,
        explanation: 'IAM stands for Identity and Access Management. It allows you to manage digital identities and user permissions to access resources securely.',
        difficulty: 'easy',
      ),
      QuestionModel(
        id: 'q_cl_3',
        categoryId: 'cat_cloud',
        questionText: 'Which cloud database service model scales storage and compute independently and handles automated sharding?',
        options: ['Relational Database (SQL)', 'Distributed NoSQL Database (e.g. DynamoDB/Firestore)', 'Local Database', 'Flat-file Storage'],
        correctOptionIndex: 1,
        explanation: 'Cloud NoSQL databases like Firestore or DynamoDB are designed for massive horizontal scalability, automatically sharding data across nodes and scaling storage dynamically.',
        difficulty: 'medium',
      ),
      QuestionModel(
        id: 'q_cl_4',
        categoryId: 'cat_cloud',
        questionText: 'What does CI/CD pipeline automation primarily help with?',
        options: [
          'Optimizing cloud subscription costs',
          'Continuous Integration of code and Continuous Delivery/Deployment of builds',
          'Improving server CPU clock speed',
          'Encrypting databases automatically'
        ],
        correctOptionIndex: 1,
        explanation: 'CI/CD pipelines automate testing, building, and deploying software projects, enabling developers to integrate changes rapidly and deploy updates with minimal manual overhead.',
        difficulty: 'medium',
      ),
      QuestionModel(
        id: 'q_cl_5',
        categoryId: 'cat_cloud',
        questionText: 'Which of the following describes a Virtual Private Cloud (VPC)?',
        options: [
          'A physical cable connecting your home router to cloud datacenters',
          'A logically isolated virtual network dedicated to your cloud account',
          'An encrypted browser connection to access cloud control panels',
          'A system to run virtual machines locally without internet'
        ],
        correctOptionIndex: 2,
        explanation: 'A Virtual Private Cloud (VPC) is a logically isolated virtual network within a public cloud. It grants complete control over subnet configurations, IP routing, and gateways.',
        difficulty: 'hard',
      ),
    ]);

    // 3. Exam Records
    final baseTime = DateTime.now();
    _examRecords.addAll([
      ExamRecordModel(
        id: 'rec_1',
        userId: 'alice_uid',
        userName: 'Alice Smith',
        categoryId: 'cat_flutter',
        categoryName: 'Mobile Development (Flutter & Dart)',
        score: 100, // 5/5
        totalQuestions: 5,
        correctAnswers: 5,
        timeTakenSeconds: 155,
        completedAt: baseTime.subtract(const Duration(hours: 2)),
        certificateId: 'CERT-FL-A9F2',
      ),
      ExamRecordModel(
        id: 'rec_2',
        userId: 'bob_uid',
        userName: 'Bob Miller',
        categoryId: 'cat_flutter',
        categoryName: 'Mobile Development (Flutter & Dart)',
        score: 80, // 4/5
        totalQuestions: 5,
        correctAnswers: 4,
        timeTakenSeconds: 195,
        completedAt: baseTime.subtract(const Duration(hours: 3)),
        certificateId: 'CERT-FL-B4C1',
      ),
      ExamRecordModel(
        id: 'rec_3',
        userId: 'charlie_uid',
        userName: 'Charlie Davis',
        categoryId: 'cat_web',
        categoryName: 'Web Engineering (JavaScript & React)',
        score: 80, // 4/5
        totalQuestions: 5,
        correctAnswers: 4,
        timeTakenSeconds: 140,
        completedAt: baseTime.subtract(const Duration(hours: 1)),
        certificateId: 'CERT-WB-C82D',
      ),
      ExamRecordModel(
        id: 'rec_4',
        userId: 'alice_uid',
        userName: 'Alice Smith',
        categoryId: 'cat_python',
        categoryName: 'Python & Data Analytics',
        score: 80, // 4/5
        totalQuestions: 5,
        correctAnswers: 4,
        timeTakenSeconds: 120,
        completedAt: baseTime.subtract(const Duration(minutes: 30)),
        certificateId: 'CERT-PY-D3E9',
      ),
      ExamRecordModel(
        id: 'rec_5',
        userId: 'dan_uid',
        userName: 'Daniel Green',
        categoryId: 'cat_cloud',
        categoryName: 'Cloud Computing & DevOps',
        score: 60, // 3/5
        totalQuestions: 5,
        correctAnswers: 3,
        timeTakenSeconds: 210,
        completedAt: baseTime.subtract(const Duration(days: 1)),
        certificateId: 'CERT-CL-E11B',
      ),
    ]);
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_categories);
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_categories.any((c) => c.id == category.id)) {
      throw Exception('Category with this ID already exists');
    }
    _categories.add(category);
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index == -1) {
      throw Exception('Category not found');
    }
    _categories[index] = category;
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _categories.removeWhere((c) => c.id == categoryId);
    _questions.removeWhere((q) => q.categoryId == categoryId);
  }

  @override
  Future<List<QuestionModel>> getQuestions(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _questions.where((q) => q.categoryId == categoryId).toList();
  }

  @override
  Future<void> addQuestion(QuestionModel question) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _questions.add(question);
    
    // Update question count in Category
    final catIndex = _categories.indexWhere((c) => c.id == question.categoryId);
    if (catIndex != -1) {
      final old = _categories[catIndex];
      _categories[catIndex] = old.copyWith(questionCount: old.questionCount + 1);
    }
  }

  @override
  Future<void> updateQuestion(QuestionModel question) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _questions.indexWhere((q) => q.id == question.id);
    if (index == -1) {
      throw Exception('Question not found');
    }
    _questions[index] = question;
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _questions.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      final categoryId = _questions[index].categoryId;
      _questions.removeAt(index);
      
      // Update question count in Category
      final catIndex = _categories.indexWhere((c) => c.id == categoryId);
      if (catIndex != -1) {
        final old = _categories[catIndex];
        _categories[catIndex] = old.copyWith(questionCount: old.questionCount - 1);
      }
    }
  }

  @override
  Future<void> saveExamRecord(ExamRecordModel record) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _examRecords.add(record);
  }

  @override
  Future<List<ExamRecordModel>> getExamRecords(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _examRecords.where((r) => r.userId == userId).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  @override
  Future<List<ExamRecordModel>> getAllExamRecords() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_examRecords)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  @override
  Future<List<ExamRecordModel>> getLeaderboard(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Filter by category, sort by score descending, then by time taken ascending
    return _examRecords.where((r) => r.categoryId == categoryId).toList()
      ..sort((a, b) {
        int scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return a.timeTakenSeconds.compareTo(b.timeTakenSeconds);
      });
  }

  @override
  Future<List<ExamRecordModel>> getGlobalLeaderboard() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Sort all records by score descending, then by time taken ascending
    return List.from(_examRecords)
      ..sort((a, b) {
        int scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return a.timeTakenSeconds.compareTo(b.timeTakenSeconds);
      });
  }
}
