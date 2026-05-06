import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import '../models/assessment.dart';
import '../models/student.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../utils/report_exporter.dart';
import '../utils/fullscreen.dart';
import '../services/offline_service.dart';
import 'report_screen.dart';

class AssessmentScreen extends StatefulWidget {
  final Assessment assessment;
  final Student student;

  const AssessmentScreen({
    super.key,
    required this.assessment,
    required this.student,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> with WidgetsBindingObserver, WindowListener {
  List<QuickfireQuestion> _questions = [];
  Map<int, String?> _answers = {}; // questionId -> answerText
  AssessmentAttempt? _attempt;
  bool _loading = true;
  bool _submitting = false;
  bool _isLocked = false;
  int _pendingSyncs = 0;
  final TextEditingController _lockCodeController = TextEditingController();
  int _currentIndex = 0;
  Timer? _timer;
  int _secondsLeft = 0;

  // Essay controllers
  final Map<int, TextEditingController> _essayControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.linux || 
         defaultTargetPlatform == TargetPlatform.macOS || 
         defaultTargetPlatform == TargetPlatform.windows)) {
      windowManager.addListener(this);
      windowManager.setAlwaysOnTop(true);
      windowManager.setPreventClose(true);
    }
    // Use the comprehensive fullscreen service
    FullscreenService.enter();
    _loadAssessment();
    _startOfflineSync();
  }

  void _startOfflineSync() {
    OfflineService.startSync();
    // Periodically update the pending count for the UI
    Timer.periodic(const Duration(seconds: 5), (t) async {
       if (!mounted) { t.cancel(); return; }
       final count = await OfflineService.getPendingCount();
       if (mounted && count != _pendingSyncs) {
         setState(() => _pendingSyncs = count);
       }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _lockAssessment();
    }
  }

  @override
  void onWindowBlur() {
    debugPrint('Security: Window focus lost. Locking assessment...');
    _lockAssessment();
  }

  @override
  void onWindowMinimize() {
    debugPrint('Security: Window minimized. Locking assessment...');
    _lockAssessment();
  }

  @override
  void onWindowLeaveFullScreen() {
    debugPrint('Security: Fullscreen escaped. Locking assessment...');
    _lockAssessment();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose && mounted) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: AppTheme.getSurface(context),
            title: const Text('Exit Assessment?'),
            content: const Text('You cannot close the application during an assessment. Please submit your work first or call your lecturer.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _handleExitRequest() async {
    if (_attempt == null || _attempt!.isSubmitted) {
      Navigator.of(context).pop();
      return;
    }

    final bool? exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        title: const Text('Exit & Lock Assessment?'),
        content: const Text(
          'WARNING: This assessment is still in progress. If you leave now, the session will be LOCKED for security reasons. \n\nYou will need a lecturer to enter the unlock code before you can continue.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('STAY & CONTINUE', style: TextStyle(color: AppTheme.primary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('EXIT & LOCK SESSION'),
          ),
        ],
      ),
    );

    if (exit == true && mounted) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }

  void _lockAssessment() {
    if (_isLocked || _attempt?.isSubmitted == true || _loading) return;
    setState(() {
      _isLocked = true;
    });
  }

  void _unlockAssessment() {
    // Default lecturer code for demonstration
    const String lecturerCode = "8888"; 
    
    if (_lockCodeController.text == lecturerCode) {
      setState(() {
        _isLocked = false;
        _lockCodeController.clear();
      });
      // Ensure we are back in focus and fullscreen
      FullscreenService.enter();
      if (!kIsWeb) {
        windowManager.focus();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid lecturer code! Access denied.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadAssessment() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAssessmentWithQuestions(
          widget.assessment.id);
      final attemptData = await SupabaseService.getOrCreateAttempt(
          widget.assessment.id, widget.student.id);

      if (!mounted) return;

      if (data != null && attemptData != null) {
        final questions = (data['questions'] as List)
            .map((q) => QuickfireQuestion.fromJson(q))
            .toList();

        final attempt = AssessmentAttempt.fromJson(attemptData);

        // Load existing answers
        final existingAnswers =
            await SupabaseService.getAttemptAnswers(attempt.id);
        final answersMap = <int, String?>{};
        for (final ans in existingAnswers) {
          answersMap[ans['question_id']] = ans['answer_text'];
        }

        if (!mounted) return;
        
        // Detect if this is a resume (e.g. they left the screen and came back)
        bool resumed = false;
        if (attempt.startedAt != null) {
          final startTime = DateTime.parse(attempt.startedAt!);
          // If the test has been active for more than 15 seconds, it's a resume
          if (DateTime.now().difference(startTime).inSeconds > 15) {
            resumed = true;
          }
        }

        setState(() {
          _questions = questions;
          _attempt = attempt;
          _answers = answersMap;
          _loading = false;
          // Security: Lock if resumed
          if (resumed && !attempt.isSubmitted) {
            _isLocked = true;
            debugPrint('Security: Resumed in-progress test. Locking...');
          }
        });

        // Setup essay controllers with existing answers and auto-save
        for (final q in questions) {
          if (q.questionType == 'essay' || q.questionType == 'short_answer') {
            final controller = TextEditingController(text: answersMap[q.id] ?? '');
            controller.addListener(() => _onEssayChanged(q.id, controller.text));
            _essayControllers[q.id] = controller;
          }
        }

        // Start timer if not submitted and duration exists
        if (!attempt.isSubmitted && 
            widget.assessment.durationMinutes != null && 
            attempt.startedAt != null) {
          
          final startedAt = DateTime.parse(attempt.startedAt!);
          final endAt = startedAt.add(Duration(minutes: widget.assessment.durationMinutes!));
          _secondsLeft = endAt.difference(DateTime.now()).inSeconds;
          
          if (_secondsLeft < 0) _secondsLeft = 0;
          
          _timer?.cancel();
          _startTimer();
          
          // Periodic sync to check for added minutes from lecturer
          Timer.periodic(const Duration(seconds: 30), (t) async {
             if (!mounted || _attempt?.isSubmitted == true) {
               t.cancel();
               return;
             }
             final update = await SupabaseService.getAssessmentWithQuestions(widget.assessment.id);
             if (update != null && mounted) {
               final newDuration = update['duration_minutes'] as int?;
               if (newDuration != null) {
                 final startedAt = DateTime.parse(_attempt!.startedAt!);
                 final endAt = startedAt.add(Duration(minutes: newDuration));
                 setState(() {
                   _secondsLeft = endAt.difference(DateTime.now()).inSeconds;
                   if (_secondsLeft < 0) _secondsLeft = 0;
                 });
               }
             }
          });
        }
      } else {
        // ignore: avoid_print
        print('[LOAD_ERROR] data=$data, attempt=$attemptData');
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load assessment. Please check your connection or permissions.')),
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('[LOAD_EXCEPTION] $e');
      setState(() => _loading = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        _submitAssessment(auto: true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft <= 60) return AppTheme.error;
    if (_secondsLeft <= 300) return AppTheme.warning;
    return AppTheme.success;
  }

  void _selectAnswer(int questionId, String answer) {
    setState(() => _answers[questionId] = answer);
    
    // Auto-save to cloud immediately for objective questions
    _saveAnswerToCloud(questionId, answer);
  }

  Future<void> _saveAnswerToCloud(int questionId, String? answer) async {
    if (_attempt == null) return;
    
    final q = _questions.firstWhere((q) => q.id == questionId);
    bool? isCorrect;
    int marks = 0;

    if (answer != null) {
      if (q.questionType == 'multiple_choice' || q.questionType == 'true_false') {
        isCorrect = q.correctAnswer != null && 
          answer.trim().toLowerCase() == q.correctAnswer!.trim().toLowerCase();
        if (isCorrect) marks = q.marks;
      }
    }

    final success = await SupabaseService.saveAnswer(
      attemptId: _attempt!.id,
      questionId: questionId,
      answerText: answer,
      isCorrect: isCorrect,
      marksObtained: marks,
    );

    if (!success) {
      // Offline fallback: Queue for later sync
      await OfflineService.queueSave(
        attemptId: _attempt!.id,
        questionId: questionId,
        answerText: answer,
        isCorrect: isCorrect,
        marksObtained: marks,
      );
      final count = await OfflineService.getPendingCount();
      if (mounted) setState(() => _pendingSyncs = count);
    }
  }

  // To prevent too many DB calls, we use a map of timers to debounce essay saves
  final Map<int, Timer> _saveDebouncers = {};

  void _onEssayChanged(int questionId, String text) {
    _saveDebouncers[questionId]?.cancel();
    _saveDebouncers[questionId] = Timer(const Duration(seconds: 2), () {
      _saveAnswerToCloud(questionId, text);
      setState(() => _answers[questionId] = text);
    });
  }

  Future<void> _submitAssessment({bool auto = false}) async {
    if (_submitting || _attempt == null) return;

    if (!auto) {
      final unanswered =
          _questions.where((q) => _answers[q.id] == null).length;
      if (unanswered > 0) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.getSurface(context),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Submit Assessment?',
                style: TextStyle(color: AppTheme.getTextPrimary(context))),
            content: Text(
              'You have unanswered questions. Are you sure you want to submit?',
              style: TextStyle(color: AppTheme.getTextSecondary(context)),
            ),
            actions: [
               TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: TextStyle(color: AppTheme.getTextSecondary(context))),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Submit'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
    }

    setState(() => _submitting = true);
    _timer?.cancel();

    // Save essay answers first
    for (final q in _questions) {
      if (q.questionType == 'essay' || q.questionType == 'short_answer') {
        final text = _essayControllers[q.id]?.text;
        if (text != null && text.isNotEmpty) {
          _answers[q.id] = text;
        }
      }
    }

    // Save all answers
    int totalScore = 0;
    for (final q in _questions) {
      final answer = _answers[q.id];
      bool? isCorrect;
      int marks = 0;

      if (answer != null) {
        if (q.questionType == 'multiple_choice' ||
            q.questionType == 'true_false') {
          isCorrect = q.correctAnswer != null &&
              answer.trim().toLowerCase() ==
                  q.correctAnswer!.trim().toLowerCase();
          if (isCorrect) marks = q.marks;
        } else {
          // essay/short_answer - no auto-grading
          marks = 0;
          isCorrect = null;
        }
      }

      totalScore += marks;

      await SupabaseService.saveAnswer(
        attemptId: _attempt!.id,
        questionId: q.id,
        answerText: answer,
        isCorrect: isCorrect,
        marksObtained: marks,
      );
    }

    await SupabaseService.submitAttempt(_attempt!.id, totalScore);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          attemptId: _attempt!.id,
          assessmentId: widget.assessment.id,
          student: widget.student,
          totalScore: totalScore,
          showResults: widget.assessment.showResults,
        ),
      ),
    );
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: AppTheme.getBackground(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: AppTheme.getSurface(context),
            title: const Text('Examination Paper Preview'),
            elevation: 0,
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Download Exam Copy'),
                onPressed: () => ReportExporter.generateAndPrintReport(
                  student: widget.student,
                  assessmentTitle: widget.assessment.title,
                  courseCode: widget.assessment.courseCode,
                  courseTitle: widget.assessment.courseTitle,
                  questions: _questions,
                  answers: _answers,
                  showResults: false,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Container(
            color: AppTheme.getBackground(context),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Paper Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.getBorder(context), width: 2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('KAMPALA INTERNATIONAL UNIVERSITY', 
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Text((widget.student.collegeName ?? 'COLLEGE OF ECONOMICS AND MANAGEMENT').toUpperCase(), 
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _headerInfoField('COURSE CODE', widget.assessment.courseCode)),
                              const SizedBox(width: 16),
                              Expanded(child: _headerInfoField('COURSE TITLE', widget.assessment.courseTitle)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _headerInfoField('REG NUMBER', widget.student.registrationNumber)),
                              const SizedBox(width: 16),
                              Expanded(child: _headerInfoField('STUDENT NAME', widget.student.fullName)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Paper Content
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(32),
                        itemCount: _questions.length,
                        separatorBuilder: (_, __) => const Divider(height: 48),
                        itemBuilder: (context, index) {
                          final q = _questions[index];
                          final answer = _answers[q.id];
                          final isObjective = q.questionType == 'multiple_choice' || q.questionType == 'true_false';
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${index + 1}. ', style: TextStyle(color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.bold, fontSize: 16)),
                                  Expanded(
                                    child: Text(q.questionText, style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
                                  ),
                                  const SizedBox(width: 16),
                                  Text('[${q.marks} marks]', style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                                ],
                              ),
                              if (isObjective) ...[
                                const SizedBox(height: 16),
                                _buildPreviewOptions(q),
                              ],
                              const SizedBox(height: 24),
                              Text('Your Response:', style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.getBackground(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.getBorder(context)),
                                ),
                                child: Text(
                                  answer ?? 'NO RESPONSE PROVIDED',
                                  style: TextStyle(
                                    color: answer != null ? AppTheme.getTextPrimary(context) : AppTheme.error,
                                    fontSize: 14,
                                    fontWeight: answer != null ? FontWeight.w500 : FontWeight.bold,
                                    fontStyle: answer != null ? FontStyle.normal : FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.getBackground(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_attempt?.isSubmitted == true) {
      return _buildAlreadySubmitted();
    }

    return PopScope(
      canPop: _attempt?.isSubmitted == true, 
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleExitRequest();
        }
      },
      child: Stack(
        children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return _buildDesktopLayout();
            } else {
              return _buildMobileLayout();
            }
          },
        ),
        if (_isLocked) _buildLockOverlay(),
      ],
    ),
  );
}

  Widget _buildLockOverlay() {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          width: 450,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_person_rounded, size: 84, color: AppTheme.error),
              const SizedBox(height: 32),
              Text(
                'SECURITY LOCKDOWN',
                style: TextStyle(
                  color: AppTheme.getTextPrimary(context),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Assessment restricted due to a focus loss or window interaction. Your progress has been saved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.getBackground(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.getBorder(context)),
                ),
                child: TextField(
                  controller: _lockCodeController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'LECTURER CODE',
                    hintStyle: TextStyle(fontSize: 14, letterSpacing: 0.5, color: AppTheme.getTextMuted(context)),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _unlockAssessment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'UNLOCK SESSION',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      body: Column(
        children: [
          _buildHeader(),
          _buildProgress(),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: AppTheme.getSurface(context),
                    border: Border(right: BorderSide(color: AppTheme.getBorder(context))),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _indexCard(index),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _buildFocusedQuestionView(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildHeader(),
      ),
      body: Column(
        children: [
          _buildProgress(),
          Expanded(
            child: _questions.isEmpty
                ? Center(
                    child: Text('No questions found.',
                        style: TextStyle(color: AppTheme.getTextSecondary(context))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final q = _questions[index];
                      final answer = _answers[q.id];
                      return _buildChatItems(q, answer, index);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF052112) : AppTheme.primary,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _handleExitRequest,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/q_dark.png', // Header is always dark/blue
                width: 38,
                height: 38,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.assessment.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.assessment.courseCode} • Click a question to answer',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (widget.assessment.durationMinutes != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: _timerColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _timerDisplay,
                      style: TextStyle(color: _timerColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
              tooltip: 'Review All',
              onPressed: _showReviewDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final answeredCount = _answers.values.where((v) => v != null && v.isNotEmpty).length;
    final progress = _questions.isEmpty ? 0.0 : answeredCount / _questions.length;
    
    return Container(
      width: double.infinity,
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F2C34).withValues(alpha: 0.5) : Colors.white70,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Text(
          'COMPLETION: ${(progress * 100).toInt()}% ($answeredCount/${_questions.length})',
          style: TextStyle(
            color: AppTheme.getTextMuted(context),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2
          ),
        ),
      ),
    );
  }

  Widget _indexCard(int index) {
    final q = _questions[index];
    final answer = _answers[q.id];
    final isSelected = _currentIndex == index;
    final isAnswered = answer != null && answer.isNotEmpty;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isAnswered ? AppTheme.success : AppTheme.getBorder(context),
              child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.questionText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.getTextPrimary(context),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13
                    ),
                  ),
                  if (isAnswered)
                    Text(
                      answer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11),
                    )
                  else
                    const Text('Not answered yet', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            if (isAnswered) const Icon(Icons.done_all, color: Colors.blue, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItems(QuickfireQuestion q, String? answer, int index) {
    bool isCurrent = _currentIndex == index;
    
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => setState(() => _currentIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 40, bottom: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F2C34) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))
                ],
                border: isCurrent ? Border.all(color: AppTheme.primary, width: 1.5) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1} (${q.marks} marks)',
                    style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    q.questionText,
                    style: TextStyle(
                      color: AppTheme.getTextPrimary(context),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (answer != null && answer.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(left: 40, top: 4, bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(0),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    answer,
                    style: TextStyle(
                      color: AppTheme.getTextPrimary(context),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'delivered',
                        style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 9),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, color: Colors.blue, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInputArea() {
    final q = _questions.isEmpty ? null : _questions[_currentIndex];
    if (q == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F2C34) : Colors.white,
        border: Border(top: BorderSide(color: AppTheme.getBorder(context))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Answering Question ${_currentIndex + 1}',
                    style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: _submitting ? null : _submitAssessment,
                  style: TextButton.styleFrom(foregroundColor: AppTheme.success),
                  child: const Text('SUBMIT ALL'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (q.questionType == 'multiple_choice' || q.questionType == 'true_false')
              _buildModernOptions(q)
            else
              _buildModernTextArea(q),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusedQuestionView() {
    final q = _questions[_currentIndex];
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Question ${_currentIndex + 1}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const Spacer(),
              Text('${q.marks} Marks', style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            q.questionText,
            style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 24, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 40),
          if (q.questionType == 'multiple_choice' || q.questionType == 'true_false')
            _buildDetailedOptions(q)
          else
            _buildDetailedTextArea(q),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentIndex > 0)
                TextButton.icon(
                  onPressed: () => setState(() => _currentIndex--),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous Question'),
                )
              else
                const SizedBox(),
              if (_currentIndex < _questions.length - 1)
                ElevatedButton(
                  onPressed: () => setState(() => _currentIndex++),
                  child: const Text('Next Question'),
                )
              else
                ElevatedButton(
                  onPressed: _submitting ? null : _submitAssessment,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                  child: const Text('Submit Assessment'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernOptions(QuickfireQuestion q) {
    final options = q.questionType == 'true_false' ? ['True', 'False'] : q.options;
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (context, i) {
          final opt = options[i];
          final isSelected = _answers[q.id] == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (val) {
                 if (val) _selectAnswer(q.id, opt);
              },
              selectedColor: AppTheme.primary,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F2C34) : Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.getTextPrimary(context)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernTextArea(QuickfireQuestion q) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _essayControllers[q.id],
              maxLines: null,
              style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Type your answer...',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (val) => setState(() => _answers[q.id] = val),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.primary),
            onPressed: () {
               if (_currentIndex < _questions.length - 1) {
                 setState(() => _currentIndex++);
               }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedOptions(QuickfireQuestion q) {
    final options = q.questionType == 'true_false' ? ['True', 'False'] : q.options;
    return Column(
      children: options.map((opt) {
        final isSelected = _answers[q.id] == opt;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _selectAnswer(q.id, opt),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.getBackground(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.getBorder(context), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? AppTheme.primary : Colors.grey),
                  const SizedBox(width: 16),
                  Text(opt, style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailedTextArea(QuickfireQuestion q) {
    return TextField(
      controller: _essayControllers[q.id],
      maxLines: 8,
      style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Type your detailed answer here...',
        filled: true,
        fillColor: AppTheme.getBackground(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      onChanged: (val) => setState(() => _answers[q.id] = val),
    );
  }

  Widget _headerInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPreviewOptions(QuickfireQuestion q) {
    final options = q.questionType == 'true_false' ? ['True', 'False'] : q.options;
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

  Widget _buildAlreadySubmitted() {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 64),
            const SizedBox(height: 16),
            Text('Assessment Submitted', style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('You have already submitted this assessment.', style: TextStyle(color: AppTheme.getTextSecondary(context))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ReportScreen(attemptId: _attempt!.id, assessmentId: widget.assessment.id, student: widget.student, totalScore: _attempt!.totalScore, showResults: widget.assessment.showResults)),
                );
              },
              child: const Text('View Report'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.linux || 
         defaultTargetPlatform == TargetPlatform.macOS || 
         defaultTargetPlatform == TargetPlatform.windows)) {
      windowManager.removeListener(this);
      windowManager.setAlwaysOnTop(false);
      windowManager.setPreventClose(false);
    }
    _lockCodeController.dispose();
    // Restore normal UI mode via service
    FullscreenService.exit();
    _timer?.cancel();
    for (final t in _saveDebouncers.values) {
      t.cancel();
    }
    for (final c in _essayControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
