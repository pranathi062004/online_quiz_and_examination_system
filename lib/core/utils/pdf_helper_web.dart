// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/exam_record_model.dart';

Future<void> downloadCertificatePdf(ExamRecordModel record) async {
  final pdf = pw.Document();
  
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (pw.Context context) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(
            margin: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#F59E0B'), width: 8),
            ),
            child: pw.Container(
              margin: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#F59E0B'), width: 2),
              ),
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Top Row: ExamiQ logo/text on left, accreditation text on right
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 18,
                            height: 18,
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('#4F46E5'),
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.CustomPaint(
                                size: const PdfPoint(12, 12),
                                painter: (PdfGraphics canvas, PdfPoint size) {
                                  canvas.setStrokeColor(PdfColor.fromHex('#FFFFFF'));
                                  canvas.setLineWidth(1.5);
                                  canvas.moveTo(2.5, 6);
                                  canvas.lineTo(5.5, 3);
                                  canvas.lineTo(9.5, 9);
                                  canvas.strokePath();
                                },
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'ExamiQ',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#4F46E5'),
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        'OFFICIAL CERTIFICATE',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#F59E0B'),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 15),

                  pw.Text(
                    'CERTIFICATE OF COMPLETION',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1E293B'),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'PROUDLY PRESENTED TO',
                    style: pw.TextStyle(
                      fontSize: 14,
                      letterSpacing: 2,
                      color: PdfColor.fromHex('#64748B'),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    record.userName,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#4F46E5'),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColor.fromHex('#CBD5E1'), thickness: 1),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'for successfully passing the examination for',
                    style: pw.TextStyle(fontSize: 14, color: PdfColor.fromRYB(0, 0, 0)),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    record.categoryName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#0F172A'),
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Score achieved: ${record.score}%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('Completed date: ${record.completedAt.toString().substring(0, 10)}'),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          // Verification QR code above Certificate ID
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: 'https://www.algoorbit.in/verify',
                            width: 44,
                            height: 44,
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text('Certificate ID: ${record.certificateId}', style: pw.TextStyle(color: PdfColor.fromHex('#64748B'), fontSize: 8)),
                          pw.Text('Verification Seal: ONLINE-QUIZ-SYSTEM', style: pw.TextStyle(fontSize: 8)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  final bytes = await pdf.save();
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute("download", "certificate_${record.certificateId}.pdf")
    ..click();
  html.Url.revokeObjectUrl(url);
}
