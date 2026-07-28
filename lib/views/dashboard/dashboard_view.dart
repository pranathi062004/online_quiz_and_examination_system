import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/icon_helper.dart';
import '../../models/category_model.dart';
import '../../models/exam_record_model.dart';
import '../../state/auth_provider.dart';
import '../../state/exam_provider.dart';
import '../../state/admin_provider.dart';
import '../auth/login_view.dart';
import '../exam/exam_view.dart';
import '../leaderboard/leaderboard_view.dart';
import '../admin/admin_panel_view.dart';
import '../widgets/animated_background.dart';
import '../certificate/certificate_view.dart';
import '../../core/utils/fullscreen_helper.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        Provider.of<AdminProvider>(context, listen: false).loadCategories();
        Provider.of<ExamProvider>(context, listen: false).fetchUserRecords(auth.user!.uid);
        Provider.of<ExamProvider>(context, listen: false).fetchGlobalLeaderboard();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCompletedWarningDialog(CategoryModel cat, ExamRecordModel record) {
    final isPassed = record.score >= 60;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      color: AppColors.success,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Exam Already Completed',
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'You completed the ${cat.name} exam with a score of ${record.score}% on ${record.completedAt.toString().substring(0, 10)}.\n\nEach exam can only be taken once to ensure academic evaluation integrity.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isPassed) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CertificateView(record: record),
                            ),
                          );
                        },
                        icon: const Icon(Icons.workspace_premium),
                        label: const Text('View Certificate'),
                      ),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    }
  }

  void _showStartQuizDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.fromHex(category.colorHex).withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.fromHex(category.colorHex).withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.fromHex(category.colorHex).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        IconHelper.getIcon(category.iconName),
                        color: AppColors.fromHex(category.colorHex),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Exam Instructions',
                            style: TextStyle(color: AppColors.fromHex(category.colorHex), fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  category.description,
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 20),
                // Parameters
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDialogParam(Icons.timer_outlined, '${category.timeLimitMinutes} Mins', 'Duration'),
                      Container(width: 1, height: 30, color: AppColors.darkBorder),
                      _buildDialogParam(Icons.format_list_numbered, '${category.questionCount} Qs', 'Questions'),
                      Container(width: 1, height: 30, color: AppColors.darkBorder),
                      _buildDialogParam(Icons.grade_outlined, '60%', 'Passing Score'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Warning
                const Text(
                  'Note: Once started, the timer cannot be paused. Make sure you have a stable connection.',
                  style: TextStyle(color: AppColors.warning, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.security, color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Anti-Cheat Warning: Starting the exam will force Fullscreen Mode. Exiting fullscreen, minimizing the browser, or changing tabs is strictly prohibited. If any attempt to switch tabs or exit fullscreen is detected, your exam will automatically be terminated and submitted immediately.',
                        style: TextStyle(color: AppColors.danger.withValues(alpha: 0.9), fontSize: 11, height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.fromHex(category.colorHex),
                        ),
                        onPressed: () {
                          // Request browser fullscreen for anti-cheating FIRST to keep user gesture context
                          requestFullscreen();
                          
                          Navigator.pop(dialogContext);
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final exam = Provider.of<ExamProvider>(context, listen: false);
                          
                          // Start exam without awaiting — ExamView handles loading state
                          exam.startExam(category, auth.user!.uid, auth.user!.displayName);
                          
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ExamView()),
                            );
                          }
                        },
                        child: const Text('Start Now'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogParam(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(height: 6),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final admin = Provider.of<AdminProvider>(context);
    final exam = Provider.of<ExamProvider>(context);
    
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    
    // Calculate Stats
    final totalQuizzes = exam.userRecords.length;
    final avgScore = totalQuizzes > 0 
        ? (exam.userRecords.map((r) => r.score).reduce((a, b) => a + b) / totalQuizzes).round()
        : 0;
    final passQuizzes = exam.userRecords.where((r) => r.score >= 60).length;
    final passRate = totalQuizzes > 0 
        ? ((passQuizzes / totalQuizzes) * 100).round()
        : 0;

    final filteredCategories = admin.categories.where((cat) {
      final nameMatch = cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final descMatch = cat.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatch || descMatch;
    }).toList();



    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ).createShader(bounds),
              child: const Text(
                'ExamiQ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (auth.user != null) ...[
            if (isDesktop) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    auth.user?.displayName ?? 'Candidate',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    auth.isAdmin ? 'Administrator' : 'Student Portal',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(width: 10),
            ],
            Tooltip(
              message: auth.user?.displayName ?? 'User Profile',
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  (auth.user?.displayName ?? 'C').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 1,
            height: 24,
            color: AppColors.darkBorder,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined, color: AppColors.textPrimary, size: 20),
            tooltip: 'Leaderboards',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardView()),
              );
            },
          ),
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.secondary, size: 20),
              tooltip: 'Admin Management Panel',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelView()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger, size: 20),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : AnimatedBackground(
              child: RefreshIndicator(
                onRefresh: () async {
                  await admin.loadCategories();
                  if (auth.user != null) {
                    await exam.fetchUserRecords(auth.user!.uid);
                    await exam.fetchGlobalLeaderboard();
                  }
                },
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stat cards layout (responsive layout)
                      _buildResponsiveStatCards(context, totalQuizzes, avgScore, passRate),
                      const SizedBox(height: 36),

                      // Database Connection Error Card
                      if (admin.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.danger, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Database Error: ${admin.error}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'The Firebase database could not be reached. You can switch to Offline Mock Mode to run the app using local preview data.',
                                style: TextStyle(fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  final auth = Provider.of<AuthProvider>(context, listen: false);
                                  final admin = Provider.of<AdminProvider>(context, listen: false);
                                  final exam = Provider.of<ExamProvider>(context, listen: false);
                                  final email = auth.user?.email;

                                  await auth.toggleMockMode(true, defaultEmail: email);
                                  
                                  await admin.loadCategories();
                                  if (auth.user != null) {
                                    await exam.fetchUserRecords(auth.user!.uid);
                                    await exam.fetchGlobalLeaderboard();
                                  }
                                },
                                icon: const Icon(Icons.swap_calls),
                                label: const Text('Switch to Offline Mock Mode'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Exam Categories title & description
                      Text(
                        'Exam Categories',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose a category to start your exam evaluation',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),

                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search exam categories...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.darkSurfaceCard,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Categories Grid
                      if (filteredCategories.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                const Text(
                                  'No exam categories found matching your search.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 360,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 220,
                          ),
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final cat = filteredCategories[index];
                            final catColor = AppColors.fromHex(cat.colorHex);
                            
                            // Check completion status for this category
                            final matchingRecords = exam.userRecords.where((r) => r.categoryId == cat.id).toList();
                            final isCompleted = matchingRecords.isNotEmpty;
                            final completedRec = isCompleted ? matchingRecords.first : null;
                            
                            // Subtle staggered entry animation
                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 400 + (index * 80).clamp(0, 400)),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1.0 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: InkWell(
                                onTap: () {
                                  if (isCompleted && completedRec != null) {
                                    _showCompletedWarningDialog(cat, completedRec);
                                  } else {
                                    _showStartQuizDialog(cat);
                                  }
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkSurfaceCard,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isCompleted ? AppColors.success.withValues(alpha: 0.5) : AppColors.darkBorder,
                                      width: isCompleted ? 1.5 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isCompleted 
                                            ? AppColors.success.withValues(alpha: 0.05) 
                                            : Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: catColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              IconHelper.getIcon(cat.iconName),
                                              color: catColor,
                                              size: 24,
                                            ),
                                          ),
                                          if (isCompleted) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.success.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check, color: AppColors.success, size: 10),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Completed',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ] else ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.darkSurface,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: AppColors.darkBorder),
                                              ),
                                              child: Text(
                                                '${cat.timeLimitMinutes}m',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        cat.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: Text(
                                          cat.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${cat.questionCount} Questions',
                                            style: TextStyle(
                                              color: isCompleted ? AppColors.success : catColor, 
                                              fontWeight: FontWeight.bold, 
                                              fontSize: 12,
                                            ),
                                          ),
                                          Icon(
                                            isCompleted ? Icons.check_circle : Icons.arrow_forward_rounded,
                                            color: isCompleted ? AppColors.success : AppColors.textSecondary,
                                            size: 18,
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 48),

                      // Recent History
                      if (exam.userRecords.isNotEmpty) ...[
                        Text(
                          'Your Recent Exams',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: exam.userRecords.length > 5 ? 5 : exam.userRecords.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final rec = exam.userRecords[idx];
                            final isPassed = rec.score >= 60;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurfaceCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.darkBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPassed ? Icons.check_circle : Icons.cancel,
                                    color: isPassed ? AppColors.success : AppColors.danger,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rec.categoryName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Completed: ${rec.completedAt.toString().substring(0, 16)} • Time: ${(rec.timeTakenSeconds / 60).floor()}m ${rec.timeTakenSeconds % 60}s',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
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
                                        '${rec.correctAnswers}/${rec.totalQuestions} Right',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildResponsiveStatCards(BuildContext context, int totalQuizzes, int avgScore, int passRate) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Quizzes Taken', '$totalQuizzes', Icons.assignment_turned_in_outlined, AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Average Score', '$avgScore%', Icons.star_border, AppColors.warning)),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard('Pass Rate', '$passRate%', Icons.verified_user_outlined, AppColors.success),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: _buildStatCard('Quizzes Taken', '$totalQuizzes', Icons.assignment_turned_in_outlined, AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Average Score', '$avgScore%', Icons.star_border, AppColors.warning)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Pass Rate', '$passRate%', Icons.verified_user_outlined, AppColors.success)),
        ],
      );
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
               color: accentColor.withValues(alpha: 0.15),
               borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


