// lib/services/supabase_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class SupabaseService {
  static const String baseUrl = 'https://zgklfrakozlpjheecatj.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpna2xmcmFrb3pscGpoZWVjYXRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1MjcwMzgsImV4cCI6MjA5MjEwMzAzOH0.kptvP36ocEnxlYfKYUnZCh9t_uziTW8SzKeY6DHvwjE';

  static Map<String, String> get headers => {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  // Login student — calls server-side RPC that verifies bcrypt password.
  // The RPC runs as SECURITY DEFINER so it bypasses RLS on the students table.
  static Future<Map<String, dynamic>?> loginStudent(
      String registrationNumber, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/rest/v1/rpc/fn_student_login');
      final res = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'p_reg_no': registrationNumber,
          'p_password': password,
        }),
      );
      // DEBUG — remove after login is working
      // ignore: avoid_print
      print('[LOGIN] status=${res.statusCode} body=${res.body}');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          return data[0] as Map<String, dynamic>;
        }
        // DEBUG: empty result = wrong credentials or RPC not yet created
        // ignore: avoid_print
        print('[LOGIN] RPC returned empty — check SQL was run in Supabase');
      } else {
        // DEBUG: non-200 = RPC doesn't exist yet
        // ignore: avoid_print
        print('[LOGIN] RPC error — have you run sql/quickfire_auth.sql in Supabase Dashboard?');
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[LOGIN] exception: $e');
      return null;
    }
  }

  // Get college name by ID
  static Future<String?> getCollegeName(int collegeId) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/rest/v1/colleges?id=eq.$collegeId&select=name');
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          return data[0]['name'] as String?;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get active assessments for all courses (student can see all active)
  static Future<List<Map<String, dynamic>>> getActiveAssessments() async {
    try {
      final uri = Uri.parse(
          '$baseUrl/rest/v1/quickfire_assessments?is_active=eq.true&select=id,title,description,duration_minutes,show_results,created_at,course_id,courses(code,title)');
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get assessments for courses the student is enrolled in
  static Future<List<Map<String, dynamic>>> getEnrolledAssessments(
      int studentId) async {
    try {
      // 1. Get enrolled course IDs
      final enrollUri = Uri.parse(
          '$baseUrl/rest/v1/course_enrollments?student_id=eq.$studentId&select=course_id');
      final enrollRes = await http.get(enrollUri, headers: headers);
      if (enrollRes.statusCode != 200) return [];

      final List enrollData = jsonDecode(enrollRes.body);
      final courseIds = enrollData.map((e) => e['course_id']).toList();

      // DEBUG
      // ignore: avoid_print
      print('[ASMT_QUERY] courses=$courseIds');

      if (courseIds.isEmpty) return [];

      // 2. Get assessments for these courses
      final idsStr = courseIds.join(',');
      final uri = Uri.parse(
          '$baseUrl/rest/v1/quickfire_assessments?course_id=in.($idsStr)&is_active=eq.true&select=id,title,description,duration_minutes,show_results,created_at,course_id,courses(code,title)');
      final res = await http.get(uri, headers: headers);
      
      // DEBUG
      // ignore: avoid_print
      print('[ASMT_RESULTS] status=${res.statusCode} body=${res.body}');

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get all available courses
  static Future<List<Map<String, dynamic>>> getAllCourses() async {
    try {
      final uri = Uri.parse(
          '$baseUrl/rest/v1/courses?is_active=eq.true&select=id,code,title,description,credit_units');
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get enrolled course IDs for a student
  static Future<List<int>> getStudentEnrollments(int studentId) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/rest/v1/course_enrollments?student_id=eq.$studentId&select=course_id');
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => e['course_id'] as int).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Enroll student in a course
  static Future<bool> enrollInCourse(int studentId, int courseId) async {
    try {
      final uri = Uri.parse('$baseUrl/rest/v1/course_enrollments');
      final res = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'student_id': studentId,
          'course_id': courseId,
          'academic_year': 2026,
          'semester': 1,
        }),
      );
      // DEBUG
      // ignore: avoid_print
      print('[ENROLL] status=${res.statusCode} body=${res.body}');
      
      final success = res.statusCode == 201 || res.statusCode == 200;
      if (success) {
        await createNotification(
          studentId: studentId,
          title: 'Course Enrolled',
          message: 'You have successfully enrolled in the course.',
          type: 'general',
        );
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Unenroll student from a course
  static Future<bool> unenrollFromCourse(int studentId, int courseId) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/rest/v1/course_enrollments?student_id=eq.$studentId&course_id=eq.$courseId');
      final res = await http.delete(uri, headers: headers);
      
      final success = res.statusCode == 200 || res.statusCode == 204;
      if (success) {
        await createNotification(
          studentId: studentId,
          title: 'Course Dropped',
          message: 'You have unenrolled from the course.',
          type: 'general',
        );
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Create a notification
  static Future<bool> createNotification({
    required int studentId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/rest/v1/notifications');
      final res = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'student_id': studentId,
          'title': title,
          'message': message,
          'type': type,
          'priority': 'medium',
        }),
      );
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get assessment by ID with questions
  static Future<Map<String, dynamic>?> getAssessmentWithQuestions(
      int assessmentId) async {
    try {
      // Get assessment
      final assessUri = Uri.parse(
          '$baseUrl/rest/v1/quickfire_assessments?id=eq.$assessmentId&select=id,title,description,duration_minutes,show_results,courses(code,title)');
      final assessRes = await http.get(assessUri, headers: headers);

      // Get questions
      final qUri = Uri.parse(
          '$baseUrl/rest/v1/quickfire_questions?assessment_id=eq.$assessmentId&select=id,question_text,question_type,options,correct_answer,marks,min_words,max_words,sequence_order&order=sequence_order.asc');
      final qRes = await http.get(qUri, headers: headers);

      if (assessRes.statusCode == 200 && qRes.statusCode == 200) {
        final assessList = jsonDecode(assessRes.body) as List;
        final questions = jsonDecode(qRes.body) as List;
        if (assessList.isNotEmpty) {
          final assessment = Map<String, dynamic>.from(assessList[0]);
          assessment['questions'] = questions;
          return assessment;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get or create attempt
  static Future<Map<String, dynamic>?> getOrCreateAttempt(
      int assessmentId, int studentId) async {
    try {
      // Check existing
      final checkUri = Uri.parse(
          '$baseUrl/rest/v1/quickfire_attempts?assessment_id=eq.$assessmentId&student_id=eq.$studentId&select=id,status,total_score,started_at,submitted_at');
      final checkRes = await http.get(checkUri, headers: headers);
      if (checkRes.statusCode == 200) {
        final existing = jsonDecode(checkRes.body) as List;
        if (existing.isNotEmpty) {
          return Map<String, dynamic>.from(existing[0]);
        }
      }

      // Create new
      final createUri =
          Uri.parse('$baseUrl/rest/v1/quickfire_attempts');
      final createRes = await http.post(createUri,
          headers: headers,
          body: jsonEncode({
            'assessment_id': assessmentId,
            'student_id': studentId,
            'status': 'in_progress',
            'total_score': 0,
          }));
      if (createRes.statusCode == 201) {
        final created = jsonDecode(createRes.body) as List;
        if (created.isNotEmpty) return Map<String, dynamic>.from(created[0]);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save/update an answer
  static Future<bool> saveAnswer({
    required int attemptId,
    required int questionId,
    required String? answerText,
    required bool? isCorrect,
    required int marksObtained,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/rest/v1/quickfire_answers');
      final res = await http.post(uri,
          headers: {
            ...headers,
            'Prefer': 'resolution=merge-duplicates,return=representation',
          },
          body: jsonEncode({
            'attempt_id': attemptId,
            'question_id': questionId,
            'answer_text': answerText,
            'is_correct': isCorrect,
            'marks_obtained': marksObtained,
          }));
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Submit attempt
  static Future<bool> submitAttempt(int attemptId, int totalScore) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/rest/v1/quickfire_attempts?id=eq.$attemptId');
      final res = await http.patch(uri,
          headers: headers,
          body: jsonEncode({
            'status': 'submitted',
            'total_score': totalScore,
            'submitted_at': DateTime.now().toIso8601String(),
          }));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // Get answers for an attempt
  static Future<List<Map<String, dynamic>>> getAttemptAnswers(
      int attemptId) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/rest/v1/quickfire_answers?attempt_id=eq.$attemptId&select=id,question_id,answer_text,is_correct,marks_obtained');
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get student's attempts with scores (report view)
  static Future<List<Map<String, dynamic>>> getStudentAttempts(
      int studentId) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/rest/v1/quickfire_attempts?student_id=eq.$studentId&order=started_at.desc&select=id,status,total_score,started_at,submitted_at,assessment_id,quickfire_assessments(id,title,duration_minutes,show_results,courses(code,title))');
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get student notifications
  static Future<List<Map<String, dynamic>>> getStudentNotifications(
      int studentId) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/rest/v1/notifications?student_id=eq.$studentId&archived_at=is.null&order=created_at.desc&select=id,title,message,type,is_read,created_at,priority,action_url');
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Mark notification as read
  static Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final uri =
          Uri.parse('$baseUrl/rest/v1/notifications?id=eq.$notificationId');
      final res = await http.patch(uri,
          headers: headers,
          body: jsonEncode({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          }));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
