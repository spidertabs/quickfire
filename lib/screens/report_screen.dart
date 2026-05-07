// lib/screens/report_screen.dart
import 'package:flutter/material.dart';
import '../models/assessment.dart';
import '../models/student.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../utils/report_exporter.dart';

class ReportScreen extends StatefulWidget {
  final int attemptId;
  final int assessmentId;
  final Student student;
  final int totalScore;
  final bool showResults;

  const ReportScreen({
    super.key,
    required this.attemptId,
    required this.assessmentId,
    required this.student,
    required this.totalScore,
    required this.showResults,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late Student _currentStudent;
  List<QuickfireQuestion> _questions = [];
  List<Map<String, dynamic>> _answers = [];
  bool _loading = true;
  int _maxMarks = 0;

  @override
  void initState() {
    super.initState();
    _currentStudent = widget.student;
    _loadReport();
  }

  Future<void> _loadReport() async {
    // 1. Fetch college name if missing
    if (_currentStudent.collegeName == null && _currentStudent.collegeId != null) {
      final cn = await SupabaseService.getCollegeName(_currentStudent.collegeId!);
      if (cn != null && mounted) {
        setState(() {
          _currentStudent = _currentStudent.copyWith(collegeName: cn);
        });
      }
    }

    final assessData = await SupabaseService.getAssessmentWithQuestions(
        widget.assessmentId);
    final answerData =
        await SupabaseService.getAttemptAnswers(widget.attemptId);

    if (!mounted) return;
    if (assessData != null) {
      final questions = (assessData['questions'] as List)
          .map((q) => QuickfireQuestion.fromJson(q))
          .toList();
      setState(() {
        _questions = questions;
        _answers = answerData;
        _maxMarks = questions.fold(0, (sum, q) => sum + q.marks);
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? _getAnswer(int questionId) {
    try {
      return _answers.firstWhere((a) => a['question_id'] == questionId);
    } catch (_) {
      return null;
    }
  }

  double get _percentage => _maxMarks == 0
      ? 0
      : (widget.totalScore / _maxMarks * 100);

  Color get _gradeColor {
    if (_percentage >= 80) return AppTheme.success;
    if (_percentage >= 60) return AppTheme.primary;
    if (_percentage >= 40) return AppTheme.warning;
    return AppTheme.error;
  }

  String get _grade {
    if (_percentage >= 80) return 'Excellent';
    if (_percentage >= 70) return 'Very Good';
    if (_percentage >= 60) return 'Good';
    if (_percentage >= 50) return 'Average';
    if (_percentage >= 40) return 'Below Average';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Column(
                            children: [
                              _buildScoreHero(),
                              const SizedBox(height: 32),
                              if (_questions.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Question Paper Review',
                                      style: TextStyle(
                                        color: AppTheme.getTextPrimary(context),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.getSurface(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.getBorder(context)),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(32),
                                    itemCount: _questions.length,
                                    separatorBuilder: (_, __) => const Divider(height: 64),
                                    itemBuilder: (context, index) => _QuestionReviewCard(
                                          index: index,
                                          question: _questions[index],
                                          answer: _getAnswer(_questions[index].id),
                                          showResults: widget.showResults,
                                        ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 40),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.dashboard_rounded),
                                label: const Text('Back to Dashboard'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        border: Border(bottom: BorderSide(color: AppTheme.getBorder(context))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: AppTheme.getTextPrimary(context)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.showResults ? 'Assessment Report' : 'Answer Preview',
                  style: TextStyle(color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  _currentStudent.fullName,
                  style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12),
                ),
                if (_currentStudent.collegeName != null)
                  Text(
                    _currentStudent.collegeName!,
                    style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 10, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'COMPLETED',
              style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primary),
            tooltip: 'Download PDF Report',
            onPressed: () => ReportExporter.generateAndPrintReport(
              student: _currentStudent,
              assessmentTitle: _questions.isNotEmpty ? "Assessment Report" : "Report",
              courseCode: "UEMS",
              questions: _questions,
              answers: { for (var a in _answers) a['question_id'] as int : a['answer_text'] as String? },
              totalScore: widget.totalScore,
              maxMarks: _maxMarks,
              showResults: widget.showResults,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHero() {
    if (!widget.showResults) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.history_edu_rounded, color: AppTheme.primary, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Submission Preview',
              style: TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You successfully submitted this assessment. Below is a record of the responses you provided during the session.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Assessment Submission Confirmed',
                style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _gradeColor,
            _gradeColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: _gradeColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Text(
            _grade.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${widget.totalScore}',
                style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, height: 1),
              ),
              Text(
                ' / $_maxMarks',
                style: const TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PERCENTAGE: ${_percentage.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_answers.length} Questions Answered',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  final int index;
  final QuickfireQuestion question;
  final Map<String, dynamic>? answer;
  final bool showResults;

  const _QuestionReviewCard({
    required this.index,
    required this.question,
    this.answer,
    required this.showResults,
  });

  @override
  Widget build(BuildContext context) {
    final studentAnswer = answer?['answer_text'];
    final isCorrect = answer?['is_correct'];
    final marksObtained = answer?['marks_obtained'] ?? 0;
    final isObjective = question.questionType == 'multiple_choice' ||
        question.questionType == 'true_false';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index + 1}. ', style: TextStyle(color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.bold, fontSize: 16)),
            Expanded(
              child: Text(question.questionText, style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
            ),
            const SizedBox(width: 16),
            Text('[${question.marks} marks]', style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
          ],
        ),
        if (isObjective) ...[
          const SizedBox(height: 16),
          _buildReviewOptions(context),
        ],
        const SizedBox(height: 24),
        if (showResults) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Text('RESULT: ', style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCorrect == true) ? AppTheme.success.withValues(alpha: 0.1) : (studentAnswer == null ? Colors.grey.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (isCorrect == true) ? 'CORRECT' : (studentAnswer == null ? 'NOT ANSWERED' : 'WRONG'),
                  style: TextStyle(
                    color: (isCorrect == true) ? AppTheme.success : (studentAnswer == null ? Colors.grey : AppTheme.error),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text('MARKS OBTAINED: $marksObtained / ${question.marks}', style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getBackground(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.getBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STUDENT RESPONSE:', style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                studentAnswer ?? 'NO RESPONSE PROVIDED',
                style: TextStyle(
                  color: studentAnswer != null ? AppTheme.getTextPrimary(context) : AppTheme.error,
                  fontSize: 14,
                  fontWeight: studentAnswer != null ? FontWeight.w500 : FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (showResults && isObjective && studentAnswer != question.correctAnswer) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CORRECT ANSWER:', style: TextStyle(color: AppTheme.success, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  question.correctAnswer!,
                  style: const TextStyle(color: AppTheme.success, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewOptions(BuildContext context) {
    final options = question.questionType == 'true_false' ? ['True', 'False'] : question.options;
    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: options.asMap().entries.map((entry) {
        final i = entry.key;
        final opt = entry.value;
        final letter = String.fromCharCode(65 + i);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$letter. ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryLight)),
            Text(opt, style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14)),
          ],
        );
      }).toList(),
    );
  }
}
