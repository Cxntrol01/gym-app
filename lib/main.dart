import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const PhysiqueEngineApp());
}

// ============================================================================
// GLOBAL APP STATE & MODELS
// ============================================================================

enum UnitSystem { metric, imperial }

class UserProfile {
  String username;
  String email;
  bool isAuthed;
  UnitSystem unitSystem;
  double totalWeightMovedAllTime;
  int consistencyStreakDays;

  UserProfile({
    required this.username,
    required this.email,
    this.isAuthed = false,
    this.unitSystem = UnitSystem.metric,
    this.totalWeightMovedAllTime = 48250.0,
    this.consistencyStreakDays = 12,
  });
}

class FriendModel {
  final String username;
  final double weeklyVolumeKg;
  final int streakDays;
  final bool isSamsungConnected;

  FriendModel({
    required this.username,
    required this.weeklyVolumeKg,
    required this.streakDays,
    required this.isSamsungConnected,
  });
}

class AppState extends ChangeNotifier {
  UserProfile currentUser = UserProfile(username: 'Athlete_X', email: 'user@engine.com', isAuthed: false);
  
  // Calendar: Map of 'YYYY-MM-DD' -> DayType ('Training', 'Rest')
  final Map<String, String> calendarDays = {
    '2026-09-01': 'Training',
    '2026-09-02': 'Training',
    '2026-09-03': 'Rest',
    '2026-09-04': 'Training',
    '2026-09-05': 'Training',
    '2026-09-06': 'Rest',
    '2026-09-07': 'Training',
  };

  // Samsung Wearable Mock State
  bool isSamsungConnected = false;
  int liveWatchHeartRate = 128;
  int liveWatchCalories = 412;

  // Friends list
  final List<FriendModel> friends = [
    FriendModel(username: 'Sarah_Liftz', weeklyVolumeKg: 14200, streakDays: 19, isSamsungConnected: true),
    FriendModel(username: 'IronMark', weeklyVolumeKg: 18900, streakDays: 5, isSamsungConnected: false),
    FriendModel(username: 'Elena_Fit', weeklyVolumeKg: 11400, streakDays: 28, isSamsungConnected: true),
  ];

  void login(String username, String email) {
    currentUser.username = username;
    currentUser.email = email;
    currentUser.isAuthed = true;
    notifyListeners();
  }

  void logout() {
    currentUser.isAuthed = false;
    notifyListeners();
  }

  void toggleCalendarDay(String dateKey) {
    final current = calendarDays[dateKey] ?? 'Training';
    calendarDays[dateKey] = current == 'Training' ? 'Rest' : 'Training';
    notifyListeners();
  }

  void toggleSamsungWatchConnection() {
    isSamsungConnected = !isSamsungConnected;
    notifyListeners();
  }

  void addFriend(String username) {
    if (username.trim().isEmpty) return;
    friends.add(FriendModel(username: username.trim(), weeklyVolumeKg: 5000, streakDays: 1, isSamsungConnected: true));
    notifyListeners();
  }
}

final AppState globalState = AppState();

// ============================================================================
// APP ROOT & AUTH WRAPPER
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
    globalState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    globalState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Physique & Bio-Engine Lab',
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
      home: globalState.currentUser.isAuthed ? const MainNavigationScreen() : const AuthScreen(),
    );
  }
}

// ============================================================================
// AUTHENTICATION SCREEN (LOGIN / SIGNUP)
// ============================================================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _usernameController.text.trim().isEmpty ? 'AlphaAthlete' : _usernameController.text.trim();
    final email = _emailController.text.trim().isEmpty ? 'athlete@engine.com' : _emailController.text.trim();
    globalState.login(username, email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF131821),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fitness_center, size: 56, color: Color(0xFF00E676)),
                const SizedBox(height: 16),
                Text(
                  _isSignUp ? 'Create Engine Account' : 'Welcome Back',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Track workouts, sync Samsung wearables, & compare with friends.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 24),
                if (_isSignUp) ...[
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submit,
                    child: Text(_isSignUp ? 'Create Account' : 'Secure Login', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(_isSignUp ? 'Already have an account? Login' : 'Need an account? Sign up'),
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
// MAIN NAVIGATION WRAPPER
// ============================================================================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    CalendarDashboardTab(),
    AdvancedStatsTab(),
    WorkoutTrackerTab(),
    ProgressDashboardTab(),
    RestTimerTab(),
    SamsungWatchTab(),
    SocialFriendsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
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
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Rest Timer'),
          BottomNavigationBarItem(icon: Icon(Icons.watch), label: 'Samsung'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. CALENDAR FOR TRAINING DAYS AND REST DAYS INTERCHANGEABLE
// ============================================================================

class CalendarDashboardTab extends StatelessWidget {
  const CalendarDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training & Rest Day Calendar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Interactive Split Planner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                  SizedBox(height: 6),
                  Text('Tap any date below to instantly interchange between a Training Day and a Rest Day.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 30,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final dayNum = index + 1;
              final dateKey = '2026-09-${dayNum.toString().padLeft(2, '0')}';
              final dayType = globalState.calendarDays[dateKey] ?? (dayNum % 3 == 0 ? 'Rest' : 'Training');
              final isRest = dayType == 'Rest';

              return GestureDetector(
                onTap: () => globalState.toggleCalendarDay(dateKey),
                child: Container(
                  decoration: BoxDecoration(
                    color: isRest ? const Color(0xFF1E1714) : const Color(0xFF10261A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isRest ? Colors.orangeAccent.withOpacity(0.4) : const Color(0xFF00E676).withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sep $dayNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isRest ? Colors.orangeAccent.withOpacity(0.2) : const Color(0xFF00E676).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dayType,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isRest ? Colors.orangeAccent : const Color(0xFF00E676),
                          ),
                        ),
                      ),
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
// 2. ADVANCED STATISTICS TAB (DAY, WEEK, MONTH, YEAR, ALL-TIME)
// ============================================================================

class AdvancedStatsTab extends StatelessWidget {
  const AdvancedStatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Performance Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(title: 'Consistency Streak', value: '${globalState.currentUser.consistencyStreakDays} Days', subtitle: 'Active streak', icon: Icons.local_fire_department, color: Colors.orangeAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(title: 'All-Time Volume', value: '${globalState.currentUser.totalWeightMovedAllTime.toInt()} kg', subtitle: 'Lifetime tonnage', icon: Icons.leaderboard, color: const Color(0xFF00E676)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Average Weight Moved Per Period', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _StatBarTile(label: 'Daily Average', amountKg: 3450, maxKg: 6000),
          _StatBarTile(label: 'Weekly Average', amountKg: 21500, maxKg: 35000),
          _StatBarTile(label: 'Monthly Average', amountKg: 89000, maxKg: 120000),
          _StatBarTile(label: 'Yearly Average', amountKg: 950000, maxKg: 1200000),
          _StatBarTile(label: 'All-Time Record Year', amountKg: 1150000, maxKg: 1200000),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _StatBarTile extends StatelessWidget {
  final String label;
  final double amountKg;
  final double maxKg;

  const _StatBarTile({required this.label, required this.amountKg, required this.maxKg});

  @override
  Widget build(BuildContext context) {
    final double pct = (amountKg / maxKg).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${amountKg.toInt()} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: pct, backgroundColor: Colors.white10, color: const Color(0xFF00E676), minHeight: 6),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. EXERCISE TRACKING & PROGRESS DASHBOARD TABS
// ============================================================================

class WorkoutModel {
  String name;
  double weightKg;
  int reps;
  WorkoutModel({required this.name, required this.weightKg, required this.reps});
}

class WorkoutTrackerTab extends StatefulWidget {
  const WorkoutTrackerTab({super.key});

  @override
  State<WorkoutTrackerTab> createState() => _WorkoutTrackerTabState();
}

class _WorkoutTrackerTabState extends State<WorkoutTrackerTab> {
  final List<WorkoutModel> _sessionWorkouts = [
    WorkoutModel(name: 'Barbell Bench Press', weightKg: 90.0, reps: 8),
    WorkoutModel(name: 'Incline Dumbbell Press', weightKg: 34.0, reps: 10),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();

  void _addWorkout() {
    if (_nameController.text.trim().isEmpty) return;
    setState(() {
      _sessionWorkouts.add(WorkoutModel(
        name: _nameController.text.trim(),
        weightKg: double.tryParse(_weightController.text) ?? 60.0,
        reps: int.tryParse(_repsController.text) ?? 10,
      ));
      _nameController.clear();
      _weightController.clear();
      _repsController.clear();
    });
    Navigator.of(context).pop();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log New Exercise Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Exercise Name')),
            TextField(controller: _weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)')),
            TextField(controller: _repsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addWorkout, child: const Text('Log Set')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Exercise Tracker')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessionWorkouts.length,
        itemBuilder: (context, index) {
          final w = _sessionWorkouts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.fitness_center, color: Color(0xFF00E676)),
              title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Weight: ${w.weightKg} kg | Reps: ${w.reps}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => setState(() => _sessionWorkouts.removeAt(index)),
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
        label: const Text('Add Exercise'),
      ),
    );
  }
}

class ProgressDashboardTab extends StatelessWidget {
  const ProgressDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Strength Progress Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated 1RM Trends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                  SizedBox(height: 12),
                  Text('Squat 1RM: 145 kg (+5 kg this month)', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 6),
                  Text('Bench Press 1RM: 110 kg (+2.5 kg this month)', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 6),
                  Text('Deadlift 1RM: 190 kg (+10 kg this month)', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Muscle Hypertrophy Volume Index', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Chest: 18 sets/wk (Optimal MAV)\nBack: 20 sets/wk (Optimal MAV)\nLegs: 14 sets/wk (MEV Met)', style: TextStyle(color: Colors.white70, height: 1.4)),
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
  int _secondsRemaining = 90;
  Timer? _timer;
  bool _isRunning = false;

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = seconds;
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('Rest Timer')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00E676), width: 6),
                  color: const Color(0xFF131821),
                ),
                child: Center(
                  child: Text(
                    '$minutes:$seconds',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                    onPressed: () => _startTimer(90),
                    child: const Text('90s'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                    onPressed: () => _startTimer(120),
                    child: const Text('120s'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: _stopTimer,
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ],
          ),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.watch, size: 64, color: Color(0xFF00E676)),
                  const SizedBox(height: 12),
                  Text(
                    globalState.isSamsungConnected ? 'Galaxy Watch Ultra Connected' : 'No Samsung Watch Linked',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    globalState.isSamsungConnected ? 'Real-time telemetry syncing active via Samsung Health SDK.' : 'Tap below to connect your Samsung wearable device.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: globalState.isSamsungConnected ? Colors.redAccent : const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => globalState.toggleSamsungWatchConnection(),
                    child: Text(globalState.isSamsungConnected ? 'Disconnect Watch' : 'Pair Samsung Watch'),
                  ),
                ],
              ),
            ),
          ),
          if (globalState.isSamsungConnected) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(title: 'Live Heart Rate', value: '${globalState.liveWatchHeartRate} BPM', subtitle: 'Sensors active', icon: Icons.favorite, color: Colors.redAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(title: 'Active Calories', value: '${globalState.liveWatchCalories} kcal', subtitle: 'Workout burn', icon: Icons.local_fire_department, color: Colors.orangeAccent),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 6. SOCIAL FRIENDS LEADERBOARD & STATS VIEW
// ============================================================================

class SocialFriendsTab extends StatefulWidget {
  const SocialFriendsTab({super.key});

  @override
  State<SocialFriendsTab> createState() => _SocialFriendsTabState();
}

class _SocialFriendsTabState extends State<SocialFriendsTab> {
  final TextEditingController _friendController = TextEditingController();

  @override
  void dispose() {
    _friendController.dispose();
    super.dispose();
  }

  void _addFriendAction() {
    if (_friendController.text.trim().isEmpty) return;
    globalState.addFriend(_friendController.text.trim());
    _friendController.clear();
    Navigator.of(context).pop();
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Friend by Username'),
        content: TextField(
          controller: _friendController,
          decoration: const InputDecoration(labelText: 'Friend Username'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addFriendAction, child: const Text('Add Friend')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friends & Leaderboard')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: globalState.friends.length,
        itemBuilder: (context, index) {
          final friend = globalState.friends[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF00E676).withOpacity(0.2),
                child: Text(friend.username[0].toUpperCase(), style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
              ),
              title: Text(friend.username, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Weekly Volume: ${friend.weeklyVolumeKg.toInt()} kg | Streak: ${friend.streakDays} days'),
              trailing: friend.isSamsungConnected ? const Icon(Icons.watch, color: Color(0xFF00E676), size: 20) : null,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFriendDialog,
        backgroundColor: const Color(0xFF00E676),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Friend'),
      ),
    );
  }
}
