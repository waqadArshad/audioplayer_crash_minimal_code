import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(home: CrashDemoPage());
}

class CrashDemoPage extends StatefulWidget {
  @override
  State<CrashDemoPage> createState() => _CrashDemoPageState();
}

class _CrashDemoPageState extends State<CrashDemoPage> {
  final Map<String, Timer> _orderTimers = {};
  final Map<String, AudioPlayer> _players = {};
  final Map<String, Stopwatch> _elapsed = {};
  final Map<String, bool> _isDisposed = {};

  final Duration totalDuration = Duration(minutes: 2);

  void _startOrderRinging(String orderId) {
    if (_orderTimers.containsKey(orderId)) return;

    final stopwatch = Stopwatch()..start();
    _elapsed[orderId] = stopwatch;

    final player = AudioPlayer(playerId: 'player_$orderId');
    _players[orderId] = player;
    _isDisposed[orderId] = false;

    debugPrint("[$orderId] STARTED");

    Future<void> play() async {
      if (_isDisposed[orderId] == true) {
        debugPrint("[$orderId] Skipped play: already disposed");
        return;
      }

      try {
        debugPrint("[$orderId] Playing...");
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource('audio/ring-doorbell-short.mp3'));
        await player.seek(Duration.zero);
        await player.resume();
        debugPrint("[$orderId] Played successfully");
      } catch (e) {
        debugPrint("[$orderId] Playback error: $e");
      }
    }

    void scheduleNext() {
      final elapsed = stopwatch.elapsed;
      if (elapsed > totalDuration) {
        _stopOrder(orderId);
        return;
      }

      play();

      final remaining = totalDuration - elapsed;
      final interval = remaining > Duration(minutes: 1)
          ? Duration(seconds: 7)
          : Duration(seconds: 3);

      _orderTimers[orderId] = Timer(interval, scheduleNext);
    }

    scheduleNext();
  }

  void _stopOrder(String orderId) {
    debugPrint("[$orderId] Stopping...");

    _orderTimers[orderId]?.cancel();
    _orderTimers.remove(orderId);

    _elapsed[orderId]?.stop();
    _elapsed.remove(orderId);

    _isDisposed[orderId] = true;

    _players[orderId]?.stop();
    _players[orderId]?.dispose();
    _players.remove(orderId);

    _isDisposed.remove(orderId);

    debugPrint("[$orderId] STOPPED");
  }

  void _startManyOrders() {
    // Start 10 immediately
    for (int i = 0; i < 10; i++) {
      _startOrderRinging('order_$i');
    }

    // Start 5 more after short delay to stagger them
    Future.delayed(Duration(seconds: 5), () {
      for (int i = 10; i < 15; i++) {
        _startOrderRinging('order_$i');
      }
    });
  }

  @override
  void dispose() {
    for (final id in _orderTimers.keys.toList()) {
      _stopOrder(id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Crash Reproducer")),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _startManyOrders,
            child: Text("Start 15 Orders"),
          ),
          ElevatedButton(
            onPressed: () {
              for (final id in _orderTimers.keys.toList()) {
                _stopOrder(id);
              }
            },
            child: Text("Stop All"),
          ),
        ],
      ),
    ),
  );
}
