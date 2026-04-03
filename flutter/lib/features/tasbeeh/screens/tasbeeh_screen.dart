import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

const _presets = [
  _Preset('SubhanAllah',     'سُبْحَانَ اللَّهِ',    33),
  _Preset('Alhamdulillah',   'الْحَمْدُ لِلَّهِ',    33),
  _Preset('Allahu Akbar',    'اللَّهُ أَكْبَرُ',      34),
  _Preset('La ilaha illallah','لَا إِلَٰهَ إِلَّا اللَّهُ', 100),
  _Preset('Astaghfirullah',  'أَسْتَغْفِرُ اللَّهَ',  100),
];

class _Preset {
  final String nameEn;
  final String arabic;
  final int target;
  const _Preset(this.nameEn, this.arabic, this.target);
}

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen>
    with SingleTickerProviderStateMixin {
  int _count   = 0;
  int _preset  = 0;
  bool _vibrate = true;
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120),
      lowerBound: 1.0, upperBound: 1.08)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _pulse.reverse();
      });
    _scale = _pulse;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int get _target => _presets[_preset].target;

  void _tap() {
    if (_count >= _target) return;
    setState(() => _count++);
    _pulse.forward(from: 1.0);

    // Haptic feedback
    if (_vibrate) {
      if (_count == _target) {
        HapticFeedback.heavyImpact();
      } else if (_count % 33 == 0) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _reset() => setState(() => _count = 0);

  void _selectPreset(int index) => setState(() {
    _preset = index;
    _count  = 0;
  });

  @override
  Widget build(BuildContext context) {
    final current = _presets[_preset];
    final done    = _count >= _target;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasbeeh Counter'),
        actions: [
          IconButton(
            icon: Icon(_vibrate ? Icons.vibration : Icons.phone_android),
            tooltip: 'Toggle vibration',
            onPressed: () => setState(() => _vibrate = !_vibrate),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          // Preset selector
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _presets.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_presets[i].nameEn),
                  selected: _preset == i,
                  selectedColor: AppTheme.green,
                  onSelected: (_) => _selectPreset(i),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Arabic text
          Text(current.arabic,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 28, color: AppTheme.gold)),
          const SizedBox(height: 4),
          Text(current.nameEn,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),

          const SizedBox(height: 32),

          // Counter circle (tap area)
          ScaleTransition(
            scale: _scale,
            child: GestureDetector(
              onTap: done ? null : _tap,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppTheme.green.withOpacity(0.2) : AppTheme.cardBg,
                  border: Border.all(
                    color: done ? AppTheme.green : AppTheme.gold, width: 3),
                  boxShadow: [BoxShadow(
                    color: AppTheme.gold.withOpacity(0.15),
                    blurRadius: 24, spreadRadius: 4)],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$_count',
                      style: TextStyle(
                        fontSize: 60, fontWeight: FontWeight.bold,
                        color: done ? AppTheme.green : AppTheme.textPrimary)),
                    Text('/ $_target',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 18)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (done)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('✓ Complete! Tap refresh to restart.',
                style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold)),
            ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _target > 0 ? _count / _target : 0,
                minHeight: 8,
                backgroundColor: AppTheme.divider,
                valueColor: AlwaysStoppedAnimation(done ? AppTheme.green : AppTheme.gold),
              ),
            ),
          ),

          // Milestone badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [33, 66, 99].map((m) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _count >= m ? AppTheme.green.withOpacity(0.2) : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _count >= m ? AppTheme.green : AppTheme.divider),
              ),
              child: Text('$m',
                style: TextStyle(
                  color: _count >= m ? AppTheme.green : AppTheme.textMuted,
                  fontSize: 12, fontWeight: FontWeight.bold)),
            )).toList(),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
