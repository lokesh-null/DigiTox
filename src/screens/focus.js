// Focus Mode Screen — Deep Work Engine with timer, task input, and app blocking

import { save, load, STORAGE_KEYS } from '../utils/storage.js';

let focusInterval = null;
let focusRemaining = 0;
let focusDuration = 25 * 60; // default 25 minutes
let isFocusActive = false;
let selectedDuration = 25;

const DURATIONS = [
  { label: '15 min', value: 15 },
  { label: '25 min', value: 25 },
  { label: '45 min', value: 45 },
  { label: '60 min', value: 60 },
  { label: '90 min', value: 90 },
];

const BLOCKABLE_APPS = [
  { id: 'instagram', name: 'Instagram', emoji: '📸', blocked: true },
  { id: 'tiktok', name: 'TikTok', emoji: '🎵', blocked: true },
  { id: 'youtube', name: 'YouTube', emoji: '▶️', blocked: true },
  { id: 'twitter', name: 'X (Twitter)', emoji: '🐦', blocked: true },
  { id: 'reddit', name: 'Reddit', emoji: '🔴', blocked: false },
  { id: 'games', name: 'Mobile Games', emoji: '🎮', blocked: true },
  { id: 'snapchat', name: 'Snapchat', emoji: '👻', blocked: false },
];

function formatTimer(seconds) {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
}

function getCircumference() {
  return 2 * Math.PI * 100; // radius=100
}

export function render() {
  const circumference = getCircumference();
  const progress = isFocusActive ? ((focusDuration - focusRemaining) / focusDuration) : 0;
  const dashOffset = circumference - (progress * circumference);
  
  const completedSessions = load(STORAGE_KEYS.FOCUS_SESSIONS, 0);
  
  const container = document.getElementById('screen-container');
  container.innerHTML = `
    <div class="screen focus-screen" id="focus-view">
      <div class="screen-title">Focus Mode</div>
      <div class="screen-subtitle">Deep work starts here</div>
      
      <!-- Timer Ring -->
      <div class="focus-ring-container">
        <svg class="focus-ring-svg" viewBox="0 0 220 220" id="focus-ring">
          <defs>
            <linearGradient id="focusGradient" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stop-color="#6C5CE7"/>
              <stop offset="100%" stop-color="#00CEC9"/>
            </linearGradient>
          </defs>
          <circle class="focus-ring-bg" cx="110" cy="110" r="100"/>
          <circle class="focus-ring-progress" cx="110" cy="110" r="100"
            stroke-dasharray="${circumference}"
            stroke-dashoffset="${dashOffset}"
            id="focus-progress-ring"/>
        </svg>
        <div class="focus-ring-center">
          <div class="focus-time" id="focus-timer-display">${isFocusActive ? formatTimer(focusRemaining) : formatTimer(selectedDuration * 60)}</div>
          <div class="focus-time-label" id="focus-status-label">${isFocusActive ? 'Remaining' : 'Ready'}</div>
        </div>
      </div>
      
      <!-- Task Input -->
      <input type="text" class="focus-task-input" id="focus-task-input" 
        placeholder="What are you working on?" 
        value="${load('digitox_current_task', '')}"
        ${isFocusActive ? 'disabled' : ''} />
      
      <!-- Duration Selector -->
      ${!isFocusActive ? `
        <div class="duration-selector">
          ${DURATIONS.map(d => `
            <button class="duration-btn ${d.value === selectedDuration ? 'active' : ''}" 
              data-duration="${d.value}" id="dur-${d.value}">
              ${d.label}
            </button>
          `).join('')}
        </div>
      ` : ''}
      
      <!-- Control Button -->
      <div class="focus-controls">
        <button class="focus-start-btn ${isFocusActive ? 'running' : ''}" id="focus-toggle-btn">
          ${isFocusActive ? `
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>
            Stop Session
          ` : `
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="5 3 19 12 5 21 5 3"/></svg>
            Start Focus
          `}
        </button>
      </div>
      
      <!-- Session Stats -->
      <div class="glass-card glass-card-sm" style="width:100%; text-align:center; margin-bottom:var(--space-lg)">
        <div style="font-size:0.75rem; color:var(--text-secondary); margin-bottom:4px">Completed Sessions</div>
        <div style="font-family:var(--font-heading); font-size:1.5rem; font-weight:700; color:var(--primary-light)">${completedSessions}</div>
      </div>
      
      <!-- Blocked Apps -->
      <div class="blocked-apps-section">
        <div class="section-title"><span class="icon">🚫</span> Blocked During Focus</div>
        ${BLOCKABLE_APPS.map(app => `
          <div class="blocked-app-item" id="block-${app.id}">
            <div class="blocked-app-left">
              <div class="blocked-app-icon" style="background:rgba(255,255,255,0.05)">${app.emoji}</div>
              <div class="blocked-app-name">${app.name}</div>
            </div>
            <div class="toggle-switch ${app.blocked ? 'active' : ''}" data-app="${app.id}" id="toggle-${app.id}"></div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
  
  bindEvents();
}

function bindEvents() {
  // Duration buttons
  document.querySelectorAll('.duration-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      selectedDuration = parseInt(btn.dataset.duration);
      document.querySelectorAll('.duration-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const display = document.getElementById('focus-timer-display');
      if (display) display.textContent = formatTimer(selectedDuration * 60);
    });
  });
  
  // Toggle button
  document.getElementById('focus-toggle-btn')?.addEventListener('click', () => {
    if (isFocusActive) {
      stopFocus();
    } else {
      startFocus();
    }
  });
  
  // Save task
  document.getElementById('focus-task-input')?.addEventListener('input', (e) => {
    save('digitox_current_task', e.target.value);
  });
  
  // Toggle switches
  document.querySelectorAll('.toggle-switch').forEach(toggle => {
    toggle.addEventListener('click', () => {
      if (isFocusActive) return;
      toggle.classList.toggle('active');
      const appId = toggle.dataset.app;
      const app = BLOCKABLE_APPS.find(a => a.id === appId);
      if (app) app.blocked = !app.blocked;
    });
  });
}

function startFocus() {
  isFocusActive = true;
  focusDuration = selectedDuration * 60;
  focusRemaining = focusDuration;
  
  render();
  
  // Add focus overlay border
  const overlay = document.createElement('div');
  overlay.className = 'focus-active-overlay';
  overlay.id = 'focus-overlay-border';
  document.getElementById('app')?.appendChild(overlay);
  
  focusInterval = setInterval(() => {
    focusRemaining--;
    
    if (focusRemaining <= 0) {
      completeFocus();
      return;
    }
    
    updateTimerUI();
  }, 1000);
}

function stopFocus() {
  isFocusActive = false;
  if (focusInterval) clearInterval(focusInterval);
  focusInterval = null;
  
  document.getElementById('focus-overlay-border')?.remove();
  render();
}

function completeFocus() {
  isFocusActive = false;
  if (focusInterval) clearInterval(focusInterval);
  focusInterval = null;
  
  // Increment completed sessions
  const sessions = load(STORAGE_KEYS.FOCUS_SESSIONS, 0) + 1;
  save(STORAGE_KEYS.FOCUS_SESSIONS, sessions);
  
  // Increment streak
  const streak = load(STORAGE_KEYS.STREAK, 0) + 1;
  save(STORAGE_KEYS.STREAK, streak);
  
  document.getElementById('focus-overlay-border')?.remove();
  
  // Show completion message
  showCompletionToast();
  render();
}

function updateTimerUI() {
  const display = document.getElementById('focus-timer-display');
  const ring = document.getElementById('focus-progress-ring');
  
  if (display) display.textContent = formatTimer(focusRemaining);
  
  if (ring) {
    const circumference = getCircumference();
    const progress = (focusDuration - focusRemaining) / focusDuration;
    ring.style.strokeDashoffset = circumference - (progress * circumference);
  }
}

function showCompletionToast() {
  const toast = document.createElement('div');
  toast.className = 'intervention-overlay';
  toast.innerHTML = `
    <div class="intervention-content">
      <div class="intervention-emoji">🎉</div>
      <div class="intervention-title">Session Complete!</div>
      <div class="intervention-message">
        Amazing focus! You just completed ${selectedDuration} minutes of deep work. 
        Your streak is growing — keep it up!
      </div>
      <button class="intervention-dismiss-btn enabled" id="completion-dismiss">Continue</button>
    </div>
  `;
  document.getElementById('app')?.appendChild(toast);
  
  document.getElementById('completion-dismiss')?.addEventListener('click', () => {
    toast.remove();
  });
}

export function cleanup() {
  // Don't clear interval on cleanup so focus can continue in background
}
