import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';

import '../../../core/theme/app_theme.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Qibla Direction')),
    body: FutureBuilder<bool>(
      future: FlutterQiblah.androidDeviceSensorSupport().then((v) => v ?? false),
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return snap.data == false
          ? const _LocationUnsupported()
          : const _QiblaCompass();
      },
    ),
  );
}

class _QiblaCompass extends StatefulWidget {
  const _QiblaCompass();

  @override
  State<_QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<_QiblaCompass> {
  StreamSubscription? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    FlutterQiblah().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QiblahDirection>(
    stream: FlutterQiblah.qiblahStream,
    builder: (_, snap) {
      if (snap.hasError) {
        return Center(child: Text('Error: ${snap.error}'));
      }
      if (!snap.hasData) {
        return const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting location…'),
          ],
        ));
      }

      final qd       = snap.data!;
      final heading  = qd.direction;               // compass, degrees
      final qibla    = qd.qiblah;                  // qibla bearing from North
      final radians  = (qd.qiblah * math.pi / 180) - (qd.direction * math.pi / 180);
      final aligned  = qd.offset.abs() < 5;

      return Center(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compass ring (counter-rotates with heading so cardinal markers move naturally)
          AnimatedRotation(
            turns: -heading / 360,
            duration: const Duration(milliseconds: 300),
            child: SizedBox(
              width: 260, height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 260, height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.gold, width: 3),
                      color: AppTheme.cardBg,
                    ),
                  ),
                  // N marker
                  Positioned(
                    top: 12,
                    child: Text('N', style: TextStyle(
                      color: aligned ? AppTheme.green : AppTheme.textMuted,
                      fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const Positioned(bottom: 12, child: Text('S', style: TextStyle(color: AppTheme.textMuted))),
                  const Positioned(left: 12, child: Text('W', style: TextStyle(color: AppTheme.textMuted))),
                  const Positioned(right: 12, child: Text('E', style: TextStyle(color: AppTheme.textMuted))),
                  // Kaaba icon + needle
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Icon(Icons.mosque, color: AppTheme.gold, size: 40),
                    ],
                  ),
                  // Center dot
                  Container(
                    width: 12, height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppTheme.gold),
                  ),
                ],
              ),
            ),
          ),

          // Qibla arrow (shows turn direction clearly)
          Transform.rotate(
            angle: radians,
            child: const Icon(Icons.navigation, size: 84, color: AppTheme.gold),
          ),

          const SizedBox(height: 32),

          // Bearing info
          Text(
            '${qibla.toStringAsFixed(1)}° from North',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Compass: ${heading.toStringAsFixed(1)}°',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: aligned ? AppTheme.green : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: aligned ? AppTheme.green : AppTheme.divider),
            ),
            child: Text(
              aligned ? '✓ Facing Qibla' : 'Rotate to align',
              style: TextStyle(
                color: aligned ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Arabic
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('اتَّجِهُوا نَحْوَ الْكَعْبَةِ',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: AppTheme.gold)),
          ),
        ],
      ),
      );
    },
  );
}

class _LocationUnsupported extends StatelessWidget {
  const _LocationUnsupported();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.compass_calibration, size: 72, color: AppTheme.textMuted),
        const SizedBox(height: 16),
        const Text('Compass not supported', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        const Text('Your device does not have the required sensors.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary)),
      ],
    ),
  );
}
