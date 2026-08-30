import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const GymApp());

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121218),
        primaryColor: Colors.cyanAccent,
      ),
      home: const WeeklyPlannerScreen(),
    );
  }
}

class WeeklyPlannerScreen extends StatefulWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  State<WeeklyPlannerScreen> createState() => _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends State<WeeklyPlannerScreen> {
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
    final savedRestDays = prefs.getStringList('rest_days');
    if (savedRestDays != null && savedRestDays.length == 2) {
      setState(() {
        restDays = savedRestDays.toSet();
      });
    }
  }

  Future<void> _saveRestDays() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('rest_days', restDays.toList());
  }

  void _toggleRestDay(String day) {
    setState(() {
      if (restDays.contains(day)) {
        if (restDays.length > 1) restDays.remove(day);
      } else {
        if (restDays.length < 2) restDays.add(day);
      }
    });
    _saveRestDays();
  }

  @override
  Widget build(BuildContext context) {
    int activeDayIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Master', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select 2 Rest Days:',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: weekDays.map((day) {
                final isRest = restDays.contains(day);
                return ChoiceChip(
                  label: Text(day),
                  selected: isRest,
                  selectedColor: Colors.redAccent,
                  onSelected: (_) => _toggleRestDay(day),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) {
                  final dayName = weekDays[index];
                  final isRest = restDays.contains(dayName);
                  
                  String assignedMuscle = 'Rest Day';
                  if (!isRest) {
                    assignedMuscle = muscleSplits[activeDayIndex % muscleSplits.length];
                    activeDayIndex++;
                  }

                  return Card(
                    color: isRest ? const Color(0xFF1E1E26) : const Color(0xFF1E1E38),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                        isRest ? Icons.nightlife : Icons.fitness_center,
                        color: isRest ? Colors.orangeAccent : Colors.cyanAccent,
                      ),
                      title: Text('$dayName: $assignedMuscle', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(isRest ? 'Rest & Recovery' : 'Tap to manage exercises'),
                      trailing: isRest ? null : const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: isRest
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExerciseDetailScreen(
                                    dayKey: dayName,
                                    muscleGroup: assignedMuscle,
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

class ExerciseDetailScreen extends StatefulWidget {
  final String dayKey;
  final String muscleGroup;

  const ExerciseDetailScreen({
    super.key,
    required this.dayKey,
    required this.muscleGroup,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  List<Map<String, String>> exercises = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString('workout_${widget.dayKey}');
    if (rawJson != null) {
      final List<dynamic> decoded = jsonDecode(rawJson);
      setState(() {
        exercises = decoded.map((item) => Map<String, String>.from(item)).toList();
      });
    }
  }

  Future<void> _saveExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(exercises);
    await prefs.setString('workout_${widget.dayKey}', encoded);
  }

  void _addExercise(String name, String equipment, String sets, String reps) {
    setState(() {
      exercises.add({
        'name': name,
        'equipment': equipment,
        'sets': sets,
        'reps': reps,
      });
    });
    _saveExercises();
  }

  void _removeExercise(int index) {
    setState(() {
      exercises.removeAt(index);
    });
    _saveExercises();
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final equipController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${widget.muscleGroup} Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Exercise Name')),
            TextField(controller: equipController, decoration: const InputDecoration(labelText: 'Equipment / Machine')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _addExercise(nameController.text, equipController.text, '3', '10-12');
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.dayKey} - ${widget.muscleGroup}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: exercises.isEmpty
                  ? const Center(child: Text('No exercises saved for this day.'))
                  : ListView.builder(
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final ex = exercises[index];
                        return Card(
                          color: const Color(0xFF1E1E2C),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                              child: Text('${index + 1}', style: const TextStyle(color: Colors.cyanAccent)),
                            ),
                            title: Text(ex['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(ex['equipment']!),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _removeExercise(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('ADD EXERCISE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
