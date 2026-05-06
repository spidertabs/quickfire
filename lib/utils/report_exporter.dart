// lib/utils/report_exporter.dart

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/assessment.dart';
import '../models/student.dart';

class ReportExporter {
  // ── Colours matched to the on-screen preview ──────────────────────────────
  static const _primaryGreen   = PdfColor.fromInt(0xff16a34a); // option letters
  static const _headerGreen    = PdfColor.fromInt(0xff16a34a); // college subtitle
  static const _marksGrey     = PdfColor.fromInt(0xff757575); // [1 marks]
  static const _labelGrey     = PdfColor.fromInt(0xff9e9e9e); // "COURSE CODE" etc.
  static const _borderGrey    = PdfColor.fromInt(0xffe0e0e0); // card / divider border
  static const _bgWhite       = PdfColors.white;
  static const _responseError = PdfColor.fromInt(0xffd32f2f); // "NO RESPONSE"


  static final _a4 = PdfPageFormat.a4.copyWith(
    marginTop: 32,
    marginBottom: 36,
    marginLeft: 40,
    marginRight: 40,
  );

  // ── Public entry point ─────────────────────────────────────────────────────
  static Future<void> generateAndPrintReport({
    required Student student,
    required String assessmentTitle,
    required String courseCode,
    String? courseTitle,
    required List<QuickfireQuestion> questions,
    required Map<int, String?> answers,
    int? totalScore,
    int? maxMarks,
    bool showResults = false,
  }) async {
    final pdfBytes = await _buildPdf(
      student: student,
      assessmentTitle: assessmentTitle,
      courseCode: courseCode,
      courseTitle: courseTitle,
      questions: questions,
      answers: answers,
      totalScore: totalScore,
      maxMarks: maxMarks,
      showResults: showResults,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'KIU_Report_${student.registrationNumber}.pdf',
      format: _a4,
    );
  }

  // ── PDF builder ────────────────────────────────────────────────────────────
  static Future<Uint8List> _buildPdf({
    required Student student,
    required String assessmentTitle,
    required String courseCode,
    String? courseTitle,
    required List<QuickfireQuestion> questions,
    required Map<int, String?> answers,
    required bool showResults,
    int? totalScore,
    int? maxMarks,
  }) async {
    final fontRegular   = await PdfGoogleFonts.robotoRegular();
    final fontBold      = await PdfGoogleFonts.robotoBold();
    final fontItalic    = await PdfGoogleFonts.robotoItalic();
    final fontBoldItalic = await PdfGoogleFonts.robotoBoldItalic();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
      boldItalic: fontBoldItalic,
    );

    final pdf = pw.Document(
      title: 'Assessment Report – ${student.registrationNumber}',
      author: 'Quickfire Assessment System',
      theme: theme,
    );

    pw.ImageProvider? logoImage;
    try {
      final bytes = await rootBundle.load('assets/images/kiu_black.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    // ── Single MultiPage document (no separate cover page) ─────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: _a4,
        // ── Page header: replicated on every page ──────────────────────────
        header: (ctx) => _buildPageHeader(
          ctx: ctx,
          student: student,
          courseCode: courseCode,
          courseTitle: courseTitle ?? assessmentTitle,
          totalScore: totalScore,
          maxMarks: maxMarks,
          logoImage: logoImage,
          fontRegular: fontRegular,
          fontBold: fontBold,
          isFirstPage: ctx.pageNumber == 1,
          showResults: showResults,
        ),
        // ── Page footer ────────────────────────────────────────────────────
        footer: (ctx) => _buildPageFooter(ctx, fontRegular),
        // ── Body: question cards ───────────────────────────────────────────
        build: (ctx) {
          int n = 0;
          return [
            pw.SizedBox(height: 8),
            ...questions.map((q) => _questionCard(
                  number: ++n,
                  q: q,
                  response: answers[q.id],
                  showResults: showResults,
                  fontRegular: fontRegular,
                  fontBold: fontBold,
                  fontItalic: fontItalic,
                )),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ── Page header ────────────────────────────────────────────────────────────
  //
  // First page  → full header with institution name + all student/course fields
  // Other pages → compact header (name + reg number on the right)
  static pw.Widget _buildPageHeader({
    required pw.Context ctx,
    required Student student,
    required String courseCode,
    required String courseTitle,
    int? totalScore,
    int? maxMarks,
    pw.ImageProvider? logoImage,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required bool isFirstPage,
    required bool showResults,
  }) {
    if (!isFirstPage) {
      // ── Compact header for continuation pages ──
      return pw.Column(children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'KAMPALA INTERNATIONAL UNIVERSITY',
              style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColors.black),
            ),
            pw.Text(
              '${student.registrationNumber}  ·  $courseCode',
              style: pw.TextStyle(font: fontRegular, fontSize: 7, color: _labelGrey),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.5, color: _borderGrey),
        pw.SizedBox(height: 4),
      ]);
    }

    // ── Full header (page 1) ──
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Institution name block
        if (logoImage != null) ...[
          pw.Center(
            child: pw.SizedBox(width: 48, height: 48, child: pw.Image(logoImage)),
          ),
          pw.SizedBox(height: 8),
        ],
        pw.Text(
          'KAMPALA INTERNATIONAL UNIVERSITY',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 15,
            color: PdfColors.black,
            letterSpacing: 0.4,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          (student.collegeName ?? '').toUpperCase(),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 8,
            color: _headerGreen,
            letterSpacing: 1.2,
          ),
        ),

        pw.SizedBox(height: 16),
        pw.Divider(thickness: 0.5, color: _borderGrey),
        pw.SizedBox(height: 12),

        // ── Info grid: 2 columns × 2 rows (matches the preview) ──
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left column
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _infoField('COURSE CODE', courseCode,
                      fontRegular: fontRegular, fontBold: fontBold),
                  pw.SizedBox(height: 12),
                  _infoField('REG NUMBER', student.registrationNumber,
                      fontRegular: fontRegular, fontBold: fontBold),
                ],
              ),
            ),
            // Right column
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _infoField('COURSE TITLE', courseTitle,
                      fontRegular: fontRegular, fontBold: fontBold),
                  pw.SizedBox(height: 12),
                  _infoField('STUDENT NAME', student.fullName,
                      fontRegular: fontRegular, fontBold: fontBold),
                ],
              ),
            ),
          ],
        ),

        // Optional score badge (shown only when results are available)
        if (showResults && totalScore != null) ...[
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: _primaryGreen,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'TOTAL: $totalScore / $maxMarks',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],

        pw.SizedBox(height: 12),
        pw.Divider(thickness: 0.5, color: _borderGrey),
        // No extra bottom gap — the body adds pw.SizedBox(height:8) itself
      ],
    );
  }

  // ── Page footer ────────────────────────────────────────────────────────────
  static pw.Widget _buildPageFooter(pw.Context ctx, pw.Font fontRegular) {
    return pw.Column(children: [
      pw.Divider(thickness: 0.5, color: _borderGrey),
      pw.SizedBox(height: 3),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated via Quickfire Assessment System',
            style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: _labelGrey),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: _labelGrey),
          ),
        ],
      ),
    ]);
  }

  // ── Info field (label + value) ─────────────────────────────────────────────
  static pw.Widget _infoField(
    String label,
    String value, {
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 6.5,
            color: _labelGrey,
            letterSpacing: 0.6,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 11,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  // ── Question card ──────────────────────────────────────────────────────────
  //
  // Matches the preview layout:
  //   • Question text (bold) + marks on the right
  //   • Options row (A. B. C. D.) in blue letter + grey text
  //   • "Your Response:" label
  //   • Response box (white, bordered)
  //   • Full-width divider between questions
  static pw.Widget _questionCard({
    required int number,
    required QuickfireQuestion q,
    required String? response,
    required bool showResults,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required pw.Font fontItalic,
  }) {
    String safe(String t) => t
        .replaceAll('\u201c', '"')
        .replaceAll('\u201d', '"')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'");

    final noResponse = response == null || response.trim().isEmpty;
    final isCorrect  = !noResponse &&
        response.trim().toLowerCase() ==
            (q.correctAnswer?.trim().toLowerCase() ?? '');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Question stem row ──────────────────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                '$number. ${safe(q.questionText)}',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              '[${q.marks} marks]',
              style: pw.TextStyle(
                font: fontItalic,
                fontSize: 8.5,
                color: _marksGrey,
              ),
            ),
          ],
        ),

        // ── Options (MCQ / True-False) ─────────────────────────────────────
        if (q.options.isNotEmpty) ...[
          pw.SizedBox(height: 7),
          pw.Wrap(
            spacing: 18,
            runSpacing: 4,
            children: List.generate(q.options.length, (i) {
              final letter = String.fromCharCode(65 + i); // A, B, C …
              return pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    '$letter. ',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8.5,
                      color: _primaryGreen,
                    ),
                  ),
                  pw.Text(
                    safe(q.options[i]),
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8.5,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],

        pw.SizedBox(height: 9),

        // ── Response box ───────────────────────────────────────────────────
        pw.Container(
          width: double.infinity,
          constraints: const pw.BoxConstraints(minHeight: 28),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: pw.BoxDecoration(
            color: _bgWhite,
            border: pw.Border.all(color: _borderGrey, width: 0.75),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (noResponse)
                pw.Text(
                  'NO RESPONSE PROVIDED',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 8.5,
                    color: _responseError,
                    fontStyle: pw.FontStyle.italic,
                  ),
                )
              else
                pw.Text(
                  safe(response),
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 9,
                    color: PdfColors.black,
                  ),
                ),

              // Show correct key when results enabled and answer wrong (MCQ/TF)
              if (showResults &&
                  !noResponse &&
                  !isCorrect &&
                  q.correctAnswer != null &&
                  (q.questionType == 'multiple_choice' ||
                      q.questionType == 'true_false')) ...[
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 0.5, color: _borderGrey),
                pw.Row(children: [
                  pw.Text(
                    'Correct answer: ',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 7.5,
                      color: const PdfColor.fromInt(0xff2e7d32),
                    ),
                  ),
                  pw.Text(
                    safe(q.correctAnswer!),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 7.5,
                      color: const PdfColor.fromInt(0xff2e7d32),
                    ),
                  ),
                ]),
              ],

              // Show CORRECT / INCORRECT badge for MCQ/TF when results on
              if (showResults &&
                  !noResponse &&
                  (q.questionType == 'multiple_choice' ||
                      q.questionType == 'true_false')) ...[
                pw.SizedBox(height: 4),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    isCorrect ? '✓ CORRECT' : '✗ INCORRECT',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 7,
                      color: isCorrect
                          ? const PdfColor.fromInt(0xff2e7d32)
                          : _responseError,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        pw.SizedBox(height: 16),
      ],
    );
  }
}