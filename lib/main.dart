import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const GymMasterProApp());

class GymMasterProApp extends StatelessWidget {
  const GymMasterProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Master PRO',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        cardColor: const Color(0xFF14141E),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF7C4DFF),
          surface: Color(0xFF14141E),
        ),
      ),
      home: const RootNavigationScreen(),
    );
  }
}

// Global Exercise Master Library
List<Map<String, String>> globalExerciseLibrary = [
  // Chest
  {'name': 'Barbell Bench Press', 'group': 'Chest & Triceps', 'equipment': 'Barbell / Flat Bench', 'target': 'Mid Chest'},
  {'name': 'Incline Dumbbell Press', 'group': 'Chest & Triceps', 'equipment': 'Dumbbells / Incline Bench', 'target': 'Upper Chest'},
  {'name': 'Chest Press Machine', 'group': 'Chest & Triceps', 'equipment': 'Machine', 'target': 'Chest Hypertrophy'},
  {'name': 'Cable Crossover Flyes', 'group': 'Chest & Triceps', 'equipment': 'Cable Tower', 'target': 'Lower/Inner Chest'},
  {'name': 'Triceps Rope Pushdown', 'group': 'Chest & Triceps', 'equipment': 'Cable Tower', 'target': 'Triceps Lateral Head'},
  {'name': 'Skull Crushers', 'group': 'Chest & Triceps', 'equipment': 'EZ-Bar / Flat Bench', 'target': 'Triceps Long Head'},

  // Back
  {'name': 'Lat Pulldown', 'group': 'Back & Biceps', 'equipment': 'Lat Cable Machine', 'target': 'Lats Width'},
  {'name': 'Seated Cable Row', 'group': 'Back & Biceps', 'equipment': 'Cable Station', 'target': 'Mid Back Thickness'},
  {'name': 'Bent Over Barbell Row', 'group': 'Back & Biceps', 'equipment': 'Barbell', 'target': 'Upper/Mid Back'},
  {'name': 'Preacher Machine Curl', 'group': 'Back & Biceps', 'equipment': 'Preacher Machine', 'target': 'Biceps Short Head'},
  {'name': 'Incline Dumbbell Curl', 'group': 'Back & Biceps', 'equipment': 'Dumbbells', 'target': 'Biceps Long Head'},

  // Legs
  {'name': 'Barbell Back Squat', 'group': 'Legs & Calves', 'equipment': 'Squat Rack', 'target': 'Quads & Glutes'},
  {'name': '45° Leg Press', 'group': 'Legs & Calves', 'equipment': 'Leg Press Machine', 'target': 'Quad Overall'},
  {'name': 'Lying Leg Curl', 'group': 'Legs & Calves', 'equipment': 'Hamstring Machine', 'target': 'Hamstrings'},
  {'name': 'Leg Extension', 'group': 'Legs & Calves', 'equipment': 'Quad Extension Machine', 'target': 'Quads Isolation'},
  {'name': 'Standing Calf Raise', 'group': 'Legs & Calves', 'equipment': 'Calf Machine', 'target': 'Gastrocnemius'},

  // Shoulders & Abs
  {'name': 'Overhead Dumbbell Press', 'group': 'Shoulders & Abs', 'equipment': 'Dumbbells / Bench', 'target': 'Anterior Delt'},
  {'name': 'Cable Lateral Raise', 'group': 'Shoulders & Abs', 'equipment': 'Cable Station', 'target': 'Lateral Delt'},
  {'name': 'Reverse Pec Deck Flye', 'group': 'Shoulders & Abs', 'equipment': 'Pec Deck Machine', 'target': 'Rear Delt'},
  {'name': 'Hanging Leg Raise', 'group': 'Shoulders & Abs', 'equipment': 'Pull-up Bar', 'target': 'Lower Abs'},
  {'name': 'Weighted Ab Crunch', 'group': 'Shoulders & Abs', 'equipment': 'Cable / Machine', 'target': 'Abs'},

  // Arms Focus
  {'name': 'EZ-Bar Bicep Curl', 'group': 'Arms Focus', 'equipment': 'EZ-Bar', 'target': 'Biceps Overall'},
  {'name': 'Hammer Curls', 'group': 'Arms Focus', 'equipment': 'Dumbbells', 'target': 'Brachialis'},
  {'name': 'Weighted Dips', 'group': 'Arms Focus', 'equipment': 'Dip Station', 'target': 'Triceps Overall'},
  {'name': 'Overhead Cable Extension', 'group': 'Arms Focus', 'equipment': 'Cable Station', 'target': 'Triceps Long Head'},
];

class RootNavigationScreen extends StatefulWidget {
  const RootNavigationScreen({super.key});

  @override
  State<RootNavigationScreen> createState() => _RootNavigationScreenState();
}

class _RootNavigationScreenState extends State<RootNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TodayWorkoutTab(),
    const ScheduleConfiguratorTab(),
    const ExerciseLibraryTab(),
    const ToolsAndAnalyticsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF101018),
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Tools'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: TODAY WORKOUT & ACTIVE TRACKER
// -----------------------------------------------------------------------------
class TodayWorkoutTab extends StatefulWidget {
  const TodayWorkoutTab({super.key});

  @override
  State<TodayWorkoutTab> createState() => _TodayWorkoutTabState();
}

class _TodayWorkoutTabState extends State<TodayWorkoutTab> {
  final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  Set<String> restDays = {'Wed', 'Sun'};
  Map<String, String> dayToMuscleMap = {};
  
  bool isWorkoutActive = false;
  int sessionSeconds = 0;
  Timer? _sessionTimer;

  int restSeconds = 0;
  Timer? _restTimer;

  List<Map<String, dynamic>> activeSessionExercises = [];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRest = prefs.getStringList('user_rest_days');
    if (savedRest != null) {
      restDays = savedRest.toSet();
    }

    final List<String> muscleSplits = [
      'Chest & Triceps', 'Back & Biceps', 'Legs & Calves', 'Shoulders & Abs', 'Arms Focus'
    ];
    int activeIdx = 0;
    Map<String, String> newMap = {};
    for (String day in weekDays) {
      if (restDays.contains(day)) {
        newMap[day] = 'Rest Day';
      } else {
        newMap[day] = muscleSplits[activeIdx % muscleSplits.length];
        activeIdx++;
      }
    }
    setState(() {
      dayToMuscleMap = newMap;
    });

    _loadTodayExercises();
  }

  String _getTodayName() {
    final now = DateTime.now();
    return weekDays[now.weekday - 1];
  }

  Future<void> _loadTodayExercises() async {
    final String today = _getTodayName();
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('exercises_$today');

    if (raw != null) {
      setState(() {
        activeSessionExercises = List<Map<String, dynamic>>.from(jsonDecode(raw));
      });
    } else {
      final String group = dayToMuscleMap[today] ?? 'Rest Day';
      final defaults = globalExerciseLibrary.where((e) => e['group'] == group).toList();
      
      setState(() {
        activeSessionExercises = defaults.map((ex) {
          return {
            'name': ex['name'],
            'equipment': ex['equipment'],
            'target': ex['target'],
            'sets': [
              {'weight': '40', 'reps': '10', 'done': false},
              {'weight': '45', 'reps': '10', 'done': false},
              {'weight': '50', 'reps': '8', 'done': false},
            ]
          };
        }).toList();
      });
      _saveTodayExercises();
    }
  }

  Future<void> _saveTodayExercises() async {
    final String today = _getTodayName();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exercises_$today', jsonEncode(activeSessionExercises));
  }

  void _startWorkoutSession() {
    setState(() {
      isWorkoutActive = true;
      sessionSeconds = 0;
    });
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => sessionSeconds++);
    });
  }

  void _finishWorkoutSession() async {
    _sessionTimer?.cancel();
    _restTimer?.cancel();

    // Calculate Volume
    double totalVol = 0;
    int setsCompleted = 0;
    for (var ex in activeSessionExercises) {
      for (var s in ex['sets']) {
        if (s['done'] == true) {
          double w = double.tryParse(s['weight'].toString()) ?? 0;
          int r = int.tryParse(s['reps'].toString()) ?? 0;
          totalVol += (w * r);
          setsCompleted++;
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final List<String> logs = prefs.getStringList('workout_history') ?? [];
    final newLog = jsonEncode({
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'day': _getTodayName(),
      'muscle': dayToMuscleMap[_getTodayName()] ?? 'Workout',
      'duration': _formatTimer(sessionSeconds),
      'volume': totalVol.toInt(),
      'sets': setsCompleted,
    });
    logs.add(newLog);
    await prefs.setStringList('workout_history', logs);

    setState(() {
      isWorkoutActive = false;
      restSeconds = 0;
    });

    _showCompletionDialog(totalVol.toInt(), setsCompleted);
  }

  void _startRestTimer(int sec) {
    _restTimer?.cancel();
    setState(() => restSeconds = sec);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (restSeconds > 0) {
        setState(() => restSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  String _formatTimer(int sec) {
    int m = sec ~/ 60;
    int s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showCompletionDialog(int volume, int sets) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141E),
        title: const Column(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 50),
            SizedBox(height: 8),
            Text('Workout Complete!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Session Duration: ${_formatTimer(sessionSeconds)}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text('Total Sets Logged: $sets', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text('Total Volume Lifted: $volume kg', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GREAT JOB', style: TextStyle(color: Color(0xFF00E5FF))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String today = _getTodayName();
    final String muscle = dayToMuscleMap[today] ?? 'Rest Day';
    final bool isRest = restDays.contains(today);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('TODAY\'S WORKOUT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00E5FF)),
              ),
              child: Text(today.toUpperCase(), style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12)),
            )
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRest 
                      ? [const Color(0xFF2A1C1C), const Color(0xFF14141E)] 
                      : [const Color(0xFF005F73), const Color(0xFF0A0A0F)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isRest ? Colors.redAccent.withOpacity(0.3) : const Color(0xFF00E5FF).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isRest ? Colors.redAccent.withOpacity(0.2) : const Color(0xFF00E5FF).withOpacity(0.2),
                    child: Icon(isRest ? Icons.bedtime : Icons.fitness_center, color: isRest ? Colors.redAccent : const Color(0xFF00E5FF)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(muscle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(isRest ? 'Optimal Growth Day' : '${activeSessionExercises.length} Target Exercises', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (!isRest)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isWorkoutActive ? Colors.redAccent : const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isWorkoutActive ? _finishWorkoutSession : _startWorkoutSession,
                      child: Text(
                        isWorkoutActive ? 'FINISH' : 'START',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Live Timers Bar
            if (isWorkoutActive || restSeconds > 0)
              Row(
                children: [
                  if (isWorkoutActive)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(color: const Color(0xFF1A1A28), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer, size: 18, color: Colors.amber),
                            const SizedBox(width: 6),
                            Text('Session: ${_formatTimer(sessionSeconds)}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  if (restSeconds > 0)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(color: const Color(0xFF00E5FF).withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF00E5FF))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.snooze, size: 18, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 6),
                            Text('Rest: ${restSeconds}s', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 12),

            // Exercises List
            Expanded(
              child: isRest
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.nightlife, size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Rest Day: Rest & Hydrate', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: activeSessionExercises.length,
                      itemBuilder: (context, exIndex) {
                        final ex = activeSessionExercises[exIndex];
                        final List sets = ex['sets'] ?? [];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14141E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('${exIndex + 1}. ', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(ex['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text('${ex['equipment']} • ${ex['target']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00E5FF), size: 20),
                                    onPressed: () {
                                      setState(() {
                                        sets.add({'weight': '50', 'reps': '10', 'done': false});
                                      });
                                      _saveTodayExercises();
                                    },
                                  )
                                ],
                              ),
                              const Divider(color: Colors.white10),

                              // Set Headers
                              const Row(
                                children: [
                                  SizedBox(width: 30, child: Text('SET', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                                  Expanded(child: Center(child: Text('KG / LBS', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)))),
                                  Expanded(child: Center(child: Text('REPS', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)))),
                                  SizedBox(width: 50, child: Center(child: Text('DONE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)))),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Set Rows
                              ...List.generate(sets.length, (sIndex) {
                                final s = sets[sIndex];
                                final bool isDone = s['done'] == true;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 30,
                                        child: Text('${sIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                          child: SizedBox(
                                            height: 32,
                                            child: TextField(
                                              keyboardType: TextInputType.number,
                                              controller: TextEditingController(text: s['weight'].toString()),
                                              onChanged: (val) {
                                                s['weight'] = val;
                                                _saveTodayExercises();
                                              },
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 13),
                                              decoration: InputDecoration(
                                                contentPadding: EdgeInsets.zero,
                                                filled: true,
                                                fillColor: const Color(0xFF1E1E2C),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                          child: SizedBox(
                                            height: 32,
                                            child: TextField(
                                              keyboardType: TextInputType.number,
                                              controller: TextEditingController(text: s['reps'].toString()),
                                              onChanged: (val) {
                                                s['reps'] = val;
                                                _saveTodayExercises();
                                              },
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 13),
                                              decoration: InputDecoration(
                                                contentPadding: EdgeInsets.zero,
                                                filled: true,
                                                fillColor: const Color(0xFF1E1E2C),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: IconButton(
                                          icon: Icon(
                                            isDone ? Icons.check_box : Icons.check_box_outline_blank,
                                            color: isDone ? const Color(0xFF00E5FF) : Colors.grey,
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              s['done'] = !isDone;
                                            });
                                            _saveTodayExercises();
                                            if (!isDone) _startRestTimer(90);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: SCHEDULE & REST DAY CONFIGURATOR
// -----------------------------------------------------------------------------
class ScheduleConfiguratorTab extends StatefulWidget {
  const ScheduleConfiguratorTab({super.key});

  @override
  State<ScheduleConfiguratorTab> createState() => _ScheduleConfiguratorTabState();
}

class _ScheduleConfiguratorTabState extends State<ScheduleConfiguratorTab> {
  final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  Set<String> restDays = {'Wed', 'Sun'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('user_rest_days');
    if (saved != null) {
      setState(() => restDays = saved.toSet());
    }
  }

  Future<void> _toggleRestDay(String day) async {
    setState(() {
      if (restDays.contains(day)) {
        if (restDays.length > 1) restDays.remove(day);
      } else {
        if (restDays.length < 2) restDays.add(day);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_rest_days', restDays.toList());
  }

  @override
  Widget build(BuildContext context) {
    final List<String> splits = ['Chest & Triceps', 'Back & Biceps', 'Legs & Calves', 'Shoulders & Abs', 'Arms Focus'];
    int splitIdx = 0;

    return Scaffold(
      appBar: AppBar(title: const Text('SPLIT & REST DAYS', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CHOOSE EXACTLY 2 REST DAYS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays.map((day) {
                final isRest = restDays.contains(day);
                return GestureDetector(
                  onTap: () => _toggleRestDay(day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isRest ? Colors.redAccent.withOpacity(0.2) : const Color(0xFF181822),
                      border: Border.all(color: isRest ? Colors.redAccent : Colors.white10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(day, style: TextStyle(color: isRest ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
            const Text('OPTIMAL 5-DAY HYPERTROPHY PROGRAM', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (ctx, i) {
                  final day = weekDays[i];
                  final isRest = restDays.contains(day);
                  String targetGroup = 'Rest Day';
                  if (!isRest) {
                    targetGroup = splits[splitIdx % splits.length];
                    splitIdx++;
                  }

                  return Card(
                    color: isRest ? const Color(0xFF14141B) : const Color(0xFF1A1A28),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(isRest ? Icons.bedtime : Icons.fitness_center, color: isRest ? Colors.redAccent : const Color(0xFF00E5FF)),
                      title: Text('$day: $targetGroup', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(isRest ? 'Muscle Recovery & Repair' : 'Hypertrophy Target'),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: EXERCISE LIBRARY & CUSTOM CREATOR
// -----------------------------------------------------------------------------
class ExerciseLibraryTab extends StatefulWidget {
  const ExerciseLibraryTab({super.key});

  @override
  State<ExerciseLibraryTab> createState() => _ExerciseLibraryTabState();
}

class _ExerciseLibraryTabState extends State<ExerciseLibraryTab> {
  String searchQuery = '';

  void _showAddCustomDialog() {
    final nameCtrl = TextEditingController();
    final equipCtrl = TextEditingController();
    String selectedGroup = 'Chest & Triceps';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141E),
        title: const Text('Add Custom Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Exercise Name')),
            TextField(controller: equipCtrl, decoration: const InputDecoration(labelText: 'Equipment / Machine')),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedGroup,
              isExpanded: true,
              dropdownColor: const Color(0xFF14141E),
              items: ['Chest & Triceps', 'Back & Biceps', 'Legs & Calves', 'Shoulders & Abs', 'Arms Focus']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) {
                if (val != null) selectedGroup = val;
              },
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  globalExerciseLibrary.add({
                    'name': nameCtrl.text,
                    'group': selectedGroup,
                    'equipment': equipCtrl.text.isEmpty ? 'Custom' : equipCtrl.text,
                    'target': 'Custom Target'
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = globalExerciseLibrary.where((e) {
      return e['name']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          e['group']!.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('EXERCISE LIBRARY'), backgroundColor: Colors.transparent),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00E5FF),
        foregroundColor: Colors.black,
        onPressed: _showAddCustomDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search machine or muscle...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF14141E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final ex = filtered[i];
                  return Card(
                    color: const Color(0xFF14141E),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF1E1E2C),
                        child: Icon(Icons.fitness_center, color: Color(0xFF00E5FF), size: 18),
                      ),
                      title: Text(ex['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${ex['group']} • ${ex['equipment']}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                        child: Text(ex['target']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 4: TOOLS, 1RM CALCULATOR & HISTORY
// -----------------------------------------------------------------------------
class ToolsAndAnalyticsTab extends StatefulWidget {
  const ToolsAndAnalyticsTab({super.key});

  @override
  State<ToolsAndAnalyticsTab> createState() => _ToolsAndAnalyticsTabState();
}

class _ToolsAndAnalyticsTabState extends State<ToolsAndAnalyticsTab> {
  final weightCtrl = TextEditingController(text: '80');
  final repsCtrl = TextEditingController(text: '8');
  double calculated1RM = 101.3;

  List<String> historyLogs = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      historyLogs = prefs.getStringList('workout_history') ?? [];
    });
  }

  void _calculate1RM() {
    double w = double.tryParse(weightCtrl.text) ?? 0;
    int r = int.tryParse(repsCtrl.text) ?? 0;
    if (w > 0 && r > 0) {
      // Epley Formula
      setState(() {
        calculated1RM = w * (1 + r / 30);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TOOLS & HISTORY'), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1RM Calculator Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF14141E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1RM (ONE REP MAX) CALCULATOR', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: weightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Weight (kg)', filled: true, fillColor: Color(0xFF1E1E2C)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: repsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Reps', filled: true, fillColor: Color(0xFF1E1E2C)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                        onPressed: _calculate1RM,
                        child: const Text('CALC'),
                      )
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Est. 1RM: ${calculated1RM.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('85% (6 Rep Target): ${(calculated1RM * 0.85).toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text('WORKOUT HISTORY LOGS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            historyLogs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No completed workouts logged yet.', style: TextStyle(color: Colors.grey))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: historyLogs.length,
                    itemBuilder: (ctx, i) {
                      final item = jsonDecode(historyLogs[historyLogs.length - 1 - i]);
                      return Card(
                        color: const Color(0xFF14141E),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.emoji_events, color: Colors.amber),
                          title: Text('${item['day']} - ${item['muscle']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Duration: ${item['duration']} • Sets: ${item['sets']}'),
                          trailing: Text('${item['volume']} kg', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  )
          ],
        ),
      ),
    );
  }
}
