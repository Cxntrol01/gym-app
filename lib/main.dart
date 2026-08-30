import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const GymMasterApp());

class GymMasterApp extends StatelessWidget {
  const GymMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Master',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F14),
        cardColor: const Color(0xFF181822),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF7C4DFF),
          surface: Color(0xFF181822),
        ),
      ),
      home: const MainHomeScreen(),
    );
  }
}

// Built-in Exercise Database
final Map<String, List<Map<String, String>>> exerciseDatabase = {
  'Chest & Triceps': [
    {'name': 'Barbell Bench Press', 'equipment': 'Barbell / Flat Bench'},
    {'name': 'Incline Dumbbell Press', 'equipment': 'Dumbbells / Incline Bench'},
    {'name': 'Cable Flyes', 'equipment': 'Cable Station'},
    {'name': 'Triceps Rope Pushdown', 'equipment': 'Cable Station'},
    {'name': 'Skull Crushers', 'equipment': 'EZ-Bar / Bench'},
  ],
  'Back & Biceps': [
    {'name': 'Lat Pulldown', 'equipment': 'Lat Pulldown Machine'},
    {'name': 'Seated Cable Row', 'equipment': 'Cable Machine'},
    {'name': 'Bent Over Barbell Row', 'equipment': 'Barbell'},
    {'name': 'Incline Dumbbell Curl', 'equipment': 'Dumbbells'},
    {'name': 'Preacher Curl', 'equipment': 'Preacher Machine'},
  ],
  'Legs & Calves': [
    {'name': 'Barbell Back Squat', 'equipment': 'Squat Rack'},
    {'name': 'Leg Press', 'equipment': 'Leg Press Machine'},
    {'name': 'Lying Leg Curl', 'equipment': 'Hamstring Machine'},
    {'name': 'Leg Extension', 'equipment': 'Quad Machine'},
    {'name': 'Standing Calf Raise', 'equipment': 'Calf Machine'},
  ],
  'Shoulders & Abs': [
    {'name': 'Overhead Dumbbell Press', 'equipment': 'Dumbbells'},
    {'name': 'Cable Lateral Raise', 'equipment': 'Cable Station'},
    {'name': 'Reverse Pec Deck Fly', 'equipment': 'Fly Machine'},
    {'name': 'Hanging Leg Raise', 'equipment': 'Pull-up Bar'},
    {'name': 'Ab Wheel Rollout', 'equipment': 'Ab Wheel'},
  ],
  'Arms Focus': [
    {'name': 'Barbell Bicep Curl', 'equipment': 'Barbell'},
    {'name': 'Hammer Curls', 'equipment': 'Dumbbells'},
    {'name': 'Dips', 'equipment': 'Dip Station'},
    {'name': 'Overhead Triceps Extension', 'equipment': 'Cable Station'},
  ]
};

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  Set<String> restDays = {'Wed', 'Sun'};
  
  final List<String> muscleSplits = [
    'Chest & Triceps',
    'Back & Biceps',
    'Legs & Calves',
    'Shoulders & Abs',
    'Arms Focus'
  ];

  @override
  void initState() {
    super.initState();
    _loadRestDays();
  }

  Future<void> _loadRestDays() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('user_rest_days');
    if (saved != null && saved.length == 2) {
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
    int activeIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GYM MASTER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SELECT 2 REST DAYS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isRest ? Colors.redAccent : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
            const Text('WEEKLY SCHEDULE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) {
                  final dayName = weekDays[index];
                  final isRest = restDays.contains(dayName);
                  
                  String assignedGroup = 'Rest & Recovery';
                  if (!isRest) {
                    assignedGroup = muscleSplits[activeIndex % muscleSplits.length];
                    activeIndex++;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isRest ? const Color(0xFF14141B) : const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isRest ? Colors.transparent : const Color(0xFF00E5FF).withOpacity(0.3)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRest ? Colors.orange.withOpacity(0.1) : const Color(0xFF00E5FF).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRest ? Icons.bedtime : Icons.fitness_center,
                          color: isRest ? Colors.orange : const Color(0xFF00E5FF),
                        ),
                      ),
                      title: Text(
                        '$dayName: $assignedGroup',
                        style: TextStyle(
                          color: isRest ? Colors.white38 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        isRest ? 'Muscle Growth Happens Here' : 'Tap to manage & track exercises',
                        style: TextStyle(color: isRest ? Colors.white24 : Colors.grey[400], fontSize: 12),
                      ),
                      trailing: isRest ? null : const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF00E5FF)),
                      onTap: isRest ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutTrackScreen(
                              dayName: dayName,
                              muscleGroup: assignedGroup,
                            ),
                          ),
                        );
                      },
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

class WorkoutTrackScreen extends StatefulWidget {
  final String dayName;
  final String muscleGroup;

  const WorkoutTrackScreen({super.key, required this.dayName, required this.muscleGroup});

  @override
  State<WorkoutTrackScreen> createState() => _WorkoutTrackScreenState();
}

class _WorkoutTrackScreenState extends State<WorkoutTrackScreen> {
  List<Map<String, dynamic>> activeExercises = [];
  int restTimerSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('day_${widget.dayName}');
    if (raw != null) {
      setState(() {
        activeExercises = List<Map<String, dynamic>>.from(jsonDecode(raw));
      });
    } else {
      final defaults = exerciseDatabase[widget.muscleGroup] ?? [];
      setState(() {
        activeExercises = defaults.map((e) => {
          'name': e['name'],
          'equipment': e['equipment'],
          'sets': 3,
          'reps': '8-12',
          'completedSets': 0,
        }).toList();
      });
      _saveExercises();
    }
  }

  Future<void> _saveExercises() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('day_${widget.dayName}', jsonEncode(activeExercises));
  }

  void _startRestTimer(int seconds) {
    _timer?.cancel();
    setState(() => restTimerSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (restTimerSeconds > 0) {
        setState(() => restTimerSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  void _addExerciseFromLibrary(Map<String, String> item) {
    setState(() {
      activeExercises.add({
        'name': item['name'],
        'equipment': item['equipment'],
        'sets': 3,
        'reps': '10-12',
        'completedSets': 0,
      });
    });
    _saveExercises();
  }

  void _showAddModal() {
    final presets = exerciseDatabase[widget.muscleGroup] ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14141E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add ${widget.muscleGroup} Exercise', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: presets.length,
                  itemBuilder: (context, i) {
                    final item = presets[i];
                    return ListTile(
                      title: Text(item['name']!),
                      subtitle: Text(item['equipment']!),
                      trailing: const Icon(Icons.add_circle, color: Color(0xFF00E5FF)),
                      onTap: () {
                        _addExerciseFromLibrary(item);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.dayName}: ${widget.muscleGroup}'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (restTimerSeconds > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00E5FF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 8),
                    Text(
                      'Rest Timer: ${restTimerSeconds}s',
                      style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: activeExercises.length,
                itemBuilder: (context, index) {
                  final ex = activeExercises[index];
                  final sets = ex['sets'] as int;
                  final completed = ex['completedSets'] as int;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(ex['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                setState(() => activeExercises.removeAt(index));
                                _saveExercises();
                              },
                            ),
                          ],
                        ),
                        Text('Target: ${ex['equipment']} • ${ex['sets']} sets x ${ex['reps']} reps', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Completed Sets:', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 10),
                            Wrap(
                              spacing: 6,
                              children: List.generate(sets, (sIndex) {
                                final isDone = sIndex < completed;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      ex['completedSets'] = isDone ? sIndex : sIndex + 1;
                                    });
                                    _saveExercises();
                                    if (!isDone) _startRestTimer(60);
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isDone ? const Color(0xFF00E5FF) : Colors.black26,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isDone ? const Color(0xFF00E5FF) : Colors.white24),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${sIndex + 1}',
                                        style: TextStyle(
                                          color: isDone ? Colors.black : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _showAddModal,
              icon: const Icon(Icons.add),
              label: const Text('ADD EXERCISE TO WORKOUT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
