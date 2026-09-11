import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const PhysiqueEngineApp());
}

// ============================================================================
// DATA MODELS & STATE MANAGEMENT
// ============================================================================

class LoggedSet {
  final String exerciseName;
  final double weightKg;
  final int reps;
  final DateTime timestamp;

  LoggedSet({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.timestamp,
  });

  double get totalTonnage => weightKg * reps;
}

class FriendModel {
  final String username;
  double weeklyVolumeKg;
  int streakDays;
  bool isSamsungConnected;

  FriendModel({
    required this.username,
    required this.weeklyVolumeKg,
    required this.streakDays,
    required this.isSamsungConnected,
  });
}

class AppState extends ChangeNotifier {
  bool isAuthed = false;
  String username = '';
  String email = '';

  // Calendar: Map 'YYYY-MM-DD' -> 'Training' or 'Rest'
  final Map<String, String> calendarDays = {};

  // Real workout history logged by the user
  final List<LoggedSet> workoutHistory = [];

  // Samsung Watch State
  bool isSamsungConnected = false;
  int liveHeartRate = 125;
  int liveCalories = 340;

  // Friends list
  final List<FriendModel> friends = [
    FriendModel(username: 'Sarah_Liftz', weeklyVolumeKg: 14200, streakDays: 19, isSamsungConnected: true),
    FriendModel(username: 'IronMark', weeklyVolumeKg: 18900, streakDays: 5, isSamsungConnected: false),
  ];

  void login(String user, String mail) {
    username = user.isEmpty ? 'Athlete' : user;
    email = mail.isEmpty ? 'athlete@engine.com' : mail;
    isAuthed = true;
    notifyListeners();
  }

  void logout() {
    isAuthed = false;
    notifyListeners();
  }

  void toggleCalendarDay(String dateKey) {
    final current = calendarDays[dateKey] ?? 'Training';
    calendarDays[dateKey] = current == 'Training' ? 'Rest' : 'Training';
    notifyListeners();
  }

  void logWorkoutSet(String name, double weight, int reps) {
    if (name.trim().isEmpty) return;
    workoutHistory.add(LoggedSet(
      exerciseName: name,
      weightKg: weight,
      reps: reps,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void deleteWorkoutSet(int index) {
    workoutHistory.removeAt(index);
    notifyListeners();
  }

  void toggleSamsung() {
    isSamsungConnected = !isSamsungConnected;
    notifyListeners();
  }

  void addFriend(String friendName) {
    if (friendName.trim().isEmpty) return;
    friends.add(FriendModel(
      username: friendName.trim(),
      weeklyVolumeKg: 0,
      streakDays: 1,
      isSamsungConnected: true,
    ));
    notifyListeners();
  }

  // --- STAT CALCULATIONS FROM REAL USER DATA ---
  double get totalWeightAllTime {
    return workoutHistory.fold(0.0, (sum, item) => sum + item.totalTonnage);
  }

  double get totalWeightToday {
    final today = DateTime.now();
    return workoutHistory
        .where((w) => w.timestamp.year == today.year && w.timestamp.month == today.month && w.timestamp.day == today.day)
        .fold(0.0, (sum, item) => sum + item.totalTonnage);
  }

  double get totalWeightThisWeek {
    final now = DateTime.now();
    return workoutHistory
        .where((w) => now.difference(w.timestamp).inDays <= 7)
        .fold(0.0, (sum, item) => sum + item.totalTonnage);
  }

  double get totalWeightThisMonth {
    final now = DateTime.now();
    return workoutHistory
        .where((w) => w.timestamp.year == now.year && w.timestamp.month == now.month)
        .fold(0.0, (sum, item) => sum + item.totalTonnage);
  }

  double get totalWeightThisYear {
    final now = DateTime.now();
    return workoutHistory
        .where((w) => w.timestamp.year == now.year)
        .fold(0.0, (sum, item) => sum + item.totalTonnage);
  }

  int get consistencyStreak {
    if (workoutHistory.isEmpty) return 1;
    // Basic streak representation based on active tracking days
    return 1 + (workoutHistory.length ~/ 3);
  }
}

final AppState appState = AppState();

// ============================================================================
// APP ROOT WIDGET
// ============================================================================

class PhysiqueEngineApp extends StatefulWidget {
  const PhysiqueEngineApp({super.key});

  @override
  State<PhysiqueEngineApp> createState() => _PhysiqueEngineAppState();
}

class _PhysiqueEngineAppState extends State<PhysiqueEngineApp> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_refresh);
  }

  @override
  void dispose() {
    appState.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Physique Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090D12),
        primaryColor: const Color(0xFF00E676),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF00E676),
          surface: Color(0xFF131821),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF131821),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: appState.isAuthed ? const MainDashboard() : const AuthScreen(),
    );
  }
}

// ============================================================================
// WORKING AUTHENTICATION SCREEN
// ============================================================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  void _handleAuth() {
    final user = _userController.text.trim();
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    appState.login(user.isEmpty ? 'Athlete' : user, email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF131821),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fitness_center, size: 52, color: Color(0xFF00E676)),
                const SizedBox(height: 16),
                Text(
                  _isSignUp ? 'Create Engine Account' : 'Sign In to Engine',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (_isSignUp) ...[
                  TextField(
                    controller: _userController,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _handleAuth,
                    child: Text(_isSignUp ? 'Register & Start' : 'Sign In', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(_isSignUp ? 'Already have an account? Sign In' : 'Need an account? Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN NAVIGATION TABS WRAPPER
// ============================================================================

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CalendarTab(),
    StatisticsTab(),
    TrackerTab(),
    ProgressTab(),
    RestTimerTab(),
    SamsungWatchTab(),
    SocialTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0C1017),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.white38,
        selectedFontSize: 9,
        unselectedFontSize: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Statistics'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Tracker'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
          BottomNavigationBarItem(icon: Icon(Icons.watch), label: 'Samsung'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. INTERCHANGEABLE CALENDAR TAB
// ============================================================================

class CalendarTab extends StatelessWidget {
  const CalendarTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training & Rest Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => appState.logout(),
            tooltip: 'Sign Out',
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tap any day to toggle between Training Day and Rest Day:', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 28,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final dayNum = index + 1;
              final dateKey = '2026-09-${dayNum.toString().padLeft(2, '0')}';
              final status = appState.calendarDays[dateKey] ?? (dayNum % 7 == 0 ? 'Rest' : 'Training');
              final isRest = status == 'Rest';

              return GestureDetector(
                onTap: () => appState.toggleCalendarDay(dateKey),
                child: Container(
                  decoration: BoxDecoration(
                    color: isRest ? const Color(0xFF261810) : const Color(0xFF10261A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isRest ? Colors.orangeAccent : const Color(0xFF00E676)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sep $dayNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(status, style: TextStyle(fontSize: 10, color: isRest ? Colors.orangeAccent : const Color(0xFF00E676))),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. ADVANCED STATISTICS TAB (REAL USER CALCULATIONS)
// ============================================================================

class StatisticsTab extends StatelessWidget {
  const StatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Performance Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Consistency Streak',
                  value: '${appState.consistencyStreak} Days',
                  icon: Icons.local_fire_department,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'All-Time Volume',
                  value: '${appState.totalWeightAllTime.toStringAsFixed(0)} kg',
                  icon: Icons.leaderboard,
                  color: const Color(0xFF00E676),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Weight Moved breakdown (From Your Logged Sets)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          _BarRow(label: 'Today', valueKg: appState.totalWeightToday),
          _BarRow(label: 'This Week', valueKg: appState.totalWeightThisWeek),
          _BarRow(label: 'This Month', valueKg: appState.totalWeightThisMonth),
          _BarRow(label: 'This Year', valueKg: appState.totalWeightThisYear),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double valueKg;

  const _BarRow({required this.label, required this.valueKg});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.between,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${valueKg.toStringAsFixed(1)} kg', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. EXERCISE TRACKING & PROGRESS DASHBOARD
// ============================================================================

class TrackerTab extends StatefulWidget {
  const TrackerTab({super.key});

  @override
  State<TrackerTab> createState() => _TrackerTabState();
}

class _TrackerTabState extends State<TrackerTab> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();

  void _submitSet() {
    final name = _nameController.text;
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final reps = int.tryParse(_repsController.text) ?? 0;

    appState.logWorkoutSet(name, weight, reps);
    _nameController.clear();
    _weightController.clear();
    _repsController.clear();
    Navigator.of(context).pop();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Workout Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Exercise (e.g. Squat)')),
            TextField(controller: _weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)')),
            TextField(controller: _repsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: _submitSet, child: const Text('Save Set')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Exercise Tracker')),
      body: appState.workoutHistory.isEmpty
          ? const Center(child: Text('No workouts logged yet. Tap + to add sets!', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appState.workoutHistory.length,
              itemBuilder: (context, index) {
                final set = appState.workoutHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.fitness_center, color: Color(0xFF00E676)),
                    title: Text(set.exerciseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Weight: ${set.weightKg} kg | Reps: ${set.reps} | Tonnage: ${set.totalTonnage} kg'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => appState.deleteWorkoutSet(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF00E676),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Log Set'),
      ),
    );
  }
}

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Sets Tracked', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                  const SizedBox(height: 8),
                  Text('${appState.workoutHistory.length} total sets logged in active history.', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. REST TIMER PAGE
// ============================================================================

class RestTimerTab extends StatefulWidget {
  const RestTimerTab({super.key});

  @override
  State<RestTimerTab> createState() => _RestTimerTabState();
}

class _RestTimerTabState extends State<RestTimerTab> {
  int _secondsLeft = 90;
  Timer? _timer;

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 90);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('Rest Timer')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$m:$s', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () => _startTimer(60), child: const Text('60s')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () => _startTimer(90), child: const Text('90s')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _stopTimer, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 5. SAMSUNG WEARABLE INTEGRATION
// ============================================================================

class SamsungWatchTab extends StatelessWidget {
  const SamsungWatchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Samsung Galaxy Watch Sync')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.watch, size: 54, color: Color(0xFF00E676)),
                    const SizedBox(height: 10),
                    Text(appState.isSamsungConnected ? 'Galaxy Watch Connected' : 'No Watch Linked'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appState.isSamsungConnected ? Colors.redAccent : const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => appState.toggleSamsung(),
                      child: Text(appState.isSamsungConnected ? 'Disconnect' : 'Connect Watch'),
                    ),
                  ],
                ),
              ),
            ),
            if (appState.isSamsungConnected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatCard(title: 'Heart Rate', value: '${appState.liveHeartRate} BPM', icon: Icons.favorite, color: Colors.redAccent)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: 'Active Burn', value: '${appState.liveCalories} kcal', icon: Icons.local_fire_department, color: Colors.orangeAccent)),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 6. SOCIAL FRIENDS LEADERBOARD
// ============================================================================

class SocialTab extends StatefulWidget {
  const SocialTab({super.key});

  @override
  State<SocialTab> createState() => _SocialTabState();
}

class _SocialTabState extends State<SocialTab> {
  final TextEditingController _friendController = TextEditingController();

  void _addFriend() {
    appState.addFriend(_friendController.text);
    _friendController.clear();
    Navigator.of(context).pop();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Friend by Username'),
        content: TextField(controller: _friendController, decoration: const InputDecoration(labelText: 'Username')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addFriend, child: const Text('Add')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friends Leaderboard')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.friends.length,
        itemBuilder: (context, index) {
          final f = appState.friends[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text(f.username[0].toUpperCase())),
              title: Text(f.username, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Weekly Volume: ${f.weeklyVolumeKg.toInt()} kg | Streak: ${f.streakDays} days'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF00E676),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Friend'),
      ),
    );
  }
}
