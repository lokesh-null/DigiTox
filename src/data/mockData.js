// Mock data for DigiTox
// Simulates real-world usage patterns

export const APP_CATEGORIES = {
  PRODUCTIVE: 'productive',
  NEUTRAL: 'neutral',
  ADDICTIVE: 'addictive'
};

export const MOCK_APPS = [
  { id: 'instagram', name: 'Instagram', emoji: '📸', category: APP_CATEGORIES.ADDICTIVE, color: '#E1306C' },
  { id: 'tiktok', name: 'TikTok', emoji: '🎵', category: APP_CATEGORIES.ADDICTIVE, color: '#FF0050' },
  { id: 'youtube', name: 'YouTube', emoji: '▶️', category: APP_CATEGORIES.ADDICTIVE, color: '#FF0000' },
  { id: 'twitter', name: 'X (Twitter)', emoji: '🐦', category: APP_CATEGORIES.ADDICTIVE, color: '#1DA1F2' },
  { id: 'reddit', name: 'Reddit', emoji: '🔴', category: APP_CATEGORIES.ADDICTIVE, color: '#FF4500' },
  { id: 'snapchat', name: 'Snapchat', emoji: '👻', category: APP_CATEGORIES.ADDICTIVE, color: '#FFFC00' },
  { id: 'vscode', name: 'VS Code', emoji: '💻', category: APP_CATEGORIES.PRODUCTIVE, color: '#007ACC' },
  { id: 'notion', name: 'Notion', emoji: '📝', category: APP_CATEGORIES.PRODUCTIVE, color: '#FFFFFF' },
  { id: 'slack', name: 'Slack', emoji: '💬', category: APP_CATEGORIES.PRODUCTIVE, color: '#4A154B' },
  { id: 'figma', name: 'Figma', emoji: '🎨', category: APP_CATEGORIES.PRODUCTIVE, color: '#F24E1E' },
  { id: 'chrome', name: 'Chrome', emoji: '🌐', category: APP_CATEGORIES.NEUTRAL, color: '#4285F4' },
  { id: 'spotify', name: 'Spotify', emoji: '🎧', category: APP_CATEGORIES.NEUTRAL, color: '#1DB954' },
  { id: 'whatsapp', name: 'WhatsApp', emoji: '💚', category: APP_CATEGORIES.NEUTRAL, color: '#25D366' },
  { id: 'games', name: 'Mobile Games', emoji: '🎮', category: APP_CATEGORIES.ADDICTIVE, color: '#9B59B6' },
];

// Generate realistic 7-day usage data
export function generateWeeklyData() {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days.map((day, i) => {
    const isWeekend = i >= 5;
    const baseProductive = isWeekend ? 30 + Math.random() * 60 : 120 + Math.random() * 120;
    const baseAddictive = isWeekend ? 120 + Math.random() * 120 : 60 + Math.random() * 90;
    const baseNeutral = 30 + Math.random() * 60;
    
    return {
      day,
      productive: Math.round(baseProductive),
      addictive: Math.round(baseAddictive),
      neutral: Math.round(baseNeutral),
      total: Math.round(baseProductive + baseAddictive + baseNeutral),
    };
  });
}

// Generate today's app usage
export function generateTodayUsage() {
  const usedApps = MOCK_APPS.filter(() => Math.random() > 0.3);
  return usedApps.map(app => {
    let minutes;
    if (app.category === APP_CATEGORIES.ADDICTIVE) {
      minutes = 15 + Math.floor(Math.random() * 90);
    } else if (app.category === APP_CATEGORIES.PRODUCTIVE) {
      minutes = 30 + Math.floor(Math.random() * 120);
    } else {
      minutes = 10 + Math.floor(Math.random() * 45);
    }
    return { ...app, minutes };
  }).sort((a, b) => b.minutes - a.minutes);
}

// Generate hourly distraction data for heatmap (24 hours)
export function generateHeatmapData() {
  const data = [];
  for (let h = 0; h < 24; h++) {
    let level;
    if (h >= 0 && h < 6) level = Math.random() > 0.7 ? 1 : 0;
    else if (h >= 6 && h < 9) level = Math.floor(Math.random() * 2);
    else if (h >= 9 && h < 12) level = Math.floor(Math.random() * 3);
    else if (h >= 12 && h < 14) level = 1 + Math.floor(Math.random() * 2);
    else if (h >= 14 && h < 18) level = Math.floor(Math.random() * 3);
    else if (h >= 18 && h < 21) level = 1 + Math.floor(Math.random() * 3);
    else level = 2 + Math.floor(Math.random() * 3); // 9 PM - midnight = peak
    data.push({ hour: h, level: Math.min(level, 4) });
  }
  return data;
}

// Time Reality equivalents
export function getTimeRealities(wastedMinutes) {
  return [
    { emoji: '📚', text: `You could've read <strong>${Math.round(wastedMinutes * 0.33)} pages</strong> of a book` },
    { emoji: '🏃', text: `That's <strong>${Math.round(wastedMinutes / 30)} workouts</strong> you could have done` },
    { emoji: '🧠', text: `<strong>${Math.round(wastedMinutes / 25)} lessons</strong> of a new language` },
    { emoji: '🎸', text: `<strong>${Math.round(wastedMinutes / 20)} practice sessions</strong> on an instrument` },
    { emoji: '📅', text: `This week = <strong>${(wastedMinutes / 60).toFixed(1)} hours</strong> lost to scrolling` },
    { emoji: '🌍', text: `In a year, that's <strong>${Math.round(wastedMinutes * 52 / 60 / 24)} full days</strong> of your life` },
  ];
}

// AI Suggestions
export function getAISuggestions(heatmapData) {
  const peakHours = heatmapData
    .filter(d => d.level >= 3)
    .map(d => d.hour);
  
  const suggestions = [];
  
  if (peakHours.some(h => h >= 21)) {
    suggestions.push({
      icon: '🌙',
      text: `You're most distracted between <strong>9 PM–12 AM</strong>. Try activating Focus Mode at 8:45 PM to build a wind-down routine.`
    });
  }
  
  if (peakHours.some(h => h >= 12 && h <= 14)) {
    suggestions.push({
      icon: '🍽️',
      text: `Your lunch break turns into a scroll session. Try a <strong>15-min phone-free lunch</strong> challenge.`
    });
  }
  
  suggestions.push({
    icon: '📊',
    text: `Your productive time peaks in the <strong>morning (9–11 AM)</strong>. Schedule your hardest tasks here.`
  });
  
  suggestions.push({
    icon: '🎯',
    text: `Social media accounts for <strong>62% of your wasted time</strong>. Consider using the 5-second pause feature.`
  });
  
  suggestions.push({
    icon: '🔄',
    text: `Replacing 30 min of Instagram with reading could help you finish <strong>24 books this year</strong>.`
  });
  
  return suggestions;
}

// Habit alternatives
export const HABIT_ALTERNATIVES = [
  { from: 'Instagram', to: '📖 Read 10 pages', emoji: '📸' },
  { from: 'TikTok', to: '🚶 Take a 10-min walk', emoji: '🎵' },
  { from: 'YouTube', to: '✍️ Journal for 5 minutes', emoji: '▶️' },
  { from: 'Twitter', to: '🧘 Meditate for 5 min', emoji: '🐦' },
  { from: 'Reddit', to: '🧩 Solve a puzzle', emoji: '🔴' },
];

// Default habits
export const DEFAULT_HABITS = [
  { id: 'h1', name: 'Morning without phone', emoji: '🌅', streak: 5, completedToday: false },
  { id: 'h2', name: 'Read for 20 minutes', emoji: '📚', streak: 12, completedToday: true },
  { id: 'h3', name: 'No social media before noon', emoji: '🚫', streak: 3, completedToday: false },
  { id: 'h4', name: 'Evening walk (no phone)', emoji: '🌆', streak: 8, completedToday: true },
  { id: 'h5', name: 'Screen-free bedtime', emoji: '😴', streak: 2, completedToday: false },
];

// Intervention prompts
export const INTERVENTION_PROMPTS = [
  { emoji: '🤔', title: 'Are you using this intentionally?', message: 'You\'ve been scrolling for a while. Take a breath and ask yourself — is this how you want to spend this moment?' },
  { emoji: '⏰', title: 'What were you supposed to do right now?', message: 'You opened your phone with a purpose. But then you got sidetracked. Let\'s get back on track.' },
  { emoji: '🪞', title: 'Time for a reality check', message: 'You\'ve spent 23 minutes on this app. That\'s already 8 pages of a book you could\'ve read.' },
  { emoji: '🧠', title: 'Your future self is watching', message: 'Every minute matters. This isn\'t about guilt — it\'s about intention. You\'re capable of more.' },
  { emoji: '💪', title: 'You\'re stronger than the algorithm', message: 'This app is designed to keep you scrolling. Break the loop. Close it and do something meaningful.' },
];

// Contribution grid data (last 28 days)
export function generateContributionData() {
  const data = [];
  for (let i = 0; i < 28; i++) {
    const rand = Math.random();
    let level;
    if (rand < 0.15) level = 0;
    else if (rand < 0.35) level = 1;
    else if (rand < 0.6) level = 2;
    else if (rand < 0.85) level = 3;
    else level = 4;
    data.push(level);
  }
  return data;
}

// Weekly report grade
export function getWeeklyGrade(weeklyData) {
  const totalProductive = weeklyData.reduce((s, d) => s + d.productive, 0);
  const totalAddictive = weeklyData.reduce((s, d) => s + d.addictive, 0);
  const ratio = totalProductive / (totalProductive + totalAddictive);
  
  if (ratio >= 0.7) return { grade: 'A', title: 'Excellent Focus!', desc: 'You\'re in the top tier of digital discipline.' };
  if (ratio >= 0.55) return { grade: 'B+', title: 'Good Progress', desc: 'You\'re trending in the right direction. Keep pushing.' };
  if (ratio >= 0.4) return { grade: 'B', title: 'Room to Grow', desc: 'You\'re aware, and that\'s the first step. Let\'s optimize.' };
  if (ratio >= 0.25) return { grade: 'C', title: 'Needs Attention', desc: 'Your screen time is outpacing your goals. Try Focus Mode more.' };
  return { grade: 'D', title: 'Time to Reset', desc: 'Consider activating Emergency Lock to break the cycle.' };
}
