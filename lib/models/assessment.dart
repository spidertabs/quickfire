class Assessment {
  final int id;
  final String title;
  final String? description;
  final int? durationMinutes;
  final bool showResults;
  final String courseCode;
  final String courseTitle;
  final String? createdAt;

  Assessment({
    required this.id,
    required this.title,
    this.description,
    this.durationMinutes,
    required this.showResults,
    required this.courseCode,
    required this.courseTitle,
    this.createdAt,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    final course = json['courses'] as Map<String, dynamic>? ?? {};
    return Assessment(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      durationMinutes: json['duration_minutes'],
      showResults: json['show_results'] ?? true,
      courseCode: course['code'] ?? '',
      courseTitle: course['title'] ?? '',
      createdAt: json['created_at'],
    );
  }
}

class QuickfireQuestion {
  final int id;
  final String questionText;
  final String questionType;
  final List<String> options;
  final String? correctAnswer;
  final int marks;
  final int? minWords;
  final int? maxWords;
  final int sequenceOrder;

  QuickfireQuestion({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.options,
    this.correctAnswer,
    required this.marks,
    this.minWords,
    this.maxWords,
    required this.sequenceOrder,
  });

  factory QuickfireQuestion.fromJson(Map<String, dynamic> json) {
    List<String> opts = [];
    if (json['options'] != null) {
      if (json['options'] is List) {
        opts = (json['options'] as List).map((e) => e.toString()).toList();
      }
    }
    return QuickfireQuestion(
      id: json['id'],
      questionText: json['question_text'],
      questionType: json['question_type'] ?? 'multiple_choice',
      options: opts,
      correctAnswer: json['correct_answer'],
      marks: json['marks'] ?? 1,
      minWords: json['min_words'],
      maxWords: json['max_words'],
      sequenceOrder: json['sequence_order'] ?? 0,
    );
  }
}

class AssessmentAttempt {
  final int id;
  final String status;
  final int totalScore;
  final String? startedAt;
  final String? submittedAt;

  AssessmentAttempt({
    required this.id,
    required this.status,
    required this.totalScore,
    this.startedAt,
    this.submittedAt,
  });

  factory AssessmentAttempt.fromJson(Map<String, dynamic> json) =>
      AssessmentAttempt(
        id: json['id'],
        status: json['status'] ?? 'in_progress',
        totalScore: json['total_score'] ?? 0,
        startedAt: json['started_at'],
        submittedAt: json['submitted_at'],
      );

  bool get isSubmitted => status == 'submitted';
}
