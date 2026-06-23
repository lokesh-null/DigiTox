import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DigiToxDatabase {
  static final DigiToxDatabase _instance = DigiToxDatabase._internal();
  factory DigiToxDatabase() => _instance;
  DigiToxDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'digitox.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE app_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT NOT NULL,
        app_name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'unknown',
        date TEXT NOT NULL,
        total_minutes INTEGER NOT NULL DEFAULT 0,
        open_count INTEGER NOT NULL DEFAULT 0,
        longest_session_minutes INTEGER NOT NULL DEFAULT 0,
        avg_session_minutes REAL NOT NULL DEFAULT 0,
        UNIQUE(package_name, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE usage_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT NOT NULL,
        event_type INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE screen_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration_minutes INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        task TEXT,
        contract_text TEXT,
        xp_earned INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        UNIQUE(habit_id, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE behavioral_scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        dopamine_debt INTEGER NOT NULL DEFAULT 0,
        focus_score INTEGER NOT NULL DEFAULT 0,
        relapse_risk TEXT NOT NULL DEFAULT 'low',
        xp_total INTEGER NOT NULL DEFAULT 0,
        identity_level INTEGER NOT NULL DEFAULT 1,
        app_switch_count INTEGER NOT NULL DEFAULT 0,
        rapid_switch_count INTEGER NOT NULL DEFAULT 0,
        screen_unlocks INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE trigger_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        trigger_type TEXT NOT NULL,
        confidence REAL NOT NULL DEFAULT 0.0,
        app_involved TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE purpose_checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        app_name TEXT NOT NULL,
        stated_purpose TEXT NOT NULL,
        actual_duration_minutes INTEGER,
        mismatch INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        challenge_type TEXT NOT NULL,
        description TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        xp_reward INTEGER NOT NULL DEFAULT 15,
        UNIQUE(challenge_type, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE app_classifications (
        package_name TEXT PRIMARY KEY,
        app_name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'unknown',
        user_override INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_app_usage_date ON app_usage(date)');
    await db.execute('CREATE INDEX idx_usage_events_ts ON usage_events(timestamp)');
    await db.execute('CREATE INDEX idx_focus_sessions_start ON focus_sessions(start_time)');
    await db.execute('CREATE INDEX idx_behavioral_scores_date ON behavioral_scores(date)');

    // v2 tables
    await _createV2Tables(db);
  }

  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createV2Tables(db);
    }
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS blocked_apps (
        package_name TEXT NOT NULL,
        app_name TEXT NOT NULL,
        blocked INTEGER NOT NULL DEFAULT 1,
        profile TEXT NOT NULL DEFAULT 'default',
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (package_name, profile)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS block_analytics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        event_type TEXT NOT NULL,
        override_reason TEXT,
        override_duration_minutes INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS focus_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '🎯',
        created_at INTEGER NOT NULL
      )
    ''');

    // Insert default profile
    await db.insert('focus_profiles', {
      'id': 'default',
      'name': 'Default',
      'emoji': '🎯',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // === App Usage ===

  Future<void> upsertAppUsage({
    required String packageName,
    required String appName,
    required String category,
    required String date,
    required int totalMinutes,
    required int openCount,
    int longestSession = 0,
    double avgSession = 0,
  }) async {
    final db = await database;
    await db.insert('app_usage', {
      'package_name': packageName,
      'app_name': appName,
      'category': category,
      'date': date,
      'total_minutes': totalMinutes,
      'open_count': openCount,
      'longest_session_minutes': longestSession,
      'avg_session_minutes': avgSession,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAppUsageForDate(String date) async {
    final db = await database;
    return db.query('app_usage', where: 'date = ?', whereArgs: [date], orderBy: 'total_minutes DESC');
  }

  Future<List<Map<String, dynamic>>> getAppUsageForRange(String startDate, String endDate) async {
    final db = await database;
    return db.query('app_usage', where: 'date >= ? AND date <= ?', whereArgs: [startDate, endDate], orderBy: 'date ASC');
  }

  Future<List<Map<String, dynamic>>> getWeeklyAggregates(String startDate, String endDate) async {
    final db = await database;
    return db.rawQuery('''
      SELECT date,
        SUM(CASE WHEN category IN ('productive','education','development') THEN total_minutes ELSE 0 END) as productive,
        SUM(CASE WHEN category IN ('social_media','gaming','streaming') THEN total_minutes ELSE 0 END) as addictive,
        SUM(CASE WHEN category NOT IN ('productive','education','development','social_media','gaming','streaming') THEN total_minutes ELSE 0 END) as neutral,
        SUM(total_minutes) as total
      FROM app_usage
      WHERE date >= ? AND date <= ?
      GROUP BY date
      ORDER BY date ASC
    ''', [startDate, endDate]);
  }

  // === Usage Events ===

  Future<void> insertUsageEvent(String packageName, int eventType, int timestamp) async {
    final db = await database;
    await db.insert('usage_events', {
      'package_name': packageName,
      'event_type': eventType,
      'timestamp': timestamp,
    });
  }

  Future<List<Map<String, dynamic>>> getUsageEventsForRange(int startMs, int endMs) async {
    final db = await database;
    return db.query('usage_events', where: 'timestamp >= ? AND timestamp < ?', whereArgs: [startMs, endMs], orderBy: 'timestamp ASC');
  }

  Future<List<Map<String, dynamic>>> getHourlyEventCounts(int startMs, int endMs) async {
    final db = await database;
    return db.rawQuery('''
      SELECT (timestamp / 3600000 % 24) as hour, COUNT(*) as count
      FROM usage_events
      WHERE timestamp >= ? AND timestamp < ? AND event_type = 1
      GROUP BY hour
      ORDER BY hour ASC
    ''', [startMs, endMs]);
  }

  Future<List<Map<String, dynamic>>> getHourlyFilteredEventCounts(int startMs, int endMs, String categoryType) async {
    final db = await database;
    // Join with app_classifications to filter by addictive/productive
    return db.rawQuery('''
      SELECT (u.timestamp / 3600000 % 24) as hour, COUNT(*) as count
      FROM usage_events u
      LEFT JOIN app_classifications c ON u.package_name = c.package_name
      WHERE u.timestamp >= ? AND u.timestamp < ? AND u.event_type = 1
      AND (
        (? = 'addictive' AND c.category IN ('social_media', 'gaming', 'streaming', 'entertainment'))
        OR
        (? = 'productive' AND c.category IN ('productive', 'education', 'development', 'finance'))
      )
      GROUP BY hour
      ORDER BY hour ASC
    ''', [startMs, endMs, categoryType, categoryType]);
  }

  Future<List<Map<String, dynamic>>> getHourlyFocusCounts(int startMs, int endMs) async {
    final db = await database;
    return db.rawQuery('''
      SELECT (start_time / 3600000 % 24) as hour, COUNT(*) as count
      FROM focus_sessions
      WHERE start_time >= ? AND start_time < ?
      GROUP BY hour
      ORDER BY hour ASC
    ''', [startMs, endMs]);
  }

  // === Focus Sessions ===

  Future<int> insertFocusSession({
    required int startTime,
    required int durationMinutes,
    String? task,
    String? contractText,
  }) async {
    final db = await database;
    return db.insert('focus_sessions', {
      'start_time': startTime,
      'duration_minutes': durationMinutes,
      'task': task,
      'contract_text': contractText,
    });
  }

  Future<void> completeFocusSession(int id, int endTime, int xpEarned) async {
    final db = await database;
    await db.update('focus_sessions', {
      'end_time': endTime,
      'completed': 1,
      'xp_earned': xpEarned,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCompletedSessionCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM focus_sessions WHERE completed = 1');
    return result.first['c'] as int;
  }

  Future<List<Map<String, dynamic>>> getFocusSessionsForRange(int startMs, int endMs) async {
    final db = await database;
    return db.query('focus_sessions', where: 'start_time >= ? AND start_time < ?', whereArgs: [startMs, endMs]);
  }

  // === Behavioral Scores ===

  Future<void> upsertBehavioralScore({
    required String date,
    required int dopamineDebt,
    required int focusScore,
    required String relapseRisk,
    required int xpTotal,
    required int identityLevel,
    int appSwitchCount = 0,
    int rapidSwitchCount = 0,
    int screenUnlocks = 0,
  }) async {
    final db = await database;
    await db.insert('behavioral_scores', {
      'date': date,
      'dopamine_debt': dopamineDebt,
      'focus_score': focusScore,
      'relapse_risk': relapseRisk,
      'xp_total': xpTotal,
      'identity_level': identityLevel,
      'app_switch_count': appSwitchCount,
      'rapid_switch_count': rapidSwitchCount,
      'screen_unlocks': screenUnlocks,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getBehavioralScoreForDate(String date) async {
    final db = await database;
    final results = await db.query('behavioral_scores', where: 'date = ?', whereArgs: [date]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getBehavioralScoresForRange(String startDate, String endDate) async {
    final db = await database;
    return db.query('behavioral_scores', where: 'date >= ? AND date <= ?', whereArgs: [startDate, endDate], orderBy: 'date ASC');
  }

  // === Habit Completions ===

  Future<void> upsertHabitCompletion(String habitId, String date, bool completed) async {
    final db = await database;
    await db.insert('habit_completions', {
      'habit_id': habitId,
      'date': date,
      'completed': completed ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getHabitCompletionsForRange(String startDate, String endDate) async {
    final db = await database;
    return db.query('habit_completions', where: 'date >= ? AND date <= ?', whereArgs: [startDate, endDate]);
  }

  Future<int> getHabitCompletionCountForDate(String date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM habit_completions WHERE date = ? AND completed = 1',
      [date]
    );
    return result.first['c'] as int;
  }

  // === App Classifications ===

  Future<void> upsertAppClassification(String packageName, String appName, String category, {bool userOverride = false}) async {
    final db = await database;
    await db.insert('app_classifications', {
      'package_name': packageName,
      'app_name': appName,
      'category': category,
      'user_override': userOverride ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> getAppCategory(String packageName) async {
    final db = await database;
    final results = await db.query('app_classifications', where: 'package_name = ?', whereArgs: [packageName]);
    if (results.isNotEmpty) return results.first['category'] as String;
    return 'unknown';
  }

  Future<Map<String, String>> getAllClassifications() async {
    final db = await database;
    final results = await db.query('app_classifications');
    final map = <String, String>{};
    for (final row in results) {
      map[row['package_name'] as String] = row['category'] as String;
    }
    return map;
  }

  // === Purpose Checks ===

  Future<void> insertPurposeCheck({
    required int timestamp,
    required String appName,
    required String statedPurpose,
  }) async {
    final db = await database;
    await db.insert('purpose_checks', {
      'timestamp': timestamp,
      'app_name': appName,
      'stated_purpose': statedPurpose,
    });
  }

  Future<void> updatePurposeCheckDuration(int id, int actualMinutes, bool mismatch) async {
    final db = await database;
    await db.update('purpose_checks', {
      'actual_duration_minutes': actualMinutes,
      'mismatch': mismatch ? 1 : 0,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> logPurposeCheck({
    required String appName,
    required String statedPurpose,
  }) async {
    await insertPurposeCheck(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      appName: appName,
      statedPurpose: statedPurpose,
    );
  }

  // === Challenges ===

  Future<void> upsertChallenge({
    required String date,
    required String challengeType,
    required String description,
    bool completed = false,
    int xpReward = 15,
  }) async {
    final db = await database;
    await db.insert('challenges', {
      'date': date,
      'challenge_type': challengeType,
      'description': description,
      'completed': completed ? 1 : 0,
      'xp_reward': xpReward,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getChallengesForDate(String date) async {
    final db = await database;
    return db.query('challenges', where: 'date = ?', whereArgs: [date]);
  }

  // === Trigger Events ===

  Future<void> insertTriggerEvent({
    required int timestamp,
    required String triggerType,
    required double confidence,
    String? appInvolved,
  }) async {
    final db = await database;
    await db.insert('trigger_events', {
      'timestamp': timestamp,
      'trigger_type': triggerType,
      'confidence': confidence,
      'app_involved': appInvolved,
    });
  }

  Future<List<Map<String, dynamic>>> getTriggerEventsForRange(int startMs, int endMs) async {
    final db = await database;
    return db.query('trigger_events', where: 'timestamp >= ? AND timestamp < ?', whereArgs: [startMs, endMs]);
  }

  // === Cleanup ===

  Future<void> cleanupOldData(int daysToKeep) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    final cutoffDate = '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
    final cutoffMs = cutoff.millisecondsSinceEpoch;

    await db.delete('app_usage', where: 'date < ?', whereArgs: [cutoffDate]);
    await db.delete('usage_events', where: 'timestamp < ?', whereArgs: [cutoffMs]);
    await db.delete('screen_events', where: 'timestamp < ?', whereArgs: [cutoffMs]);
    await db.delete('behavioral_scores', where: 'date < ?', whereArgs: [cutoffDate]);
    await db.delete('trigger_events', where: 'timestamp < ?', whereArgs: [cutoffMs]);
  }

  // === Blocked Apps ===

  Future<void> upsertBlockedApp(String packageName, String appName, bool blocked, {String profile = 'default'}) async {
    final db = await database;
    await db.insert('blocked_apps', {
      'package_name': packageName,
      'app_name': appName,
      'blocked': blocked ? 1 : 0,
      'profile': profile,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<String>> getBlockedPackages({String profile = 'default'}) async {
    final db = await database;
    final results = await db.query('blocked_apps',
      where: 'blocked = 1 AND profile = ?',
      whereArgs: [profile],
    );
    return results.map((r) => r['package_name'] as String).toList();
  }

  Future<Map<String, bool>> getBlockedAppsMap({String profile = 'default'}) async {
    final db = await database;
    final results = await db.query('blocked_apps', where: 'profile = ?', whereArgs: [profile]);
    final map = <String, bool>{};
    for (final row in results) {
      map[row['package_name'] as String] = (row['blocked'] as int) == 1;
    }
    return map;
  }

  Future<void> removeBlockedApp(String packageName, {String profile = 'default'}) async {
    final db = await database;
    await db.delete('blocked_apps',
      where: 'package_name = ? AND profile = ?',
      whereArgs: [packageName, profile],
    );
  }

  // === Block Analytics ===

  Future<void> insertBlockEvent(String packageName, String eventType, {String? overrideReason, int? overrideDuration}) async {
    final db = await database;
    await db.insert('block_analytics', {
      'package_name': packageName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'event_type': eventType,
      'override_reason': overrideReason,
      'override_duration_minutes': overrideDuration,
    });
  }

  Future<List<Map<String, dynamic>>> getBlockAnalyticsForRange(int startMs, int endMs) async {
    final db = await database;
    return db.query('block_analytics',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startMs, endMs],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> getBlockedAttemptCount(int startMs, int endMs) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM block_analytics WHERE event_type = ? AND timestamp >= ? AND timestamp < ?',
      ['blocked', startMs, endMs],
    );
    return result.first['c'] as int;
  }

  Future<String?> getMostBlockedApp(int startMs, int endMs) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT package_name, COUNT(*) as c FROM block_analytics
      WHERE event_type = 'blocked' AND timestamp >= ? AND timestamp < ?
      GROUP BY package_name ORDER BY c DESC LIMIT 1
    ''', [startMs, endMs]);
    return result.isNotEmpty ? result.first['package_name'] as String : null;
  }

  Future<int> getOverrideCount(int startMs, int endMs) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM block_analytics WHERE event_type = ? AND timestamp >= ? AND timestamp < ?',
      ['override', startMs, endMs],
    );
    return result.first['c'] as int;
  }

  // === Focus Profiles ===

  Future<List<Map<String, dynamic>>> getAllFocusProfiles() async {
    final db = await database;
    return db.query('focus_profiles', orderBy: 'created_at ASC');
  }

  Future<void> insertFocusProfile(String id, String name, String emoji) async {
    final db = await database;
    await db.insert('focus_profiles', {
      'id': id,
      'name': name,
      'emoji': emoji,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteFocusProfile(String id) async {
    final db = await database;
    await db.delete('focus_profiles', where: 'id = ?', whereArgs: [id]);
    await db.delete('blocked_apps', where: 'profile = ?', whereArgs: [id]);
  }
}
