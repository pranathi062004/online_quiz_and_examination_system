import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';
import '../../models/question_model.dart';
import '../../models/exam_record_model.dart';
import 'database_service.dart';

class FirestoreDatabaseService implements DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<T> _withTimeout<T>(Future<T> future) {
    return future.timeout(
      const Duration(seconds: 6),
      onTimeout: () => throw TimeoutException(
        'Database connection timed out. Please check your connection or switch to Mock Mode.',
      ),
    );
  }

  // Categories
  @override
  Future<List<CategoryModel>> getCategories() async {
    final querySnapshot = await _withTimeout(_firestore.collection('categories').get());
    
    // Auto-seed if the database is currently empty
    if (querySnapshot.docs.isEmpty) {
      await _seedDefaultData();
      final freshSnapshot = await _withTimeout(_firestore.collection('categories').get());
      return freshSnapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data()))
          .toList();
    }

    return querySnapshot.docs
        .map((doc) => CategoryModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    await _withTimeout(_firestore
        .collection('categories')
        .doc(category.id)
        .set(category.toMap()));
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    await _withTimeout(_firestore
        .collection('categories')
        .doc(category.id)
        .update(category.toMap()));
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    // Delete the category document
    await _withTimeout(_firestore.collection('categories').doc(categoryId).delete());

    // Delete all questions associated with this category
    final questionsSnapshot = await _withTimeout(_firestore
        .collection('questions')
        .where('categoryId', isEqualTo: categoryId)
        .get());

    final batch = _firestore.batch();
    for (var doc in questionsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await _withTimeout(batch.commit());
  }

  // Questions
  @override
  Future<List<QuestionModel>> getQuestions(String categoryId) async {
    final querySnapshot = await _withTimeout(_firestore
        .collection('questions')
        .where('categoryId', isEqualTo: categoryId)
        .get());
    
    // Fallback: If for some reason questions are empty but categories exist, let's see if we should seed.
    // Usually they are seeded together, so we just return the list.
    return querySnapshot.docs
        .map((doc) => QuestionModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> addQuestion(QuestionModel question) async {
    // Save question document
    await _withTimeout(_firestore
        .collection('questions')
        .doc(question.id)
        .set(question.toMap()));

    // Update the questionCount in the corresponding category using a transaction
    final categoryRef = _firestore.collection('categories').doc(question.categoryId);
    await _withTimeout(_firestore.runTransaction((transaction) async {
      final categoryDoc = await transaction.get(categoryRef);
      if (categoryDoc.exists) {
        final currentCount = categoryDoc.data()?['questionCount'] as int? ?? 0;
        transaction.update(categoryRef, {'questionCount': currentCount + 1});
      }
    }));
  }

  @override
  Future<void> updateQuestion(QuestionModel question) async {
    await _withTimeout(_firestore
        .collection('questions')
        .doc(question.id)
        .update(question.toMap()));
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    final questionDoc = await _withTimeout(_firestore.collection('questions').doc(questionId).get());
    if (questionDoc.exists) {
      final categoryId = questionDoc.data()?['categoryId'] as String?;
      if (categoryId != null) {
        final categoryRef = _firestore.collection('categories').doc(categoryId);
        await _withTimeout(_firestore.runTransaction((transaction) async {
          final categoryDoc = await transaction.get(categoryRef);
          if (categoryDoc.exists) {
            final currentCount = categoryDoc.data()?['questionCount'] as int? ?? 0;
            transaction.update(categoryRef, {
              'questionCount': currentCount > 0 ? currentCount - 1 : 0
            });
          }
        }));
      }
      await _withTimeout(_firestore.collection('questions').doc(questionId).delete());
    }
  }

  // Exam Records
  @override
  Future<void> saveExamRecord(ExamRecordModel record) async {
    await _withTimeout(_firestore
        .collection('exam_records')
        .doc(record.id)
        .set(record.toMap()));
  }

  @override
  Future<List<ExamRecordModel>> getExamRecords(String userId) async {
    final querySnapshot = await _withTimeout(_firestore
        .collection('exam_records')
        .where('userId', isEqualTo: userId)
        .get());

    final records = querySnapshot.docs
        .map((doc) => ExamRecordModel.fromMap(doc.data()))
        .toList();

    // Sort by completion time descending
    records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return records;
  }

  @override
  Future<List<ExamRecordModel>> getAllExamRecords() async {
    final querySnapshot = await _withTimeout(_firestore.collection('exam_records').get());
    final records = querySnapshot.docs
        .map((doc) => ExamRecordModel.fromMap(doc.data()))
        .toList();

    // Sort by completion time descending
    records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return records;
  }

  // Leaderboard
  @override
  Future<List<ExamRecordModel>> getLeaderboard(String categoryId) async {
    final querySnapshot = await _withTimeout(_firestore
        .collection('exam_records')
        .where('categoryId', isEqualTo: categoryId)
        .get());

    final records = querySnapshot.docs
        .map((doc) => ExamRecordModel.fromMap(doc.data()))
        .toList();

    // Sort by score descending, then by time taken ascending
    records.sort((a, b) {
      int scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.timeTakenSeconds.compareTo(b.timeTakenSeconds);
    });

    return records;
  }

  @override
  Future<List<ExamRecordModel>> getGlobalLeaderboard() async {
    final querySnapshot = await _withTimeout(_firestore.collection('exam_records').get());
    final records = querySnapshot.docs
        .map((doc) => ExamRecordModel.fromMap(doc.data()))
        .toList();

    // Sort by score descending, then by time taken ascending
    records.sort((a, b) {
      int scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.timeTakenSeconds.compareTo(b.timeTakenSeconds);
    });

    return records;
  }

  // Helper method to seed initial categories, questions, and high scores
  Future<void> _seedDefaultData() async {
    final batch = _firestore.batch();

    // 1. Add Categories
    final categories = [
      CategoryModel(
        id: 'cat_flutter',
        name: 'Mobile Development (Flutter & Dart)',
        description: 'Test your knowledge on widgets, state management, Dart basics, and lifecycle methods.',
        iconName: 'phone_android',
        colorHex: '#6366F1',
        questionCount: 5,
        timeLimitMinutes: 5,
      ),
      CategoryModel(
        id: 'cat_web',
        name: 'Web Engineering (JavaScript & React)',
        description: 'Examine concepts like closures, DOM manipulation, React hooks, and asynchronous JS.',
        iconName: 'web',
        colorHex: '#0D9488',
        questionCount: 5,
        timeLimitMinutes: 5,
      ),
      CategoryModel(
        id: 'cat_python',
        name: 'Python & Data Analytics',
        description: 'Covers Python fundamentals, data structures, list comprehensions, NumPy, and Pandas.',
        iconName: 'analytics',
        colorHex: '#D97706',
        questionCount: 5,
        timeLimitMinutes: 5,
      ),
      CategoryModel(
        id: 'cat_cloud',
        name: 'Cloud Computing & DevOps',
        description: 'Assess understanding of virtualization, serverless architectures, storage, CI/CD pipelines, and IAM.',
        iconName: 'cloud_queue',
        colorHex: '#0284C7',
        questionCount: 5,
        timeLimitMinutes: 5,
      ),
    ];

    for (var cat in categories) {
      final ref = _firestore.collection('categories').doc(cat.id);
      batch.set(ref, cat.toMap());
    }

    // 2. Add Questions
    final questions = [
      // Flutter
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

      // Web
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

      // Python
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

      // Cloud
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
    ];

    for (var q in questions) {
      final ref = _firestore.collection('questions').doc(q.id);
      batch.set(ref, q.toMap());
    }

    // 3. Add initial Leaderboard entries
    final baseTime = DateTime.now();
    final records = [
      ExamRecordModel(
        id: 'rec_seed_1',
        userId: 'alice_uid',
        userName: 'Alice Smith',
        categoryId: 'cat_flutter',
        categoryName: 'Mobile Development (Flutter & Dart)',
        score: 100,
        totalQuestions: 5,
        correctAnswers: 5,
        timeTakenSeconds: 155,
        completedAt: baseTime.subtract(const Duration(hours: 2)),
        certificateId: 'CERT-FL-A9F2',
      ),
      ExamRecordModel(
        id: 'rec_seed_2',
        userId: 'bob_uid',
        userName: 'Bob Miller',
        categoryId: 'cat_flutter',
        categoryName: 'Mobile Development (Flutter & Dart)',
        score: 80,
        totalQuestions: 5,
        correctAnswers: 4,
        timeTakenSeconds: 195,
        completedAt: baseTime.subtract(const Duration(hours: 3)),
        certificateId: 'CERT-FL-B4C1',
      ),
      ExamRecordModel(
        id: 'rec_seed_3',
        userId: 'charlie_uid',
        userName: 'Charlie Davis',
        categoryId: 'cat_web',
        categoryName: 'Web Engineering (JavaScript & React)',
        score: 80,
        totalQuestions: 5,
        correctAnswers: 4,
        timeTakenSeconds: 140,
        completedAt: baseTime.subtract(const Duration(hours: 1)),
        certificateId: 'CERT-WB-C82D',
      ),
      ExamRecordModel(
        id: 'rec_seed_4',
        userId: 'alice_uid',
        userName: 'Alice Smith',
        categoryId: 'cat_python',
        categoryName: 'Python & Data Analytics',
        score: 80,
        totalQuestions: 5,
        correctAnswers: 4,
        timeTakenSeconds: 120,
        completedAt: baseTime.subtract(const Duration(minutes: 30)),
        certificateId: 'CERT-PY-D3E9',
      ),
      ExamRecordModel(
        id: 'rec_seed_5',
        userId: 'dan_uid',
        userName: 'Daniel Green',
        categoryId: 'cat_cloud',
        categoryName: 'Cloud Computing & DevOps',
        score: 60,
        totalQuestions: 5,
        correctAnswers: 3,
        timeTakenSeconds: 210,
        completedAt: baseTime.subtract(const Duration(days: 1)),
        certificateId: 'CERT-CL-E11B',
      ),
    ];

    for (var rec in records) {
      final ref = _firestore.collection('exam_records').doc(rec.id);
      batch.set(ref, rec.toMap());
    }

    await batch.commit();
  }
}
