import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'data_provider.dart';
import 'behavioral_engine.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final _storage = const FlutterSecureStorage();
  static const String _apiKeyKey = 'gemini_api_key';

  Future<void> setApiKey(String key) async {
    await _storage.write(key: _apiKeyKey, value: key.trim());
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyKey);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  Future<GenerativeModel?> _getModel() async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;
    
    // We use gemini-2.5-flash as it is supported by your specific API key
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
      ),
      systemInstruction: Content.system('''
You are the DigiTox AI Coach, a strict but empathetic digital wellbeing psychologist.
Your goal is to analyze the user's smartphone telemetry data and provide hyper-personalized psychological insights.
Do not use generic advice like "put your phone down". Instead, reference their specific app usage, their focus contracts, and behavioral patterns (e.g., rapid switching, late-night usage).
Your tone is professional, direct, and encouraging. You hold the user accountable but understand that digital addiction is a design problem.
'''),
    );
  }

  // ==========================================
  // FEATURE 11: AI Coach Daily Briefing
  // ==========================================
  Future<String> getDailyBriefing() async {
    final model = await _getModel();
    if (model == null) return "AI Coach is disabled. Please set your Gemini API key in Settings.";

    try {
      final usageStats = await DataProvider().getTodayStats();
      final usage = await DataProvider().getTodayUsage();
      final dopamine = await BehavioralEngine().computeDopamineDebt();
      
      final String contextData = jsonEncode({
        "today_total_minutes": usageStats.total,
        "productive_minutes": usageStats.productive,
        "addictive_minutes": usageStats.addictive,
        "dopamine_debt_score": dopamine.score,
        "dopamine_severity": dopamine.severity,
        "top_apps": usage.take(3).map((a) => {"app": a.appName, "mins": a.minutes}).toList(),
      });

      final response = await model.generateContent([
        Content.text('''
Analyze the following device telemetry for today and write a custom 2-sentence morning/daily briefing. 
If it's early in the day (low usage), set an intention based on yesterday. If it's later in the day, comment on their current progress.
Keep it strictly under 3 sentences. Be direct.

Telemetry JSON:
$contextData
''')
      ]);

      return response.text?.trim() ?? "Unable to generate briefing at this time.";
    } catch (e) {
      final apiKey = await getApiKey();
      String availableModels = "";
      try {
        final res = await http.get(Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final models = (data['models'] as List).map((m) => m['name']).toList();
          availableModels = "\nAvailable models on your key: ${models.join(', ')}";
        } else {
          availableModels = "\nFailed to fetch models: ${res.statusCode}";
        }
      } catch (innerE) {
        availableModels = "\nCould not fetch models: $innerE";
      }
      return "AI Coach Error: $e$availableModels";
    }
  }

  // ==========================================
  // FEATURE 12: Legacy Projection
  // ==========================================
  Future<String> getLegacyProjection() async {
    final model = await _getModel();
    if (model == null) return "AI projection requires an API key.";

    try {
      final weeklyData = await DataProvider().getWeeklyData();
      final totalAddictive = weeklyData.fold(0, (s, d) => s + d.addictive);
      final avgAddictiveDaily = (totalAddictive / 7).round();
      final yearlyHours = (avgAddictiveDaily * 365) / 60;

      final String contextData = jsonEncode({
        "average_daily_addictive_minutes": avgAddictiveDaily,
        "projected_yearly_hours_lost": yearlyHours.round(),
      });

      final response = await model.generateContent([
        Content.text('''
Based on this user's current addictive app usage trajectory, write a strict, realistic 1-paragraph psychological projection of where they will be in 5 years if nothing changes.
Focus on the psychological toll, missed potential, and the compound effect of lost time. Do not sugarcoat it.

Telemetry JSON:
$contextData
''')
      ]);

      return response.text?.trim() ?? "Unable to generate projection.";
    } catch (e) {
      return "Error generating legacy projection: $e";
    }
  }

  // ==========================================
  // FEATURE 15: Weekly Psychological Report
  // ==========================================
  Future<String> getWeeklyPsychologicalReport() async {
    final model = await _getModel();
    if (model == null) return "Weekly Report requires an API key.";

    try {
      final weeklyData = await DataProvider().getWeeklyData();
      final heatmap = await DataProvider().getHeatmapData();
      final grade = await DataProvider().getWeeklyGrade();
      
      final String contextData = jsonEncode({
        "weekly_grade": grade['grade'],
        "daily_breakdown": weeklyData.map((d) => {
          "day": d.day,
          "productive_mins": d.productive,
          "addictive_mins": d.addictive,
        }).toList(),
        "peak_distraction_hours": heatmap.where((h) => h.level >= 3).map((h) => h.hour).toList(),
      });

      final response = await model.generateContent([
        Content.text('''
Write a comprehensive Weekly Psychological Report based on this 7-day smartphone telemetry.
Format the report with these exactly 3 markdown headers:
### 🧠 Behavioral Triggers Identified
(List 2-3 specific patterns you see in their data, e.g., "You consistently spike in addictive usage on Thursdays.")
### ⚖️ The Dopamine Imbalance
(Analyze the ratio of their productive vs addictive time)
### 🎯 Intervention Plan
(Provide 2 strict, actionable rules for next week based on their specific peak distraction hours)

Telemetry JSON:
$contextData
''')
      ]);

      return response.text?.trim() ?? "Unable to generate report.";
    } catch (e) {
      return "Error generating weekly report: $e";
    }
  }
}
