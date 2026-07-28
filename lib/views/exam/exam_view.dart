import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';
import '../../state/exam_provider.dart';
import '../results/result_view.dart';
import '../../core/utils/fullscreen_helper.dart';
import 'package:flutter/services.dart';

class ExamView extends StatefulWidget {
  const ExamView({super.key});

  @override
  State<ExamView> createState() => _ExamViewState();
}

class _ExamViewState extends State<ExamView> with WidgetsBindingObserver {
  // Flag to prevent double submission triggers
  bool _submitting = false;
  // Track whether the exam was in progress so we know when timer truly expired
  bool _wasExamInProgress = false;

  bool _initialRulesShown = false;
  bool _examStarted = false;
  DateTime? _lastWarningTime;
  StreamSubscription<void>? _fullscreenSubscription;
  StreamSubscription<void>? _escapeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    if (kIsWeb) {
      // Subscribe to browser fullscreen changes to detect exits
      _fullscreenSubscription = getFullscreenChangeStream().listen((_) {
        // Fast 10ms delay to allow browser thread to update document.fullscreenElement instantly
        Future.delayed(const Duration(milliseconds: 10), () {
          if (!mounted || !_examStarted) return;
          final exam = Provider.of<ExamProvider>(context, listen: false);
          if (exam.isExamInProgress && !_submitting) {
            if (!isCurrentlyFullscreen()) {
              _handleTabChangeAttempt();
            }
          }
        });
      });

      // Subscribe to Escape keydown events for immediate lockout warning/termination
      _escapeSubscription = getEscapeKeyPressStream().listen((_) {
        if (mounted && _examStarted && !_submitting) {
          _handleTabChangeAttempt();
        }
      });
    }

    // Intercept physical hardware keyboard events (like Escape) globally for instant warning triggers
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fullscreenSubscription?.cancel();
    _escapeSubscription?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    if (kIsWeb) {
      exitFullscreen();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (!mounted || !_examStarted) return;
    
    final exam = Provider.of<ExamProvider>(context, listen: false);
    if (!exam.isExamInProgress || _submitting) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      _handleTabChangeAttempt();
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (kIsWeb && event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      if (_examStarted && !_submitting) {
        _handleTabChangeAttempt();
      }
    }
    return false; // Propagate down the line
  }

  void _handleTabChangeAttempt() {
    if (_submitting || !_examStarted) return;

    final now = DateTime.now();
    if (_lastWarningTime != null && now.difference(_lastWarningTime!).inMilliseconds < 1000) {
      // Cooldown active, ignore duplicate transition events
      return;
    }
    _lastWarningTime = now;

    _autoSubmitDueToCheating();
  }

  void _autoSubmitDueToCheating() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final exam = Provider.of<ExamProvider>(context, listen: false);

    // Show a loading overlay dialog while we submit the exam in the background
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await exam.submitExam();
    } catch (e) {
      // ignore
    }

    if (mounted) {
      Navigator.pop(context); // Close the loading dialog
    }

    // Now show the "Exam Terminated" warning dialog. Since the exam has already been submitted,
    // when they press OK they are taken directly to the ResultView.
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.danger),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Exam Terminated', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
            ],
          ),
          content: const Text(
            'You have left the exam window or exited fullscreen mode. Your exam has been submitted automatically.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () {
                Navigator.pop(dialogCtx); // Close warning dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ResultView()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }



  void _showInitialRulesDialog() {
    setState(() {
      _initialRulesShown = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.primary),
          ),
          title: const Row(
            children: [
              Icon(Icons.gavel, color: AppColors.primary),
              SizedBox(width: 10),
              Text('EXAM RULES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildRuleItem(Icons.fullscreen, '1. Fullscreen Mode', 'The exam will open in full-screen. Do not exit it.'),
                const SizedBox(height: 16),
                _buildRuleItem(Icons.tab_unselected, '2. No Tab Swapping', 'Do not change tabs or open other programs.'),
                const SizedBox(height: 16),
                _buildRuleItem(Icons.warning_amber_rounded, '3. Auto-Submit Action', 'If tab switching or fullscreen exit is attempted, the exam will automatically be terminated and submitted.'),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: () {
                // Request browser fullscreen FIRST to preserve synchronous user gesture
                requestFullscreen();
                Navigator.pop(context);
                setState(() {
                  _examStarted = true;
                });
              },
              child: const Text('I AGREE, START EXAM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRuleItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.secondary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (context) {
        final exam = Provider.of<ExamProvider>(context, listen: false);
        final unanswered = exam.totalQuestions - exam.answeredCount;
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.darkBorder),
          ),
          title: const Text('Submit Exam?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You have answered ${exam.answeredCount} out of ${exam.totalQuestions} questions.'),
              if (unanswered > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Warning: $unanswered question(s) remain unanswered.',
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Resume Exam', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () async {
                Navigator.pop(context); // close dialog
                _submit();
              },
              child: const Text('Submit Now'),
            ),
          ],
        );
      },
    );
  }

  void _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final exam = Provider.of<ExamProvider>(context, listen: false);
    
    // Show submitting overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await exam.submitExam();
      if (mounted) {
        Navigator.pop(context); // close loader dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResultView()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting exam: $e"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  // Monitor timer countdown for auto-submission
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final exam = Provider.of<ExamProvider>(context);

    // Track when the exam transitions from in-progress to finished
    if (exam.isExamInProgress) {
      _wasExamInProgress = true;
    }

    // Auto-submit only when:
    // 1. Exam WAS running (we tracked it as in-progress before)
    // 2. Now it's no longer in progress (timer ran out)
    // 3. Questions are loaded (not empty)
    // 4. Timer is at 0 (confirming real expiry, not initial state)
    // 5. We aren't already submitting
    // 6. No lastRecord yet (prevents re-triggering after submission)
    if (_wasExamInProgress &&
        !exam.isExamInProgress &&
        !_submitting &&
        exam.questions.isNotEmpty &&
        exam.timeLeftSeconds == 0 &&
        exam.lastRecord == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _submit();
      });
    }
    // Trigger initial rules overlay once exam is loaded
    if (!exam.isLoadingQuestions && exam.questions.isNotEmpty && !_initialRulesShown) {
      _showInitialRulesDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = Provider.of<ExamProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    final isFullscreen = kIsWeb ? isCurrentlyFullscreen() : true;
    if (_examStarted && !isFullscreen && !_submitting) {
      // Trigger warning instantly on frame layout if fullscreen was lost
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleTabChangeAttempt();
      });

      // Return a beautiful, secure lockout view to obscure the exam until fullscreen is restored
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fullscreen_exit_rounded, color: AppColors.danger, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Fullscreen Mode Exited',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Exiting fullscreen mode is not allowed during the exam. Please click the button below to return to fullscreen and continue.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  onPressed: () {
                    requestFullscreen();
                  },
                  icon: const Icon(Icons.fullscreen_rounded),
                  label: const Text(
                    'RETURN TO FULLSCREEN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (exam.isLoadingQuestions) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Fetching exam papers...', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (exam.questions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No questions available in this category.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final currentQuestion = exam.questions[exam.currentIndex];
    final selectedOption = exam.selectedAnswers[exam.currentIndex];
    final isFlagged = exam.flaggedQuestions.contains(exam.currentIndex);

    // Format remaining time (MM:SS)
    final minutes = (exam.timeLeftSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (exam.timeLeftSeconds % 60).toString().padLeft(2, '0');
    final timerColor = exam.timeLeftSeconds < 60
        ? AppColors.danger
        : exam.timeLeftSeconds < 180
            ? AppColors.warning
            : AppColors.secondary;

    // Core Question Area
    Widget questionBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question Header Card
        Container(
          padding: const EdgeInsets.all(24),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Question ${exam.currentIndex + 1} of ${exam.totalQuestions}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Row(
                    children: [
                      // Difficulty badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(currentQuestion.difficulty).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          currentQuestion.difficulty.toUpperCase(),
                          style: TextStyle(
                            color: _getDifficultyColor(currentQuestion.difficulty),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Flag review button
                      IconButton(
                        icon: Icon(
                          isFlagged ? Icons.flag : Icons.flag_outlined,
                          color: isFlagged ? AppColors.warning : AppColors.textSecondary,
                        ),
                        onPressed: () => exam.toggleFlagQuestion(exam.currentIndex),
                        tooltip: 'Flag for Review',
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),
              Text(
                currentQuestion.questionText,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Multiple Choice Options
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentQuestion.options.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final optionText = currentQuestion.options[idx];
            final isSelected = selectedOption == idx;
            final optionLetter = String.fromCharCode(65 + idx); // A, B, C, D

            return InkWell(
              onTap: () => exam.selectAnswer(exam.currentIndex, idx),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.darkSurfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.darkBorder,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Option letter indicator
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.2),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : AppColors.darkBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          optionLetter,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Option text
                    Expanded(
                      child: Text(
                        optionText,
                        style: TextStyle(
                          fontSize: 15,
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const Spacer(),

        // Bottom Navigation Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
              onPressed: exam.currentIndex > 0 ? () => exam.previousQuestion() : null,
            ),
            if (exam.currentIndex < exam.totalQuestions - 1)
              ElevatedButton.icon(
                icon: const Text('Next'),
                label: const Icon(Icons.arrow_forward, size: 18),
                onPressed: () => exam.nextQuestion(),
              )
            else
              ElevatedButton.icon(
                icon: const Text('Submit Exam'),
                label: const Icon(Icons.check, size: 18),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: _confirmSubmit,
              ),
          ],
        ),
      ],
    );

    // Sidebar navigation status board (Answered / Unanswered count)
    Widget navigationPanel = Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Question Board',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: exam.totalQuestions,
              itemBuilder: (context, idx) {
                final isCurrent = exam.currentIndex == idx;
                final isAnswered = exam.selectedAnswers.containsKey(idx);
                final isFlag = exam.flaggedQuestions.contains(idx);

                Color bgColor = Colors.black.withValues(alpha: 0.3);
                Color borderCol = AppColors.darkBorder;
                Color txtColor = AppColors.textSecondary;

                if (isAnswered) {
                  bgColor = AppColors.primary.withValues(alpha: 0.2);
                  borderCol = AppColors.primary;
                  txtColor = AppColors.textPrimary;
                }
                if (isFlag) {
                  bgColor = AppColors.warning.withValues(alpha: 0.2);
                  borderCol = AppColors.warning;
                  txtColor = AppColors.textPrimary;
                }
                if (isCurrent) {
                  borderCol = Colors.white;
                }

                return InkWell(
                  onTap: () => exam.goToQuestion(idx),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderCol, width: isCurrent ? 2 : 1),
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: txtColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 24, color: AppColors.darkBorder),
          // Legend
          _buildLegendItem(AppColors.primary, 'Answered'),
          const SizedBox(height: 6),
          _buildLegendItem(AppColors.warning, 'Flagged'),
          const SizedBox(height: 6),
          _buildLegendItem(AppColors.darkBorder, 'Not Visited'),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exam.activeCategory?.name ?? 'Exam',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              'Candidate Exam Portal',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          // Dynamic Timer Display
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: timerColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: timerColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_bottom, color: timerColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '$minutes:$seconds',
                    style: TextStyle(
                      color: timerColor,
                      fontSize: 15,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: questionBody),
                    const SizedBox(width: 24),
                    navigationPanel,
                  ],
                )
              : Column(
                  children: [
                    // Mobile navigation toggle bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${exam.currentIndex + 1}/${exam.totalQuestions}',
                          style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: AppColors.darkBackground,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (_) => Container(
                                height: 400,
                                padding: const EdgeInsets.all(16),
                                child: navigationPanel,
                              ),
                            );
                          },
                          icon: const Icon(Icons.grid_view_outlined, size: 18),
                          label: const Text('Show Board'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: questionBody),
                  ],
                ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
