/// Automatic app classification engine.
/// Classifies installed apps into behavioral categories using
/// package name patterns and Android's built-in category system.
class AppClassifier {
  // Well-known package → category mappings
  static const Map<String, String> _knownApps = {
    // Social Media
    'com.instagram.android': 'social_media',
    'com.twitter.android': 'social_media',
    'com.facebook.katana': 'social_media',
    'com.facebook.lite': 'social_media',
    'com.snapchat.android': 'social_media',
    'com.pinterest': 'social_media',
    'com.tumblr': 'social_media',
    'com.linkedin.android': 'social_media',
    'com.reddit.frontpage': 'social_media',
    'com.zhiliaoapp.musically': 'social_media', // TikTok
    'com.ss.android.ugc.trill': 'social_media', // TikTok (alt)

    // Messaging
    'com.whatsapp': 'messaging',
    'com.whatsapp.w4b': 'messaging',
    'org.telegram.messenger': 'messaging',
    'com.discord': 'messaging',
    'com.Slack': 'messaging',
    'com.viber.voip': 'messaging',
    'com.skype.raider': 'messaging',
    'jp.naver.line.android': 'messaging',
    'com.google.android.apps.messaging': 'messaging',

    // Gaming
    'com.supercell.clashofclans': 'gaming',
    'com.supercell.clashroyale': 'gaming',
    'com.kiloo.subwaysurf': 'gaming',
    'com.miniclip.eightballpool': 'gaming',
    'com.mojang.minecraftpe': 'gaming',
    'com.activision.callofduty.shooter': 'gaming',
    'com.pubg.imobile': 'gaming',
    'com.epicgames.fortnite': 'gaming',
    'com.roblox.client': 'gaming',

    // Streaming / Entertainment
    'com.google.android.youtube': 'streaming',
    'com.google.android.apps.youtube.music': 'streaming',
    'com.netflix.mediaclient': 'streaming',
    'com.amazon.avod.thirdpartyclient': 'streaming', // Prime Video
    'com.disney.disneyplus': 'streaming',
    'in.startv.hotstar': 'streaming', // Disney+ Hotstar
    'com.spotify.music': 'streaming',
    'com.apple.android.music': 'streaming',
    'tv.twitch.android.app': 'streaming',

    // Productivity
    'com.microsoft.office.outlook': 'productive',
    'com.microsoft.teams': 'productive',
    'com.microsoft.office.word': 'productive',
    'com.microsoft.office.excel': 'productive',
    'com.google.android.apps.docs': 'productive',
    'com.google.android.apps.docs.editors.docs': 'productive',
    'com.google.android.apps.docs.editors.sheets': 'productive',
    'com.google.android.apps.docs.editors.slides': 'productive',
    'com.google.android.gm': 'productive', // Gmail
    'com.google.android.calendar': 'productive',
    'com.todoist': 'productive',
    'notion.id': 'productive',
    'com.figma.mirror': 'productive',
    'com.trello': 'productive',
    'com.asana.app': 'productive',
    'com.evernote': 'productive',

    // Education
    'com.duolingo': 'education',
    'com.coursera.app': 'education',
    'com.udemy.android': 'education',
    'com.byju': 'education',
    'com.google.android.apps.classroom': 'education',
    'com.khanacademy': 'education',
    'com.linkedin.android.learning': 'education',

    // Development
    'com.termux': 'development',
    'com.foxdebug.acodefree': 'development',

    // Health & Fitness
    'com.google.android.apps.fitness': 'health',
    'com.strava': 'health',
    'com.myfitnesspal.android': 'health',
    'com.calm.android': 'health',
    'com.headspace.android': 'health',

    // Shopping
    'com.amazon.mShop.android.shopping': 'shopping',
    'com.flipkart.android': 'shopping',
    'com.myntra.android': 'shopping',
    'in.amazon.mShop.android.shopping': 'shopping',

    // Navigation
    'com.google.android.apps.maps': 'navigation',
    'com.waze': 'navigation',
    'com.ubercab': 'navigation',
    'com.olacabs.customer': 'navigation',

    // Finance
    'com.google.android.apps.walletnfcrel': 'finance',
    'net.one97.paytm': 'finance',
    'com.phonepe.app': 'finance',

    // Browsers
    'com.android.chrome': 'browser',
    'org.mozilla.firefox': 'browser',
    'com.brave.browser': 'browser',
    'com.opera.browser': 'browser',

    // Utilities (benign)
    'com.google.android.apps.photos': 'utility',
    'com.google.android.deskclock': 'utility',
    'com.android.calculator2': 'utility',
    'com.google.android.contacts': 'utility',
  };

  // Pattern-based classification for unknown packages
  static const Map<String, List<String>> _categoryPatterns = {
    'social_media': ['social', 'tiktok', 'instagram', 'twitter', 'facebook', 'snapchat', 'reddit'],
    'gaming': ['game', 'games', 'play', 'arcade', 'puzzle', 'racing', 'rpg'],
    'streaming': ['video', 'music', 'stream', 'movie', 'tv', 'media', 'player'],
    'messaging': ['chat', 'messenger', 'message', 'sms', 'call'],
    'productive': ['office', 'work', 'productivity', 'task', 'note', 'calendar', 'email', 'mail'],
    'education': ['learn', 'education', 'study', 'course', 'school', 'university'],
    'health': ['fitness', 'health', 'workout', 'meditation', 'yoga', 'diet'],
    'shopping': ['shop', 'store', 'buy', 'cart', 'market', 'deal'],
    'finance': ['bank', 'pay', 'money', 'finance', 'wallet', 'invest'],
    'navigation': ['map', 'navigate', 'ride', 'taxi', 'cab', 'drive'],
  };

  /// Classify a single app by package name.
  /// Returns category string.
  static String classify(String packageName, {int androidCategory = -1}) {
    // 1. Check known apps first
    if (_knownApps.containsKey(packageName)) {
      return _knownApps[packageName]!;
    }

    // 2. Try Android's built-in category
    final androidCat = _fromAndroidCategory(androidCategory);
    if (androidCat != 'unknown') return androidCat;

    // 3. Pattern matching on package name
    final lowerPkg = packageName.toLowerCase();
    for (final entry in _categoryPatterns.entries) {
      for (final pattern in entry.value) {
        if (lowerPkg.contains(pattern)) {
          return entry.key;
        }
      }
    }

    return 'unknown';
  }

  static String _fromAndroidCategory(int category) {
    // Android ApplicationInfo category constants
    switch (category) {
      case 0: return 'gaming';        // CATEGORY_GAME
      case 1: return 'streaming';     // CATEGORY_AUDIO
      case 2: return 'streaming';     // CATEGORY_VIDEO
      case 3: return 'streaming';     // CATEGORY_IMAGE
      case 4: return 'social_media';  // CATEGORY_SOCIAL
      case 5: return 'utility';       // CATEGORY_NEWS
      case 6: return 'navigation';    // CATEGORY_MAPS
      case 7: return 'productive';    // CATEGORY_PRODUCTIVITY
      default: return 'unknown';
    }
  }

  /// Whether a category is considered "addictive" for scoring purposes
  static bool isAddictive(String category) {
    return ['social_media', 'gaming', 'streaming'].contains(category);
  }

  /// Whether a category is considered "productive" for scoring purposes
  static bool isProductive(String category) {
    return ['productive', 'education', 'development', 'health'].contains(category);
  }

  /// Get emoji for a category
  static String categoryEmoji(String category) {
    switch (category) {
      case 'social_media': return '📱';
      case 'messaging': return '💬';
      case 'gaming': return '🎮';
      case 'streaming': return '🎬';
      case 'productive': return '💼';
      case 'education': return '📚';
      case 'development': return '💻';
      case 'health': return '🏃';
      case 'shopping': return '🛒';
      case 'finance': return '💰';
      case 'navigation': return '🗺️';
      case 'browser': return '🌐';
      case 'utility': return '🔧';
      default: return '📦';
    }
  }

  /// Get display name for a category
  static String categoryDisplayName(String category) {
    switch (category) {
      case 'social_media': return 'Social Media';
      case 'messaging': return 'Messaging';
      case 'gaming': return 'Gaming';
      case 'streaming': return 'Streaming';
      case 'productive': return 'Productivity';
      case 'education': return 'Education';
      case 'development': return 'Development';
      case 'health': return 'Health & Fitness';
      case 'shopping': return 'Shopping';
      case 'finance': return 'Finance';
      case 'navigation': return 'Navigation';
      case 'browser': return 'Browser';
      case 'utility': return 'Utilities';
      default: return 'Other';
    }
  }
}
