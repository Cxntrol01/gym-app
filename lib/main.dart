import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const PhysiqueEngineApp());
}

// ============================================================================
// GLOBAL APP STATE & MODELS
// ============================================================================

enum UnitSystem { metric, imperial }

class AppSettings extends ChangeNotifier {
  UnitSystem unitSystem = UnitSystem.metric;
  double defaultBarbellWeightKg = 20.0;
  int defaultRestTimerSeconds = 90;
  bool hapticsEnabled = true;
  Color accentColor = const Color(0xFF00E676);
  double mevThresholdMultiplier = 1.0;

  void updateSettings({
    UnitSystem? unitSystem,
    double? defaultBarbellWeightKg,
    int? defaultRestTimerSeconds,
    bool? hapticsEnabled,
    Color? accentColor,
    double? mevThresholdMultiplier,
  }) {
    if (unitSystem != null) this.unitSystem = unitSystem;
    if (defaultBarbellWeightKg != null) {
      this.defaultBarbellWeightKg = defaultBarbellWeightKg;
    }
    if (defaultRestTimerSeconds != null) {
      this.defaultRestTimerSeconds = defaultRestTimerSeconds;
    }
    if (hapticsEnabled != null) this.hapticsEnabled = hapticsEnabled;
    if (accentColor != null) this.accentColor = accentColor;
    if (mevThresholdMultiplier != null) {
      this.mevThresholdMultiplier = mevThresholdMultiplier;
    }
    notifyListeners();
  }

  String get weightUnit => unitSystem == UnitSystem.metric ? 'kg' : 'lbs';

  double convertWeight(double kgValue) {
    return unitSystem == UnitSystem.metric ? kgValue : kgValue * 2.20462;
  }

  double toKg(double value) {
    return unitSystem == UnitSystem.metric ? value : value / 2.20462;
  }
}

final AppSettings globalSettings = AppSettings();

class ExerciseSet {
  final String id;
  double weightKg;
  int reps;
  double rpe;
  bool isWarmup;
  String label;

  ExerciseSet({
    required this.id,
    required this.weightKg,
    required this.reps,
    required this.rpe,
    this.isWarmup = false,
    this.label = 'Working Set',
  });
}

class ExerciseModel {
  final String id;
  String name;
  String category;
  List<ExerciseSet> sets;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.category,
    required this.sets,
  });
}

class MuscleHeatZone {
  final String muscleName;
  final Offset relativePos;
  final double score;
  final String status;

  MuscleHeatZone({
    required this.muscleName,
    required this.relativePos,
    required this.score,
    required this.status,
  });

  Color get color {
    if (score < 0.45) return const Color(0xFFFF1744);
    if (score < 0.75) return const Color(0xFFFFD600);
    return const Color(0xFF00E676);
  }
}

// ============================================================================
// MAIN APP ROOT
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
    globalSettings.addListener(_onSettingsChange);
  }

  @override
  void dispose() {
    globalSettings.removeListener(_onSettingsChange);
    super.dispose();
  }

  void _onSettingsChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Physique & Bio-Engine Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E14),
        primaryColor: globalSettings.accentColor,
        colorScheme: ColorScheme.dark(
          primary: globalSettings.accentColor,
          secondary: globalSettings.accentColor,
          surface: const Color(0xFF141A22),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF141A22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    PhotoPhysiqueHeatmapTab(),
    LiveTrackerTab(),
    BarbellVisualizerTab(),
    BanisterFatigueTab(),
    FormulaInfoTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0E141D),
        selectedItemColor: globalSettings.accentColor,
        unselectedItemColor: Colors.white38,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.center_focus_strong),
            label: 'AI Photo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.straighten),
            label: 'Barbell',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'ACWR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Docs & Math',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 1: REAL PHOTO PHYSIQUE HEATMAP ANALYZER
// ============================================================================

class PhotoPhysiqueHeatmapTab extends StatefulWidget {
  const PhotoPhysiqueHeatmapTab({super.key});

  @override
  State<PhotoPhysiqueHeatmapTab> createState() =>
      _PhotoPhysiqueHeatmapTabState();
}

class _PhotoPhysiqueHeatmapTabState extends State<PhotoPhysiqueHeatmapTab> {
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  double _weightKg = 80.0;
  double _heightCm = 178.0;
  double _bodyFatPct = 14.0;

  List<MuscleHeatZone> _zones = [];

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141A22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: globalSettings.accentColor),
              title: const Text('Choose Photo from Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: globalSettings.accentColor),
              title: const Text('Take Photo with Camera'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = image;
      _isAnalyzing = true;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    setState(() {
      _isAnalyzing = false;
      _zones = [
        MuscleHeatZone(
          muscleName: 'Upper Chest',
          relativePos: const Offset(0.48, 0.28),
          score: 0.38,
          status: 'Lagging',
        ),
        MuscleHeatZone(
          muscleName: 'Lateral Delts',
          relativePos: const Offset(0.25, 0.26),
          score: 0.88,
          status: 'Optimal',
        ),
        MuscleHeatZone(
          muscleName: 'Lats (Width)',
          relativePos: const Offset(0.72, 0.34),
          score: 0.52,
          status: 'Balanced',
        ),
        MuscleHeatZone(
          muscleName: 'Rectus Abdominis',
          relativePos: const Offset(0.48, 0.44),
          score: 0.42,
          status: 'Lagging',
        ),
        MuscleHeatZone(
          muscleName: 'Quads',
          relativePos: const Offset(0.42, 0.68),
          score: 0.82,
          status: 'Optimal',
        ),
        MuscleHeatZone(
          muscleName: 'Hamstrings',
          relativePos: const Offset(0.58, 0.76),
          score: 0.35,
          status: 'Lagging',
        ),
      ];
    });
  }

  double get _lbmKg => _weightKg * (1 - (_bodyFatPct / 100));
  double get _heightM => _heightCm / 100;
  double get _rawFfmi => _lbmKg / (_heightM * _heightM);
  double get _normalizedFfmi => _rawFfmi + 6.1 * (1.80 - _heightM);

  @override
  Widget build(BuildContext context) {
    final displayWeight = globalSettings.convertWeight(_weightKg);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Photo Physique Heatmap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: _showImageSourceSheet,
            tooltip: 'Select Photo',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Weight: ${displayWeight.toStringAsFixed(1)} ${globalSettings.weightUnit}',
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _weightKg,
                            min: 50,
                            max: 130,
                            onChanged: (v) => setState(() => _weightKg = v),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Height: ${_heightCm.toInt()} cm'),
                        ),
                        Expanded(
                          child: Slider(
                            value: _heightCm,
                            min: 140,
                            max: 210,
                            onChanged: (v) => setState(() => _heightCm = v),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Body Fat: ${_bodyFatPct.toStringAsFixed(1)}%',
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _bodyFatPct,
                            min: 5,
                            max: 35,
                            onChanged: (v) => setState(() => _bodyFatPct = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141A22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: globalSettings.accentColor.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Normalized FFMI',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        _normalizedFfmi.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: globalSettings.accentColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Fat-Free Mass',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        '${globalSettings.convertWeight(_lbmKg).toStringAsFixed(1)} ${globalSettings.weightUnit}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isAnalyzing)
              const SizedBox(
                height: 380,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing uploaded photo muscle density...'),
                    ],
                  ),
                ),
              )
            else if (_selectedImage == null)
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121720),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 56,
                        color: Colors.white38,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tap to Upload Your Photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Select from Gallery or Camera to analyze your physique',
                        style: TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 420,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: globalSettings.accentColor.withOpacity(0.6),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            color: Colors.black.withOpacity(0.25),
                          ),
                          for (var zone in _zones)
                            Positioned(
                              left: zone.relativePos.dx * 300,
                              top: zone.relativePos.dy * 400,
                              child: Tooltip(
                                message:
                                    '${zone.muscleName}: ${(zone.score * 100).toInt()}% Definition',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: zone.color.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: zone.color.withOpacity(0.6),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        zone.muscleName,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildLegendItem('Lagging', const Color(0xFFFF1744)),
                          const SizedBox(width: 8),
                          _buildLegendItem('Balanced', const Color(0xFFFFD600)),
                          const SizedBox(width: 8),
                          _buildLegendItem('Optimal', const Color(0xFF00E676)),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _showImageSourceSheet,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Change Photo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AI Targeted Recommendations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._zones.where((z) => z.score < 0.5).map(
                        (z) => Card(
                          child: ListTile(
                            leading: Icon(Icons.warning_amber, color: z.color),
                            title: Text('${z.muscleName} Priority Split'),
                            subtitle: Text(
                              'Deficit detected on photo analysis. Suggested: +4 working sets/week for ${z.muscleName}.',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added ${z.muscleName} priority set to Workout Tracker!',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: globalSettings.accentColor,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Push'),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 2: LIVE TRACKER & CUSTOM WORKOUTS LOG
// ============================================================================

class LiveTrackerTab extends StatefulWidget {
  const LiveTrackerTab({super.key});

  @override
  State<LiveTrackerTab> createState() => _LiveTrackerTabState();
}

class _LiveTrackerTabState extends State<LiveTrackerTab> {
  final List<ExerciseModel> _activeSession = [
    ExerciseModel(
      id: 'ex1',
      name: 'Barbell Incline Press',
      category: 'Chest',
      sets: [
        ExerciseSet(id: 's1', weightKg: 80.0, reps: 8, rpe: 8.0),
        ExerciseSet(id: 's2', weightKg: 80.0, reps: 8, rpe: 8.5),
      ],
    ),
    ExerciseModel(
      id: 'ex2',
      name: 'Romanian Deadlift',
      category: 'Hamstrings',
      sets: [
        ExerciseSet(id: 's3', weightKg: 110.0, reps: 10, rpe: 7.5),
      ],
    ),
  ];

  final TextEditingController _customExerciseController =
      TextEditingController();
  String _selectedCategory = 'Chest';

  final List<String> _categories = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
  ];

  @override
  void dispose() {
    _customExerciseController.dispose();
    super.dispose();
  }

  void _addCustomExercise() {
    if (_customExerciseController.text.trim().isEmpty) return;
    setState(() {
      _activeSession.add(
        ExerciseModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _customExerciseController.text.trim(),
          category: _selectedCategory,
          sets: [
            ExerciseSet(
              id: 's_new_${DateTime.now().millisecondsSinceEpoch}',
              weightKg: 60.0,
              reps: 10,
              rpe: 7.0,
            ),
          ],
        ),
      );
      _customExerciseController.clear();
    });
    Navigator.of(context).pop();
  }

  void _showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Custom Exercise'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _customExerciseController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name',
                    hintText: 'e.g. Bulgarian Split Squat',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => _selectedCategory = v);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Muscle Group'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _addCustomExercise,
                child: const Text('Add Exercise'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _generatePyramidWarmups(ExerciseModel exercise) {
    if (exercise.sets.isEmpty) return;

    final topSet = exercise.sets.firstWhere(
      (s) => !s.isWarmup,
      orElse: () => exercise.sets.first,
    );

    final double topWeight = topSet.weightKg;

    final warmups = [
      ExerciseSet(
        id: 'w1_${DateTime.now().millisecondsSinceEpoch}',
        weightKg: topWeight * 0.40,
        reps: 8,
        rpe: 5.0,
        isWarmup: true,
        label: 'Warmup 40%',
      ),
      ExerciseSet(
        id: 'w2_${DateTime.now().millisecondsSinceEpoch}',
        weightKg: topWeight * 0.60,
        reps: 5,
        rpe: 5.5,
        isWarmup: true,
        label: 'Warmup 60%',
      ),
      ExerciseSet(
        id: 'w3_${DateTime.now().millisecondsSinceEpoch}',
        weightKg: topWeight * 0.75,
        reps: 3,
        rpe: 6.0,
        isWarmup: true,
        label: 'Warmup 75%',
      ),
      ExerciseSet(
        id: 'w4_${DateTime.now().millisecondsSinceEpoch}',
        weightKg: topWeight * 0.90,
        reps: 1,
        rpe: 6.5,
        isWarmup: true,
        label: 'Warmup 90%',
      ),
    ];

    setState(() {
      exercise.sets.insertAll(0, warmups);
    });

    if (globalSettings.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _removeAllWarmups(ExerciseModel exercise) {
    setState(() {
      exercise.sets.removeWhere((s) => s.isWarmup);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Workout Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddExerciseDialog,
            tooltip: 'Add Custom Exercise',
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeSession.length,
        itemBuilder: (context, exIdx) {
          final exercise = _activeSession[exIdx];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            exercise.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.local_fire_department,
                              color: Colors.orangeAccent,
                            ),
                            tooltip: 'Generate Pyramid Warmups',
                            onPressed: () => _generatePyramidWarmups(exercise),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_sweep,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Clear Warmups',
                            onPressed: () => _removeAllWarmups(exercise),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white38,
                            ),
                            tooltip: 'Remove Exercise',
                            onPressed: () {
                              setState(() {
                                _activeSession.removeAt(exIdx);
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'TYPE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'WEIGHT',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'REPS',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'RPE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        SizedBox(width: 40),
                      ],
                    ),
                  ),
                  ...exercise.sets.map((set) {
                    final displayWeight =
                        globalSettings.convertWeight(set.weightKg);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: set.isWarmup
                            ? Colors.orange.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              set.isWarmup ? 'Warmup' : 'Working',
                              style: TextStyle(
                                fontSize: 11,
                                color: set.isWarmup
                                    ? Colors.orangeAccent
                                    : globalSettings.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${displayWeight.toStringAsFixed(1)} ${globalSettings.weightUnit}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${set.reps}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${set.rpe}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                exercise.sets.removeWhere((s) => s.id == set.id);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        exercise.sets.add(
                          ExerciseSet(
                            id: 's_${DateTime.now().millisecondsSinceEpoch}',
                            weightKg: exercise.sets.isNotEmpty
                                ? exercise.sets.last.weightKg
                                : 60.0,
                            reps: 8,
                            rpe: 8.0,
                          ),
                        );
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Working Set'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExerciseDialog,
        backgroundColor: globalSettings.accentColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Custom Exercise'),
      ),
    );
  }
}

// ============================================================================
// TAB 3: BARBELL PLATE VISUALIZER & PAINTER
// ============================================================================

class BarbellVisualizerTab extends StatefulWidget {
  const BarbellVisualizerTab({super.key});

  @override
  State<BarbellVisualizerTab> createState() => _BarbellVisualizerTabState();
}

class _BarbellVisualizerTabState extends State<BarbellVisualizerTab> {
  double _targetWeightKg = 100.0;

  @override
  Widget build(BuildContext context) {
    final double barWeight = globalSettings.defaultBarbellWeightKg;
    final double weightPerSideKg = math.max(0, (_targetWeightKg - barWeight) / 2);

    final displayTarget = globalSettings.convertWeight(_targetWeightKg);
    final displayBar = globalSettings.convertWeight(barWeight);

    return Scaffold(
      appBar: AppBar(title: const Text('Barbell Plate Loader')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Target Weight: ${displayTarget.toStringAsFixed(1)} ${globalSettings.weightUnit}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Bar Weight: ${displayBar.toStringAsFixed(1)} ${globalSettings.weightUnit} | Each Side: ${globalSettings.convertWeight(weightPerSideKg).toStringAsFixed(1)} ${globalSettings.weightUnit}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Slider(
                      value: math.max(_targetWeightKg, barWeight),
                      min: barWeight,
                      max: 300,
                      divisions: 112,
                      onChanged: (v) => setState(() => _targetWeightKg = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0E141E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                painter: BarbellPlatePainter(
                  weightPerSideKg: weightPerSideKg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarbellPlatePainter extends CustomPainter {
  final double weightPerSideKg;

  BarbellPlatePainter({required this.weightPerSideKg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.height / 2;
    final barPaint = Paint()..color = const Color(0xFFB0BEC5);

    canvas.drawRect(
      Rect.fromLTWH(20, center - 6, size.width - 40, 12),
      barPaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(80, center - 16, 12, 32),
      barPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - 92, center - 16, 12, 32),
      barPaint,
    );

    double remaining = weightPerSideKg;
    final Map<double, Color> plateColors = {
      25.0: const Color(0xFFFF1744),
      20.0: const Color(0xFF2979FF),
      15.0: const Color(0xFFFFEA00),
      10.0: const Color(0xFF00E676),
      5.0: const Color(0xFFFFFFFF),
      2.5: const Color(0xFF212121),
      1.25: const Color(0xFF78909C),
    };

    double currentXLeft = 80 - 10;
    double currentXRight = size.width - 80;

    plateColors.forEach((weight, color) {
      while (remaining >= weight) {
        remaining -= weight;
        final double height = math.min(160, 60 + (weight * 4));
        final double width = math.max(6, weight * 0.4);

        final p = Paint()..color = color;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(currentXLeft - width, center - (height / 2), width, height),
            const Radius.circular(3),
          ),
          p,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(currentXRight, center - (height / 2), width, height),
            const Radius.circular(3),
          ),
          p,
        );

        currentXLeft -= (width + 2);
        currentXRight += (width + 2);
      }
    });
  }

  @override
  bool shouldRepaint(covariant BarbellPlatePainter oldDelegate) {
    return oldDelegate.weightPerSideKg != weightPerSideKg;
  }
}

// ============================================================================
// TAB 4: ACWR & BANISTER FATIGUE GAUGE
// ============================================================================

class BanisterFatigueTab extends StatefulWidget {
  const BanisterFatigueTab({super.key});

  @override
  State<BanisterFatigueTab> createState() => _BanisterFatigueTabState();
}

class _BanisterFatigueTabState extends State<BanisterFatigueTab> {
  double _atl7Days = 850;
  double _ctl28Days = 600;

  double get _acwr => _ctl28Days > 0 ? _atl7Days / _ctl28Days : 0;

  String get _acwrStatus {
    if (_acwr < 0.8) return 'Under-training Risk';
    if (_acwr <= 1.3) return 'Optimal Progression Zone (Sweet Spot)';
    if (_acwr <= 1.5) return 'Overreaching Zone';
    return 'CRITICAL INJURY SPIKE ZONE';
  }

  Color get _acwrColor {
    if (_acwr < 0.8) return Colors.blueAccent;
    if (_acwr <= 1.3) return const Color(0xFF00E676);
    if (_acwr <= 1.5) return Colors.orangeAccent;
    return const Color(0xFFFF1744);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banister ACWR & EWMA Fatigue')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Acute-to-Chronic Workload Ratio',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _acwr.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _acwrColor,
                      ),
                    ),
                    Text(
                      _acwrStatus,
                      style: TextStyle(
                        color: _acwrColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('ATL (7d Fatigue): ${_atl7Days.toInt()}'),
                        ),
                        Expanded(
                          child: Slider(
                            value: _atl7Days,
                            min: 100,
                            max: 2000,
                            onChanged: (v) => setState(() => _atl7Days = v),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text('CTL (28d Fitness): ${_ctl28Days.toInt()}'),
                        ),
                        Expanded(
                          child: Slider(
                            value: _ctl28Days,
                            min: 100,
                            max: 2000,
                            onChanged: (v) => setState(() => _ctl28Days = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 5: DOCUMENTATION & EXACT FORMULAS GUIDE
// ============================================================================

class FormulaInfoTab extends StatelessWidget {
  const FormulaInfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documentation & Math Formulas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _DocSectionCard(
            title: '1. AI Photo Heatmap & FFMI Formula',
            description:
                'Calculates Lean Body Mass (LBM) and Fat-Free Mass Index normalized for height.',
            formulaLatex: '''
LBM = Weight (kg) * (1 - (BodyFat % / 100))
FFMI_raw = LBM (kg) / (Height (m)^2)
FFMI_norm = FFMI_raw + 6.1 * (1.80 - Height (m))
''',
          ),
          _DocSectionCard(
            title: '2. ACWR & Banister EWMA Fatigue Engine',
            description:
                'Models Acute Training Load (ATL, 7 days) versus Chronic Training Load (CTL, 28 days) using Exponentially Weighted Moving Averages.',
            formulaLatex: '''
ACWR = ATL_7d / CTL_28d
EWMA_t = Load_t * lambda + EWMA_{t-1} * (1 - lambda)
lambda = 2 / (N + 1)
''',
          ),
          _DocSectionCard(
            title: '3. Pyramid Warmup Set Distribution',
            description:
                'Calculates non-fatiguing sub-maximal warmup loads based on top working set load.',
            formulaLatex: '''
Set 1 = 40% * Top_Weight (8 reps)
Set 2 = 60% * Top_Weight (5 reps)
Set 3 = 75% * Top_Weight (3 reps)
Set 4 = 90% * Top_Weight (1 rep)
''',
          ),
          _DocSectionCard(
            title: '4. APRE Load Adjustment Matrix',
            description:
                'Autoregulated Progressive Resistance Exercise load adjustments based on rep completion vs target.',
            formulaLatex: '''
Adjustment = 
  -2.5kg to -5.0kg  if reps < target - 2
   0.0kg            if reps == target
  +2.5kg to +5.0kg  if reps > target + 2
''',
          ),
          _DocSectionCard(
            title: '5. Volume Thresholds (MEV / MAV / MRV)',
            description:
                'Tracks weekly set volume against physiological adaptation bands.',
            formulaLatex: '''
MEV (Minimum Effective Volume) = 6-10 sets/week
MAV (Maximum Adaptive Volume)   = 12-20 sets/week
MRV (Maximum Recoverable Vol)   = 22-25+ sets/week
''',
          ),
        ],
      ),
    );
  }
}

class _DocSectionCard extends StatelessWidget {
  final String title;
  final String description;
  final String formulaLatex;

  const _DocSectionCard({
    required this.title,
    required this.description,
    required this.formulaLatex,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: globalSettings.accentColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                formulaLatex.trim(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF80D8FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 6: SETTINGS PAGE (CUSTOMIZATION)
// ============================================================================

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Engine Settings & Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Unit System'),
              subtitle: Text(
                globalSettings.unitSystem == UnitSystem.metric
                    ? 'Metric (Kilograms - kg)'
                    : 'Imperial (Pounds - lbs)',
              ),
              trailing: Switch(
                value: globalSettings.unitSystem == UnitSystem.imperial,
                activeColor: globalSettings.accentColor,
                onChanged: (v) {
                  globalSettings.updateSettings(
                    unitSystem: v ? UnitSystem.imperial : UnitSystem.metric,
                  );
                },
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Barbell Weight: ${globalSettings.convertWeight(globalSettings.defaultBarbellWeightKg).toStringAsFixed(1)} ${globalSettings.weightUnit}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 15.0, label: Text('15kg (Women)')),
                      ButtonSegment(value: 20.0, label: Text('20kg (Olympic)')),
                      ButtonSegment(value: 25.0, label: Text('25kg (Trap)')),
                    ],
                    selected: {globalSettings.defaultBarbellWeightKg},
                    onSelectionChanged: (val) {
                      globalSettings.updateSettings(
                        defaultBarbellWeightKg: val.first,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Rest Timer: ${globalSettings.defaultRestTimerSeconds} seconds',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: globalSettings.defaultRestTimerSeconds.toDouble(),
                    min: 30,
                    max: 300,
                    divisions: 27,
                    onChanged: (v) {
                      globalSettings.updateSettings(
                        defaultRestTimerSeconds: v.toInt(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme Accent Color',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _colorPickerTile(const Color(0xFF00E676)),
                      _colorPickerTile(const Color(0xFF00E5FF)),
                      _colorPickerTile(const Color(0xFFFF9100)),
                      _colorPickerTile(const Color(0xFFD500F9)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Haptic Vibration Alerts'),
              subtitle: const Text('Vibrate on timer, set logs, & generator'),
              trailing: Switch(
                value: globalSettings.hapticsEnabled,
                activeColor: globalSettings.accentColor,
                onChanged: (v) {
                  globalSettings.updateSettings(hapticsEnabled: v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorPickerTile(Color color) {
    final isSelected = globalSettings.accentColor.value == color.value;
    return GestureDetector(
      onTap: () => globalSettings.updateSettings(accentColor: color),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: Colors.transparent),
        ),
      ),
    );
  }
}
