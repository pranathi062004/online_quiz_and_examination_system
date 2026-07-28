import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/exam_record_model.dart';
import '../../core/utils/pdf_helper.dart';
import '../dashboard/dashboard_view.dart';

class CertificateView extends StatefulWidget {
  final ExamRecordModel record;
  const CertificateView({super.key, required this.record});

  @override
  State<CertificateView> createState() => _CertificateViewState();
}

class _CertificateViewState extends State<CertificateView> {
  bool _isDownloading = false;

  void _download() async {
    setState(() => _isDownloading = true);
    
    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Generating PDF certificate..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await downloadCertificatePdf(widget.record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Certificate downloaded successfully!"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to download PDF: $e"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.record;
    final dateString = rec.completedAt.toString().substring(0, 10);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Your Certificate', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Certificate Visual Card (Landscape ratio simulated)
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 750),
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.warning, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) {
                      final isMobile = MediaQuery.of(context).size.width < 600;
                      
                      final cardContent = Container(
                        padding: EdgeInsets.all(isMobile ? 18 : 24),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5), width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Top row: Logo on left, Seal on right
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Top Left: ExamiQ Logo and Name
                                 Row(
                                   children: [
                                     Container(
                                       padding: EdgeInsets.all(isMobile ? 5 : 7),
                                       decoration: BoxDecoration(
                                         gradient: const LinearGradient(
                                           colors: [AppColors.primary, AppColors.secondary],
                                         ),
                                         borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                       ),
                                       child: Icon(
                                         Icons.check_circle_outline,
                                         size: isMobile ? 16 : 22,
                                         color: Colors.white,
                                       ),
                                     ),
                                     SizedBox(width: isMobile ? 6 : 8),
                                     ShaderMask(
                                       shaderCallback: (bounds) => const LinearGradient(
                                         colors: [AppColors.primary, AppColors.secondary],
                                       ).createShader(bounds),
                                       child: Text(
                                         'ExamiQ',
                                         style: TextStyle(
                                           fontSize: isMobile ? 16 : 22,
                                           fontWeight: FontWeight.w900,
                                           color: Colors.white,
                                           letterSpacing: -0.5,
                                         ),
                                       ),
                                     ),
                                   ],
                                 ),
                                // Top Right: Premium Seal
                                Icon(
                                  Icons.workspace_premium_outlined,
                                  color: AppColors.warning,
                                  size: isMobile ? 22 : 28,
                                ),
                              ],
                            ),
                            SizedBox(height: isMobile ? 8 : 12),
                            
                            // Header
                            Text(
                              'CERTIFICATE OF COMPLETION',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PROUDLY PRESENTED TO',
                              style: TextStyle(
                                fontSize: isMobile ? 8 : 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 2.0,
                              ),
                            ),
                            
                            // Name
                            SizedBox(height: isMobile ? 10 : 16),
                            Text(
                              rec.userName,
                              style: TextStyle(
                                fontSize: isMobile ? 20 : 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            
                            // Divider line
                            Container(
                              width: isMobile ? 180 : 250,
                              height: 1,
                              color: AppColors.darkBorder,
                            ),
                            SizedBox(height: isMobile ? 10 : 12),
                            
                            // Body text
                            Text(
                              'for outstanding achievement in passing the exam for',
                              style: TextStyle(fontSize: isMobile ? 10 : 12, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rec.categoryName,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isMobile ? 8 : 10),
                            
                            // Pass details
                            Text(
                              'Grade Achieved: ${rec.score}% Accuracy',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            
                            if (isMobile) const SizedBox(height: 24) else const Spacer(),
                            
                            // Footer Signatures/IDs
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Date: $dateString',
                                      style: TextStyle(fontSize: isMobile ? 8 : 10, color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      'EXAMINATION HEAD',
                                      style: TextStyle(fontSize: isMobile ? 6 : 8, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Verification QR code above Certificate ID
                                    SizedBox(
                                      width: isMobile ? 36 : 44,
                                      height: isMobile ? 36 : 44,
                                      child: QrImageView(
                                        data: 'https://www.algoorbit.in/verify',
                                        version: QrVersions.auto,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Colors.white,
                                        ),
                                        dataModuleStyle: const QrDataModuleStyle(
                                          dataModuleShape: QrDataModuleShape.square,
                                          color: Colors.white,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${rec.certificateId}',
                                      style: TextStyle(fontSize: isMobile ? 8 : 10, color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      'VERIFIED ACCREDITATION',
                                      style: TextStyle(fontSize: isMobile ? 6 : 8, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      );

                      if (isMobile) {
                        return cardContent;
                      } else {
                        return AspectRatio(
                          aspectRatio: 1.4,
                          child: cardContent,
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Action buttons
              ElevatedButton.icon(
                icon: _isDownloading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download),
                label: const Text('Download PDF Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: _isDownloading ? null : _download,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardView()),
                    (route) => false,
                  );
                },
                child: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
