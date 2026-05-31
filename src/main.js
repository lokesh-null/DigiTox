// DigiTox — Main Application Entry Point
// Handles routing, splash screen, interventions, and initialization

import './style.css';
import { getTracker } from './utils/tracker.js';
import { INTERVENTION_PROMPTS } from './data/mockData.js';
import * as dashboard from './screens/dashboard.js';
import * as focus from './screens/focus.js';
import * as insights from './screens/insights.js';
import * as habits from './screens/habits.js';
import { showEmergencySetup } from './screens/emergency.js';

// --- State ---
let currentScreen = 'dashboard';
let interventionTimeout = null;
let interventionShown = false;

const screens = {
  dashboard,
  focus,
  insights,
  habits,
};

// --- Splash Screen ---
function hideSplash() {
  const splash = document.getElementById('splash-screen');
  const appContainer = document.getElementById('app-container');
  
  setTimeout(() => {
    if (splash) splash.style.display = 'none';
    if (appContainer) appContainer.classList.remove('hidden');
    
    // Initialize with dashboard
    navigateTo('dashboard');
    
    // Start intervention timer
    scheduleIntervention();
  }, 2800);
}

// --- Navigation ---
function navigateTo(screenName) {
  // Cleanup previous screen
  if (screens[currentScreen]?.cleanup) {
    screens[currentScreen].cleanup();
  }
  
  currentScreen = screenName;
  
  // Update nav
  document.querySelectorAll('.nav-item').forEach(item => {
    item.classList.toggle('active', item.dataset.screen === screenName);
  });
  
  // Update header title based on screen
  const headerTitle = document.querySelector('.header-title');
  if (headerTitle) {
    const titles = {
      dashboard: 'DigiTox',
      focus: 'DigiTox',
      insights: 'DigiTox',
      habits: 'DigiTox',
    };
    headerTitle.textContent = titles[screenName] || 'DigiTox';
  }
  
  // Render screen
  if (screens[screenName]?.render) {
    screens[screenName].render();
  }
  
  // Scroll to top
  const container = document.getElementById('screen-container');
  if (container) container.scrollTop = 0;
}

// --- Intervention System ---
function scheduleIntervention() {
  // Show intervention after 60-120 seconds of browsing
  const delay = (60 + Math.random() * 60) * 1000;
  
  interventionTimeout = setTimeout(() => {
    if (!interventionShown) {
      showIntervention();
    }
  }, delay);
}

function showIntervention() {
  interventionShown = true;
  
  const prompt = INTERVENTION_PROMPTS[Math.floor(Math.random() * INTERVENTION_PROMPTS.length)];
  const overlay = document.getElementById('intervention-overlay');
  if (!overlay) return;
  
  overlay.classList.remove('hidden');
  overlay.innerHTML = `
    <div class="intervention-content">
      <div class="intervention-emoji">${prompt.emoji}</div>
      <div class="intervention-title">${prompt.title}</div>
      <div class="intervention-message">${prompt.message}</div>
      <div class="intervention-timer-bar">
        <div class="intervention-timer-fill" id="intervention-fill"></div>
      </div>
      <button class="intervention-dismiss-btn" id="intervention-dismiss" disabled>
        Wait 5 seconds...
      </button>
    </div>
  `;
  
  // Enable dismiss after 5 seconds
  setTimeout(() => {
    const btn = document.getElementById('intervention-dismiss');
    if (btn) {
      btn.disabled = false;
      btn.classList.add('enabled');
      btn.textContent = 'I understand, continue';
    }
  }, 5000);
  
  // Dismiss handler
  overlay.addEventListener('click', function handler(e) {
    const btn = document.getElementById('intervention-dismiss');
    if (btn && !btn.disabled && (e.target === btn || btn.contains(e.target))) {
      overlay.classList.add('hidden');
      overlay.removeEventListener('click', handler);
      
      // Schedule next intervention (much later)
      setTimeout(() => {
        interventionShown = false;
        scheduleIntervention();
      }, 120000); // 2 min cooldown
    }
  });
}

// --- Event Bindings ---
function bindNavigation() {
  document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', () => {
      const screen = item.dataset.screen;
      if (screen && screen !== currentScreen) {
        navigateTo(screen);
      }
    });
  });
}

function bindEmergency() {
  // Header emergency button
  document.getElementById('btn-emergency-header')?.addEventListener('click', () => {
    showEmergencySetup();
  });
  
  // Custom event from dashboard
  window.addEventListener('show-emergency', () => {
    showEmergencySetup();
  });
}

// --- Initialize ---
function init() {
  // Start tracker
  getTracker();
  
  // Bind navigation
  bindNavigation();
  
  // Bind emergency
  bindEmergency();
  
  // Start splash sequence
  hideSplash();
}

// Wait for DOM
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
