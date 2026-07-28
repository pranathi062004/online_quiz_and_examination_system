import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/exam_provider.dart';
import '../certificate/certificate_view.dart';
import '../dashboard/dashboard_view.dart';

class ResultView extends StatefulWidget {
  const ResultView({super.key});

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  bool _showReview = false;

  @override
  Widget build(BuildContext context) {
    final exam = Provider.of<ExamProvider>(context);
    final record = exam.lastRecord;

    if (record == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No exam record found.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardView()),
                ),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final isPassed = record.score >= 60;
    final timeMinutes = (record.timeTakenSeconds / 60).floor();
    final timeSeconds = record.timeTakenSeconds % 60;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Header
              Text(
                'Exam Result',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                record.categoryName,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Radial score gauge using CustomPaint
              Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: _RadialGaugePainter(
                      scorePercentage: record.score,
                      color: isPassed ? AppColors.success : AppColors.danger,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${record.score}%',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: isPassed ? AppColors.success : AppColors.danger,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPassed ? 'PASSED' : 'FAILED',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Status message
              Text(
                isPassed 
                    ? 'Congratulations! You successfully cleared the exam.'
                    : 'You did not achieve the 60% passing mark. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPassed ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(height: 36),

              // Performance Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _buildStatCard('Accuracy', '${record.score}%', Icons.track_changes, AppColors.secondary),
                  _buildStatCard('Correct Answers', '${record.correctAnswers} / ${record.totalQuestions}', Icons.check_circle_outline, AppColors.success),
                  _buildStatCard('Time Taken', '${timeMinutes}m ${timeSeconds}s', Icons.timer_outlined, AppColors.primary),
                  _buildStatCard('Certificate Status', isPassed ? 'Generated' : 'Locked', Icons.workspace_premium_outlined, isPassed ? AppColors.warning : AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 36),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const DashboardView()),
                        );
                      },
                      child: const Text('Dashboard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isPassed)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.workspace_premium),
                        label: const Text('View Certificate'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CertificateView(record: record),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Toggle review button
              OutlinedButton.icon(
                icon: Icon(_showReview ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                label: Text(_showReview ? 'Hide Answer Review' : 'Review Answers & Explanations'),
                onPressed: () => setState(() => _showReview = !_showReview),
              ),

              // Review Sheet
              if (_showReview) ...[
                const SizedBox(height: 24),
                Text(
                  'Answer Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exam.questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, idx) {
                    final q = exam.questions[idx];
                    final userAns = exam.selectedAnswers[idx];
                    final correctAns = q.correctOptionIndex;
                    final isCorrect = userAns == correctAns;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCorrect ? AppColors.success.withValues(alpha: 0.3) : AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Index and Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question ${idx + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect ? AppColors.success : AppColors.danger,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Question Text
                          Text(
                            q.questionText,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4),
                          ),
                          const SizedBox(height: 16),

                          // List of Options
                          ...List.generate(q.options.length, (optIdx) {
                            final optText = q.options[optIdx];
                            final isUserSelected = userAns == optIdx;
                            final isCorrectOpt = correctAns == optIdx;

                            Color textColor = AppColors.textSecondary;
                            Color borderCol = AppColors.darkBorder;
                            Color bgCol = Colors.transparent;

                            if (isCorrectOpt) {
                              borderCol = AppColors.success;
                              textColor = AppColors.success;
                              bgCol = AppColors.success.withValues(alpha: 0.05);
                            } else if (isUserSelected && !isCorrectOpt) {
                              borderCol = AppColors.danger;
                              textColor = AppColors.danger;
                              bgCol = AppColors.danger.withValues(alpha: 0.05);
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: bgCol,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderCol),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isCorrectOpt
                                        ? Icons.check_circle_outline
                                        : isUserSelected
                                            ? Icons.highlight_off
                                            : Icons.radio_button_off,
                                    color: textColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      optText,
                                      style: TextStyle(color: textColor, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),

                          // Explanation Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Explanation:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.secondary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  q.explanation,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(
                  val,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Custom radial painter for beautiful score indicator
class _RadialGaugePainter extends CustomPainter {
  final int scorePercentage;
  final Color color;

  _RadialGaugePainter({required this.scorePercentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 8;

    final basePaint = Paint()
      ..color = AppColors.darkBorder.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;

    // Background circle
    canvas.drawCircle(center, radius, basePaint);

    // Active progress arc
    final double sweepAngle = 2 * pi * (scorePercentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start at the top (12 o'clock)
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) {
    return oldDelegate.scorePercentage != scorePercentage || oldDelegate.color != color;
  }
}
