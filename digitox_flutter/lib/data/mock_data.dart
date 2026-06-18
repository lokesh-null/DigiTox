import 'package:flutter/material.dart';

class MockApp {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final Color color;
  int minutes;
  bool blocked;

  MockApp({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.color,
    this.minutes = 0,
    this.blocked = true,
  });
}

class AppCategories {
  static const productive = 'productive';
  static const neutral = 'neutral';
  static const addictive = 'addictive';
}

final List<MockApp> mockApps = [
  MockApp(id: 'instagram', name: 'Instagram', emoji: '📸', category: AppCategories.addictive, color: const Color(0xFFE1306C), blocked: true),
  MockApp(id: 'tiktok', name: 'TikTok', emoji: '🎵', category: AppCategories.addictive, color: const Color(0xFFFF0050), blocked: true),
  MockApp(id: 'youtube', name: 'YouTube', emoji: '▶️', category: AppCategories.addictive, color: const Color(0xFFFF0000), blocked: true),
  MockApp(id: 'twitter', name: 'X (Twitter)', emoji: '🐦', category: AppCategories.addictive, color: const Color(0xFF1DA1F2), blocked: true),
  MockApp(id: 'reddit', name: 'Reddit', emoji: '🔴', category: AppCategories.addictive, color: const Color(0xFFFF4500), blocked: false),
  MockApp(id: 'snapchat', name: 'Snapchat', emoji: '👻', category: AppCategories.addictive, color: const Color(0xFFFFFC00), blocked: false),
  MockApp(id: 'vscode', name: 'VS Code', emoji: '💻', category: AppCategories.productive, color: const Color(0xFF007ACC)),
  MockApp(id: 'notion', name: 'Notion', emoji: '📝', category: AppCategories.productive, color: const Color(0xFFFFFFFF)),
  MockApp(id: 'slack', name: 'Slack', emoji: '💬', category: AppCategories.productive, color: const Color(0xFF4A154B)),
  MockApp(id: 'figma', name: 'Figma', emoji: '🎨', category: AppCategories.productive, color: const Color(0xFFF24E1E)),
  MockApp(id: 'chrome', name: 'Chrome', emoji: '🌐', category: AppCategories.neutral, color: const Color(0xFF4285F4)),
  MockApp(id: 'spotify', name: 'Spotify', emoji: '🎧', category: AppCategories.neutral, color: const Color(0xFF1DB954)),
  MockApp(id: 'whatsapp', name: 'WhatsApp', emoji: '💚', category: AppCategories.neutral, color: const Color(0xFF25D366)),
  MockApp(id: 'games', name: 'Mobile Games', emoji: '🎮', category: AppCategories.addictive, color: const Color(0xFF9B59B6), blocked: true),
];

class WeeklyData {
  final String day;
  final int productive;
  final int addictive;
  final int neutral;
  final int total;

  WeeklyData({required this.day, required this.productive, required this.addictive, required this.neutral, required this.total});
}

List<WeeklyData> generateWeeklyData() {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<WeeklyData> data = [];
  for (int i = 0; i < days.length; i++) {
    bool isWeekend = i >= 5;
    double baseProductive = isWeekend ? 30 + (DateTime.now().millisecond % 60) : 120 + (DateTime.now().millisecond % 120);
    double baseAddictive = isWeekend ? 120 + (DateTime.now().millisecond % 120) : 60 + (DateTime.now().millisecond % 90);
    double baseNeutral = 30 + (DateTime.now().millisecond % 60);

    data.add(WeeklyData(
      day: days[i],
      productive: baseProductive.round(),
      addictive: baseAddictive.round(),
      neutral: baseNeutral.round(),
      total: (baseProductive + baseAddictive + baseNeutral).round(),
    ));
  }
  return data;
}

List<MockApp> generateTodayUsage() {
  var usedApps = mockApps.where((app) => (DateTime.now().millisecond % 10) > 3).toList();
  for (var app in usedApps) {
    if (app.category == AppCategories.addictive) {
      app.minutes = 15 + (DateTime.now().millisecond % 90);
    } else if (app.category == AppCategories.productive) {
      app.minutes = 30 + (DateTime.now().millisecond % 120);
    } else {
      app.minutes = 10 + (DateTime.now().millisecond % 45);
    }
  }
  usedApps.sort((a, b) => b.minutes.compareTo(a.minutes));
  return usedApps;
}

class HeatmapData {
  final int hour;
  final int level;
  HeatmapData({required this.hour, required this.level});
}

List<HeatmapData> generateHeatmapData() {
  List<HeatmapData> data = [];
  for (int h = 0; h < 24; h++) {
    int level;
    if (h >= 0 && h < 6) level = (DateTime.now().millisecond % 10) > 7 ? 1 : 0;
    else if (h >= 6 && h < 9) level = (DateTime.now().millisecond % 2);
    else if (h >= 9 && h < 12) level = (DateTime.now().millisecond % 3);
    else if (h >= 12 && h < 14) level = 1 + (DateTime.now().millisecond % 2);
    else if (h >= 14 && h < 18) level = (DateTime.now().millisecond % 3);
    else if (h >= 18 && h < 21) level = 1 + (DateTime.now().millisecond % 3);
    else level = 2 + (DateTime.now().millisecond % 3);
    data.add(HeatmapData(hour: h, level: level > 4 ? 4 : level));
  }
  return data;
}

List<Map<String, String>> getTimeRealities(int wastedMinutes) {
  return [
    {'emoji': '📚', 'text': 'You could\'ve read **${(wastedMinutes * 0.33).round()} pages** of a book'},
    {'emoji': '🏃', 'text': 'That\'s **${(wastedMinutes / 30).round()} workouts** you could have done'},
    {'emoji': '🧠', 'text': '**${(wastedMinutes / 25).round()} lessons** of a new language'},
    {'emoji': '🎸', 'text': '**${(wastedMinutes / 20).round()} practice sessions** on an instrument'},
    {'emoji': '📅', 'text': 'This week = **${(wastedMinutes / 60).toStringAsFixed(1)} hours** lost to scrolling'},
    {'emoji': '🌍', 'text': 'In a year, that\'s **${(wastedMinutes * 52 / 60 / 24).round()} full days** of your life'},
  ];
}

List<Map<String, String>> getAISuggestions(List<HeatmapData> heatmapData) {
  var peakHours = heatmapData.where((d) => d.level >= 3).map((d) => d.hour).toList();
  List<Map<String, String>> suggestions = [];
  
  if (peakHours.any((h) => h >= 21)) {
    suggestions.add({
      'icon': '🌙',
      'text': 'You\'re most distracted between **9 PM–12 AM**. Try activating Focus Mode at 8:45 PM to build a wind-down routine.'
    });
  }
  if (peakHours.any((h) => h >= 12 && h <= 14)) {
    suggestions.add({
      'icon': '🍽️',
      'text': 'Your lunch break turns into a scroll session. Try a **15-min phone-free lunch** challenge.'
    });
  }
  suggestions.add({
    'icon': '📊',
    'text': 'Your productive time peaks in the **morning (9–11 AM)**. Schedule your hardest tasks here.'
  });
  suggestions.add({
    'icon': '🎯',
    'text': 'Social media accounts for **62% of your wasted time**. Consider using the 5-second pause feature.'
  });
  suggestions.add({
    'icon': '🔄',
    'text': 'Replacing 30 min of Instagram with reading could help you finish **24 books this year**.'
  });
  return suggestions;
}

final List<Map<String, String>> habitAlternatives = [
  {'from': 'Instagram', 'to': '📖 Read 10 pages', 'emoji': '📸'},
  {'from': 'TikTok', 'to': '🚶 Take a 10-min walk', 'emoji': '🎵'},
  {'from': 'YouTube', 'to': '✍️ Journal for 5 minutes', 'emoji': '▶️'},
  {'from': 'Twitter', 'to': '🧘 Meditate for 5 min', 'emoji': '🐦'},
  {'from': 'Reddit', 'to': '🧩 Solve a puzzle', 'emoji': '🔴'},
];

class Habit {
  String id;
  String name;
  String emoji;
  int streak;
  bool completedToday;

  Habit({required this.id, required this.name, required this.emoji, required this.streak, required this.completedToday});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'streak': streak,
    'completedToday': completedToday,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'],
    name: json['name'],
    emoji: json['emoji'],
    streak: json['streak'],
    completedToday: json['completedToday'],
  );
}

final List<Habit> defaultHabits = [
  Habit(id: 'h1', name: 'Morning without phone', emoji: '🌅', streak: 5, completedToday: false),
  Habit(id: 'h2', name: 'Read for 20 minutes', emoji: '📚', streak: 12, completedToday: true),
  Habit(id: 'h3', name: 'No social media before noon', emoji: '🚫', streak: 3, completedToday: false),
  Habit(id: 'h4', name: 'Evening walk (no phone)', emoji: '🌆', streak: 8, completedToday: true),
  Habit(id: 'h5', name: 'Screen-free bedtime', emoji: '😴', streak: 2, completedToday: false),
];

final List<Map<String, String>> interventionPrompts = [
  {'emoji': '🤔', 'title': 'Are you using this intentionally?', 'message': 'You\'ve been scrolling for a while. Take a breath and ask yourself — is this how you want to spend this moment?'},
  {'emoji': '⏰', 'title': 'What were you supposed to do right now?', 'message': 'You opened your phone with a purpose. But then you got sidetracked. Let\'s get back on track.'},
  {'emoji': '🪞', 'title': 'Time for a reality check', 'message': 'You\'ve spent 23 minutes on this app. That\'s already 8 pages of a book you could\'ve read.'},
  {'emoji': '🧠', 'title': 'Your future self is watching', 'message': 'Every minute matters. This isn\'t about guilt — it\'s about intention. You\'re capable of more.'},
  {'emoji': '💪', 'title': 'You\'re stronger than the algorithm', 'message': 'This app is designed to keep you scrolling. Break the loop. Close it and do something meaningful.'},
];

List<int> generateContributionData() {
  List<int> data = [];
  for (int i = 0; i < 28; i++) {
    double rand = (DateTime.now().millisecond % 100) / 100.0;
    int level;
    if (rand < 0.15) level = 0;
    else if (rand < 0.35) level = 1;
    else if (rand < 0.6) level = 2;
    else if (rand < 0.85) level = 3;
    else level = 4;
    data.add(level);
  }
  return data;
}

Map<String, String> getWeeklyGrade(List<WeeklyData> weeklyData) {
  int totalProductive = weeklyData.fold(0, (s, d) => s + d.productive);
  int totalAddictive = weeklyData.fold(0, (s, d) => s + d.addictive);
  double ratio = totalProductive / (totalProductive + totalAddictive);
  
  if (ratio >= 0.7) return {'grade': 'A', 'title': 'Excellent Focus!', 'desc': 'You\'re in the top tier of digital discipline.'};
  if (ratio >= 0.55) return {'grade': 'B+', 'title': 'Good Progress', 'desc': 'You\'re trending in the right direction. Keep pushing.'};
  if (ratio >= 0.4) return {'grade': 'B', 'title': 'Room to Grow', 'desc': 'You\'re aware, and that\'s the first step. Let\'s optimize.'};
  if (ratio >= 0.25) return {'grade': 'C', 'title': 'Needs Attention', 'desc': 'Your screen time is outpacing your goals. Try Focus Mode more.'};
  return {'grade': 'D', 'title': 'Time to Reset', 'desc': 'Consider activating Emergency Lock to break the cycle.'};
}
