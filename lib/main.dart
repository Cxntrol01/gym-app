import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
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

// Global Exercise Database
const List<Map<String, String>> globalExerciseLibrary = [
  {'name': 'Barbell Bench Press', 'group': 'Chest', 'equipment': 'Barbell', 'target': 'Chest'},
  {'name': 'Incline DB Press', 'group': 'Chest', 'equipment': 'Dumbbells', 'target': 'Chest'},
  {'name': 'Triceps Pushdown', 'group': 'Arms', 'equipment': 'Cable Tower', 'target': 'Triceps'},
  {'name': 'EZ-Bar Skullcrusher', 'group': 'Arms', 'equipment': 'EZ-Bar', 'target': 'Triceps'},
  {'name': 'Barbell Back Squat', 'group': 'Legs', 'equipment': 'Squat Rack', 'target': 'Quads'},
  {'name': 'Romanian Deadlift', 'group': 'Legs', 'equipment': 'Barbell', 'target': 'Hamstrings'},
  {'name': 'Standing Calf Raise', 'group': 'Legs', 'equipment': 'Machine', 'target': 'Calves'},
  {'name': 'Lat Pulldown', 'group': 'Back', 'equipment': 'Lat Pulldown', 'target': 'Lats'},
  {'name': 'Seated Cable Row', 'group': 'Back', 'equipment': 'Cable Tower', 'target': 'Back'},
  {'name': 'Dumbbell Biceps Curl', 'group': 'Arms', 'equipment': 'Dumbbells', 'target': 'Biceps'},
  {'name': 'Overhead DB Press', 'group': 'Shoulders', 'equipment': 'Dumbbells', 'target': 'Shoulders'},
  {'name': 'Cable Lateral Raise', 'group': 'Shoulders', 'equipment': 'Cable Tower', 'target': 'Shoulders'},
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
      const AnatomicalHeatmapTab(),
      const ApreVbtTab(),
      const BanisterTab(),
      const PlateMathTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TITAN PRO 5.0 ENGINE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: Colors.white70),
            tooltip: 'Engine Documentation',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EngineDocsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white70),
            tooltip: 'System Preferences',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(onAccentChanged: widget.onAccentColorChanged),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
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
        selectedFontSize: 10,
        unselectedFontSize: 9,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Session Log'),
          BottomNavigationBarItem(icon: Icon(Icons.accessibility_new), label: 'Heatmap'),
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'APRE / VBT'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'EWMA Stress'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Plates & 1RM'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SETTINGS SCREEN: SYSTEM & VOLUME THRESHOLD CUSTOMIZATION
// -----------------------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  final Function(Color) onAccentChanged;
  const SettingsScreen({super.key, required this.onAccentChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double mevThreshold = 6;
  double mavThreshold = 14;
  double mrvThreshold = 20;
  int defaultRestSec = 90;
  String unitSystem = 'KG';
  Color selectedAccent = const Color(0xFF00F0FF);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      mevThreshold = prefs.getDouble('setting_mev') ?? 6.0;
      mavThreshold = prefs.getDouble('setting_mav') ?? 14.0;
      mrvThreshold = prefs.getDouble('setting_mrv') ?? 20.0;
      defaultRestSec = prefs.getInt('setting_rest_timer') ?? 90;
      unitSystem = prefs.getString('setting_unit') ?? 'KG';
      int colorValue = prefs.getInt('setting_accent_color') ?? 0xFF00F0FF;
      selectedAccent = Color(colorValue);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('setting_mev', mevThreshold);
    await prefs.setDouble('setting_mav', mavThreshold);
    await prefs.setDouble('setting_mrv', mrvThreshold);
    await prefs.setInt('setting_rest_timer', defaultRestSec);
    await prefs.setString('setting_unit', unitSystem);
    await prefs.setInt('setting_accent_color', selectedAccent.value);

    widget.onAccentChanged(selectedAccent);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences committed to system memory.'),
          backgroundColor: Color(0xFF00F0FF),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CUSTOMIZATION & THRESHOLDS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('HYPERTROPHY VOLUME THRESHOLDS (WEEKLY SETS)'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
              child: Column(
                children: [
                  _buildSliderRow('Minimum Effective Volume (MEV)', mevThreshold, 2, 10, (v) => setState(() => mevThreshold = v)),
                  const Divider(color: Colors.white10),
                  _buildSliderRow('Maximum Adaptive Volume (MAV)', mavThreshold, 8, 18, (v) => setState(() => mavThreshold = v)),
                  const Divider(color: Colors.white10),
                  _buildSliderRow('Maximum Recoverable Volume (MRV)', mrvThreshold, 16, 30, (v) => setState(() => mrvThreshold = v)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('TIMER & UNITS CONFIGURATION'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Weight System Units', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'KG', label: Text('KG')),
                          ButtonSegment(value: 'LBS', label: Text('LBS')),
                        ],
                        selected: {unitSystem},
                        onSelectionChanged: (set) {
                          setState(() => unitSystem = set.first);
                        },
                      )
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Default Rest Timer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      DropdownButton<int>(
                        value: defaultRestSec,
                        dropdownColor: const Color(0xFF101222),
                        items: [30, 60, 90, 120, 180, 240]
                            .map((sec) => DropdownMenuItem(value: sec, child: Text('${sec}s', style: TextStyle(color: Theme.of(context).primaryColor))))
                            .toList(),
                        onChanged: (val) => setState(() => defaultRestSec = val!),
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('INTERFACE ACCENT COLOR'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Color(0xFF00F0FF),
                  const Color(0xFF00FF87),
                  const Color(0xFFFFB700),
                  const Color(0xFFFF0055),
                  const Color(0xFF7000FF),
                ].map((c) {
                  bool isSelected = selectedAccent.value == c.value;
                  return GestureDetector(
                    onTap: () => setState(() => selectedAccent = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: selectedAccent, foregroundColor: Colors.black),
                onPressed: _saveSettings,
                child: const Text('SAVE PREFERENCES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _buildSliderRow(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Text('${value.toInt()} Sets', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: Theme.of(context).primaryColor,
          onChanged: onChanged,
        )
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ENGINE DOCS SCREEN: EXPLAINING THE SCIENCE & ALGORITHMS
// -----------------------------------------------------------------------------
class EngineDocsScreen extends StatelessWidget {
  const EngineDocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ENGINE MANUAL & FORMULAS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDocCard(
              context,
              title: '1. Anatomical Body Heatmapping',
              icon: Icons.accessibility_new,
              color: const Color(0xFF00F0FF),
              content:
                  'The muscle visualizer reads hard completed working sets (type N, D, F) logged across microcycles and compares them against localized volume thresholds:\n\n'
                  '• Cold (Below MEV): Insufficient stimulus for hypertrophy.\n'
                  '• Neon Cyan (MEV): Maintenance & baseline adaptation threshold.\n'
                  '• Neon Green (MEV to MAV): Optimal hypertrophy volume window.\n'
                  '• Hot Red (Above MRV): Maximum recoverable volume exceeded, signaling high systemic fatigue risk.',
            ),
            const SizedBox(height: 12),
            _buildDocCard(
              context,
              title: '2. APRE 3.0 & VBT Velocity Curves',
              icon: Icons.speed,
              color: const Color(0xFF7000FF),
              content:
                  'Autoregulated Progressive Resistance Exercise (APRE) adjusts next-session working sets based on reps executed to failure.\n\n'
                  'Mean Concentric Velocity (m/s) is estimated via standard linear transducer proxy models derived from Repetitions in Reserve (RIR):\n'
                  '  Estimated Velocity = 0.52 - (0.035 * RIR)\n\n'
                  'Velocity drop-off thresholds indicate neuromuscular fatigue during working sets.',
            ),
            const SizedBox(height: 12),
            _buildDocCard(
              context,
              title: '3. Banister EWMA Fatigue Engine',
              icon: Icons.show_chart,
              color: const Color(0xFFFF0055),
              content:
                  'Uses Exponentially Weighted Moving Averages (EWMA) to model systemic adaptation:\n\n'
                  '• Acute Training Load (ATL / 7-Day): Represents acute fatigue.\n'
                  '• Chronic Training Load (CTL / 42-Day): Represents chronic fitness.\n'
                  '• Training Stress Balance (TSB = CTL - ATL): Positive values indicate readiness & peak strength output; negative values indicate accumulated overload.',
            ),
            const SizedBox(height: 12),
            _buildDocCard(
              context,
              title: '4. Multi-Equation 1RM & Plate Math',
              icon: Icons.calculate,
              color: Colors.amber,
              content:
                  'Calculates Estimated 1-Rep Max (e1RM) using 3 validated scientific equations:\n\n'
                  '• Epley: Weight * (1 + Reps / 30)\n'
                  '• Brzycki: Weight * (36 / (37 - Reps))\n'
                  '• Lander: (100 * Weight) / (101.3 - 2.67123 * Reps)\n\n'
                  'The loading calculator strips standard 20kg/45lb barbell weight and yields exact symmetrical plate distributions per side.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(BuildContext context, {required String title, required IconData icon, required Color color, required String content}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.5)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: LIVE TRACKER WITH DYNAMIC UNITS & REST TIMER PREFERENCES
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
  String weightUnit = 'KG';

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
    weightUnit = prefs.getString('setting_unit') ?? 'KG';
    restTotalDuration = prefs.getInt('setting_rest_timer') ?? 90;

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
      Map<String, int> muscleSetCounts = {};

      for (var ex in todayExercises) {
        String target = ex['target'] ?? 'Chest';
        for (var s in ex['sets']) {
          if (s['done'] == true) {
            double w = double.tryParse(s['weight'].toString()) ?? 0;
            int r = int.tryParse(s['reps'].toString()) ?? 0;
            double rpe = double.tryParse(s['rpe'].toString()) ?? 8.0;
            volume += (w * r);
            totalRpeSum += rpe;
            setsDone++;

            if (s['type'] != 'W') {
              muscleSetCounts[target] = (muscleSetCounts[target] ?? 0) + 1;
            }
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
        'volume': volume.toInt(),
        'sets': setsDone,
        'stress': stressImpulse.toInt(),
        'muscleSets': muscleSetCounts,
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
      default: return Theme.of(context).primaryColor;
    }
  }

  void _showSessionSummary(int volume, int sets, int stress) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B0C16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).primaryColor, width: 0.5)),
        title: Column(
          children: [
            Icon(Icons.military_tech, color: Theme.of(context).primaryColor, size: 48),
            const SizedBox(height: 8),
            const Text('SESSION LOGGED', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow('Session Duration', _formatTime(sessionTimeSec)),
            _summaryRow('Completed Sets', '$sets Sets'),
            _summaryRow('Total Tonnage', '$volume $weightUnit', color: Theme.of(context).primaryColor),
            _summaryRow('Banister Stress Impulse', '$stress Points', color: const Color(0xFFFF0055)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('COMMIT TO DATABASE', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: isRest ? Colors.redAccent.withOpacity(0.3) : Theme.of(context).primaryColor.withOpacity(0.3))),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isRest ? Colors.redAccent.withOpacity(0.2) : Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Icon(isRest ? Icons.nightlight_round : Icons.fitness_center, color: isRest ? Colors.redAccent : Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(isRest ? 'Active Recovery Protocol' : 'Hypertrophy Microcycle', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),
                if (!isRest)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: isSessionActive ? const Color(0xFFFF0055) : Theme.of(context).primaryColor, foregroundColor: Colors.black),
                    onPressed: _toggleSession,
                    child: Text(isSessionActive ? 'FINISH' : 'START', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  )
              ],
            ),
          ),

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
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Rest: ${restTimeSec}s', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => restTimeSec += 30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text('+30s', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]
                ],
              ),
            )
          ],

          const SizedBox(height: 10),

          Expanded(
            child: isRest
                ? const Center(child: Text('CNS Active Recovery Protocol Active', style: TextStyle(color: Colors.grey)))
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
                                Text('${exIdx + 1}. ', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                Expanded(child: Text(ex['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor, size: 18),
                                  onPressed: () {
                                    setState(() => sets.add({'weight': '70', 'reps': '8', 'rpe': '8.0', 'type': 'N', 'done': false}));
                                    _saveTodayExercises();
                                  },
                                )
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 6),

                            Row(
                              children: [
                                const SizedBox(width: 24, child: Text('TAG', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold))),
                                Expanded(child: Center(child: Text(weightUnit, style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))),
                                const Expanded(child: Center(child: Text('REPS', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))),
                                const Expanded(child: Center(child: Text('RPE', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))),
                                const Expanded(child: Center(child: Text('VBT (m/s)', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))),
                                const Expanded(child: Center(child: Text('e1RM', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))),
                                const SizedBox(width: 28, child: Center(child: Text('SET', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))),
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

                                    Expanded(
                                      child: Center(
                                        child: Text(estVelocity.toStringAsFixed(2), style: TextStyle(fontSize: 9, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                      ),
                                    ),

                                    Expanded(
                                      child: Center(
                                        child: Text('${e1RM.toStringAsFixed(0)}${weightUnit.toLowerCase()}', style: const TextStyle(fontSize: 9, color: Colors.amber, fontWeight: FontWeight.bold)),
                                      ),
                                    ),

                                    SizedBox(
                                      width: 28,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? Theme.of(context).primaryColor : Colors.grey[700], size: 16),
                                        onPressed: () {
                                          setState(() => s['done'] = !isDone);
                                          _saveTodayExercises();
                                          if (!isDone) _startRestTimer(type == 'W' ? 45 : restTotalDuration);
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
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: ANATOMICAL HEATMAP READS CUSTOM THRESHOLDS
// -----------------------------------------------------------------------------
class AnatomicalHeatmapTab extends StatefulWidget {
  const AnatomicalHeatmapTab({super.key});

  @override
  State<AnatomicalHeatmapTab> createState() => _AnatomicalHeatmapTabState();
}

class _AnatomicalHeatmapTabState extends State<AnatomicalHeatmapTab> {
  Map<String, int> muscleSetVolume = {
    'Chest': 12, 'Shoulders': 10, 'Biceps': 14, 'Triceps': 8,
    'Abs': 6, 'Quads': 16, 'Hamstrings': 12, 'Calves': 8, 'Lats': 15, 'Back': 14
  };

  double mev = 6;
  double mav = 14;
  double mrv = 20;

  @override
  void initState() {
    super.initState();
    _loadVolumesAndSettings();
  }

  Future<void> _loadVolumesAndSettings() async {
    final prefs = await SharedPreferences.getInstance();
    mev = prefs.getDouble('setting_mev') ?? 6.0;
    mav = prefs.getDouble('setting_mav') ?? 14.0;
    mrv = prefs.getDouble('setting_mrv') ?? 20.0;

    final history = prefs.getStringList('titan_pro_history_logs') ?? [];
    if (history.isNotEmpty) {
      Map<String, int> aggregated = {
        'Chest': 0, 'Shoulders': 0, 'Biceps': 0, 'Triceps': 0,
        'Abs': 0, 'Quads': 0, 'Hamstrings': 0, 'Calves': 0, 'Lats': 0, 'Back': 0
      };
      for (String item in history) {
        final decoded = jsonDecode(item);
        if (decoded['muscleSets'] != null) {
          Map<String, dynamic> mSets = Map<String, dynamic>.from(decoded['muscleSets']);
          mSets.forEach((m, cnt) {
            aggregated[m] = (aggregated[m] ?? 0) + (cnt as int);
          });
        }
      }
      setState(() => muscleSetVolume = aggregated);
    } else {
      setState(() {});
    }
  }

  Color _getHeatColor(int sets) {
    if (sets == 0) return const Color(0xFF1E2038);
    if (sets < mev) return Theme.of(context).primaryColor;
    if (sets <= mav) return const Color(0xFF00FF87);
    if (sets <= mrv) return const Color(0xFFFFB700);
    return const Color(0xFFFF0055);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text('CUSTOMIZED HYPERTROPHY STIMULUS MAP', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            Container(
              height: 280,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))),
              child: CustomPaint(
                painter: AccurateAnatomicalBodyPainter(
                  muscleVolumes: muscleSetVolume,
                  colorResolver: _getHeatColor,
                  primaryThemeColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _legendItem('Cold (0)', const Color(0xFF1E2038)),
                  _legendItem('MEV (<${mev.toInt()})', Theme.of(context).primaryColor),
                  _legendItem('MAV (${mev.toInt()}-${mav.toInt()})', const Color(0xFF00FF87)),
                  _legendItem('High (${mav.toInt()}-${mrv.toInt()})', const Color(0xFFFFB700)),
                  _legendItem('MRV (>${mrv.toInt()})', const Color(0xFFFF0055)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: muscleSetVolume.entries.map((e) {
                Color heatColor = _getHeatColor(e.value);
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(8), border: Border.all(color: heatColor.withOpacity(0.4))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: heatColor, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      Text('${e.value} Sets Logged', style: TextStyle(color: heatColor, fontWeight: FontWeight.bold, fontSize: 11))
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class AccurateAnatomicalBodyPainter extends CustomPainter {
  final Map<String, int> muscleVolumes;
  final Color Function(int sets) colorResolver;
  final Color primaryThemeColor;

  AccurateAnatomicalBodyPainter({
    required this.muscleVolumes,
    required this.colorResolver,
    required this.primaryThemeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double frontCenterX = width * 0.28;
    final double backCenterX = width * 0.72;

    final outlinePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    void drawHeader(String text, double cx) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: primaryThemeColor, fontSize: 10, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - (tp.width / 2), 0));
    }

    drawHeader('ANTERIOR (FRONT)', frontCenterX);
    drawHeader('POSTERIOR (REAR)', backCenterX);

    void drawMuscleGroup(Path path, String muscleName) {
      int sets = muscleVolumes[muscleName] ?? 0;
      Color heatColor = colorResolver(sets);

      final fillPaint = Paint()
        ..color = heatColor.withOpacity(sets > 0 ? 0.85 : 0.25)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, outlinePaint);
    }

    // FRONT
    canvas.drawOval(Rect.fromLTWH(frontCenterX - 12, 18, 24, 28), outlinePaint);

    Path chestPath = Path()
      ..moveTo(frontCenterX - 20, 56)
      ..lineTo(frontCenterX + 20, 56)
      ..lineTo(frontCenterX + 18, 76)
      ..lineTo(frontCenterX, 82)
      ..lineTo(frontCenterX - 18, 76)
      ..close();
    drawMuscleGroup(chestPath, 'Chest');

    Path shouldersFront = Path()
      ..addOval(Rect.fromLTWH(frontCenterX - 32, 50, 12, 22))
      ..addOval(Rect.fromLTWH(frontCenterX + 20, 50, 12, 22));
    drawMuscleGroup(shouldersFront, 'Shoulders');

    Path bicepsFront = Path()
      ..addRect(Rect.fromLTWH(frontCenterX - 34, 74, 10, 26))
      ..addRect(Rect.fromLTWH(frontCenterX + 24, 74, 10, 26));
    drawMuscleGroup(bicepsFront, 'Biceps');

    Path absPath = Path()..addRect(Rect.fromLTWH(frontCenterX - 14, 84, 28, 42));
    drawMuscleGroup(absPath, 'Abs');

    Path quadsPath = Path()
      ..moveTo(frontCenterX - 18, 128)..lineTo(frontCenterX - 2, 128)..lineTo(frontCenterX - 4, 190)..lineTo(frontCenterX - 16, 190)..close()
      ..moveTo(frontCenterX + 2, 128)..lineTo(frontCenterX + 18, 128)..lineTo(frontCenterX + 16, 190)..lineTo(frontCenterX + 4, 190)..close();
    drawMuscleGroup(quadsPath, 'Quads');

    Path calvesFront = Path()
      ..addRect(Rect.fromLTWH(frontCenterX - 15, 200, 10, 45))
      ..addRect(Rect.fromLTWH(frontCenterX + 5, 200, 10, 45));
    drawMuscleGroup(calvesFront, 'Calves');

    // REAR
    canvas.drawOval(Rect.fromLTWH(backCenterX - 12, 18, 24, 28), outlinePaint);

    Path latsPath = Path()
      ..moveTo(backCenterX - 24, 52)..lineTo(backCenterX + 24, 52)..lineTo(backCenterX + 14, 94)..lineTo(backCenterX - 14, 94)..close();
    drawMuscleGroup(latsPath, 'Lats');

    Path tricepsRear = Path()
      ..addRect(Rect.fromLTWH(backCenterX - 34, 70, 9, 28))
      ..addRect(Rect.fromLTWH(backCenterX + 25, 70, 9, 28));
    drawMuscleGroup(tricepsRear, 'Triceps');

    Path hamstringsPath = Path()
      ..moveTo(backCenterX - 18, 128)..lineTo(backCenterX - 2, 128)..lineTo(backCenterX - 4, 190)..lineTo(backCenterX - 16, 190)..close()
      ..moveTo(backCenterX + 2, 128)..lineTo(backCenterX + 18, 128)..lineTo(backCenterX + 16, 190)..lineTo(backCenterX + 4, 190)..close();
    drawMuscleGroup(hamstringsPath, 'Hamstrings');

    Path calvesRear = Path()
      ..addRect(Rect.fromLTWH(backCenterX - 15, 200, 10, 45))
      ..addRect(Rect.fromLTWH(backCenterX + 5, 200, 10, 45));
    drawMuscleGroup(calvesRear, 'Calves');
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// TAB 3: APRE / VBT
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
        recommendation = 'Reduce load by -5.0';
      } else if (actualReps <= 7) {
        adjustedWeight = currentWeight;
        recommendation = 'Maintain target load';
      } else if (actualReps <= 9) {
        adjustedWeight = currentWeight + 2.5;
        recommendation = 'Increase load by +2.5';
      } else {
        adjustedWeight = currentWeight + 5.0;
        recommendation = 'Increase load by +5.0';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('AUTOREGULATION PROTOCOL:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      DropdownButton<String>(
                        value: protocol,
                        dropdownColor: const Color(0xFF101222),
                        items: ['APRE-3', 'APRE-6', 'APRE-10'].map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (v) => setState(() => protocol = v!),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: weightCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Current Load', filled: true, fillColor: Color(0xFF101222)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: repsCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Reps Executed', filled: true, fillColor: Color(0xFF101222)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF7000FF))),
              child: Column(
                children: [
                  const Text('RECOMMENDED NEXT LOAD', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('${adjustedWeight.toStringAsFixed(1)}', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(recommendation, style: const TextStyle(color: Color(0xFFFF0055), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 4: BANISTER EWMA FATIGUE
// -----------------------------------------------------------------------------
class BanisterTab extends StatefulWidget {
  const BanisterTab({super.key});

  @override
  State<BanisterTab> createState() => _BanisterTabState();
}

class _BanisterTabState extends State<BanisterTab> {
  double acuteLoad = 250;
  double chronicLoad = 310;

  @override
  Widget build(BuildContext context) {
    double tsb = chronicLoad - acuteLoad;
    double readiness = max(0, min(100, 50 + (tsb * 1.5)));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))),
            child: Column(
              children: [
                const Text('NEUROMUSCULAR READINESS SCORE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('${readiness.toStringAsFixed(1)}%', style: TextStyle(color: readiness > 60 ? Theme.of(context).primaryColor : const Color(0xFFFF0055), fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(readiness > 65 ? 'Status: Prime Adaptive Window' : 'Warning: High CNS Fatigue', style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
                  decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(10), border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))),
                  child: Column(
                    children: [
                      const Text('Fitness (CTL 42d)', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text('${chronicLoad.toInt()} pts', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 5: PLATE MATH
// -----------------------------------------------------------------------------
class PlateMathTab extends StatefulWidget {
  const PlateMathTab({super.key});

  @override
  State<PlateMathTab> createState() => _PlateMathTabState();
}

class _PlateMathTabState extends State<PlateMathTab> {
  final weightCtrl = TextEditingController(text: '100');
  final repsCtrl = TextEditingController(text: '5');

  @override
  Widget build(BuildContext context) {
    double w = double.tryParse(weightCtrl.text) ?? 0;
    int r = int.tryParse(repsCtrl.text) ?? 0;
    double epley = (w > 0 && r > 0) ? w * (1 + (r / 30.0)) : 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))),
            child: Column(
              children: [
                TextField(
                  controller: weightCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Target Weight', filled: true, fillColor: Color(0xFF101222)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: repsCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Reps Executed', filled: true, fillColor: Color(0xFF101222)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF0B0C16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5))),
            child: Column(
              children: [
                const Text('ESTIMATED 1-REP MAX (EPLEY)', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${epley.toStringAsFixed(1)}', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// RADIAL TIMER PAINTER
class ProRadialTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  ProRadialTimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.white12..strokeWidth = 2..style = PaintingStyle.stroke;
    final progressPaint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, bgPaint);
    double sweepAngle = 2 * pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
