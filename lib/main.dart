import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const GymMasterApexApp());

class GymMasterApexApp extends StatelessWidget {
  const GymMasterApexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Master APEX',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A10),
        cardColor: const Color(0xFF141422),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFD500F9),
          surface: Color(0xFF141422),
        ),
      ),
      home: const ApexNavigationShell(),
    );
  }
}

// Master Global Exercise Database
List<Map<String, String>> globalExerciseLibrary = [
  {'name': 'Barbell Bench Press', 'group': 'Chest & Triceps', 'equipment': 'Barbell', 'target': 'Mid Chest'},
  {'name': 'Incline Dumbbell Press', 'group': 'Chest & Triceps', 'equipment': 'Dumbbells', 'target': 'Upper Chest'},
  {'name': 'Cable Chest Flyes', 'group': 'Chest & Triceps', 'equipment': 'Cable Tower', 'target': 'Inner Chest'},
  {'name': 'Triceps Rope Pushdown', 'group': 'Chest & Triceps', 'equipment': 'Cable Tower', 'target': 'Triceps Lateral'},
  {'name': 'EZ-Bar Skull Crushers', 'group': 'Chest & Triceps', 'equipment': 'EZ-Bar', 'target': 'Triceps Long Head'},
  {'name': 'Lat Pulldown', 'group': 'Back & Biceps', 'equipment': 'Lat Pulldown', 'target': 'Lats Width'},
  {'name': 'Seated Cable Row', 'group': 'Back & Biceps', 'equipment': 'Cable Machine', 'target': 'Mid Back'},
  {'name': 'Barbell Bent Over Row', 'group': 'Back & Biceps', 'equipment': 'Barbell', 'target': 'Back Thickness'},
  {'name': 'Incline Dumbbell Curl', 'group': 'Back & Biceps', 'equipment': 'Dumbbells', 'target': 'Biceps Long Head'},
  {'name': 'Barbell Back Squat', 'group': 'Legs & Calves', 'equipment': 'Squat Rack', 'target': 'Quads & Glutes'},
  {'name': '45° Leg Press', 'group': 'Legs & Calves', 'equipment': 'Machine', 'target': 'Quad Hypertrophy'},
  {'name': 'Lying Leg Curl', 'group': 'Legs & Calves', 'equipment': 'Hamstring Machine', 'target': 'Hamstrings'},
  {'name': 'Standing Calf Raise', 'group': 'Legs & Calves', 'equipment': 'Calf Machine', 'target': 'Calves'},
  {'name': 'Overhead DB Press', 'group': 'Shoulders & Abs', 'equipment': 'Dumbbells', 'target': 'Anterior Delt'},
  {'name': 'Cable Lateral Raise', 'group': 'Shoulders & Abs', 'equipment': 'Cable Tower', 'target': 'Side Delt'},
  {'name': 'Hanging Leg Raise', 'group': 'Shoulders & Abs', 'equipment': 'Pull-up Bar', 'target': 'Lower Abs'},
];

class ApexNavigationShell extends StatefulWidget {
  const ApexNavigationShell({super.key});

  @override
  State<ApexNavigationShell> createState() => _ApexNavigationShellState();
}

class _ApexNavigationShellState extends State<ApexNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const ActiveTrackerTab(),
    const OneRepMaxCalcTab(),
    const PlateCalculatorTab(),
    const MasterLibraryTab(),
    const AdvancedAnalyticsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0C0C14),
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 10,
        unselectedFontSize: 9,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Tracker'),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: '1RM Engine'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Plates'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: WORKOUT TRACKER WITH RPE & ADVANCED REST TIMER
// -----------------------------------------------------------------------------
class ActiveTrackerTab extends StatefulWidget {
  const ActiveTrackerTab({super.key});

  @override
  State<ActiveTrackerTab> createState() => _ActiveTrackerTabState();
}

class _ActiveTrackerTabState extends State<ActiveTrackerTab> {
  final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  Set<String> restDays = {'Wed', 'Sun'};
  Map<String, String> dayToGroupMap = {};

  bool isDeload = false;
  bool isSessionActive = false;
  int sessionTimeSec = 0;
  Timer? _sessionTimer;

  int restTimeSec = 0;
  int restTotalDuration = 90;
  Timer? _restTimer;

  List<Map<String, dynamic>> todayExercises = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  String _getTodayName() => weekDays[DateTime.now().weekday - 1];

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRest = prefs.getStringList('apex_rest_days');
    if (savedRest != null) restDays = savedRest.toSet();

    final splits = ['Chest & Triceps', 'Back & Biceps', 'Legs & Calves', 'Shoulders & Abs'];
    int idx = 0;
    Map<String, String> newMap = {};
    for (String d in weekDays) {
      if (restDays.contains(d)) {
        newMap[d] = 'Rest Day';
      } else {
        newMap[d] = splits[idx % splits.length];
        idx++;
      }
    }
    setState(() => dayToGroupMap = newMap);

    _loadTodayExercises();
  }

  Future<void> _loadTodayExercises() async {
    final today = _getTodayName();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('apex_ex_$today');

    if (raw != null) {
      setState(() {
        todayExercises = List<Map<String, dynamic>>.from(jsonDecode(raw));
      });
    } else {
      final group = dayToGroupMap[today] ?? 'Rest Day';
      final defaults = globalExerciseLibrary.where((e) => e['group'] == group).toList();
      setState(() {
        todayExercises = defaults.map((ex) {
          return {
            'name': ex['name'],
            'equipment': ex['equipment'],
            'target': ex['target'],
            'sets': [
              {'weight': '60', 'reps': '10', 'rpe': '7.5', 'type': 'W', 'done': false},
              {'weight': '80', 'reps': '8', 'rpe': '8.5', 'type': 'N', 'done': false},
              {'weight': '80', 'reps': '8', 'rpe': '9.0', 'type': 'N', 'done': false},
            ]
          };
        }).toList();
      });
      _saveTodayExercises();
    }
  }

  Future<void> _saveTodayExercises() async {
    final today = _getTodayName();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apex_ex_$today', jsonEncode(todayExercises));
  }

  void _toggleSession() async {
    if (!isSessionActive) {
      setState(() {
        isSessionActive = true;
        sessionTimeSec = 0;
      });
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => sessionTimeSec++));
    } else {
      _sessionTimer?.cancel();
      _restTimer?.cancel();

      double volume = 0;
      int setsDone = 0;
      for (var ex in todayExercises) {
        for (var s in ex['sets']) {
          if (s['done'] == true) {
            double w = double.tryParse(s['weight'].toString()) ?? 0;
            int r = int.tryParse(s['reps'].toString()) ?? 0;
            volume += (w * r);
            setsDone++;
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('apex_history_logs') ?? [];
      history.add(jsonEncode({
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'day': _getTodayName(),
        'muscle': dayToGroupMap[_getTodayName()] ?? 'Workout',
        'duration': _formatTime(sessionTimeSec),
        'volume': volume.toInt(),
        'sets': setsDone,
      }));
      await prefs.setStringList('apex_history_logs', history);

      setState(() {
        isSessionActive = false;
        restTimeSec = 0;
      });
      _showCompletionDialog(volume.toInt(), setsDone);
    }
  }

  void _startRestTimer(int sec) {
    _restTimer?.cancel();
    setState(() {
      restTimeSec = sec;
      restTotalDuration = sec;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (restTimeSec > 0) {
        setState(() => restTimeSec--);
      } else {
        t.cancel();
      }
    });
  }

  String _formatTime(int sec) {
    int m = sec ~/ 60;
    int s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double _calculate1RM(double weight, int reps) {
    if (reps <= 0) return 0;
    return weight * (1 + (reps / 30.0));
  }

  void _showCompletionDialog(int volume, int sets) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141422),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.emoji_events, color: Color(0xFF00E5FF), size: 50),
            SizedBox(height: 8),
            Text('Session Completed', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Duration: ${_formatTime(sessionTimeSec)}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Completed Sets: $sets', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Total Tonnage: $volume kg', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: Color(0xFF00E5FF))))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = _getTodayName();
    final group = dayToGroupMap[today] ?? 'Rest Day';
    final isRest = restDays.contains(today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GYM MASTER APEX', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF00E5FF).withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00E5FF))),
            child: Center(child: Text(today.toUpperCase(), style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 11))),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: Column(
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF141422), borderRadius: BorderRadius.circular(12), border: Border.all(color: isRest ? Colors.redAccent.withOpacity(0.3) : const Color(0xFF00E5FF).withOpacity(0.3))),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isRest ? Colors.redAccent.withOpacity(0.2) : const Color(0xFF00E5FF).withOpacity(0.2),
                    child: Icon(isRest ? Icons.hotel : Icons.fitness_center, color: isRest ? Colors.redAccent : const Color(0xFF00E5FF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(isRest ? 'Active Recovery' : 'Hypertrophy Target', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  if (!isRest)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: isSessionActive ? Colors.redAccent : const Color(0xFF00E5FF), foregroundColor: Colors.black),
                      onPressed: _toggleSession,
                      child: Text(isSessionActive ? 'FINISH' : 'START', style: const TextStyle(fontWeight: FontWeight.bold)),
                    )
                ],
              ),
            ),

            // Live Timer & Rest Banner
            if (isSessionActive || restTimeSec > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isSessionActive)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF1E1E30), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text('Elapsed: ${_formatTime(sessionTimeSec)}', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  if (restTimeSec > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF00E5FF).withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00E5FF))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bedtime, size: 14, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 4),
                            Text('Rest: ${restTimeSec}s', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.add, size: 14, color: Color(0xFF00E5FF)),
                              onPressed: () => setState(() => restTimeSec += 30),
                            )
                          ],
                        ),
                      ),
                    ),
                  ]
                ],
              )
            ],

            const SizedBox(height: 10),

            // Exercise Cards List
            Expanded(
              child: isRest
                  ? const Center(child: Text('Rest & Recovery Day', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: todayExercises.length,
                      itemBuilder: (ctx, exIdx) {
                        final ex = todayExercises[exIdx];
                        final List sets = ex['sets'] ?? [];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF141422), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('${exIdx + 1}. ', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(ex['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Color(0xFF00E5FF), size: 18),
                                    onPressed: () {
                                      setState(() => sets.add({'weight': '70', 'reps': '8', 'rpe': '8.0', 'type': 'N', 'done': false}));
                                      _saveTodayExercises();
                                    },
                                  )
                                ],
                              ),
                              const Divider(color: Colors.white10, height: 8),

                              // Table Header
                              const Row(
                                children: [
                                  SizedBox(width: 25, child: Text('SET', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold))),
                                  Expanded(child: Center(child: Text('KG', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)))),
                                  Expanded(child: Center(child: Text('REPS', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)))),
                                  Expanded(child: Center(child: Text('RPE', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)))),
                                  Expanded(child: Center(child: Text('EST 1RM', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)))),
                                  SizedBox(width: 35, child: Center(child: Text('DONE', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)))),
                                ],
                              ),
                              const SizedBox(height: 4),

                              ...List.generate(sets.length, (sIdx) {
                                final s = sets[sIdx];
                                final bool isDone = s['done'] == true;
                                double w = double.tryParse(s['weight'].toString()) ?? 0;
                                int r = int.tryParse(s['reps'].toString()) ?? 0;
                                double est1RM = _calculate1RM(w, r);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 25, child: Text('${sIdx + 1}', style: const TextStyle(fontSize: 11, color: Colors.grey))),
                                      
                                      // Weight Box
                                      Expanded(
                                        child: SizedBox(
                                          height: 28,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            controller: TextEditingController(text: s['weight'].toString()),
                                            onChanged: (v) {
                                              s['weight'] = v;
                                              _saveTodayExercises();
                                            },
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 11),
                                            decoration: InputDecoration(contentPadding: EdgeInsets.zero, filled: true, fillColor: const Color(0xFF1E1E30), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // Reps Box
                                      Expanded(
                                        child: SizedBox(
                                          height: 28,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            controller: TextEditingController(text: s['reps'].toString()),
                                            onChanged: (v) {
                                              s['reps'] = v;
                                              _saveTodayExercises();
                                            },
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 11),
                                            decoration: InputDecoration(contentPadding: EdgeInsets.zero, filled: true, fillColor: const Color(0xFF1E1E30), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // RPE Box
                                      Expanded(
                                        child: SizedBox(
                                          height: 28,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            controller: TextEditingController(text: s['rpe'].toString()),
                                            onChanged: (v) {
                                              s['rpe'] = v;
                                              _saveTodayExercises();
                                            },
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFFD500F9)),
                                            decoration: InputDecoration(contentPadding: EdgeInsets.zero, filled: true, fillColor: const Color(0xFF1E1E30), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)),
                                          ),
                                        ),
                                      ),

                                      // Est 1RM Text
                                      Expanded(
                                        child: Center(
                                          child: Text('${est1RM.toStringAsFixed(1)}k', style: const TextStyle(fontSize: 10, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                                        ),
                                      ),

                                      // Done Checkbox
                                      SizedBox(
                                        width: 35,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? const Color(0xFF00E5FF) : Colors.grey, size: 18),
                                          onPressed: () {
                                            setState(() => s['done'] = !isDone);
                                            _saveTodayExercises();
                                            if (!isDone) _startRestTimer(90);
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              })
                            ],
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
// TAB 2: ONE-REP MAX CALCULATOR ENGINE
// -----------------------------------------------------------------------------
class OneRepMaxCalcTab extends StatefulWidget {
  const OneRepMaxCalcTab({super.key});

  @override
  State<OneRepMaxCalcTab> createState() => _OneRepMaxCalcTabState();
}

class _OneRepMaxCalcTabState extends State<OneRepMaxCalcTab> {
  final weightCtrl = TextEditingController(text: '100');
  final repsCtrl = TextEditingController(text: '5');
  double epley1RM = 0;
  double brzycki1RM = 0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    double w = double.tryParse(weightCtrl.text) ?? 0;
    int r = int.tryParse(repsCtrl.text) ?? 0;

    if (w > 0 && r > 0) {
      setState(() {
        epley1RM = w * (1 + (r / 30.0));
        brzycki1RM = w * (36.0 / (37.0 - r));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('1-REP MAX ENGINE'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF141422), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3))),
              child: Column(
                children: [
                  TextField(
                    controller: weightCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculate(),
                    decoration: const InputDecoration(labelText: 'Weight Lifted (KG)', filled: true, fillColor: Color(0xFF1E1E30)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: repsCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculate(),
                    decoration: const InputDecoration(labelText: 'Reps Performed', filled: true, fillColor: Color(0xFF1E1E30)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Results Card
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF141422), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Text('Epley Formula', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 6),
                        Text('${epley1RM.toStringAsFixed(1)} KG', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF141422), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Text('Brzycki Formula', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 6),
                        Text('${brzycki1RM.toStringAsFixed(1)} KG', style: const TextStyle(color: Color(0xFFD500F9), fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Training Load Percentages Table
            const Align(alignment: Alignment.centerLeft, child: Text('TRAINING PERCENTAGES', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [95, 90, 85, 80, 75, 70, 65].map((pct) {
                  double targetWeight = epley1RM * (pct / 100.0);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF141422), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$pct% 1RM', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${targetWeight.toStringAsFixed(1)} KG', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: BARBELL PLATE CALCULATOR
// -----------------------------------------------------------------------------
class PlateCalculatorTab extends StatefulWidget {
  const PlateCalculatorTab({super.key});

  @override
  State<PlateCalculatorTab> createState() => _PlateCalculatorTabState();
}

class _PlateCalculatorTabState extends State<PlateCalculatorTab> {
  final weightCtrl = TextEditingController(text: '100');
  double barWeight = 20.0;
  List<double> plateSizes = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
  Map<double, int> calculatedPlates = {};

  @override
  void initState() {
    super.initState();
    _computePlates();
  }

  void _computePlates() {
    double target = double.tryParse(weightCtrl.text) ?? 20.0;
    if (target < barWeight) {
      setState(() => calculatedPlates = {});
      return;
    }
    double perSide = (target - barWeight) / 2.0;
    Map<double, int> result = {};

    for (double p in plateSizes) {
      int count = perSide ~/ p;
      if (count > 0) {
        result[p] = count;
        perSide -= (count * p);
      }
    }
    setState(() => calculatedPlates = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BARBELL PLATE CALCULATOR'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF141422), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3))),
              child: Column(
                children: [
                  TextField(
                    controller: weightCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _computePlates(),
                    decoration: const InputDecoration(labelText: 'Target Load (KG)', filled: true, fillColor: Color(0xFF1E1E30)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('PLATES PER SIDE:', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: calculatedPlates.isEmpty
                  ? const Center(child: Text('Enter weight greater than bar (20kg)', style: TextStyle(color: Colors.grey)))
                  : ListView(
                      children: calculatedPlates.entries.map((e) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF141422), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              CircleAvatar(backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2), child: Text('${e.key}k', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold))),
                              const SizedBox(width: 14),
                              Text('${e.key} KG Plate', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text('x ${e.value}', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 4: MASTER LIBRARY & CUSTOM EXERCISE BUILDER
// -----------------------------------------------------------------------------
class MasterLibraryTab extends StatefulWidget {
  const MasterLibraryTab({super.key});

  @override
  State<MasterLibraryTab> createState() => _MasterLibraryTabState();
}

class _MasterLibraryTabState extends State<MasterLibraryTab> {
  String search = '';

  void _showAddExerciseDialog() {
    final nameCtrl = TextEditingController();
    final groupCtrl = TextEditingController(text: 'Chest & Triceps');
    final targetCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141422),
        title: const Text('Add Custom Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Exercise Name')),
            const SizedBox(height: 8),
            TextField(controller: groupCtrl, decoration: const InputDecoration(labelText: 'Muscle Group')),
            const SizedBox(height: 8),
            TextField(controller: targetCtrl, decoration: const InputDecoration(labelText: 'Target Focus')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  globalExerciseLibrary.add({
                    'name': nameCtrl.text,
                    'group': groupCtrl.text,
                    'equipment': 'Custom',
                    'target': targetCtrl.text,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('ADD', style: TextStyle(color: Color(0xFF00E5FF))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = globalExerciseLibrary.where((e) {
      return e['name']!.toLowerCase().contains(search.toLowerCase()) || e['group']!.toLowerCase().contains(search.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('EXERCISE LIBRARY'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Color(0xFF00E5FF)), onPressed: _showAddExerciseDialog)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: 'Search exercise...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF141422),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final item = list[i];
                  return Card(
                    color: const Color(0xFF141422),
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center, color: Color(0xFF00E5FF)),
                      title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${item['group']} • ${item['equipment']}'),
                      trailing: Text(item['target']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
// TAB 5: ADVANCED ANALYTICS & JSON BACKUP/RESTORE ENGINE
// -----------------------------------------------------------------------------
class AdvancedAnalyticsTab extends StatefulWidget {
  const AdvancedAnalyticsTab({super.key});

  @override
  State<AdvancedAnalyticsTab> createState() => _AdvancedAnalyticsTabState();
}

class _AdvancedAnalyticsTabState extends State<AdvancedAnalyticsTab> {
  List<String> logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      logs = prefs.getStringList('apex_history_logs') ?? [];
    });
  }

  void _exportJSON() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> fullData = {
      'logs': prefs.getStringList('apex_history_logs') ?? [],
      'rest_days': prefs.getStringList('apex_rest_days') ?? [],
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141422),
        title: const Text('Exported JSON Backup'),
        content: SelectableText(jsonEncode(fullData), style: const TextStyle(fontSize: 10, color: Color(0xFF00E5FF))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE'))
        ],
      ),
    );
  }

  void _importJSON() {
    final importCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141422),
        title: const Text('Restore Data from JSON'),
        content: TextField(
          controller: importCtrl,
          maxLines: 5,
          style: const TextStyle(fontSize: 11),
          decoration: const InputDecoration(hintText: 'Paste valid JSON string here...', filled: true, fillColor: Color(0xFF1E1E30)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final parsed = jsonDecode(importCtrl.text);
                final prefs = await SharedPreferences.getInstance();
                if (parsed['logs'] != null) await prefs.setStringList('apex_history_logs', List<String>.from(parsed['logs']));
                if (parsed['rest_days'] != null) await prefs.setStringList('apex_rest_days', List<String>.from(parsed['rest_days']));
                Navigator.pop(ctx);
                _loadLogs();
              } catch (e) {
                // Invalid JSON
              }
            },
            child: const Text('RESTORE', style: TextStyle(color: Color(0xFF00E5FF))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ANALYTICS & DATA SYNC'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                    onPressed: _exportJSON,
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('EXPORT JSON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD500F9), foregroundColor: Colors.white),
                    onPressed: _importJSON,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('RESTORE JSON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('WORKOUT HISTORY', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text('No workout history found.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (ctx, i) {
                        final item = jsonDecode(logs[logs.length - 1 - i]);
                        return Card(
                          color: const Color(0xFF141422),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.bolt, color: Color(0xFF00E5FF)),
                            title: Text('${item['date']} • ${item['muscle']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('Duration: ${item['duration']} • Sets: ${item['sets']}'),
                            trailing: Text('${item['volume']} KG', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
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
