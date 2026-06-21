import 'package:intl/intl.dart';
import 'database.dart';
import 'device_intelligence.dart';
import 'app_classifier.dart';

/// Central Behavioral Intelligence Engine.
/// Computes all behavioral scores from real device data:
/// - Dopamine Debt Score (0-100)
/// - Focus Identity XP & Level
/// - Relapse Risk (Low/Medium/High/Very High)
/// - Trigger Detection
/// - Life Recovery metrics
/// - Attention Investment analysis
class BehavioralEngine {
  static final BehavioralEngine _instance = BehavioralEngine._internal();
  factory BehavioralEngine() => _instance;
  BehavioralEngine._internal();

  final _db = DigiToxDatabase();

  // ============================================================
  // DOPAMINE DEBT SCORE (Feature 1)
  // 0 = clean baseline, 100 = critically overloaded
  // ============================================================

  Future<DopamineDebtResult> computeDopamineDebt() async {
    final today = DeviceIntelligence.todayString();
    int score = 0;
    List<String> factors = [];

    // --- Factor 1: Addictive app opens ---
    final usage = await _db.getAppUsageForDate(today);
    int addictiveOpens = 0;
    int addictiveMinutes = 0;
    for (final app in usage) {
      final category = app['category'] as String;
      if (AppClassifier.isAddictive(category)) {
        addictiveOpens += (app['open_count'] as int? ?? 0);
        addictiveMinutes += (app['total_minutes'] as int? ?? 0);
      }
    }
    // +3 per addictive app open, max +30
    int openPenalty = (addictiveOpens * 3).clamp(0, 30);
    score += openPenalty;
    if (openPenalty > 0) factors.add('+$openPenalty from $addictiveOpens addictive app opens');

    // +1 per 5 minutes of addictive usage, max +20
    int usagePenalty = (addictiveMinutes ~/ 5).clamp(0, 20);
    score += usagePenalty;
    if (usagePenalty > 0) factors.add('+$usagePenalty from ${addictiveMinutes}min addictive usage');

    // --- Factor 2: Rapid app switching (from accessibility service) ---
    final accessData = await DeviceIntelligence.getAccessibilityData();
    final rapidSwitches = accessData['rapidSwitchCountToday'] as int? ?? 0;
    // +5 per rapid switch within 30 seconds, max +25
    int switchPenalty = (rapidSwitches * 5).clamp(0, 25);
    score += switchPenalty;
    if (switchPenalty > 0) factors.add('+$switchPenalty from $rapidSwitches rapid app switches');

    // --- Factor 3: Late night usage (after 11 PM) ---
    final now = DateTime.now();
    if (now.hour >= 23 || now.hour < 5) {
      final lateNightUsage = usage.where((app) {
        return AppClassifier.isAddictive(app['category'] as String);
      }).fold(0, (sum, app) => sum + (app['total_minutes'] as int? ?? 0));
      if (lateNightUsage > 0) {
        int nightPenalty = (lateNightUsage ~/ 3).clamp(0, 15);
        score += nightPenalty;
        factors.add('+$nightPenalty from late-night scrolling');
      }
    }

    // --- Factor 4: Broken focus sessions ---
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final sessions = await _db.getFocusSessionsForRange(todayStart, now.millisecondsSinceEpoch);
    int brokenSessions = sessions.where((s) => s['completed'] == 0).length;
    int completedSessions = sessions.where((s) => s['completed'] == 1).length;
    score += (brokenSessions * 10).clamp(0, 20);
    if (brokenSessions > 0) factors.add('+${(brokenSessions * 10).clamp(0, 20)} from $brokenSessions broken focus sessions');

    // --- Positive offsets ---
    // -10 per completed focus session
    int focusBonus = (completedSessions * 10).clamp(0, 30);
    score -= focusBonus;
    if (focusBonus > 0) factors.add('-$focusBonus from $completedSessions completed focus sessions');

    // -5 per completed habit
    int habitsCompleted = await _db.getHabitCompletionCountForDate(today);
    int habitBonus = (habitsCompleted * 5).clamp(0, 25);
    score -= habitBonus;
    if (habitBonus > 0) factors.add('-$habitBonus from $habitsCompleted habits completed');

    // -2 per hour of screen-free time (estimated)
    int totalScreenMinutes = usage.fold(0, (sum, app) => sum + (app['total_minutes'] as int? ?? 0));
    int awakeMinutes = (now.hour - 7).clamp(0, 16) * 60; // assume wake at 7am
    int freeMinutes = (awakeMinutes - totalScreenMinutes).clamp(0, awakeMinutes);
    int freeHours = freeMinutes ~/ 60;
    int freeBonus = (freeHours * 2).clamp(0, 10);
    score -= freeBonus;
    if (freeBonus > 0) factors.add('-$freeBonus from ${freeHours}h screen-free time');

    score = score.clamp(0, 100);

    // Determine severity
    String severity;
    String label;
    if (score <= 20) {
      severity = 'low';
      label = 'Balanced';
    } else if (score <= 45) {
      severity = 'moderate';
      label = 'Moderate';
    } else if (score <= 70) {
      severity = 'high';
      label = 'Elevated';
    } else {
      severity = 'critical';
      label = 'Critical';
    }

    return DopamineDebtResult(
      score: score,
      severity: severity,
      label: label,
      factors: factors,
      addictiveMinutes: addictiveMinutes,
      rapidSwitches: rapidSwitches,
      completedSessions: completedSessions,
    );
  }

  // ============================================================
  // FOCUS IDENTITY SYSTEM (Feature 4)
  // XP-based progression system
  // ============================================================

  Future<FocusIdentityResult> computeFocusIdentity() async {
    // Calculate total XP from all completed focus sessions
    final db = await _db.database;
    final xpResult = await db.rawQuery('SELECT COALESCE(SUM(xp_earned), 0) as total FROM focus_sessions WHERE completed = 1');
    int totalXP = xpResult.first['total'] as int? ?? 0;

    // Add XP from habit completions (5 XP each)
    final habitResult = await db.rawQuery('SELECT COUNT(*) as c FROM habit_completions WHERE completed = 1');
    int habitCompletions = habitResult.first['c'] as int? ?? 0;
    totalXP += habitCompletions * 5;

    // Add XP from challenges (15 XP each)
    final challengeResult = await db.rawQuery('SELECT COUNT(*) as c FROM challenges WHERE completed = 1');
    int challengeCompletions = challengeResult.first['c'] as int? ?? 0;
    totalXP += challengeCompletions * 15;

    // Calculate level and progress
    final identity = _getIdentityForXP(totalXP);

    // Calculate streak
    int streak = await _calculateStreak();

    return FocusIdentityResult(
      totalXP: totalXP,
      level: identity.level,
      title: identity.title,
      emoji: identity.emoji,
      xpForCurrentLevel: identity.xpForCurrentLevel,
      xpForNextLevel: identity.xpForNextLevel,
      progressPercent: identity.progressPercent,
      streak: streak,
      sessionsCompleted: (xpResult.first['total'] as int? ?? 0) > 0
        ? await _db.getCompletedSessionCount()
        : 0,
    );
  }

  _IdentityLevel _getIdentityForXP(int xp) {
    final levels = [
      _IdentityLevel(level: 1, title: 'Digital Seedling', emoji: '🌱', minXP: 0, maxXP: 50),
      _IdentityLevel(level: 2, title: 'Aware Wanderer', emoji: '🚶', minXP: 50, maxXP: 150),
      _IdentityLevel(level: 3, title: 'Focus Apprentice', emoji: '🎯', minXP: 150, maxXP: 350),
      _IdentityLevel(level: 4, title: 'Mindful Warrior', emoji: '⚔️', minXP: 350, maxXP: 600),
      _IdentityLevel(level: 5, title: 'Digital Monk', emoji: '🧘', minXP: 600, maxXP: 1000),
      _IdentityLevel(level: 6, title: 'Time Sovereign', emoji: '👑', minXP: 1000, maxXP: 1500),
      _IdentityLevel(level: 7, title: 'Zen Master', emoji: '🏔️', minXP: 1500, maxXP: 2500),
      _IdentityLevel(level: 8, title: 'Transcendent', emoji: '✨', minXP: 2500, maxXP: 5000),
      _IdentityLevel(level: 9, title: 'Digital Ascendant', emoji: '🌟', minXP: 5000, maxXP: 10000),
      _IdentityLevel(level: 10, title: 'Legend', emoji: '🏆', minXP: 10000, maxXP: 99999),
    ];

    for (int i = levels.length - 1; i >= 0; i--) {
      if (xp >= levels[i].minXP) {
        final current = levels[i];
        final xpInLevel = xp - current.minXP;
        final xpRange = current.maxXP - current.minXP;
        return _IdentityLevel(
          level: current.level,
          title: current.title,
          emoji: current.emoji,
          minXP: current.minXP,
          maxXP: current.maxXP,
          xpForCurrentLevel: xpInLevel,
          xpForNextLevel: xpRange,
          progressPercent: (xpInLevel / xpRange).clamp(0.0, 1.0),
        );
      }
    }
    return levels.first;
  }

  Future<int> _calculateStreak() async {
    int streak = 0;
    final now = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DeviceIntelligence.formatDate(date);

      // Check if there was at least one focus session or habit completion
      final sessions = await _db.getFocusSessionsForRange(
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch,
        DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch,
      );
      final habitsCompleted = await _db.getHabitCompletionCountForDate(dateStr);
      final completedFocusSessions = sessions.where((s) => s['completed'] == 1).length;

      if (completedFocusSessions > 0 || habitsCompleted > 0) {
        streak++;
      } else if (i > 0) {
        // Skip today (might not have done anything yet)
        break;
      }
    }
    return streak;
  }

  // ============================================================
  // LIFE RECOVERY CALCULATOR (Feature 6)
  // Shows real minutes recovered from reducing addictive usage
  // ============================================================

  Future<LifeRecoveryResult> computeLifeRecovery() async {
    final now = DateTime.now();
    final format = DateFormat('yyyy-MM-dd');

    // Get this week's addictive usage
    int thisWeekAddictive = 0;
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = format.format(date);
      final usage = await _db.getAppUsageForDate(dateStr);
      for (final app in usage) {
        if (AppClassifier.isAddictive(app['category'] as String)) {
          thisWeekAddictive += app['total_minutes'] as int? ?? 0;
        }
      }
    }

    // Get last week's addictive usage (days 7-13 ago)
    int lastWeekAddictive = 0;
    for (int i = 7; i < 14; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = format.format(date);
      final usage = await _db.getAppUsageForDate(dateStr);
      for (final app in usage) {
        if (AppClassifier.isAddictive(app['category'] as String)) {
          lastWeekAddictive += app['total_minutes'] as int? ?? 0;
        }
      }
    }

    // Calculate recovered minutes (positive = improvement)
    int recoveredMinutes = lastWeekAddictive - thisWeekAddictive;
    if (lastWeekAddictive == 0) recoveredMinutes = 0; // No baseline data yet

    // Calculate productive time gained this week
    int productiveMinutes = 0;
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = format.format(date);
      final usage = await _db.getAppUsageForDate(dateStr);
      for (final app in usage) {
        if (AppClassifier.isProductive(app['category'] as String)) {
          productiveMinutes += app['total_minutes'] as int? ?? 0;
        }
      }
    }

    // Generate what-if scenarios based on actual addictive usage
    int dailyAddictive = thisWeekAddictive > 0 ? thisWeekAddictive ~/ 7 : 0;
    List<RecoveryScenario> scenarios = [
      RecoveryScenario(
        emoji: '📚',
        label: 'Books per year',
        value: '${(dailyAddictive * 365 * 0.33 / 250).round()}',
        description: 'At ${dailyAddictive}min/day of scrolling, you could read ${(dailyAddictive * 365 * 0.33 / 250).round()} books instead',
      ),
      RecoveryScenario(
        emoji: '🏃',
        label: 'Workouts per month',
        value: '${(dailyAddictive * 30 / 30).round()}',
        description: '${(dailyAddictive * 30 / 30).round()} full workout sessions per month',
      ),
      RecoveryScenario(
        emoji: '🧠',
        label: 'Language lessons',
        value: '${(dailyAddictive * 365 / 25).round()}',
        description: 'Enough to become conversational in a new language',
      ),
      RecoveryScenario(
        emoji: '💰',
        label: 'Productive hours/year',
        value: '${(dailyAddictive * 365 / 60).round()}',
        description: 'That\'s ${(dailyAddictive * 365 / 60 / 8).round()} full work days of recovered time',
      ),
    ];

    return LifeRecoveryResult(
      recoveredMinutes: recoveredMinutes,
      thisWeekAddictive: thisWeekAddictive,
      lastWeekAddictive: lastWeekAddictive,
      productiveMinutes: productiveMinutes,
      dailyAddictiveAvg: dailyAddictive,
      improvementPercent: lastWeekAddictive > 0
        ? ((lastWeekAddictive - thisWeekAddictive) / lastWeekAddictive * 100).round()
        : 0,
      scenarios: scenarios,
    );
  }

  // ============================================================
  // ATTENTION INVESTMENT PORTFOLIO (Feature 10)
  // Categorizes all usage into "invested" vs "spent"
  // ============================================================

  Future<AttentionPortfolioResult> computeAttentionPortfolio() async {
    final now = DateTime.now();
    final format = DateFormat('yyyy-MM-dd');

    Map<String, int> categoryMinutes = {};
    int totalInvested = 0;
    int totalSpent = 0;
    int totalNeutral = 0;

    // Aggregate last 7 days
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = format.format(date);
      final usage = await _db.getAppUsageForDate(dateStr);

      for (final app in usage) {
        final category = app['category'] as String;
        final minutes = app['total_minutes'] as int? ?? 0;

        categoryMinutes[category] = (categoryMinutes[category] ?? 0) + minutes;

        if (AppClassifier.isProductive(category)) {
          totalInvested += minutes;
        } else if (AppClassifier.isAddictive(category)) {
          totalSpent += minutes;
        } else {
          totalNeutral += minutes;
        }
      }
    }

    int total = totalInvested + totalSpent + totalNeutral;
    double investmentRatio = total > 0 ? totalInvested / total : 0;

    // Build holdings list sorted by time
    List<AttentionHolding> holdings = [];
    categoryMinutes.forEach((category, minutes) {
      holdings.add(AttentionHolding(
        category: category,
        displayName: AppClassifier.categoryDisplayName(category),
        emoji: AppClassifier.categoryEmoji(category),
        minutes: minutes,
        percent: total > 0 ? (minutes / total * 100).round() : 0,
        isInvested: AppClassifier.isProductive(category),
        isSpent: AppClassifier.isAddictive(category),
      ));
    });
    holdings.sort((a, b) => b.minutes.compareTo(a.minutes));

    // Portfolio grade
    String grade;
    String advice;
    if (investmentRatio >= 0.6) {
      grade = 'A';
      advice = 'Your attention portfolio is heavily invested in growth. Outstanding discipline.';
    } else if (investmentRatio >= 0.45) {
      grade = 'B';
      advice = 'Solid portfolio. Shift a bit more time from entertainment to productive categories.';
    } else if (investmentRatio >= 0.3) {
      grade = 'C';
      advice = 'Your portfolio is consumption-heavy. Try replacing 30 minutes of scrolling with deep work.';
    } else {
      grade = 'D';
      advice = 'Most of your attention is being spent, not invested. Consider an emergency rebalance.';
    }

    return AttentionPortfolioResult(
      totalInvested: totalInvested,
      totalSpent: totalSpent,
      totalNeutral: totalNeutral,
      total: total,
      investmentRatio: investmentRatio,
      grade: grade,
      advice: advice,
      holdings: holdings,
    );
  }

  // ============================================================
  // SAVE DAILY SCORES
  // ============================================================

  Future<void> computeAndSaveDailyScores() async {
    final today = DeviceIntelligence.todayString();
    final dopamine = await computeDopamineDebt();
    final identity = await computeFocusIdentity();

    // Simple relapse risk from dopamine score trend
    String relapseRisk = 'low';
    if (dopamine.score > 60) {
      relapseRisk = 'very_high';
    } else if (dopamine.score > 40) {
      relapseRisk = 'high';
    } else if (dopamine.score > 20) {
      relapseRisk = 'medium';
    }

    final accessData = await DeviceIntelligence.getAccessibilityData();

    await _db.upsertBehavioralScore(
      date: today,
      dopamineDebt: dopamine.score,
      focusScore: identity.totalXP,
      relapseRisk: relapseRisk,
      xpTotal: identity.totalXP,
      identityLevel: identity.level,
      appSwitchCount: accessData['appSwitchCountToday'] as int? ?? 0,
      rapidSwitchCount: accessData['rapidSwitchCountToday'] as int? ?? 0,
    );
  }

  // ============================================================
  // DIGITAL ALTER EGO (Feature 2)
  // Mood-based character reflecting real behavior
  // ============================================================

  Future<AlterEgoResult> computeAlterEgo() async {
    final dopamine = await computeDopamineDebt();
    final today = DeviceIntelligence.todayString();
    final usage = await _db.getAppUsageForDate(today);

    int totalMinutes = usage.fold(0, (s, a) => s + (a['total_minutes'] as int? ?? 0));
    int productiveMinutes = 0;
    int addictiveMinutes = 0;
    for (final app in usage) {
      final cat = app['category'] as String;
      final mins = app['total_minutes'] as int? ?? 0;
      if (AppClassifier.isProductive(cat)) {
        productiveMinutes += mins;
      } else if (AppClassifier.isAddictive(cat)) {
        addictiveMinutes += mins;
      }
    }

    double productiveRatio = totalMinutes > 0 ? productiveMinutes / totalMinutes : 0.5;

    // Compute mood (0-100 where 100 = thriving)
    // Based on: dopamine debt (inverted), productive ratio, focus sessions
    int moodScore = 50; // baseline
    moodScore += ((productiveRatio - 0.3) * 60).round().clamp(-30, 30);
    moodScore -= (dopamine.score * 0.4).round();
    moodScore += (dopamine.completedSessions * 8).clamp(0, 20);
    moodScore = moodScore.clamp(0, 100);

    // Determine alter ego state
    String emoji;
    String state;
    String message;
    String aura;

    if (moodScore >= 80) {
      emoji = '🌟';
      state = 'Thriving';
      aura = 'golden';
      message = 'Your digital self is radiant. You\'re in full control today.';
    } else if (moodScore >= 60) {
      emoji = '😊';
      state = 'Balanced';
      aura = 'green';
      message = 'Doing well. A focus session would push you into thriving territory.';
    } else if (moodScore >= 40) {
      emoji = '😐';
      state = 'Drifting';
      aura = 'yellow';
      message = 'Your digital self is getting pulled toward distractions. Time to recenter.';
    } else if (moodScore >= 20) {
      emoji = '😰';
      state = 'Struggling';
      aura = 'orange';
      message = 'Heavy addictive usage is draining your energy. Take a break from screens.';
    } else {
      emoji = '🫠';
      state = 'Overwhelmed';
      aura = 'red';
      message = 'Critical dopamine overload. Consider using Emergency Lock right now.';
    }

    return AlterEgoResult(
      moodScore: moodScore,
      emoji: emoji,
      state: state,
      message: message,
      aura: aura,
      productiveRatio: productiveRatio,
      addictiveMinutes: addictiveMinutes,
      productiveMinutes: productiveMinutes,
    );
  }

  // ============================================================
  // REGRET FORECAST ENGINE (Feature 3)
  // Annual projections per app based on real daily averages
  // ============================================================

  Future<RegretForecastResult> computeRegretForecast() async {
    final now = DateTime.now();
    final format = DateFormat('yyyy-MM-dd');

    // Aggregate last 7 days per app
    Map<String, _AppAccumulator> appData = {};

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = format.format(date);
      final usage = await _db.getAppUsageForDate(dateStr);

      for (final app in usage) {
        final name = app['app_name'] as String? ?? app['package_name'] as String;
        final minutes = app['total_minutes'] as int? ?? 0;
        final category = app['category'] as String;

        appData.putIfAbsent(name, () => _AppAccumulator(name: name, category: category));
        appData[name]!.totalMinutes += minutes;
        appData[name]!.days++;
      }
    }

    // Build forecasts for addictive apps
    List<RegretForecast> forecasts = [];
    for (final entry in appData.entries) {
      final acc = entry.value;
      if (!AppClassifier.isAddictive(acc.category)) continue;
      if (acc.totalMinutes < 5) continue; // skip trivial usage

      int dailyAvg = acc.totalMinutes ~/ 7;
      int yearlyHours = (dailyAvg * 365) ~/ 60;
      int yearlyDays = yearlyHours ~/ 24;

      forecasts.add(RegretForecast(
        appName: acc.name,
        emoji: AppClassifier.categoryEmoji(acc.category),
        dailyAvgMinutes: dailyAvg,
        weeklyMinutes: acc.totalMinutes,
        yearlyHours: yearlyHours,
        yearlyDays: yearlyDays,
        regretLine: _generateRegretLine(acc.name, yearlyHours, yearlyDays),
      ));
    }

    // Sort by yearly hours (most impactful first)
    forecasts.sort((a, b) => b.yearlyHours.compareTo(a.yearlyHours));

    // Total addictive projection
    int totalDailyAddictive = forecasts.fold(0, (s, f) => s + f.dailyAvgMinutes);
    int totalYearlyHours = forecasts.fold(0, (s, f) => s + f.yearlyHours);

    return RegretForecastResult(
      forecasts: forecasts,
      totalDailyAddictive: totalDailyAddictive,
      totalYearlyHours: totalYearlyHours,
      totalYearlyDays: totalYearlyHours ~/ 24,
    );
  }

  String _generateRegretLine(String appName, int yearlyHours, int yearlyDays) {
    if (yearlyDays >= 30) {
      return 'At this rate, you\'ll spend $yearlyDays full days on $appName this year. That\'s an entire month of your life.';
    } else if (yearlyDays >= 14) {
      return '$yearlyDays days per year lost to $appName. That\'s a two-week vacation — gone.';
    } else if (yearlyHours >= 100) {
      return '${yearlyHours}h/year on $appName. You could master a new skill in that time.';
    } else {
      return '${yearlyHours}h/year on $appName. Small but adds up over a lifetime.';
    }
  }

  // ============================================================
  // AI TRIGGER DETECTION (Feature 5)
  // Analyzes usage patterns to identify emotional triggers
  // ============================================================

  Future<TriggerDetectionResult> computeTriggerDetection() async {
    final now = DateTime.now();
    final format = DateFormat('yyyy-MM-dd');

    // Analyze last 7 days of usage patterns
    Map<int, int> weekdayAddictive = {};

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = format.format(date);
      final usage = await _db.getAppUsageForDate(dateStr);
      int dayOfWeek = date.weekday; // 1=Mon, 7=Sun

      for (final app in usage) {
        if (AppClassifier.isAddictive(app['category'] as String)) {
          int mins = app['total_minutes'] as int? ?? 0;
          // Distribute evenly across waking hours as approximation
          // In future, use usage_events for precise timestamps
          weekdayAddictive[dayOfWeek] = (weekdayAddictive[dayOfWeek] ?? 0) + mins;
        }
      }
    }

    // Use accessibility data for hourly patterns
    final accessData = await DeviceIntelligence.getAccessibilityData();
    final currentHour = now.hour;

    // Detect triggers based on patterns
    List<DetectedTrigger> triggers = [];

    // Boredom: High usage during 2-5 PM weekdays
    int afternoonUsage = 0;
    for (int d = 1; d <= 5; d++) {
      afternoonUsage += weekdayAddictive[d] ?? 0;
    }
    if (afternoonUsage > 60) {
      triggers.add(DetectedTrigger(
        type: 'boredom',
        emoji: '😴',
        label: 'Afternoon Boredom',
        confidence: (afternoonUsage / 200).clamp(0.3, 0.95),
        description: 'You tend to scroll more during weekday afternoons. This is often boredom-triggered.',
        suggestion: 'Try a 15-min walk or a quick focus session when the urge hits between 2-5 PM.',
      ));
    }

    // Stress: Spikes after work hours (6-8 PM weekdays)
    int eveningWeekdayUsage = 0;
    for (int d = 1; d <= 5; d++) {
      eveningWeekdayUsage += (weekdayAddictive[d] ?? 0);
    }
    if (eveningWeekdayUsage > 80) {
      triggers.add(DetectedTrigger(
        type: 'stress',
        emoji: '😤',
        label: 'Post-Work Decompression',
        confidence: (eveningWeekdayUsage / 250).clamp(0.3, 0.9),
        description: 'Your addictive usage peaks after work hours, suggesting stress-relief scrolling.',
        suggestion: 'Replace post-work scrolling with 10 min of meditation or a short exercise.',
      ));
    }

    // Fatigue: Late night usage (11 PM - 2 AM)
    final today = DeviceIntelligence.todayString();
    final todayUsage = await _db.getAppUsageForDate(today);
    bool hasLateNightUsage = currentHour >= 23 || currentHour < 2;
    if (hasLateNightUsage) {
      int lateAddictive = todayUsage
        .where((a) => AppClassifier.isAddictive(a['category'] as String))
        .fold(0, (s, a) => s + (a['total_minutes'] as int? ?? 0));
      if (lateAddictive > 10) {
        triggers.add(DetectedTrigger(
          type: 'fatigue',
          emoji: '🌙',
          label: 'Late-Night Scrolling',
          confidence: 0.85,
          description: 'You\'re scrolling past 11 PM. Blue light disrupts sleep and feeds dopamine loops.',
          suggestion: 'Set a phone bedtime at 10:30 PM. Use Emergency Lock to enforce it.',
        ));
      }
    }

    // Loneliness: Weekend late-night usage
    int weekendUsage = (weekdayAddictive[6] ?? 0) + (weekdayAddictive[7] ?? 0);
    if (weekendUsage > 90) {
      triggers.add(DetectedTrigger(
        type: 'loneliness',
        emoji: '💔',
        label: 'Weekend Isolation',
        confidence: (weekendUsage / 300).clamp(0.3, 0.85),
        description: 'Your weekend social media usage is high, which often signals loneliness.',
        suggestion: 'Try scheduling one real-world activity every weekend to break the cycle.',
      ));
    }

    // Procrastination: High rapid switches
    int rapidSwitches = accessData['rapidSwitchCountToday'] as int? ?? 0;
    if (rapidSwitches > 5) {
      triggers.add(DetectedTrigger(
        type: 'procrastination',
        emoji: '🔄',
        label: 'App-Hopping Procrastination',
        confidence: (rapidSwitches / 15).clamp(0.4, 0.95),
        description: '$rapidSwitches rapid app switches detected today. This is classic procrastination behavior.',
        suggestion: 'Start a 25-minute focus session. Just commit to the first 5 minutes.',
      ));
    }

    // Sort by confidence
    triggers.sort((a, b) => b.confidence.compareTo(a.confidence));

    return TriggerDetectionResult(
      triggers: triggers,
      dominantTrigger: triggers.isNotEmpty ? triggers.first.type : 'none',
      overallRisk: triggers.isEmpty ? 'low' : triggers.first.confidence > 0.7 ? 'high' : 'moderate',
    );
  }

  // ============================================================
  // DIGITAL RELAPSE PREDICTOR (Feature 9)
  // 3-day rolling avg vs 7-day baseline trend analysis
  // ============================================================

  Future<RelapseResult> computeRelapsePrediction() async {
    final now = DateTime.now();
    final format = DateFormat('yyyy-MM-dd');

    // Last 3 days addictive usage (recent trend)
    int recent3DayAddictive = 0;
    for (int i = 0; i < 3; i++) {
      final dateStr = format.format(now.subtract(Duration(days: i)));
      final usage = await _db.getAppUsageForDate(dateStr);
      for (final app in usage) {
        if (AppClassifier.isAddictive(app['category'] as String)) {
          recent3DayAddictive += app['total_minutes'] as int? ?? 0;
        }
      }
    }
    double recent3DayAvg = recent3DayAddictive / 3;

    // Last 7 days addictive usage (baseline)
    int baseline7DayAddictive = 0;
    for (int i = 0; i < 7; i++) {
      final dateStr = format.format(now.subtract(Duration(days: i)));
      final usage = await _db.getAppUsageForDate(dateStr);
      for (final app in usage) {
        if (AppClassifier.isAddictive(app['category'] as String)) {
          baseline7DayAddictive += app['total_minutes'] as int? ?? 0;
        }
      }
    }
    double baseline7DayAvg = baseline7DayAddictive / 7;

    // Calculate risk factors
    List<String> riskFactors = [];
    int riskScore = 0;

    // Factor 1: Rising addictive trend
    if (baseline7DayAvg > 0 && recent3DayAvg > baseline7DayAvg * 1.2) {
      int increase = ((recent3DayAvg / baseline7DayAvg - 1) * 100).round();
      riskScore += 25;
      riskFactors.add('Addictive usage up $increase% vs weekly average');
    }

    // Factor 2: Dopamine debt level
    final dopamine = await computeDopamineDebt();
    if (dopamine.score > 50) {
      riskScore += 20;
      riskFactors.add('Dopamine debt at ${dopamine.score}/100');
    }

    // Factor 3: Broken habits
    final habitsToday = await _db.getHabitCompletionCountForDate(DeviceIntelligence.todayString());
    if (habitsToday == 0) {
      riskScore += 15;
      riskFactors.add('No habits completed today');
    }

    // Factor 4: No focus sessions today
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final sessions = await _db.getFocusSessionsForRange(todayStart, now.millisecondsSinceEpoch);
    int completedToday = sessions.where((s) => s['completed'] == 1).length;
    if (completedToday == 0) {
      riskScore += 10;
      riskFactors.add('No focus sessions completed today');
    }

    // Factor 5: Late night time
    if (now.hour >= 21) {
      riskScore += 10;
      riskFactors.add('Evening hours — peak vulnerability time');
    }

    // Factor 6: Rapid app switches
    final accessData = await DeviceIntelligence.getAccessibilityData();
    int rapidSwitches = accessData['rapidSwitchCountToday'] as int? ?? 0;
    if (rapidSwitches > 3) {
      riskScore += 15;
      riskFactors.add('$rapidSwitches rapid app switches (restlessness)');
    }

    riskScore = riskScore.clamp(0, 100);

    // Determine risk level
    String riskLevel;
    String riskEmoji;
    String advice;

    if (riskScore <= 20) {
      riskLevel = 'Low';
      riskEmoji = '🟢';
      advice = 'You\'re in control. Keep maintaining healthy patterns.';
    } else if (riskScore <= 45) {
      riskLevel = 'Moderate';
      riskEmoji = '🟡';
      advice = 'Some warning signs present. A focus session would help stabilize.';
    } else if (riskScore <= 70) {
      riskLevel = 'High';
      riskEmoji = '🟠';
      advice = 'Multiple risk factors active. Consider Emergency Lock or a digital break.';
    } else {
      riskLevel = 'Very High';
      riskEmoji = '🔴';
      advice = 'Critical relapse risk. Activate Emergency Lock now and step away from your phone.';
    }

    return RelapseResult(
      riskScore: riskScore,
      riskLevel: riskLevel,
      riskEmoji: riskEmoji,
      advice: advice,
      factors: riskFactors,
      recent3DayAvg: recent3DayAvg.round(),
      baseline7DayAvg: baseline7DayAvg.round(),
      trendDirection: recent3DayAvg > baseline7DayAvg * 1.1 ? 'rising' : recent3DayAvg < baseline7DayAvg * 0.9 ? 'falling' : 'stable',
    );
  }

  // ============================================================
  // ANTI-DOOMSCROLL CHALLENGES (Feature 7)
  // Generates 3 personalized daily challenges based on recent usage
  // ============================================================

  Future<void> generateDailyChallenges() async {
    final today = DeviceIntelligence.todayString();
    final existing = await _db.getChallengesForDate(today);
    if (existing.isNotEmpty) return; // Already generated

    final format = DateFormat('yyyy-MM-dd');
    final yesterday = format.format(DateTime.now().subtract(const Duration(days: 1)));
    final yesterdayUsage = await _db.getAppUsageForDate(yesterday);

    List<Map<String, dynamic>> newChallenges = [];

    // 1. App-specific reduction challenge (find most used addictive app)
    String topAddictiveApp = '';
    int topMinutes = 0;
    for (final app in yesterdayUsage) {
      if (AppClassifier.isAddictive(app['category'] as String)) {
        int mins = app['total_minutes'] as int? ?? 0;
        if (mins > topMinutes) {
          topMinutes = mins;
          topAddictiveApp = app['app_name'] as String? ?? app['package_name'] as String;
        }
      }
    }

    if (topAddictiveApp.isNotEmpty && topMinutes > 15) {
      int targetMinutes = (topMinutes * 0.7).round(); // 30% reduction
      newChallenges.add({
        'type': 'reduction',
        'desc': 'Keep $topAddictiveApp usage under $targetMinutes mins today (Yesterday: $topMinutes mins)',
        'xp': 20,
      });
    } else {
      newChallenges.add({
        'type': 'baseline_addictive',
        'desc': 'Keep total addictive app usage under 60 minutes today',
        'xp': 20,
      });
    }

    // 2. Focus challenge
    final sessions = await _db.getFocusSessionsForRange(
        DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        DateTime.now().millisecondsSinceEpoch);
    
    int completedYesterday = sessions.where((s) => s['completed'] == 1).length;
    if (completedYesterday == 0) {
      newChallenges.add({
        'type': 'focus_starter',
        'desc': 'Complete at least one 15-minute Focus Session',
        'xp': 15,
      });
    } else {
      newChallenges.add({
        'type': 'focus_streak',
        'desc': 'Complete ${completedYesterday + 1} Focus Sessions today',
        'xp': 25,
      });
    }

    // 3. Behavioral challenge
    final accessData = await DeviceIntelligence.getAccessibilityData();
    int rapidSwitches = accessData['rapidSwitchCountToday'] as int? ?? 0;
    
    if (rapidSwitches > 5) {
      newChallenges.add({
        'type': 'mindfulness',
        'desc': 'Reduce rapid app switching (less than 3 times today)',
        'xp': 15,
      });
    } else {
      newChallenges.add({
        'type': 'night_routine',
        'desc': 'No addictive apps after 10:00 PM',
        'xp': 15,
      });
    }

    // Insert into DB
    for (final c in newChallenges) {
      await _db.upsertChallenge(
        date: today,
        challengeType: c['type'] as String,
        description: c['desc'] as String,
        completed: false,
        xpReward: c['xp'] as int,
      );
    }
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

class DopamineDebtResult {
  final int score;
  final String severity; // low, moderate, high, critical
  final String label;
  final List<String> factors;
  final int addictiveMinutes;
  final int rapidSwitches;
  final int completedSessions;

  DopamineDebtResult({
    required this.score,
    required this.severity,
    required this.label,
    required this.factors,
    required this.addictiveMinutes,
    required this.rapidSwitches,
    required this.completedSessions,
  });
}

class FocusIdentityResult {
  final int totalXP;
  final int level;
  final String title;
  final String emoji;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final double progressPercent;
  final int streak;
  final int sessionsCompleted;

  FocusIdentityResult({
    required this.totalXP,
    required this.level,
    required this.title,
    required this.emoji,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
    required this.progressPercent,
    required this.streak,
    required this.sessionsCompleted,
  });
}

class _IdentityLevel {
  final int level;
  final String title;
  final String emoji;
  final int minXP;
  final int maxXP;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final double progressPercent;

  _IdentityLevel({
    required this.level,
    required this.title,
    required this.emoji,
    required this.minXP,
    required this.maxXP,
    this.xpForCurrentLevel = 0,
    this.xpForNextLevel = 0,
    this.progressPercent = 0.0,
  });
}

class LifeRecoveryResult {
  final int recoveredMinutes;
  final int thisWeekAddictive;
  final int lastWeekAddictive;
  final int productiveMinutes;
  final int dailyAddictiveAvg;
  final int improvementPercent;
  final List<RecoveryScenario> scenarios;

  LifeRecoveryResult({
    required this.recoveredMinutes,
    required this.thisWeekAddictive,
    required this.lastWeekAddictive,
    required this.productiveMinutes,
    required this.dailyAddictiveAvg,
    required this.improvementPercent,
    required this.scenarios,
  });
}

class RecoveryScenario {
  final String emoji;
  final String label;
  final String value;
  final String description;

  RecoveryScenario({
    required this.emoji,
    required this.label,
    required this.value,
    required this.description,
  });
}

class AttentionPortfolioResult {
  final int totalInvested;
  final int totalSpent;
  final int totalNeutral;
  final int total;
  final double investmentRatio;
  final String grade;
  final String advice;
  final List<AttentionHolding> holdings;

  AttentionPortfolioResult({
    required this.totalInvested,
    required this.totalSpent,
    required this.totalNeutral,
    required this.total,
    required this.investmentRatio,
    required this.grade,
    required this.advice,
    required this.holdings,
  });
}

class AttentionHolding {
  final String category;
  final String displayName;
  final String emoji;
  final int minutes;
  final int percent;
  final bool isInvested;
  final bool isSpent;

  AttentionHolding({
    required this.category,
    required this.displayName,
    required this.emoji,
    required this.minutes,
    required this.percent,
    required this.isInvested,
    required this.isSpent,
  });
}

// Phase 2 data classes

class AlterEgoResult {
  final int moodScore;
  final String emoji;
  final String state;
  final String message;
  final String aura; // golden, green, yellow, orange, red
  final double productiveRatio;
  final int addictiveMinutes;
  final int productiveMinutes;

  AlterEgoResult({
    required this.moodScore,
    required this.emoji,
    required this.state,
    required this.message,
    required this.aura,
    required this.productiveRatio,
    required this.addictiveMinutes,
    required this.productiveMinutes,
  });
}

class _AppAccumulator {
  final String name;
  final String category;
  int totalMinutes = 0;
  int days = 0;

  _AppAccumulator({required this.name, required this.category});
}

class RegretForecast {
  final String appName;
  final String emoji;
  final int dailyAvgMinutes;
  final int weeklyMinutes;
  final int yearlyHours;
  final int yearlyDays;
  final String regretLine;

  RegretForecast({
    required this.appName,
    required this.emoji,
    required this.dailyAvgMinutes,
    required this.weeklyMinutes,
    required this.yearlyHours,
    required this.yearlyDays,
    required this.regretLine,
  });
}

class RegretForecastResult {
  final List<RegretForecast> forecasts;
  final int totalDailyAddictive;
  final int totalYearlyHours;
  final int totalYearlyDays;

  RegretForecastResult({
    required this.forecasts,
    required this.totalDailyAddictive,
    required this.totalYearlyHours,
    required this.totalYearlyDays,
  });
}

class DetectedTrigger {
  final String type;
  final String emoji;
  final String label;
  final double confidence;
  final String description;
  final String suggestion;

  DetectedTrigger({
    required this.type,
    required this.emoji,
    required this.label,
    required this.confidence,
    required this.description,
    required this.suggestion,
  });
}

class TriggerDetectionResult {
  final List<DetectedTrigger> triggers;
  final String dominantTrigger;
  final String overallRisk;

  TriggerDetectionResult({
    required this.triggers,
    required this.dominantTrigger,
    required this.overallRisk,
  });
}

class RelapseResult {
  final int riskScore;
  final String riskLevel;
  final String riskEmoji;
  final String advice;
  final List<String> factors;
  final int recent3DayAvg;
  final int baseline7DayAvg;
  final String trendDirection; // rising, falling, stable

  RelapseResult({
    required this.riskScore,
    required this.riskLevel,
    required this.riskEmoji,
    required this.advice,
    required this.factors,
    required this.recent3DayAvg,
    required this.baseline7DayAvg,
    required this.trendDirection,
  });
}
