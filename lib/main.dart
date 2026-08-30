import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GymMasterTitanProApp());
}

class GymMasterTitanProApp extends StatelessWidget {
  const GymMasterTitanProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Master TITAN PRO',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030307),
        cardColor: const Color(0xFF0B0C16),
        primaryColor: const Color(0xFF00F0FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F0FF),
          secondary: Color(0xFF7000FF),
          tertiary: Color(0xFFFF0055),
          surface: Color(0xFF0B0C16),
        ),
      ),
      home: const TitanProShell(),
    );
  }
}

// Global Exercise Database with Anatomical Target Mapping
const List<Map<String, String>> globalExerciseLibrary = [
  {'name': 'Barbell Bench Press', 'group': 'Chest', 'equipment': 'Barbell', 'target': 'Mid Chest'},
  {'name': 'Incline DB Press', 'group': 'Chest', 'equipment': 'Dumbbells', 'target': 'Upper Chest'},
  {'name': 'Triceps Pushdown', 'group': 'Arms', 'equipment': 'Cable Tower', 'target': 'Triceps Lateral'},
  {'name': 'EZ-Bar Skullcrusher', 'group': 'Arms', 'equipment': 'EZ-Bar', 'target': 'Triceps Long Head'},
  {'name': 'Barbell Back Squat', 'group': 'Legs', 'equipment': 'Squat Rack', 'target': 'Quads & Glutes'},
  {'name': 'Romanian Deadlift', 'group': 'Legs', 'equipment': 'Barbell', 'target': 'Hamstrings'},
  {'name': 'Standing Calf Raise', 'group': 'Legs', 'equipment': 'Machine', 'target': 'Calves'},
  {'name': 'Lat Pulldown', 'group': 'Back', 'equipment': 'Lat Pulldown', 'target': 'Lats Width'},
  {'name': 'Seated Cable Row', 'group': 'Back', 'equipment': 'Cable Tower', 'target': 'Mid Back'},
  {'name': 'Barbell DB Curl', 'group': 'Arms', 'equipment': 'Dumbbells', 'target': 'Biceps Short Head'},
  {'name': 'Overhead DB Press', 'group': 'Shoulders', 'equipment': 'Dumbbells', 'target': 'Anterior Delt'},
  {'name': 'Cable Lateral Raise', 'group': 'Shoulders', 'equipment': 'Cable Tower', 'target': 'Side Delt'},
  {'name': 'Hanging Leg Raise', 'group': 'Core', 'equipment': 'Pull-up Bar', 'target': 'Lower Abs'},
  {'name': 'Ab Wheel Rollout', 'group': 'Core', 'equipment': 'Ab Wheel', 'target': 'Core Stability'},
];

class TitanProShell extends StatefulWidget {
  const TitanProShell({super.key});

  @override
  State<TitanProShell> createState() => _TitanProShellState();
}

class _TitanProShellState extends State<TitanProShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    LiveTrackerTab(),
    ApreVbtTab(),
    BanisterTab(),
    VolumeRadarTab(),
    PlateMathTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF06060D),
        selectedItemColor: const Color(0xFF00F0FF),
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 10,
        unselectedFontSize: 9,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Live Session'),
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'APRE / VBT'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Banister EWMA'),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Volume Radar'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Plates & 1RM'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: LIVE WORKOUT TRACKER WITH VELOCITY PROXY & RADIAL REST TIMER
// -----------------------------------------------------------------------------
class LiveTrackerTab extends StatefulWidget {
  const LiveTrackerTab({super.key});

  @override
  State<LiveTrackerTab> createState() => _LiveTrackerTabState();
}

class _LiveTrackerTabState extends State<LiveTrackerTab> {
  final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  Set<String> restDays = {'Wed', 'Sun'};
  Map<String, String> dayToGroupMap = {};

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
    final savedRest = prefs.getStringList('titan_rest_days');
    if (savedRest != null) restDays = savedRest.toSet();

    final splits = ['Chest', 'Back', 'Legs', 'Shoulders'];
    int idx = 0;
    Map<String, String> newMap = {};
    for (String d in weekDays) {
      if (restDays.contains(d)) {
        newMap[d] = 'Rest & Recovery';
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
    final raw = prefs.getString('titan_pro_ex_$today');

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
            'group': ex['group'],
            'equipment': ex['equipment'],
            'target': ex['target'],
            'sets': [
              {'weight': '60', 'reps': '10', 'rpe': '7.0', 'type': 'W', 'done': false},
              {'weight': '80', 'reps': '8', 'rpe': '8.0', 'type': 'N', 'done': false},
              {'weight': '85', 'reps': '6', 'rpe': '9.0', 'type': 'N', 'done': false},
              {'weight': '70', 'reps': '10', 'rpe': '10.0', 'type': 'F', 'done': false},
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
    await prefs.setString('titan_pro_ex_$today', jsonEncode(todayExercises));
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
      double totalRpeSum = 0;

      for (var ex in todayExercises) {
        for (var s in ex['sets']) {
          if (s['done'] == true) {
            double w = double.tryParse(s['weight'].toString()) ?? 0;
            int r = int.tryParse(s['reps'].toString()) ?? 0;
            double rpe = double.tryParse(s['rpe'].toString()) ?? 8.0;
            volume += (w * r);
            totalRpeSum += rpe;
            setsDone++;
          }
        }
      }

      double avgRpe = setsDone > 0 ? totalRpeSum / setsDone : 8.0;
      double stressImpulse = volume * (avgRpe / 10.0);

      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('titan_pro_history_logs') ?? [];
      history.add(jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'day': _getTodayName(),
        'group': dayToGroupMap[_getTodayName()] ?? 'Workout',
        'durationSec': sessionTimeSec,
        'durationFormatted': _formatTime(sessionTimeSec),
        'volume': volume.toInt(),
        'sets': setsDone,
        'stress': stressImpulse.toInt(),
      }));
      await prefs.setStringList('titan_pro_history_logs', history);

      setState(() {
        isSessionActive = false;
        restTimeSec = 0;
      });
      _showSessionSummary(volume.toInt(), setsDone, stressImpulse.toInt());
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

  Color _getTagColor(String type) {
    switch (type) {
      case 'W': return Colors.amber;
      case 'D': return const Color(0xFF7000FF);
      case 'F': return const Color(0xFFFF0055);
      case 'C': return Colors.tealAccent;
      case 'M': return Colors.orangeAccent;
      default: return const Color(0xFF00F0FF);
    }
  }

  void _showSessionSummary(int volume, int sets, int stress) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B0C16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF00F0FF), width: 0.5)),
        title: const Column(
          children: [
            Icon(Icons.military_tech, color: Color(0xFF00F0FF), size: 48),
            SizedBox(height: 8),
            Text('SESSION LOGGED', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow('Session Duration', _formatTime(sessionTimeSec)),
            _summaryRow('Completed Sets', '$sets Sets'),
            _summaryRow('Total Tonnage', '$volume KG', color: const Color(0xFF00F0FF)),
            _summaryRow('Banister Stress Impulse', '$stress Points', color: const Color(0xFFFF0055)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('COMMIT TO DATABASE', style: TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
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
        title: const Text('TITAN PRO 4.0 ENGINE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 15)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF00F0FF).withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00F0FF))),
            child: Center(child: Text(today.toUpperCase(), style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 10))),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: Column(
          children: [
            // Status Header Block
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: isRest ? Colors.redAccent.withOpacity(0.3) : const Color(0xFF00F0FF).withOpacity(0.3))),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isRest ? Colors.redAccent.withOpacity(0.2) : const Color(0xFF00F0FF).withOpacity(0.2),
                    child: Icon(isRest ? Icons.nightlight_round : Icons.fitness_center, color: isRest ? Colors.redAccent : const Color(0xFF00F0FF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(isRest ? 'CNS Neuromuscular Deload Phase' : 'High-Intensity Hypertrophy Microcycle', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                  if (!isRest)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: isSessionActive ? const Color(0xFFFF0055) : const Color(0xFF00F0FF), foregroundColor: Colors.black),
                      onPressed: _toggleSession,
                      child: Text(isSessionActive ? 'FINISH' : 'START', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    )
                ],
              ),
            ),

            // Live Timer & Rest Timer Bar
            if (isSessionActive || restTimeSec > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFF101222), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                child: Row(
                  children: [
                    if (isSessionActive) ...[
                      const Icon(Icons.timer, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('Elapsed: ${_formatTime(sessionTimeSec)}', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                    const Spacer(),
                    if (restTimeSec > 0) ...[
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(
                          painter: ProRadialTimerPainter(
                            progress: restTotalDuration > 0 ? restTimeSec / restTotalDuration : 0,
                            color: const Color(0xFF00F0FF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Rest: ${restTimeSec}s', style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => restTimeSec += 30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF00F0FF).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text('+30s', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]
                  ],
                ),
              )
            ],

            const SizedBox(height: 10),

            // Exercises Interactive Table List
            Expanded(
              child: isRest
                  ? const Center(child: Text('CNS Active Recovery Protocol Enabled', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: todayExercises.length,
                      itemBuilder: (ctx, exIdx) {
                        final ex = todayExercises[exIdx];
                        final List sets = ex['sets'] ?? [];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('${exIdx + 1}. ', style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(ex['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00F0FF), size: 18),
                                    onPressed: () {
                                      setState(() => sets.add({'weight': '70', 'reps': '8', 'rpe': '8.0', 'type': 'N', 'done': false}));
                                      _saveTodayExercises();
                                    },
                                  )
                                ],
                              ),
                              const Divider(color: Colors.white10, height: 6),

                              // Table Header
                              const Row(
                                children: [
                                  SizedBox(width: 24, child: Text('TAG', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold))),
                                  Expanded(child: Center(child: Text('KG', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))),
                                  Expanded(child: Center(child: Text('REPS', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))),
                                  Expanded(child: Center(child: Text('RPE', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))),
                                  Expanded(child: Center(child: Text('VBT (m/s)', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))),
                                  Expanded(child: Center(child: Text('e1RM', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))),
                                  SizedBox(width: 28, child: Center(child: Text('SET', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))),
                                ],
                              ),
                              const SizedBox(height: 4),

                              ...List.generate(sets.length, (sIdx) {
                                final s = sets[sIdx];
                                final bool isDone = s['done'] == true;
                                double weight = double.tryParse(s['weight'].toString()) ?? 0;
                                int reps = int.tryParse(s['reps'].toString()) ?? 0;
                                double rpe = double.tryParse(s['rpe'].toString()) ?? 8.0;

                                double rir = max(0, 10.0 - rpe);
                                double estVelocity = max(0.1, 0.52 - (0.035 * rir));
                                double e1RM = (weight > 0 && reps > 0) ? weight * (1 + (reps / 30.0)) : 0;
                                String type = s['type'] ?? 'N';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    children: [
                                      // Type Selector Toggle Button
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (type == 'N') s['type'] = 'W';
                                            else if (type == 'W') s['type'] = 'D';
                                            else if (type == 'D') s['type'] = 'F';
                                            else if (type == 'F') s['type'] = 'C';
                                            else if (type == 'C') s['type'] = 'M';
                                            else s['type'] = 'N';
                                          });
                                          _saveTodayExercises();
                                        },
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(color: _getTagColor(type).withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: _getTagColor(type))),
                                          child: Center(child: Text(type, style: TextStyle(color: _getTagColor(type), fontSize: 9, fontWeight: FontWeight.bold))),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // Weight Input Box
                                      Expanded(
                                        child: SizedBox(
                                          height: 24,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            controller: TextEditingController(text: s['weight'].toString()),
                                            onChanged: (v) {
                                              s['weight'] = v;
                                              _saveTodayExercises();
                                            },
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 10),
                                            decoration: InputDecoration(contentPadding: EdgeInsets.zero, filled: true, fillColor: const Color(0xFF101222), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // Reps Input Box
                                      Expanded(
                                        child: SizedBox(
                                          height: 24,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            controller: TextEditingController(text: s['reps'].toString()),
                                            onChanged: (v) {
                                              s['reps'] = v;
                                              _saveTodayExercises();
                                            },
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 10),
                                            decoration: InputDecoration(contentPadding: EdgeInsets.zero, filled: true, fillColor: const Color(0xFF101222), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // RPE Input Box
                                      Expanded(
                                        child: SizedBox(
                                          height: 24,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            controller: TextEditingController(text: s['rpe'].toString()),
                                            onChanged: (v) {
                                              s['rpe'] = v;
                                              _saveTodayExercises();
                                            },
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF7000FF), fontWeight: FontWeight.bold),
                                            decoration: InputDecoration(contentPadding: EdgeInsets.zero, filled: true, fillColor: const Color(0xFF101222), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)),
                                          ),
                                        ),
                                      ),

                                      // Velocity Output
                                      Expanded(
                                        child: Center(
                                          child: Text('${estVelocity.toStringAsFixed(2)}', style: const TextStyle(fontSize: 9, color: Color(0xFF00F0FF), fontWeight: FontWeight.bold)),
                                        ),
                                      ),

                                      // e1RM Output
                                      Expanded(
                                        child: Center(
                                          child: Text('${e1RM.toStringAsFixed(0)}kg', style: const TextStyle(fontSize: 9, color: Colors.amber, fontWeight: FontWeight.bold)),
                                        ),
                                      ),

                                      // Set Done Button
                                      SizedBox(
                                        width: 28,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? const Color(0xFF00F0FF) : Colors.grey[700], size: 16),
                                          onPressed: () {
                                            setState(() => s['done'] = !isDone);
                                            _saveTodayExercises();
                                            if (!isDone) _startRestTimer(type == 'W' ? 45 : 90);
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
// TAB 2: APRE 3.0 & VELOCITY-BASED TRAINING (VBT) PROXY ENGINE
// -----------------------------------------------------------------------------
class ApreVbtTab extends StatefulWidget {
  const ApreVbtTab({super.key});

  @override
  State<ApreVbtTab> createState() => _ApreVbtTabState();
}

class _ApreVbtTabState extends State<ApreVbtTab> {
  final weightCtrl = TextEditingController(text: '100');
  final repsCtrl = TextEditingController(text: '6');
  String protocol = 'APRE-6';

  @override
  Widget build(BuildContext context) {
    double currentWeight = double.tryParse(weightCtrl.text) ?? 100;
    int actualReps = int.tryParse(repsCtrl.text) ?? 6;

    double adjustedWeight = currentWeight;
    String recommendation = 'Maintain current load';

    if (protocol == 'APRE-6') {
      if (actualReps < 4) {
        adjustedWeight = currentWeight - 5.0;
        recommendation = 'Reduce load by -5.0kg';
      } else if (actualReps <= 7) {
        adjustedWeight = currentWeight;
        recommendation = 'Maintain target load';
      } else if (actualReps <= 9) {
        adjustedWeight = currentWeight + 2.5;
        recommendation = 'Increase load by +2.5kg';
      } else {
        adjustedWeight = currentWeight + 5.0;
        recommendation = 'Increase load by +5.0kg';
      }
    } else if (protocol == 'APRE-10') {
      if (actualReps < 8) {
        adjustedWeight = currentWeight - 5.0;
        recommendation = 'Reduce load by -5.0kg';
      } else if (actualReps <= 11) {
        adjustedWeight = currentWeight;
        recommendation = 'Maintain target load';
      } else {
        adjustedWeight = currentWeight + 2.5;
        recommendation = 'Increase load by +2.5kg';
      }
    } else {
      // APRE-3 Strength Protocol
      if (actualReps < 2) {
        adjustedWeight = currentWeight - 2.5;
        recommendation = 'Reduce load by -2.5kg';
      } else if (actualReps <= 4) {
        adjustedWeight = currentWeight;
        recommendation = 'Maintain target load';
      } else {
        adjustedWeight = currentWeight + 2.5;
        recommendation = 'Increase load by +2.5kg';
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('APRE 3.0 & VBT MATRIX'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3))),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AUTOREGULATION PROTOCOL:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        DropdownButton<String>(
                          value: protocol,
                          dropdownColor: const Color(0xFF101222),
                          items: ['APRE-3', 'APRE-6', 'APRE-10'].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold)))).toList(),
                          onChanged: (v) => setState(() => protocol = v!),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Current Load (KG)', filled: true, fillColor: Color(0xFF101222)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: repsCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Performed Reps to Failure', filled: true, fillColor: Color(0xFF101222)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // APRE Output Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF7000FF))),
                child: Column(
                  children: [
                    const Text('NEXT MICROCYCLE TARGET LOAD', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('${adjustedWeight.toStringAsFixed(1)} KG', style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(recommendation, style: const TextStyle(color: Color(0xFFFF0055), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // VBT Velocity Zones Reference Table
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VELOCITY-BASED TRAINING (VBT) ZONES', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    _VbtZoneRow(zone: 'Absolute Strength', velocity: '< 0.35 m/s', loadPct: '90 - 100% 1RM'),
                    _VbtZoneRow(zone: 'Accelerative Strength', velocity: '0.45 - 0.75 m/s', loadPct: '80 - 90% 1RM'),
                    _VbtZoneRow(zone: 'Strength-Speed', velocity: '0.75 - 1.00 m/s', loadPct: '60 - 80% 1RM'),
                    _VbtZoneRow(zone: 'Speed-Strength', velocity: '1.00 - 1.30 m/s', loadPct: '30 - 60% 1RM'),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _VbtZoneRow extends StatelessWidget {
  final String zone;
  final String velocity;
  final String loadPct;
  const _VbtZoneRow({required this.zone, required this.velocity, required this.loadPct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(zone, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          Text(velocity, style: const TextStyle(fontSize: 10, color: Color(0xFF00F0FF))),
          Text(loadPct, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: BANISTER EXPONENTIALLY WEIGHTED MOVING AVERAGE (EWMA) RECOVERY
// -----------------------------------------------------------------------------
class BanisterTab extends StatefulWidget {
  const BanisterTab({super.key});

  @override
  State<BanisterTab> createState() => _BanisterTabState();
}

class _BanisterTabState extends State<BanisterTab> {
  double acuteLoad = 0; // ATL (7-day EWMA)
  double chronicLoad = 0; // CTL (42-day EWMA)
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _computeBanisterMetrics();
  }

  Future<void> _computeBanisterMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList('titan_pro_history_logs') ?? [];

    double atl = 250; 
    double ctl = 310;

    double alphaAtl = 2.0 / (7.0 + 1.0);
    double alphaCtl = 2.0 / (42.0 + 1.0);

    for (String raw in logs) {
      final data = jsonDecode(raw);
      double stress = double.tryParse(data['stress'].toString()) ?? 0.0;
      atl = (stress * alphaAtl) + (atl * (1.0 - alphaAtl));
      ctl = (stress * alphaCtl) + (ctl * (1.0 - alphaCtl));
    }

    setState(() {
      acuteLoad = atl;
      chronicLoad = ctl;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double tsb = chronicLoad - acuteLoad; // Training Stress Balance
    double readiness = max(0, min(100, 50 + (tsb * 1.5)));

    return Scaffold(
      appBar: AppBar(title: const Text('BANISTER EWMA RECOVERY'), backgroundColor: Colors.transparent),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Readiness Dial Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3))),
                    child: Column(
                      children: [
                        const Text('NEUROMUSCULAR READINESS SCORE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text('${readiness.toStringAsFixed(1)}%', style: TextStyle(color: readiness > 60 ? const Color(0xFF00F0FF) : const Color(0xFFFF0055), fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          readiness > 65
                              ? 'Status: Prime Hypertrophic Stimulus Window'
                              : (readiness > 45 ? 'Status: Normal Adaptive Load' : 'Warning: High CNS Fatigue — Consider Deload'),
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFF0055).withOpacity(0.3))),
                          child: Column(
                            children: [
                              const Text('Fatigue (ATL 7d)', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              const SizedBox(height: 4),
                              Text('${acuteLoad.toInt()} pts', style: const TextStyle(color: Color(0xFFFF0055), fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3))),
                          child: Column(
                            children: [
                              const Text('Fitness (CTL 42d)', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              const SizedBox(height: 4),
                              Text('${chronicLoad.toInt()} pts', style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TRAINING STRESS BALANCE (TSB)', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('${tsb.toStringAsFixed(1)}', style: TextStyle(color: tsb >= 0 ? const Color(0xFF00F0FF) : const Color(0xFFFF0055), fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('TSB = CTL - ATL. Positive values denote freshness; negative values denote accumulated fatigue.', style: TextStyle(color: Colors.grey, fontSize: 9)),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 4: 6-AXIS MUSCLE RADAR ENGINE WITH ANATOMICAL LABELS
// -----------------------------------------------------------------------------
class VolumeRadarTab extends StatefulWidget {
  const VolumeRadarTab({super.key});

  @override
  State<VolumeRadarTab> createState() => _VolumeRadarTabState();
}

class _VolumeRadarTabState extends State<VolumeRadarTab> {
  Map<String, double> muscleVolumes = {
    'Chest': 14,
    'Back': 18,
    'Legs': 20,
    'Shoulders': 12,
    'Arms': 16,
    'Core': 10,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ANATOMICAL VOLUME RADAR'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('CURRENT WEEKLY HARD SETS vs MEV THRESHOLD (10-20 SETS)', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Canvas Radar
            SizedBox(
              height: 250,
              width: double.infinity,
              child: CustomPaint(
                painter: ProRadarChartPainter(muscleVolumes),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: muscleVolumes.entries.map((e) {
                  double targetMEV = 10.0;
                  double statusRatio = e.value / targetMEV;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Row(
                          children: [
                            Text('${e.value.toInt()} Sets ', style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(statusRatio >= 1.0 ? '(Optimal)' : '(Below MEV)', style: TextStyle(color: statusRatio >= 1.0 ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10)),
                          ],
                        ),
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
// TAB 5: OLYMPIC BARBELL PLATE BREAKDOWN & MULTI-EQUATION 1RM ENGINE
// -----------------------------------------------------------------------------
class PlateMathTab extends StatefulWidget {
  const PlateMathTab({super.key});

  @override
  State<PlateMathTab> createState() => _PlateMathTabState();
}

class _PlateMathTabState extends State<PlateMathTab> {
  final weightCtrl = TextEditingController(text: '100');
  final repsCtrl = TextEditingController(text: '5');

  double epley = 0;
  double brzycki = 0;
  double lander = 0;
  Map<double, int> calculatedPlates = {};

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  void _recalculate() {
    double w = double.tryParse(weightCtrl.text) ?? 0;
    int r = int.tryParse(repsCtrl.text) ?? 0;

    if (w > 0 && r > 0) {
      setState(() {
        epley = w * (1 + (r / 30.0));
        brzycki = w * (36.0 / (37.0 - r));
        lander = (100 * w) / (101.3 - (2.67123 * r));
        calculatedPlates = _computePlates(w);
      });
    }
  }

  Map<double, int> _computePlates(double totalWeightKg) {
    double sideWeight = (totalWeightKg - 20.0) / 2.0;
    if (sideWeight <= 0) return {};

    List<double> availablePlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
    Map<double, int> plateCounts = {};

    for (double p in availablePlates) {
      int count = (sideWeight ~/ p);
      if (count > 0) {
        plateCounts[p] = count;
        sideWeight -= (count * p);
      }
    }
    return plateCounts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PLATES & 1RM COMPUTATION'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3))),
                child: Column(
                  children: [
                    TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalculate(),
                      decoration: const InputDecoration(labelText: 'Target Load (KG)', filled: true, fillColor: Color(0xFF101222)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: repsCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalculate(),
                      decoration: const InputDecoration(labelText: 'Reps Performed', filled: true, fillColor: Color(0xFF101222)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 1RM Models Output
              Row(
                children: [
                  Expanded(child: _1rmMetricTile('Epley 1RM', '${epley.toStringAsFixed(1)} KG', const Color(0xFF00F0FF))),
                  const SizedBox(width: 6),
                  Expanded(child: _1rmMetricTile('Brzycki 1RM', '${brzycki.toStringAsFixed(1)} KG', const Color(0xFF7000FF))),
                  const SizedBox(width: 6),
                  Expanded(child: _1rmMetricTile('Lander 1RM', '${lander.toStringAsFixed(1)} KG', const Color(0xFFFF0055))),
                ],
              ),
              const SizedBox(height: 16),

              // Barbell Loading Breakdown Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OLYMPIC BARBELL LOADING (PER SIDE)', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Assumes standard 20kg barbell baseline', style: TextStyle(color: Colors.grey, fontSize: 9)),
                    const SizedBox(height: 10),

                    calculatedPlates.isEmpty
                        ? const Text('Load target is <= 20kg (Empty Barbell)', style: TextStyle(color: Colors.white70, fontSize: 11))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: calculatedPlates.entries.map((e) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFF101222), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF00F0FF))),
                                child: Text('${e.value}x ${e.key} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF00F0FF))),
                              );
                            }).toList(),
                          )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _1rmMetricTile(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CUSTOM CANVAS PAINTERS
// -----------------------------------------------------------------------------
class ProRadialTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  ProRadialTimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, bgPaint);
    double sweepAngle = 2 * pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ProRadarChartPainter extends CustomPainter {
  final Map<String, double> data;
  ProRadarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 32;

    final gridPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final keys = data.keys.toList();
    final count = keys.length;
    final angleStep = (2 * pi) / count;

    // Grid Rings
    for (int step = 1; step <= 4; step++) {
      double r = radius * (step / 4.0);
      Path gridPath = Path();
      for (int i = 0; i < count; i++) {
        double x = center.dx + r * cos(i * angleStep - pi / 2);
        double y = center.dy + r * sin(i * angleStep - pi / 2);
        if (i == 0) gridPath.moveTo(x, y); else gridPath.lineTo(x, y);
      }
      gridPath.close();
      canvas.drawPath(gridPath, gridPaint);
    }

    // Data Polygon
    Path dataPath = Path();
    double maxVal = 24; // Baseline maximum scale sets
    for (int i = 0; i < count; i++) {
      double val = data[keys[i]] ?? 0;
      double r = radius * min(1.0, (val / maxVal));
      double x = center.dx + r * cos(i * angleStep - pi / 2);
      double y = center.dy + r * sin(i * angleStep - pi / 2);
      if (i == 0) dataPath.moveTo(x, y); else dataPath.lineTo(x, y);

      // Label Rendering
      double labelRadius = radius + 18;
      double lx = center.dx + labelRadius * cos(i * angleStep - pi / 2);
      double ly = center.dy + labelRadius * sin(i * angleStep - pi / 2);

      final textSpan = TextSpan(
        text: keys[i],
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(lx - (textPainter.width / 2), ly - (textPainter.height / 2)));
    }
    dataPath.close();

    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
