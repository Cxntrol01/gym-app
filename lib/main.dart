import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GymMasterTitanProApp());
}

class GymMasterTitanProApp extends StatefulWidget {
  const GymMasterTitanProApp({super.key});

  @override
  State<GymMasterTitanProApp> createState() => _GymMasterTitanProAppState();
}

class _GymMasterTitanProAppState extends State<GymMasterTitanProApp> {
  Color _accentColor = const Color(0xFF00F0FF);

  void _updateAccentColor(Color newColor) {
    setState(() {
      _accentColor = newColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Master TITAN PRO',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030307),
        cardColor: const Color(0xFF0B0C16),
        primaryColor: _accentColor,
        colorScheme: ColorScheme.dark(
          primary: _accentColor,
          secondary: const Color(0xFF7000FF),
          tertiary: const Color(0xFFFF0055),
          surface: const Color(0xFF0B0C16),
        ),
      ),
      home: TitanProShell(onAccentColorChanged: _updateAccentColor),
    );
  }
}

// -----------------------------------------------------------------------------
// GLOBAL EXERCISE LIBRARY
// -----------------------------------------------------------------------------
const List<Map<String, String>> globalExerciseLibrary = [
  {'name': 'Barbell Bench Press', 'group': 'Chest', 'equipment': 'Barbell', 'target': 'Chest'},
  {'name': 'Incline DB Press', 'group': 'Chest', 'equipment': 'Dumbbells', 'target': 'Chest'},
  {'name': 'Cable Chest Flye', 'group': 'Chest', 'equipment': 'Cable Tower', 'target': 'Chest'},
  {'name': 'Triceps Pushdown', 'group': 'Arms', 'equipment': 'Cable Tower', 'target': 'Triceps'},
  {'name': 'EZ-Bar Skullcrusher', 'group': 'Arms', 'equipment': 'EZ-Bar', 'target': 'Triceps'},
  {'name': 'Barbell Back Squat', 'group': 'Legs', 'equipment': 'Squat Rack', 'target': 'Quads'},
  {'name': 'Leg Press', 'group': 'Legs', 'equipment': 'Machine', 'target': 'Quads'},
  {'name': 'Romanian Deadlift', 'group': 'Legs', 'equipment': 'Barbell', 'target': 'Hamstrings'},
  {'name': 'Standing Calf Raise', 'group': 'Legs', 'equipment': 'Machine', 'target': 'Calves'},
  {'name': 'Lat Pulldown', 'group': 'Back', 'equipment': 'Lat Pulldown', 'target': 'Lats'},
  {'name': 'Seated Cable Row', 'group': 'Back', 'equipment': 'Cable Tower', 'target': 'Back'},
  {'name': 'Dumbbell Biceps Curl', 'group': 'Arms', 'equipment': 'Dumbbells', 'target': 'Biceps'},
  {'name': 'Overhead DB Press', 'group': 'Shoulders', 'equipment': 'Dumbbells', 'target': 'Shoulders'},
  {'name': 'Cable Lateral Raise', 'group': 'Shoulders', 'equipment': 'Cable Tower', 'target': 'Delts'},
  {'name': 'Hanging Leg Raise', 'group': 'Core', 'equipment': 'Pull-up Bar', 'target': 'Abs'},
  {'name': 'Ab Wheel Rollout', 'group': 'Core', 'equipment': 'Ab Wheel', 'target': 'Abs'},
];

class TitanProShell extends StatefulWidget {
  final Function(Color) onAccentColorChanged;
  const TitanProShell({super.key, required this.onAccentColorChanged});

  @override
  State<TitanProShell> createState() => _TitanProShellState();
}

class _TitanProShellState extends State<TitanProShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      const LiveTrackerTab(),
      const CustomRoutineBuilderTab(),
      const PhotoPhysiqueHeatmapTab(),
      const AnatomicalHeatmapTab(),
      const ApreVbtTab(),
      const BanisterTab(),
      const PlateMathTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.bolt, color: Theme.of(context).primaryColor, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('TITAN PRO 6.0 ENGINE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF06060D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: Colors.white70, size: 20),
            tooltip: 'Engine Documentation',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EngineDocsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white70, size: 20),
            tooltip: 'System Preferences',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen(onAccentChanged: widget.onAccentColorChanged)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF06060D),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 9,
        unselectedFontSize: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Session Log'),
          BottomNavigationBarItem(icon: Icon(Icons.alt_route), label: 'Split Builder'),
          BottomNavigationBarItem(icon: Icon(Icons.linked_camera), label: 'Photo AI Heatmap'),
          BottomNavigationBarItem(icon: Icon(Icons.accessibility_new), label: 'Volume Map'),
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'APRE / VBT'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'ACWR Stress'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: '1RM & Plates'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: LIVE SESSION TRACKER & WARMUP GENERATOR
// -----------------------------------------------------------------------------
class LiveTrackerTab extends StatefulWidget {
  const LiveTrackerTab({super.key});

  @override
  State<LiveTrackerTab> createState() => _LiveTrackerTabState();
}

class _LiveTrackerTabState extends State<LiveTrackerTab> {
  String selectedExercise = 'Barbell Bench Press';
  double currentWeight = 100.0;
  int currentReps = 8;
  double currentRpe = 8.0;

  List<Map<String, dynamic>> loggedSets = [];
  int restTimerSeconds = 0;
  Timer? timer;

  void _startRestTimer(int duration) {
    timer?.cancel();
    setState(() => restTimerSeconds = duration);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (restTimerSeconds > 0) {
        setState(() => restTimerSeconds--);
        if (restTimerSeconds == 10 || restTimerSeconds == 5 || restTimerSeconds == 0) {
          HapticFeedback.vibrate();
        }
      } else {
        t.cancel();
      }
    });
  }

  void _addSet({String tag = 'W'}) {
    setState(() {
      loggedSets.add({
        'exercise': selectedExercise,
        'weight': currentWeight,
        'reps': currentReps,
        'rpe': currentRpe,
        'tag': tag,
        'time': DateTime.now(),
      });
    });
    _startRestTimer(90);
  }

  void _generateWarmupPyramid() {
    setState(() {
      loggedSets.add({'exercise': selectedExercise, 'weight': (currentWeight * 0.40).roundToDouble(), 'reps': 10, 'rpe': 5.0, 'tag': 'W', 'time': DateTime.now()});
      loggedSets.add({'exercise': selectedExercise, 'weight': (currentWeight * 0.60).roundToDouble(), 'reps': 5, 'rpe': 6.0, 'tag': 'W', 'time': DateTime.now()});
      loggedSets.add({'exercise': selectedExercise, 'weight': (currentWeight * 0.75).roundToDouble(), 'reps': 3, 'rpe': 7.0, 'tag': 'W', 'time': DateTime.now()});
      loggedSets.add({'exercise': selectedExercise, 'weight': (currentWeight * 0.90).roundToDouble(), 'reps': 1, 'rpe': 8.0, 'tag': 'W', 'time': DateTime.now()});
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Injected 4 Warmup Sets (Pyramid Protocol).')));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('LIVE WORKOUT LOG & REST CONTROLLER'),
          const SizedBox(height: 8),

          // Rest Timer Bar
          if (restTimerSeconds > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0055).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF0055)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Color(0xFFFF0055), size: 20),
                      const SizedBox(width: 8),
                      Text('REST COUNTDOWN: ${restTimerSeconds}s', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF0055))),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setState(() => restTimerSeconds = 0),
                    child: const Text('SKIP', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  )
                ],
              ),
            ),

          // Exercise Selector & Input Panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: selectedExercise,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF101222),
                  items: globalExerciseLibrary.map((e) => DropdownMenuItem(value: e['name']!, child: Text(e['name']!))).toList(),
                  onChanged: (v) => setState(() => selectedExercise = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WEIGHT (kg)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 4),
                          SpinBoxWidget(
                            value: currentWeight,
                            step: 2.5,
                            onChanged: (v) => setState(() => currentWeight = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('REPS', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 4),
                          SpinBoxWidget(
                            value: currentReps.toDouble(),
                            step: 1.0,
                            onChanged: (v) => setState(() => currentReps = v.toInt()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TARGET RPE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 4),
                          SpinBoxWidget(
                            value: currentRpe,
                            step: 0.5,
                            onChanged: (v) => setState(() => currentRpe = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Theme.of(context).primaryColor)),
                        onPressed: _generateWarmupPyramid,
                        icon: Icon(Icons.fireplace, size: 16, color: Theme.of(context).primaryColor),
                        label: Text('GENERATE WARMUPS', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.black),
                        onPressed: () => _addSet(tag: 'W'),
                        icon: const Icon(Icons.add_task, size: 16),
                        label: const Text('LOG WORKING SET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 14),

          _buildHeader('COMPLETED SETS IN THIS SESSION'),
          const SizedBox(height: 8),

          loggedSets.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('No sets logged yet. Select an exercise and hit log.', style: TextStyle(color: Colors.grey, fontSize: 11))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: loggedSets.length,
                  itemBuilder: (ctx, idx) {
                    final s = loggedSets[idx];
                    bool isWarmup = s['tag'] == 'W' && s['weight'] < currentWeight * 0.9;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0C16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isWarmup ? Colors.amber.withOpacity(0.3) : Theme.of(context).primaryColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isWarmup ? Colors.amber.withOpacity(0.2) : Theme.of(context).primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(isWarmup ? 'WARM' : 'WORK', style: TextStyle(color: isWarmup ? Colors.amber : Theme.of(context).primaryColor, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Text(s['exercise'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                          Text('${s['weight']} kg  ×  ${s['reps']} reps  •  RPE ${s['rpe']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }
}

// -----------------------------------------------------------------------------
// TAB 2: CUSTOM ROUTINE BUILDER (OPTION 5)
// -----------------------------------------------------------------------------
class CustomRoutineBuilderTab extends StatefulWidget {
  const CustomRoutineBuilderTab({super.key});

  @override
  State<CustomRoutineBuilderTab> createState() => _CustomRoutineBuilderTabState();
}

class _CustomRoutineBuilderTabState extends State<CustomRoutineBuilderTab> {
  List<Map<String, dynamic>> customRoutines = [
    {
      'title': 'Push Hypertrophy A',
      'days': 'Mon / Thu',
      'isDeload': false,
      'exercises': [
        {'name': 'Barbell Bench Press', 'targetSets': 4, 'repRange': '6-8', 'targetRpe': 8.5},
        {'name': 'Overhead DB Press', 'targetSets': 3, 'repRange': '8-10', 'targetRpe': 8.0},
        {'name': 'Triceps Pushdown', 'targetSets': 4, 'repRange': '10-12', 'targetRpe': 9.0},
      ]
    },
    {
      'title': 'Pull & Lat Width B',
      'days': 'Tue / Fri',
      'isDeload': false,
      'exercises': [
        {'name': 'Lat Pulldown', 'targetSets': 4, 'repRange': '8-10', 'targetRpe': 8.5},
        {'name': 'Seated Cable Row', 'targetSets': 3, 'repRange': '10-12', 'targetRpe': 8.0},
        {'name': 'Dumbbell Biceps Curl', 'targetSets': 4, 'repRange': '10-12', 'targetRpe': 9.0},
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomRoutines();
  }

  Future<void> _loadCustomRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('titan_pro_custom_routines');
    if (raw != null) {
      setState(() {
        customRoutines = List<Map<String, dynamic>>.from(jsonDecode(raw));
      });
    }
  }

  Future<void> _saveRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('titan_pro_custom_routines', jsonEncode(customRoutines));
  }

  void _addRoutineDialog() {
    final titleCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: 'Mon / Wed / Fri');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B0C16),
        title: const Text('CREATE CUSTOM ROUTINE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Routine Name (e.g. Legs & Core)')),
            const SizedBox(height: 8),
            TextField(controller: daysCtrl, decoration: const InputDecoration(labelText: 'Target Days (e.g. Wed / Sat)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.black),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                setState(() {
                  customRoutines.add({'title': titleCtrl.text, 'days': daysCtrl.text, 'isDeload': false, 'exercises': []});
                });
                _saveRoutines();
                Navigator.pop(ctx);
              }
            },
            child: const Text('CREATE'),
          )
        ],
      ),
    );
  }

  void _addExerciseToRoutine(int routineIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B0C16),
      builder: (ctx) => ListView.builder(
        itemCount: globalExerciseLibrary.length,
        itemBuilder: (c, i) {
          final ex = globalExerciseLibrary[i];
          return ListTile(
            title: Text(ex['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            subtitle: Text('${ex['group']} • ${ex['equipment']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
            trailing: Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
            onTap: () {
              setState(() {
                customRoutines[routineIndex]['exercises'].add({
                  'name': ex['name'],
                  'targetSets': 3,
                  'repRange': '8-12',
                  'targetRpe': 8.0,
                });
              });
              _saveRoutines();
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('NEW ROUTINE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        onPressed: _addRoutineDialog,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CUSTOM SPLIT TEMPLATES & DELOAD CONTROL', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 10),

            ...List.generate(customRoutines.length, (rIdx) {
              final routine = customRoutines[rIdx];
              final List exList = routine['exercises'] ?? [];
              bool isDeload = routine['isDeload'] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0C16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDeload ? Colors.amber : Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(routine['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(routine['days'], style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10)),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Deload', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Switch(
                              value: isDeload,
                              activeColor: Colors.amber,
                              onChanged: (val) {
                                setState(() => routine['isDeload'] = val);
                                _saveRoutines();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              onPressed: () {
                                setState(() => customRoutines.removeAt(rIdx));
                                _saveRoutines();
                              },
                            )
                          ],
                        )
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 12),

                    ...List.generate(exList.length, (eIdx) {
                      final ex = exList[eIdx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${eIdx + 1}. ${ex['name']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            Text(
                              isDeload ? '${(ex['targetSets'] / 2).ceil()} Sets (Deload -20% Load)' : '${ex['targetSets']} Sets • ${ex['repRange']} Reps • RPE ${ex['targetRpe']}',
                              style: TextStyle(color: isDeload ? Colors.amber : Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: Icon(Icons.add, size: 14, color: Theme.of(context).primaryColor),
                        label: Text('ADD EXERCISE', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () => _addExerciseToRoutine(rIdx),
                      ),
                    )
                  ],
                ),
              );
            }),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: PHOTO PHYSIQUE AI HEATMAP ANALYZER
// -----------------------------------------------------------------------------
class PhotoPhysiqueHeatmapTab extends StatefulWidget {
  const PhotoPhysiqueHeatmapTab({super.key});

  @override
  State<PhotoPhysiqueHeatmapTab> createState() => _PhotoPhysiqueHeatmapTabState();
}

class _PhotoPhysiqueHeatmapTabState extends State<PhotoPhysiqueHeatmapTab> {
  final weightCtrl = TextEditingController(text: '80');
  final heightCtrl = TextEditingController(text: '180');
  final bodyFatCtrl = TextEditingController(text: '14');

  bool isAnalyzing = false;
  bool photoLoaded = false;
  String selectedPose = 'Anterior (Front Pose)';

  Map<String, double> muscleScores = {
    'Chest': 85.0,
    'Shoulders': 78.0,
    'Abs': 90.0,
    'Quads': 52.0,
    'Lats': 45.0,
    'Arms': 82.0,
  };

  void _runAiPhysiqueScan() {
    setState(() => isAnalyzing = true);
    Timer(const Duration(seconds: 2), () {
      double weight = double.tryParse(weightCtrl.text) ?? 80;
      double height = double.tryParse(heightCtrl.text) ?? 180;
      double bf = double.tryParse(bodyFatCtrl.text) ?? 14;

      double leanMassKg = weight * (1 - (bf / 100));
      double heightM = height / 100;
      double ffmi = leanMassKg / (heightM * heightM);

      setState(() {
        isAnalyzing = false;
        photoLoaded = true;
        muscleScores = {
          'Chest': min(98.0, 60 + (ffmi * 1.2)),
          'Shoulders': min(95.0, 55 + (ffmi * 1.1)),
          'Abs': max(30.0, 100 - (bf * 3.5)),
          'Quads': max(40.0, 42 + (ffmi * 0.8)),
          'Lats': max(35.0, 38 + (ffmi * 0.7)),
          'Arms': min(92.0, 58 + (ffmi * 1.1)),
        };
      });
    });
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF00FF87);
    if (score >= 65) return Theme.of(context).primaryColor;
    if (score >= 50) return const Color(0xFFFFB700);
    return const Color(0xFFFF0055);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('AI PHOTO PHYSIQUE HEATMAP ANALYZER'),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Body Weight (kg)', filled: true, fillColor: Color(0xFF101222)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Height (cm)', filled: true, fillColor: Color(0xFF101222)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: bodyFatCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Body Fat %', filled: true, fillColor: Color(0xFF101222)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<String>(
                      value: selectedPose,
                      dropdownColor: const Color(0xFF101222),
                      items: ['Anterior (Front Pose)', 'Posterior (Back Pose)'].map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 11)))).toList(),
                      onChanged: (v) => setState(() => selectedPose = v!),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.black),
                      onPressed: isAnalyzing ? null : _runAiPhysiqueScan,
                      icon: const Icon(Icons.camera_enhance, size: 16),
                      label: Text(isAnalyzing ? 'SCANNING...' : 'SCAN & MAP PHOTO', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF070810),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isAnalyzing ? const Color(0xFFFF0055) : Colors.white12),
            ),
            child: isAnalyzing
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Theme.of(context).primaryColor),
                        const SizedBox(height: 12),
                        const Text('ANALYZING MUSCLE CONTOURS & FFMI RATIOS...', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2)),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: CustomPaint(
                          size: const Size(200, 300),
                          painter: PhysiqueSilhouettePainter(isAnterior: selectedPose.contains('Anterior')),
                        ),
                      ),
                      if (photoLoaded) ...[
                        _buildHeatmapPin(xRatio: 0.50, yRatio: 0.28, label: 'Chest', score: muscleScores['Chest']!),
                        _buildHeatmapPin(xRatio: 0.32, yRatio: 0.25, label: 'Shoulders', score: muscleScores['Shoulders']!),
                        _buildHeatmapPin(xRatio: 0.68, yRatio: 0.25, label: 'Delts', score: muscleScores['Shoulders']!),
                        _buildHeatmapPin(xRatio: 0.50, yRatio: 0.42, label: 'Abs', score: muscleScores['Abs']!),
                        _buildHeatmapPin(xRatio: 0.38, yRatio: 0.62, label: 'Quads', score: muscleScores['Quads']!),
                        _buildHeatmapPin(xRatio: 0.62, yRatio: 0.62, label: 'Lats/Quads', score: muscleScores['Lats']!),
                      ],
                      Positioned(
                        bottom: 8,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            children: [
                              _legendDot('Optimal', const Color(0xFF00FF87)),
                              const SizedBox(width: 8),
                              _legendDot('Balanced', Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              _legendDot('Lagging', const Color(0xFFFF0055)),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
          ),
          const SizedBox(height: 14),

          _buildHeader('BODY WEIGHT vs MUSCLE DENSITY BREAKDOWN'),
          const SizedBox(height: 8),

          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: muscleScores.entries.map((e) {
              Color color = _getScoreColor(e.value);
              String status = e.value >= 80 ? 'Excellent Volume' : (e.value >= 65 ? 'Balanced for Frame' : 'High Hypertrophy Priority');

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.4))),
                child: Row(
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: color.withOpacity(0.2), child: Text('${e.value.toInt()}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(status, style: TextStyle(color: Colors.grey[400], fontSize: 9)),
                        ],
                      ),
                    ),
                    if (e.value < 65)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF0055), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added +3 weekly targeted sets for ${e.key} into Split Builder.')));
                        },
                        child: const Text('+ADD TO SPLIT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildHeatmapPin({required double xRatio, required double yRatio, required String label, required double score}) {
    Color color = _getScoreColor(score);
    return Positioned(
      left: MediaQuery.of(context).size.width * xRatio - 28,
      top: 320 * yRatio - 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)],
        ),
        child: Text('$label ${score.toInt()}%', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8)),
      ),
    );
  }

  Widget _legendDot(String text, Color c) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 8)),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }
}

// -----------------------------------------------------------------------------
// TAB 4: ANATOMICAL VOLUME MAP (MEV / MAV / MRV)
// -----------------------------------------------------------------------------
class AnatomicalHeatmapTab extends StatefulWidget {
  const AnatomicalHeatmapTab({super.key});

  @override
  State<AnatomicalHeatmapTab> createState() => _AnatomicalHeatmapTabState();
}

class _AnatomicalHeatmapTabState extends State<AnatomicalHeatmapTab> {
  final Map<String, Map<String, int>> muscleVolumes = {
    'Chest': {'weeklySets': 16, 'mev': 10, 'mav': 18, 'mrv': 22},
    'Lats/Back': {'weeklySets': 20, 'mev': 12, 'mav': 20, 'mrv': 25},
    'Quads': {'weeklySets': 8, 'mev': 8, 'mav': 16, 'mrv': 20},
    'Hamstrings': {'weeklySets': 12, 'mev': 6, 'mav': 14, 'mrv': 18},
    'Delts': {'weeklySets': 22, 'mev': 8, 'mav': 22, 'mrv': 26},
    'Triceps': {'weeklySets': 14, 'mev': 6, 'mav': 14, 'mrv': 18},
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WEEKLY VOLUME THRESHOLD TRACKER (RP HYPERTROPHY MODEL)', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),

          ...muscleVolumes.entries.map((entry) {
            final name = entry.key;
            final sets = entry.value['weeklySets']!;
            final mev = entry.value['mev']!;
            final mav = entry.value['mav']!;
            final mrv = entry.value['mrv']!;

            Color statusColor;
            String statusText;
            if (sets < mev) {
              statusColor = const Color(0xFFFF0055);
              statusText = 'Under Maintenance (Below MEV)';
            } else if (sets <= mav) {
              statusColor = const Color(0xFF00FF87);
              statusText = 'Optimal Growth Zone (MEV-MAV)';
            } else if (sets <= mrv) {
              statusColor = Colors.amber;
              statusText = 'High Overreach (Near MRV)';
            } else {
              statusColor = const Color(0xFFFF0055);
              statusText = 'Overtraining Hazard (Exceeds MRV)';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(10), border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('$sets Weekly Sets', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(statusText, style: TextStyle(color: statusColor, fontSize: 9)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (sets / mrv).clamp(0.0, 1.0),
                    backgroundColor: Colors.white10,
                    color: statusColor,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MEV: $mev', style: const TextStyle(color: Colors.grey, fontSize: 8)),
                      Text('MAV: $mav', style: const TextStyle(color: Colors.grey, fontSize: 8)),
                      Text('MRV: $mrv', style: const TextStyle(color: Colors.grey, fontSize: 8)),
                    ],
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 5: APRE 3/6/10 & LOAD-VELOCITY ENGINE
// -----------------------------------------------------------------------------
class ApreVbtTab extends StatefulWidget {
  const ApreVbtTab({super.key});

  @override
  State<ApreVbtTab> createState() => _ApreVbtTabState();
}

class _ApreVbtTabState extends State<ApreVbtTab> {
  double currentWorkingWeight = 100.0;
  int repsPerformed = 8;
  String apreProtocol = 'APRE 6-RM Protocol';

  double _calculateNextSetAdjustment() {
    if (apreProtocol == 'APRE 6-RM Protocol') {
      if (repsPerformed < 4) return -5.0;
      if (repsPerformed < 6) return -2.5;
      if (repsPerformed == 6) return 0.0;
      if (repsPerformed <= 8) return 2.5;
      return 5.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    double adjustment = _calculateNextSetAdjustment();
    double nextWeight = currentWorkingWeight + adjustment;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AUTOREGULATED PROGRESSIVE RESISTANCE EXERCISE (APRE)', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: apreProtocol,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF101222),
                  items: ['APRE 3-RM Protocol', 'APRE 6-RM Protocol', 'APRE 10-RM Protocol'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => apreProtocol = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SpinBoxWidget(
                        value: currentWorkingWeight,
                        step: 2.5,
                        onChanged: (v) => setState(() => currentWorkingWeight = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SpinBoxWidget(
                        value: repsPerformed.toDouble(),
                        step: 1.0,
                        onChanged: (v) => setState(() => repsPerformed = v.toInt()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF101222), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('NEXT SET ADJUSTED LOAD:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      Text('$nextWeight kg (${adjustment >= 0 ? "+$adjustment" : adjustment} kg)', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 6: ACWR STRESS ENGINE (BANISTER EWMA)
// -----------------------------------------------------------------------------
class BanisterTab extends StatefulWidget {
  const BanisterTab({super.key});

  @override
  State<BanisterTab> createState() => _BanisterTabState();
}

class _BanisterTabState extends State<BanisterTab> {
  double acuteLoad = 1250.0; // 7-day EWMA
  double chronicLoad = 1000.0; // 28-day EWMA

  @override
  Widget build(BuildContext context) {
    double acwr = acuteLoad / chronicLoad;

    Color acwrColor;
    String statusLabel;
    if (acwr < 0.8) {
      acwrColor = Colors.blueAccent;
      statusLabel = 'UNDERTRAINING (Deconditioning Risk)';
    } else if (acwr <= 1.3) {
      acwrColor = const Color(0xFF00FF87);
      statusLabel = 'SWEET SPOT (Optimal Progression)';
    } else if (acwr <= 1.5) {
      acwrColor = Colors.amber;
      statusLabel = 'HIGH DANGER ZONE (Overreach Alert)';
    } else {
      acwrColor = const Color(0xFFFF0055);
      statusLabel = 'CRITICAL SPIKE (Trigger Deload Week)';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACUTE-TO-CHRONIC WORKLOAD RATIO (ACWR / EWMA)', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: acwrColor.withOpacity(0.4))),
            child: Column(
              children: [
                Text(acwr.toStringAsFixed(2), style: TextStyle(color: acwrColor, fontSize: 36, fontWeight: FontWeight.w900)),
                Text(statusLabel, style: TextStyle(color: acwrColor, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ACUTE FATIGUE (7d ATL)', style: TextStyle(fontSize: 9, color: Colors.grey)),
                          Slider(value: acuteLoad, min: 500, max: 2500, onChanged: (v) => setState(() => acuteLoad = v)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CHRONIC FITNESS (28d CTL)', style: TextStyle(fontSize: 9, color: Colors.grey)),
                          Slider(value: chronicLoad, min: 500, max: 2500, onChanged: (v) => setState(() => chronicLoad = v)),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 7: MULTI-EQUATION 1RM & BARBELL PLATE PAINTER
// -----------------------------------------------------------------------------
class PlateMathTab extends StatefulWidget {
  const PlateMathTab({super.key});

  @override
  State<PlateMathTab> createState() => _PlateMathTabState();
}

class _PlateMathTabState extends State<PlateMathTab> {
  double targetWeight = 140.0;
  double barWeight = 20.0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BARBELL PLATE LOADING & VISUAL PAINTER', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Target Weight (kg):', style: TextStyle(fontSize: 11)),
                    SizedBox(width: 120, child: SpinBoxWidget(value: targetWeight, step: 2.5, onChanged: (v) => setState(() => targetWeight = v))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Barbell Type:', style: TextStyle(fontSize: 11)),
                    DropdownButton<double>(
                      value: barWeight,
                      dropdownColor: const Color(0xFF101222),
                      items: const [
                        DropdownMenuItem(value: 20.0, child: Text('Olympic Bar (20kg)')),
                        DropdownMenuItem(value: 15.0, child: Text('Women\'s Bar (15kg)')),
                        DropdownMenuItem(value: 25.0, child: Text('Trap Bar (25kg)')),
                      ],
                      onChanged: (v) => setState(() => barWeight = v!),
                    )
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFF06060D), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
            child: CustomPaint(
              painter: BarbellPlatePainter(targetWeight: targetWeight, barWeight: barWeight, isKg: true),
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CUSTOM PAINTER FOR BARBELL PLATES
// -----------------------------------------------------------------------------
class BarbellPlatePainter extends CustomPainter {
  final double targetWeight;
  final double barWeight;
  final bool isKg;

  BarbellPlatePainter({required this.targetWeight, required this.barWeight, required this.isKg});

  @override
  void paint(Canvas canvas, Size size) {
    final double sideWeight = (targetWeight - barWeight) / 2;
    if (sideWeight <= 0) return;

    final List<double> availablePlates = isKg ? [25, 20, 15, 10, 5, 2.5, 1.25] : [45, 35, 25, 10, 5, 2.5];
    final Map<double, Color> plateColors = {
      25: Colors.red,
      20: Colors.blue,
      15: Colors.yellow,
      10: Colors.green,
      5: Colors.white,
      2.5: Colors.black,
      1.25: Colors.grey,
    };

    double remaining = sideWeight;
    List<double> platesToDraw = [];

    for (double p in availablePlates) {
      while (remaining >= p) {
        platesToDraw.add(p);
        remaining -= p;
      }
    }

    final Paint barPaint = Paint()..color = Colors.grey[400]!..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, size.height / 2 - 4, size.width, 8), barPaint);

    double currentX = size.width / 2 + 10;
    for (double plate in platesToDraw) {
      double plateHeight = min(size.height * 0.85, 30 + (plate * 2.5));
      Paint pPaint = Paint()..color = plateColors[plate] ?? Colors.cyan;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(currentX, (size.height - plateHeight) / 2, 10, plateHeight),
          const Radius.circular(2),
        ),
        pPaint,
      );
      currentX += 12.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// CUSTOM PAINTER FOR PHYSIQUE SILHOUETTE
// -----------------------------------------------------------------------------
class PhysiqueSilhouettePainter extends CustomPainter {
  final bool isAnterior;
  PhysiqueSilhouettePainter({required this.isAnterior});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = const Color(0xFF101322)
      ..style = PaintingStyle.fill;

    double cx = size.width / 2;

    canvas.drawCircle(Offset(cx, 30), 16, fillPaint);
    canvas.drawCircle(Offset(cx, 30), 16, paint);

    Path torso = Path()
      ..moveTo(cx - 38, 54)
      ..lineTo(cx + 38, 54)
      ..lineTo(cx + 24, 130)
      ..lineTo(cx - 24, 130)
      ..close();
    canvas.drawPath(torso, fillPaint);
    canvas.drawPath(torso, paint);

    Path legs = Path()
      ..moveTo(cx - 22, 130)
      ..lineTo(cx - 4, 130)
      ..lineTo(cx - 8, 250)
      ..lineTo(cx - 24, 250)
      ..close()
      ..moveTo(cx + 4, 130)
      ..lineTo(cx + 22, 130)
      ..lineTo(cx + 24, 250)
      ..lineTo(cx + 8, 250)
      ..close();
    canvas.drawPath(legs, fillPaint);
    canvas.drawPath(legs, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// HELPER WIDGETS & AUXILIARY SCREENS
// -----------------------------------------------------------------------------
class SpinBoxWidget extends StatelessWidget {
  final double value;
  final double step;
  final Function(double) onChanged;

  const SpinBoxWidget({super.key, required this.value, required this.step, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFF101222), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(onTap: () => onChanged(max(0, value - step)), child: const Icon(Icons.remove, size: 16, color: Colors.white70)),
          Text(value.toStringAsFixed(step < 1 ? 1 : 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          InkWell(onTap: () => onChanged(value + step), child: const Icon(Icons.add, size: 16, color: Colors.white70)),
        ],
      ),
    );
  }
}

class EngineDocsScreen extends StatelessWidget {
  const EngineDocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ENGINE MANUAL & FORMULAS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            _buildDocCard(
              context,
              title: 'Custom Split Builder & Deload Microcycles',
              icon: Icons.alt_route,
              color: Theme.of(context).primaryColor,
              content: 'Build custom split routines with target volume sets and RPE goals. Deload mode auto-scales set volume by -50% and weight loads by -20%.',
            ),
            const SizedBox(height: 10),
            _buildDocCard(
              context,
              title: 'AI Photo Physique Heatmapping',
              icon: Icons.linked_camera,
              color: const Color(0xFF00FF87),
              content: 'Scans user photos against FFMI and bodyweight standards to highlight lagging or overdeveloped muscle zones directly on silhouette overlays.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(BuildContext context, {required String title, required IconData icon, required Color color, required String content}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const Divider(color: Colors.white10, height: 12),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.4)),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final Function(Color) onAccentChanged;
  const SettingsScreen({super.key, required this.onAccentChanged});

  @override
  Widget build(BuildContext context) {
    final List<Color> accents = [
      const Color(0xFF00F0FF),
      const Color(0xFF00FF87),
      const Color(0xFFFF0055),
      const Color(0xFFFFB700),
      const Color(0xFF7000FF),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS & PREFERENCES', style: TextStyle(fontSize: 13))),
      body: ListView(
        padding: const EdgeInsets.all(14.0),
        children: [
          const Text('SYSTEM ACCENT COLOR', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: accents.map((c) {
              return GestureDetector(
                onTap: () => onAccentChanged(c),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}
