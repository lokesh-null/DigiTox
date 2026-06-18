import 'dart:async';
import 'package:intl/intl.dart';
import 'storage.dart';

class UsageTracker {
  static final UsageTracker _instance = UsageTracker._internal();

  factory UsageTracker() {
    return _instance;
  }

  UsageTracker._internal() {
    _init();
  }

  int _sessionStart = DateTime.now().millisecondsSinceEpoch;
  int _totalTodaySeconds = 0;
  Timer? _tickInterval;
  
  final _streamController = StreamController<int>.broadcast();
  Stream<int> get onTick => _streamController.stream;

  Future<void> _init() async {
    _totalTodaySeconds = await Storage.load('${StorageKeys.settings}_today_seconds', fallback: 0) as int;
    
    // Check if it's a new day
    final lastDate = await Storage.load(StorageKeys.lastDate, fallback: '');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    if (lastDate != today) {
      _totalTodaySeconds = 0;
      await Storage.save(StorageKeys.lastDate, today);
    }
    
    startTicking();
  }

  void startTicking() {
    _tickInterval?.cancel();
    _tickInterval = Timer.periodic(const Duration(seconds: 1), (timer) {
      _totalTodaySeconds++;
      Storage.save('${StorageKeys.settings}_today_seconds', _totalTodaySeconds);
      _streamController.add(_totalTodaySeconds);
    });
  }

  int getSessionTime() {
    return ((DateTime.now().millisecondsSinceEpoch - _sessionStart) / 1000).floor();
  }

  int getTodayTime() {
    return _totalTodaySeconds;
  }

  String formatTime(int totalSeconds) {
    final hours = (totalSeconds / 3600).floor();
    final minutes = ((totalSeconds % 3600) / 60).floor();
    final seconds = totalSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${hours}h ${mStr}m ${sStr}s';
    }
    return '${minutes}m ${sStr}s';
  }

  String formatTimeShort(int totalMinutes) {
    final hours = (totalMinutes / 60).floor();
    final minutes = totalMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  void destroy() {
    _tickInterval?.cancel();
    _streamController.close();
  }
}
