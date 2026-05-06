// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../models/student.dart';
import '../models/assessment.dart';
import '../theme.dart';
import '../screens/login_screen.dart';
import '../screens/assessment_screen.dart';
import '../screens/report_screen.dart';
import '../utils/fullscreen.dart';

enum HomeView { dashboard, assessments, results, courses }

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  const HomeScreen({super.key, required this.studentData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Student student;
  List<Assessment> _assessments = [];
  List<Map<String, dynamic>> _attempts = [];
  List<Map<String, dynamic>> _courses = [];
  List<int> _enrolledCourseIds = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  HomeView _currentView = HomeView.dashboard;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    student = Student.fromJson(widget.studentData);
    _loadData();
    // Refresh UI every second for countdowns
    int seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
        seconds++;
        // Refresh data every 30 seconds
        if (seconds >= 30) {
          seconds = 0;
          _loadData();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Only show loading if we don't have data yet
    if (_courses.isEmpty) {
      setState(() => _loading = true);
    }
    
    final assessments = await SupabaseService.getEnrolledAssessments(student.id);
    final attempts = await SupabaseService.getStudentAttempts(student.id);
    final courses = await SupabaseService.getAllCourses();
    final enrollments = await SupabaseService.getStudentEnrollments(student.id);
    final notifs = await SupabaseService.getStudentNotifications(student.id);

    if (mounted) {
      setState(() {
        _assessments = assessments.map((a) => Assessment.fromJson(a)).toList();
        _attempts = attempts;
        _courses = courses;
        _enrolledCourseIds = enrollments;
        _notifications = notifs;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('student');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['is_read']).length;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: AppBar(
        title: Text(_getViewTitle()),
        backgroundColor: AppTheme.getSurface(context),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showNotifications,
            icon: Badge(
              label: Text(unreadCount.toString()),
              isLabelVisible: unreadCount > 0,
              backgroundColor: AppTheme.error,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: _buildCurrentView(),
            ),
          ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            const Icon(Icons.notifications_active_outlined, color: AppTheme.primary),
            const SizedBox(width: 12),
            Text('Notifications', style: TextStyle(color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 500,
          child: _notifications.isEmpty
            ? Center(child: Text('No notifications yet', style: TextStyle(color: AppTheme.getTextMuted(context))))
            : ListView.separated(
                itemCount: _notifications.length,
                separatorBuilder: (context, i) => Divider(color: AppTheme.getBorder(context), height: 1),
                itemBuilder: (context, i) {
                  final n = _notifications[i];
                  final isRead = n['is_read'] == true;
                  return ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    tileColor: isRead ? null : AppTheme.primary.withValues(alpha: 0.05),
                    title: Text(n['title'], style: TextStyle(color: AppTheme.getTextPrimary(context), fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(n['message'], style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(n['created_at']),
                          style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 11),
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (!isRead) {
                        await SupabaseService.markNotificationAsRead(n['id']);
                        _loadData();
                      }
                    },
                  );
                },
              ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return '';
    }
  }

  String _getRemainingTime(dynamic attempt, int? durationMinutes) {
    if (attempt == null || attempt['started_at'] == null || durationMinutes == null) return '';
    try {
      final startedAt = DateTime.parse(attempt['started_at']);
      final endAt = startedAt.add(Duration(minutes: durationMinutes));
      final remaining = endAt.difference(DateTime.now());

      if (remaining.isNegative) return 'Time Up';
      
      final h = remaining.inHours;
      final m = remaining.inMinutes % 60;
      final s = remaining.inSeconds % 60;

      if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _getViewTitle() {
    switch (_currentView) {
      case HomeView.dashboard: return 'Dashboard';
      case HomeView.assessments: return 'Tasks';
      case HomeView.results: return 'Preview';
      case HomeView.courses: return 'Course Directory';
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.getBackground(context),
      child: Column(
        children: [
          _buildDrawerHeader(),
          _drawerItem(HomeView.dashboard, 'Dashboard', Icons.dashboard_rounded),
          _drawerItem(HomeView.assessments, 'Tasks', Icons.assignment_outlined),
          _drawerItem(HomeView.courses, 'Courses', Icons.school_outlined),
          const Spacer(),
          Divider(color: AppTheme.getBorder(context)),
          ListTile(
            onTap: _logout,
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Logout', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        border: Border(bottom: BorderSide(color: AppTheme.getBorder(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? 'assets/images/q_dark.png'
                      : 'assets/images/q_light.png',
                  width: 48,
                  height: 48,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quickfire',
                    style: TextStyle(
                      color: AppTheme.getTextPrimary(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Exam Portal',
                    style: TextStyle(
                      color: AppTheme.getTextSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primary,
                child: Text(
                  student.firstName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: TextStyle(
                        color: AppTheme.getTextPrimary(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      student.registrationNumber,
                      style: TextStyle(
                        color: AppTheme.getTextSecondary(context),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(HomeView view, String title, IconData icon) {
    final isSelected = _currentView == view;
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.getTextSecondary(context)),
      title: Text(title, style: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.getTextPrimary(context), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        setState(() => _currentView = view);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case HomeView.dashboard: return _buildDashboard();
      case HomeView.assessments: return _buildAssessmentsList();
      case HomeView.results: return _buildResultsList();
      case HomeView.courses: return _buildCoursesList();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back,', style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 16)),
          Text(student.firstName, style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 32, fontWeight: FontWeight.bold)),
          Text('Here is your academic overview.', style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 14)),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: MediaQuery.of(context).size.width > 600 ? 2.5 : 1.3,
            children: [
              _statCard('Enrolled Courses', _enrolledCourseIds.length.toString(), Icons.school_outlined, AppTheme.primary, onTap: () => setState(() => _currentView = HomeView.courses)),
              _statCard('Active Assessments', _assessments.length.toString(), Icons.assignment_outlined, Colors.purple, onTap: () => setState(() => _currentView = HomeView.assessments)),
              _statCard('Pending Work', _assessments.where((asmt) => !_attempts.any((att) => att['assessment_id'] == asmt.id && att['status'] == 'submitted')).length.toString(), Icons.pending_outlined, AppTheme.warning, onTap: () => setState(() => _currentView = HomeView.assessments)),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Text('Recent Activity', style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    // Merge attempts and notifications into a unified activity list
    final List<Map<String, dynamic>> activities = [
      ..._attempts.map((a) => {
        'type': 'assessment',
        'title': (a['quickfire_assessments']?['title'] ?? 'Assessment'),
        'subtitle': (a['quickfire_assessments']?['courses']?['code'] ?? ''),
        'date': DateTime.tryParse(a['started_at'] ?? '') ?? DateTime.now(),
        'status': a['status'] == 'submitted' ? 'Completed' : 'In Progress',
        'remaining': a['status'] == 'submitted' 
            ? null 
            : _getRemainingTime(a, (a['quickfire_assessments']?['duration_minutes'] as int?)),
        'color': a['status'] == 'submitted' ? AppTheme.success : AppTheme.warning,
        'icon': a['status'] == 'submitted' ? Icons.check_rounded : Icons.timer_outlined,
        'onTap': () {
            final assessData = a['quickfire_assessments'] as Map<String, dynamic>? ?? {};
            if (a['status'] == 'submitted') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(attemptId: a['id'], assessmentId: a['assessment_id'], student: student, totalScore: a['total_score'] ?? 0, showResults: false)));
            } else {
              FullscreenService.enter();
              Navigator.push(context, MaterialPageRoute(builder: (_) => AssessmentScreen(assessment: Assessment.fromJson(assessData), student: student)));
            }
        },
      }),
      ..._notifications.map((n) => {
        'type': 'notification',
        'title': n['title'],
        'subtitle': n['message'],
        'date': DateTime.tryParse(n['created_at'] ?? '') ?? DateTime.now(),
        'status': 'System Alert',
        'color': AppTheme.primary,
        'icon': Icons.notifications_none_rounded,
        'onTap': _showNotifications,
      }),
    ];

    activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    final recent = activities.take(5).toList();
    
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.getBorder(context)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history_rounded, color: AppTheme.getTextMuted(context), size: 40),
              const SizedBox(height: 12),
              Text('No recent activity', style: TextStyle(color: AppTheme.getTextSecondary(context), fontWeight: FontWeight.w600)),
              Text('Start a task or enroll in a course to see it here.', style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: recent.map((act) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.getSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getBorder(context)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: act['color'].withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(act['icon'], color: act['color'], size: 20),
            ),
            title: Text(act['title'], style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(act['subtitle'], style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(act['status'], 
                  style: TextStyle(color: act['color'], fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (act['remaining'] != null && act['remaining'].isNotEmpty)
                  Text(
                    'Time: ${act['remaining']}',
                    style: TextStyle(color: AppTheme.warning.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.bold),
                  )
                else
                  Text(
                    _formatTime(act['date'].toIso8601String()),
                    style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 10),
                  ),
              ],
            ),
            onTap: act['onTap'],
          ),
        );
      }).toList(),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.getBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value, style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(label, style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentsList() {
    if (_assessments.isEmpty) {
      if (_enrolledCourseIds.isEmpty) {
        return _emptyState(
          icon: Icons.school_outlined,
          title: 'No Subscriptions',
          subtitle: 'Go to the Courses section to subscribe to courses and see assessments.',
        );
      }
      return _emptyState(
        icon: Icons.assignment_outlined,
        title: 'No Tasks Found',
        subtitle: 'Your lecturers haven\'t posted any work yet for your enrolled courses.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _assessments.length,
      itemBuilder: (context, i) => _buildAssessmentCard(_assessments[i]),
    );
  }

  Widget _buildAssessmentCard(Assessment assessment) {
    final attempt = _attempts.firstWhere((a) => a['assessment_id'] == assessment.id, orElse: () => {});
    final isSubmitted = attempt['status'] == 'submitted';
    final isInProgress = attempt['status'] == 'in_progress';

    return GestureDetector(
      onTap: () async {
        if (isSubmitted) {
          // View Preview
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => ReportScreen(
              attemptId: attempt['id'], 
              assessmentId: assessment.id, 
              student: student, 
              totalScore: attempt['total_score'] ?? 0, 
              showResults: false
            ))
          );
        } else {
          // Start/Resume Assessment
          FullscreenService.enter();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AssessmentScreen(assessment: assessment, student: student)),
          );
          _loadData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSubmitted ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.getBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _badge(assessment.courseCode, AppTheme.primary),
                const Spacer(),
                if (isSubmitted) _badge('Completed', AppTheme.success)
                else if (isInProgress) 
                  _badge('Time: ${_getRemainingTime(attempt, assessment.durationMinutes)}', AppTheme.warning)
                else _badge('Available', AppTheme.getTextMuted(context)),
              ],
            ),
            const SizedBox(height: 12),
            Text(assessment.title, 
              style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(assessment.courseTitle, 
              style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: AppTheme.getTextMuted(context)),
                const SizedBox(width: 4),
                Text('${assessment.durationMinutes} mins', style: TextStyle(color: AppTheme.getTextMuted(context), fontSize: 12)),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    final submitted = _attempts.where((a) => a['status'] == 'submitted').toList();

    if (submitted.isEmpty) {
      return _emptyState(
        icon: Icons.bar_chart_rounded,
        title: 'No Submissions Ready',
        subtitle: 'Submit an assessment to preview your responses and academic record here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: submitted.length,
      itemBuilder: (context, i) {
        final attempt = submitted[i];
        final assessData = attempt['quickfire_assessments'] as Map<String, dynamic>? ?? {};
        final courseData = assessData['courses'] as Map<String, dynamic>? ?? {};
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.getSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getBorder(context)),
          ),
          child: ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(attemptId: attempt['id'], assessmentId: attempt['assessment_id'], student: student, totalScore: attempt['total_score'] ?? 0, showResults: false))),
            title: Text(assessData['title'] ?? 'Assessment', style: TextStyle(color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.bold)),
            subtitle: Text('${courseData['code'] ?? ''} • ${courseData['title'] ?? ''}', style: TextStyle(color: AppTheme.getTextSecondary(context))),
            trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.getTextMuted(context)),
          ),
        );
      },
    );
  }

  Widget _buildCoursesList() {
    final filtered = _courses.where((c) {
      final query = _searchQuery.toLowerCase();
      final code = (c['code'] ?? '').toString().toLowerCase();
      final title = (c['title'] ?? '').toString().toLowerCase();
      return code.contains(query) || title.contains(query);
    }).toList();

    final enrolled = filtered.where((c) => _enrolledCourseIds.contains(c['id'])).toList();
    final available = filtered.where((c) => !_enrolledCourseIds.contains(c['id'])).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: const InputDecoration(hintText: 'Search courses...', prefixIcon: Icon(Icons.search)),
          ),
        ),
        Expanded(
          child: (enrolled.isEmpty && available.isEmpty)
            ? _emptyState(icon: Icons.search_off_rounded, title: 'No Courses Found', subtitle: 'Try a different search term.')
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (enrolled.isNotEmpty) ...[
                    _sectionHeader('My Subscriptions'),
                    ...enrolled.map((c) => _buildCourseCard(c)),
                    const SizedBox(height: 24),
                  ],
                  if (available.isNotEmpty) ...[
                    _sectionHeader('Course Directory'),
                    ...available.map((c) => _buildCourseCard(c)),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Text(title,
          style: TextStyle(
              color: AppTheme.getTextPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final isEnrolled = _enrolledCourseIds.contains(course['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isEnrolled ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.getBorder(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course['code'], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(course['title'], style: TextStyle(color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isEnrolled)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 16),
                      SizedBox(width: 6),
                      Text('Enrolled', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showUnenrollDialog(course),
                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.error, size: 20),
                  tooltip: 'Unenroll from course',
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: () async {
                setState(() => _loading = true);
                final ok = await SupabaseService.enrollInCourse(student.id, course['id']);
                if (ok) {
                  _loadData();
                } else {
                  if (mounted) setState(() => _loading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Enroll Now'),
            ),
        ],
      ),
    );
  }

  void _showUnenrollDialog(Map<String, dynamic> course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unenroll from ${course['code']}?'),
        content: const Text('You will no longer be able to see assessments for this course.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _loading = true);
              final ok = await SupabaseService.unenrollFromCourse(student.id, course['id']);
              if (ok) {
                _loadData();
              } else {
                if (mounted) setState(() => _loading = false);
              }
            },
            child: const Text('Drop Course', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppTheme.getTextMuted(context).withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.getTextSecondary(context))),
          ),
        ],
      ),
    );
  }
}
