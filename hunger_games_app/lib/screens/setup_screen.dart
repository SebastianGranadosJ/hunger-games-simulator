import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';
import '../services/api_service.dart';
import 'simulation_screen.dart';

// The 8 default tributes loaded by the backend when use_default_tributes=true
const List<Map<String, dynamic>> kDefaultTributes = [
  {'name': 'Katniss Everdeen', 'gender': 'F', 'district': 12},
  {'name': 'Peeta Mellark', 'gender': 'M', 'district': 12},
  {'name': 'Cato', 'gender': 'M', 'district': 2},
  {'name': 'Clove', 'gender': 'F', 'district': 2},
  {'name': 'Finnick Odair', 'gender': 'M', 'district': 4},
  {'name': 'Glimmer', 'gender': 'F', 'district': 1},
  {'name': 'Marvel', 'gender': 'M', 'district': 1},
  {'name': 'Rue', 'gender': 'F', 'district': 11},
];

enum SetupMode { none, manual, defaultTributes }

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  SetupMode _mode = SetupMode.none;

  // How many tributes will enter the arena (chosen by the user)
  int _targetCount = 6;

  // Language selector
  String _language = 'English';
  final _customLanguageController = TextEditingController();
  bool _useCustomLanguage = false;

  // Manual tribute form
  final _nameController = TextEditingController();
  String _selectedGender = 'M';
  int _selectedDistrict = 1;
  final _imageUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Registered tributes (manual mode)
  final List<TributeInput> _tributes = [];

  // Image URLs map: name -> URL
  final Map<String, String> _tributeImages = {};

  // Default tribute image URL controllers
  final Map<String, TextEditingController> _defaultImageControllers = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final t in kDefaultTributes) {
      _defaultImageControllers[t['name'] as String] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customLanguageController.dispose();
    _imageUrlController.dispose();
    for (final c in _defaultImageControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _effectiveLanguage {
    if (_useCustomLanguage) {
      final custom = _customLanguageController.text.trim();
      return custom.isEmpty ? 'English' : custom;
    }
    return _language;
  }

  int get _maxCount => _mode == SetupMode.defaultTributes ? 8 : 10;

  /// Returns districts that still have room for at least one more tribute (< 2).
  List<int> get _availableDistricts => List.generate(12, (i) => i + 1)
      .where((d) => _tributes.where((t) => t.district == d).length < 2)
      .toList();

  int _tributesInDistrict(int district) =>
      _tributes.where((t) => t.district == district).length;

  /// If the currently selected district is now full, move to the next available one.
  void _ensureValidDistrict() {
    final available = _availableDistricts;
    if (!available.contains(_selectedDistrict)) {
      _selectedDistrict = available.isNotEmpty ? available.first : 1;
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _addTribute() {
    if (!_formKey.currentState!.validate()) return;
    if (_tributes.length >= _targetCount) return;

    final name = _nameController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    // Safety net: district capacity check
    if (_tributesInDistrict(_selectedDistrict) >= 2) {
      _showError('District $_selectedDistrict already has 2 tributes. Choose another district.');
      return;
    }

    setState(() {
      _tributes.add(TributeInput(
        name: name,
        gender: _selectedGender,
        district: _selectedDistrict,
      ));
      if (imageUrl.isNotEmpty) _tributeImages[name] = imageUrl;
      _nameController.clear();
      _imageUrlController.clear();
      _selectedGender = 'M';
      _ensureValidDistrict();
    });
  }

  void _removeTribute(int index) {
    setState(() {
      final name = _tributes[index].name;
      _tributes.removeAt(index);
      _tributeImages.remove(name);
      _ensureValidDistrict();
    });
  }

  Future<void> _startSimulation({required bool useDefault}) async {
    setState(() => _isLoading = true);

    try {
      final api = ApiService.instance;
      await api.resetSimulation();

      if (useDefault) {
        // Collect image URLs only for tributes that will participate
        final selected = kDefaultTributes.sublist(0, _targetCount);
        for (final t in selected) {
          final name = t['name'] as String;
          final url = _defaultImageControllers[name]?.text.trim() ?? '';
          if (url.isNotEmpty) _tributeImages[name] = url;
        }

        if (_targetCount == 8) {
          // Let the backend load all 8 defaults
          await api.startSimulation(
            language: _effectiveLanguage,
            useDefaultTributes: true,
          );
        } else {
          // Send the chosen subset explicitly
          final tributes = selected
              .map((t) => TributeInput(
                    name: t['name'] as String,
                    gender: t['gender'] as String,
                    district: t['district'] as int,
                  ))
              .toList();
          await api.startSimulation(
            tributes: tributes,
            language: _effectiveLanguage,
            useDefaultTributes: false,
          );
        }
      } else {
        await api.startSimulation(
          tributes: _tributes,
          language: _effectiveLanguage,
          useDefaultTributes: false,
        );
      }

      final status = await api.getStatus();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        _fadeRoute(SimulationScreen(
          tributeImages: Map<String, String>.from(_tributeImages),
          initialStatus: status,
        )),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _showError('Connection error. Is the backend running at $kBaseUrl?');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(color: AppColors.offWhite)),
        backgroundColor: AppColors.deathRedDark,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('REGISTER TRIBUTES'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: _mode == SetupMode.none
              ? () => Navigator.pop(context)
              : () => setState(() {
                    _mode = SetupMode.none;
                    _tributes.clear();
                    _tributeImages.clear();
                  }),
        ),
      ),
      body: _isLoading
          ? const _LoadingOverlay()
          : _mode == SetupMode.none
              ? _buildModeSelector()
              : _mode == SetupMode.manual
                  ? _buildManualSetup()
                  : _buildDefaultSetup(),
    );
  }

  // ── Mode selector ─────────────────────────────────────────────────────────

  Widget _buildModeSelector() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'SELECT YOUR TRIBUTE SOURCE',
              style: GoogleFonts.cinzel(
                fontSize: 13,
                color: AppColors.muted,
                letterSpacing: 2.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildLanguageSelector(),
            const SizedBox(height: 40),
            _ModeCard(
              title: 'REGISTER MANUALLY',
              subtitle: 'Create your own tributes.\n4–10 tributes, max 2 per district.',
              icon: Icons.edit_outlined,
              onTap: () => setState(() {
                _mode = SetupMode.manual;
                _targetCount = 6;
              }),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              title: 'USE DEFAULT TRIBUTES',
              subtitle: 'The classic tributes from\nthe 74th Hunger Games (4–8).',
              icon: Icons.auto_awesome_outlined,
              onTap: () => setState(() {
                _mode = SetupMode.defaultTributes;
                _targetCount = 8;
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Language selector ─────────────────────────────────────────────────────

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NARRATIVE LANGUAGE',
          style: GoogleFonts.cinzel(
              fontSize: 10, color: AppColors.muted, letterSpacing: 2.0),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _LangButton(
              label: 'English',
              selected: !_useCustomLanguage && _language == 'English',
              onTap: () => setState(() {
                _language = 'English';
                _useCustomLanguage = false;
              }),
            ),
            const SizedBox(width: 8),
            _LangButton(
              label: 'Spanish',
              selected: !_useCustomLanguage && _language == 'Spanish',
              onTap: () => setState(() {
                _language = 'Spanish';
                _useCustomLanguage = false;
              }),
            ),
            const SizedBox(width: 8),
            _LangButton(
              label: 'Other',
              selected: _useCustomLanguage,
              onTap: () => setState(() => _useCustomLanguage = true),
            ),
          ],
        ),
        if (_useCustomLanguage) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _customLanguageController,
            style: const TextStyle(color: AppColors.offWhite),
            decoration: const InputDecoration(
              hintText: 'Enter language (e.g. French, Portuguese...)',
              prefixIcon:
                  Icon(Icons.language, color: AppColors.muted, size: 18),
            ),
          ),
        ],
      ],
    );
  }

  // ── Tribute count selector ────────────────────────────────────────────────

  Widget _buildCountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NUMBER OF TRIBUTES',
          style: GoogleFonts.cinzel(
              fontSize: 10, color: AppColors.muted, letterSpacing: 2.0),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_maxCount - 3, (i) {
              final n = i + 4;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CountButton(
                  count: n,
                  selected: _targetCount == n,
                  onTap: () => setState(() => _targetCount = n),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Manual setup ──────────────────────────────────────────────────────────

  Widget _buildManualSetup() {
    final available = _availableDistricts;
    final districtFull = _tributesInDistrict(_selectedDistrict) >= 2;
    final canAdd =
        _tributes.length < _targetCount && available.isNotEmpty;
    final ready = _tributes.length == _targetCount;
    final remaining = _targetCount - _tributes.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLanguageSelector(),
          const SizedBox(height: 24),
          _buildCountSelector(),
          const SizedBox(height: 20),

          // Progress bar
          _ProgressBar(current: _tributes.length, target: _targetCount),
          const SizedBox(height: 16),

          // Form
          Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(
                    color: ready ? AppColors.goldBorder : AppColors.goldBorder),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ADD TRIBUTE',
                    style: GoogleFonts.cinzel(
                        fontSize: 11,
                        color: AppColors.gold,
                        letterSpacing: 2.0),
                  ),
                  const SizedBox(height: 14),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.offWhite),
                    decoration: const InputDecoration(labelText: 'Name'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (_tributes.any((t) =>
                          t.name.toLowerCase() ==
                          v.trim().toLowerCase())) {
                        return 'A tribute with this name already exists';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Gender + District
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gender
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GENDER',
                              style: GoogleFonts.cinzel(
                                  fontSize: 9,
                                  color: AppColors.muted,
                                  letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _GenderButton(
                                  label: 'M',
                                  selected: _selectedGender == 'M',
                                  onTap: () => setState(
                                      () => _selectedGender = 'M'),
                                ),
                                const SizedBox(width: 8),
                                _GenderButton(
                                  label: 'F',
                                  selected: _selectedGender == 'F',
                                  onTap: () => setState(
                                      () => _selectedGender = 'F'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // District (only available ones)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DISTRICT',
                              style: GoogleFonts.cinzel(
                                  fontSize: 9,
                                  color: AppColors.muted,
                                  letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 6),
                            InputDecorator(
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                errorText: districtFull
                                    ? 'District full'
                                    : null,
                              ),
                              child: DropdownButton<int>(
                                value: available.contains(_selectedDistrict)
                                    ? _selectedDistrict
                                    : (available.isNotEmpty
                                        ? available.first
                                        : null),
                                dropdownColor: AppColors.surfaceVariant,
                                isExpanded: true,
                                underline: const SizedBox(),
                                style: const TextStyle(
                                    color: AppColors.offWhite,
                                    fontSize: 14),
                                items: List.generate(12, (i) {
                                  final d = i + 1;
                                  final count = _tributesInDistrict(d);
                                  final isFull = count >= 2;
                                  return DropdownMenuItem(
                                    value: d,
                                    enabled: !isFull,
                                    child: Text(
                                      'District $d${isFull ? " (full)" : count == 1 ? " (1/2)" : ""}',
                                      style: TextStyle(
                                        color: isFull
                                            ? AppColors.muted
                                            : AppColors.offWhite,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedDistrict = v);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Image URL
                  TextField(
                    controller: _imageUrlController,
                    style: const TextStyle(
                        color: AppColors.offWhite, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Image URL (optional)',
                      prefixIcon: Icon(Icons.image_outlined,
                          color: AppColors.muted, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: canAdd ? _addTribute : null,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(canAdd
                        ? 'ADD TRIBUTE'
                        : ready
                            ? 'TARGET REACHED'
                            : 'NO DISTRICTS AVAILABLE'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Registered tributes list
          if (_tributes.isNotEmpty) ...[
            Text(
              'REGISTERED TRIBUTES',
              style: GoogleFonts.cinzel(
                  fontSize: 10, color: AppColors.muted, letterSpacing: 2.0),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _tributes.length,
              (i) => _RegisteredTributeCard(
                tribute: _tributes[i],
                imageUrl: _tributeImages[_tributes[i].name],
                onRemove: () => _removeTribute(i),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Start / hint
          if (ready)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startSimulation(useDefault: false),
                child: Text('START — $_targetCount TRIBUTES ENTER THE ARENA'),
              ),
            )
          else if (_tributes.isNotEmpty)
            Center(
              child: Text(
                '$remaining tribute${remaining != 1 ? "s" : ""} still needed',
                style:
                    const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Default setup ─────────────────────────────────────────────────────────

  Widget _buildDefaultSetup() {
    final selected = kDefaultTributes.sublist(0, _targetCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLanguageSelector(),
          const SizedBox(height: 24),
          _buildCountSelector(),
          const SizedBox(height: 20),

          Text(
            'TRIBUTES ENTERING THE ARENA',
            style: GoogleFonts.cinzel(
                fontSize: 10, color: AppColors.muted, letterSpacing: 1.8),
          ),
          const SizedBox(height: 4),
          const Text(
            'Optionally add a portrait URL for each tribute.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),

          ...selected.map((t) {
            final name = t['name'] as String;
            final district = t['district'] as int;
            final gender = t['gender'] as String;
            return _DefaultTributeImageRow(
              name: name,
              district: district,
              gender: gender,
              controller: _defaultImageControllers[name]!,
            );
          }),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _startSimulation(useDefault: true),
              child: Text('START — $_targetCount TRIBUTES ENTER THE ARENA'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
              color: AppColors.gold, strokeWidth: 2),
          const SizedBox(height: 20),
          Text(
            'ENTERING THE ARENA...',
            style: GoogleFonts.cinzel(
                fontSize: 12, color: AppColors.muted, letterSpacing: 3.0),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.goldBorder),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cinzel(
                        fontSize: 13,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.goldDark),
          ],
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.surface,
          border: Border.all(
              color: selected ? AppColors.gold : AppColors.border),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.background : AppColors.muted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _CountButton(
      {required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.surface,
          border: Border.all(
              color: selected ? AppColors.gold : AppColors.border),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          '$count',
          style: GoogleFonts.cinzel(
            color: selected ? AppColors.background : AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.surfaceVariant,
          border: Border.all(
              color: selected ? AppColors.gold : AppColors.border),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.background : AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int target;

  const _ProgressBar({required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    final done = current == target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              color: done ? AppColors.gold : AppColors.muted,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '$current / $target tributes registered'
              '${done ? " — ready to begin" : ""}',
              style: TextStyle(
                  color: done ? AppColors.gold : AppColors.muted,
                  fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: target > 0 ? current / target : 0,
            backgroundColor: AppColors.border,
            color: done ? AppColors.gold : AppColors.goldDark,
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _RegisteredTributeCard extends StatelessWidget {
  final TributeInput tribute;
  final String? imageUrl;
  final VoidCallback onRemove;

  const _RegisteredTributeCard({
    required this.tribute,
    required this.imageUrl,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.goldBorder),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          _TributeAvatar(name: tribute.name, imageUrl: imageUrl, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tribute.name,
                  style: const TextStyle(
                      color: AppColors.offWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _DistrictBadge(district: tribute.district),
                    const SizedBox(width: 6),
                    Text(
                      tribute.gender == 'M' ? 'Male' : 'Female',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.muted, size: 18),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _DefaultTributeImageRow extends StatelessWidget {
  final String name;
  final int district;
  final String gender;
  final TextEditingController controller;

  const _DefaultTributeImageRow({
    required this.name,
    required this.district,
    required this.gender,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          _DistrictBadge(district: district),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      color: AppColors.offWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  gender == 'M' ? 'Male' : 'Female',
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              style:
                  const TextStyle(color: AppColors.offWhite, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Image URL...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TributeAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;

  const _TributeAvatar(
      {required this.name, this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.surfaceVariant,
        backgroundImage: NetworkImage(imageUrl!),
        onBackgroundImageError: (_, _) {},
        child: null,
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.surfaceVariant,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.gold,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DistrictBadge extends StatelessWidget {
  final int district;
  const _DistrictBadge({required this.district});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.goldDark.withValues(alpha: 0.3),
        border: Border.all(color: AppColors.goldDark),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        'D$district',
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

PageRouteBuilder _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, _, _) => page,
    transitionDuration: const Duration(milliseconds: 600),
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      );
    },
  );
}
