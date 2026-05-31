// Dashboard Screen — Home view with usage stats, time reality, and quick actions

import { getTracker } from '../utils/tracker.js';
import { generateTodayUsage, generateWeeklyData, getTimeRealities, APP_CATEGORIES } from '../data/mockData.js';
import { load, save, STORAGE_KEYS } from '../utils/storage.js';

let todayUsage = null;
let weeklyData = null;
let timerUnsub = null;

function getTodayStats() {
  if (!todayUsage) todayUsage = generateTodayUsage();
  
  const productive = todayUsage.filter(a => a.category === APP_CATEGORIES.PRODUCTIVE).reduce((s, a) => s + a.minutes, 0);
  const addictive = todayUsage.filter(a => a.category === APP_CATEGORIES.ADDICTIVE).reduce((s, a) => s + a.minutes, 0);
  const neutral = todayUsage.filter(a => a.category === APP_CATEGORIES.NEUTRAL).reduce((s, a) => s + a.minutes, 0);
  const total = productive + addictive + neutral;
  
  return { productive, addictive, neutral, total };
}

function getGreeting() {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

export function render() {
  const tracker = getTracker();
  const stats = getTodayStats();
  if (!weeklyData) weeklyData = generateWeeklyData();
  
  const streak = load(STORAGE_KEYS.STREAK, 7);
  const realities = getTimeRealities(stats.addictive);
  const prodPercent = stats.total > 0 ? (stats.productive / stats.total * 100).toFixed(0) : 0;
  const addPercent = stats.total > 0 ? (stats.addictive / stats.total * 100).toFixed(0) : 0;
  const neutPercent = stats.total > 0 ? (stats.neutral / stats.total * 100).toFixed(0) : 0;
  
  const topApps = todayUsage.slice(0, 5);
  const maxMinutes = topApps.length > 0 ? topApps[0].minutes : 1;

  const container = document.getElementById('screen-container');
  container.innerHTML = `
    <div class="screen dashboard-screen" id="dashboard-view">
      <!-- Greeting -->
      <div class="dashboard-greeting">
        <div class="greeting-text">${getGreeting()} 👋</div>
        <div class="greeting-sub">Here's your digital wellness report for today</div>
      </div>
      
      <!-- Live Session Timer -->
      <div class="live-timer-card">
        <div class="live-timer-label">Today's Screen Time</div>
        <div class="live-timer-value" id="live-timer">${tracker.formatTime(tracker.getTodayTime())}</div>
        <div class="live-timer-status">
          <div class="pulse-dot"></div>
          Tracking live
        </div>
      </div>
      
      <!-- Stats Grid -->
      <div class="stats-grid">
        <div class="stat-card productive">
          <div class="stat-value">${tracker.formatTimeShort(stats.productive)}</div>
          <div class="stat-label">Time Invested</div>
        </div>
        <div class="stat-card addictive">
          <div class="stat-value">${tracker.formatTimeShort(stats.addictive)}</div>
          <div class="stat-label">Time Wasted</div>
        </div>
        <div class="stat-card streak">
          <div class="stat-value">🔥 ${streak}</div>
          <div class="stat-label">Day Streak</div>
        </div>
        <div class="stat-card score">
          <div class="stat-value">${prodPercent}%</div>
          <div class="stat-label">Focus Score</div>
        </div>
      </div>
      
      <!-- Time Distribution -->
      <div class="time-split glass-card glass-card-sm">
        <div class="section-title"><span class="icon">📊</span> Time Distribution</div>
        <div class="time-split-bar">
          <div class="time-split-segment productive" style="width:${prodPercent}%"></div>
          <div class="time-split-segment neutral" style="width:${neutPercent}%"></div>
          <div class="time-split-segment addictive" style="width:${addPercent}%"></div>
        </div>
        <div class="time-split-legend">
          <div class="legend-item"><div class="legend-dot productive"></div> Productive ${prodPercent}%</div>
          <div class="legend-item"><div class="legend-dot neutral"></div> Neutral ${neutPercent}%</div>
          <div class="legend-item"><div class="legend-dot addictive"></div> Addictive ${addPercent}%</div>
        </div>
      </div>
      
      <!-- Quick Actions -->
      <div class="quick-actions">
        <button class="quick-action-btn focus-btn" id="dash-focus-btn">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></svg>
          Start Focus
        </button>
        <button class="quick-action-btn lock-btn" id="dash-lock-btn">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
          Emergency Lock
        </button>
      </div>
      
      <!-- Top Apps -->
      <div class="section-title"><span class="icon">📱</span> Most Used Today</div>
      <div class="app-usage-list">
        ${topApps.map(app => {
          const barWidth = (app.minutes / maxMinutes * 100).toFixed(0);
          const barColor = app.category === APP_CATEGORIES.ADDICTIVE ? 'var(--danger)' : 
                          app.category === APP_CATEGORIES.PRODUCTIVE ? 'var(--secondary)' : 'var(--warning)';
          return `
            <div class="app-usage-item">
              <div class="app-icon" style="background:${app.color}20; color:${app.color}">${app.emoji}</div>
              <div class="app-usage-info">
                <div class="app-usage-name">${app.name}</div>
                <div class="app-usage-bar-wrap">
                  <div class="app-usage-bar" style="width:${barWidth}%; background:${barColor}"></div>
                </div>
              </div>
              <div class="app-usage-time" style="color:${barColor}">${tracker.formatTimeShort(app.minutes)}</div>
            </div>
          `;
        }).join('')}
      </div>
      
      <!-- Time Reality Check -->
      <div class="section-title"><span class="icon">💡</span> Time Reality Check</div>
      <div class="reality-cards">
        ${realities.map(r => `
          <div class="reality-card">
            <div class="reality-emoji">${r.emoji}</div>
            <div class="reality-text">${r.text}</div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
  
  // Live timer update
  const timerEl = document.getElementById('live-timer');
  if (timerUnsub) timerUnsub();
  timerUnsub = tracker.subscribe((seconds) => {
    if (timerEl) timerEl.textContent = tracker.formatTime(seconds);
  });
  
  // Quick action handlers
  document.getElementById('dash-focus-btn')?.addEventListener('click', () => {
    document.querySelector('[data-screen="focus"]')?.click();
  });
  
  document.getElementById('dash-lock-btn')?.addEventListener('click', () => {
    window.dispatchEvent(new CustomEvent('show-emergency'));
  });
}

export function cleanup() {
  if (timerUnsub) {
    timerUnsub();
    timerUnsub = null;
  }
}
