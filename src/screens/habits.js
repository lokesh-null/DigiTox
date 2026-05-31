// Habits Screen — Habit tracking, streaks, alternatives, contribution grid

import { DEFAULT_HABITS, HABIT_ALTERNATIVES, generateContributionData } from '../data/mockData.js';
import { save, load, STORAGE_KEYS } from '../utils/storage.js';

const HABIT_EMOJIS = ['🌅', '📚', '🚫', '🌆', '😴', '🧘', '🏃', '✍️', '🎸', '🌿', '💧', '🍎'];

function getHabits() {
  return load(STORAGE_KEYS.HABITS, DEFAULT_HABITS);
}

function saveHabits(habits) {
  save(STORAGE_KEYS.HABITS, habits);
}

function calculateConsistency(habits) {
  if (habits.length === 0) return 0;
  const avgStreak = habits.reduce((s, h) => s + h.streak, 0) / habits.length;
  return Math.min(Math.round((avgStreak / 14) * 100), 100);
}

export function render() {
  const habits = getHabits();
  const consistency = calculateConsistency(habits);
  const contributionData = generateContributionData();
  
  const container = document.getElementById('screen-container');
  container.innerHTML = `
    <div class="screen" id="habits-view">
      <!-- Header Row -->
      <div class="habits-header-row">
        <div>
          <div class="screen-title">Habits</div>
          <div class="screen-subtitle">Build better patterns</div>
        </div>
        <button class="add-habit-btn" id="add-habit-btn">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Add
        </button>
      </div>
      
      <!-- Consistency Score -->
      <div class="consistency-card">
        <div class="consistency-value">${consistency}%</div>
        <div class="consistency-label">Consistency Score</div>
      </div>
      
      <!-- Habit List -->
      <div class="section-title"><span class="icon">✅</span> Today's Habits</div>
      <div class="habit-list" id="habit-list">
        ${habits.map(h => `
          <div class="habit-item" data-habit-id="${h.id}">
            <div class="habit-check ${h.completedToday ? 'checked' : ''}" data-id="${h.id}" id="check-${h.id}">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="20 6 9 17 4 12"/>
              </svg>
            </div>
            <div class="habit-info">
              <div class="habit-name">${h.name}</div>
              <div class="habit-streak">🔥 ${h.streak} day streak</div>
            </div>
            <div class="habit-emoji">${h.emoji}</div>
          </div>
        `).join('')}
      </div>
      
      <!-- Contribution Grid -->
      <div class="contribution-grid-wrap glass-card">
        <div class="section-title" style="margin-bottom:var(--space-md)"><span class="icon">📅</span> Last 28 Days</div>
        <div class="contribution-grid">
          ${contributionData.map(level => `
            <div class="contribution-cell ${level === 0 ? 'empty' : `level-${level}`}"></div>
          `).join('')}
        </div>
        <div style="display:flex; justify-content:space-between; align-items:center; margin-top:var(--space-sm); font-size:0.65rem; color:var(--text-tertiary)">
          <span>Less</span>
          <div style="display:flex; gap:3px;">
            <div style="width:10px;height:10px;border-radius:2px;background:rgba(255,255,255,0.03)"></div>
            <div style="width:10px;height:10px;border-radius:2px;background:rgba(0,184,148,0.2)"></div>
            <div style="width:10px;height:10px;border-radius:2px;background:rgba(0,184,148,0.4)"></div>
            <div style="width:10px;height:10px;border-radius:2px;background:rgba(0,184,148,0.6)"></div>
            <div style="width:10px;height:10px;border-radius:2px;background:rgba(0,184,148,0.8)"></div>
          </div>
          <span>More</span>
        </div>
      </div>
      
      <!-- Alternatives -->
      <div class="alternatives-section" style="margin-top:var(--space-lg)">
        <div class="section-title"><span class="icon">🔄</span> Instead of Scrolling, Try...</div>
        ${HABIT_ALTERNATIVES.map(alt => `
          <div class="alternative-card">
            <div style="font-size:1.2rem;">${alt.emoji}</div>
            <div class="alt-from">${alt.from}</div>
            <div class="alt-arrow">→</div>
            <div class="alt-to">${alt.to}</div>
          </div>
        `).join('')}
      </div>
    </div>
    
    <!-- Add Habit Modal (hidden by default) -->
    <div id="add-habit-modal" class="hidden"></div>
  `;
  
  bindEvents();
}

function bindEvents() {
  // Check/uncheck habits
  document.querySelectorAll('.habit-check').forEach(check => {
    check.addEventListener('click', () => {
      const id = check.dataset.id;
      const habits = getHabits();
      const habit = habits.find(h => h.id === id);
      if (habit) {
        habit.completedToday = !habit.completedToday;
        if (habit.completedToday) {
          habit.streak++;
          check.classList.add('checked');
        } else {
          habit.streak = Math.max(0, habit.streak - 1);
          check.classList.remove('checked');
        }
        saveHabits(habits);
        
        // Animate
        check.style.transform = 'scale(1.2)';
        setTimeout(() => { check.style.transform = ''; }, 200);
      }
    });
  });
  
  // Add habit button
  document.getElementById('add-habit-btn')?.addEventListener('click', showAddHabitModal);
}

function showAddHabitModal() {
  const modalContainer = document.getElementById('add-habit-modal');
  if (!modalContainer) return;
  
  modalContainer.classList.remove('hidden');
  modalContainer.innerHTML = `
    <div class="modal-overlay" id="habit-modal-overlay">
      <div class="modal-content">
        <div class="modal-handle"></div>
        <div class="modal-title">New Habit</div>
        <input type="text" class="modal-input" id="new-habit-name" placeholder="e.g., Read for 20 minutes" autofocus />
        <div style="font-size:0.8rem; color:var(--text-secondary); margin-bottom:var(--space-sm);">Choose an icon</div>
        <div class="emoji-picker" id="emoji-picker">
          ${HABIT_EMOJIS.map((e, i) => `
            <button class="emoji-option ${i === 0 ? 'selected' : ''}" data-emoji="${e}">${e}</button>
          `).join('')}
        </div>
        <div class="modal-btn-row">
          <button class="modal-btn secondary" id="modal-cancel">Cancel</button>
          <button class="modal-btn primary" id="modal-save">Add Habit</button>
        </div>
      </div>
    </div>
  `;
  
  let selectedEmoji = HABIT_EMOJIS[0];
  
  // Emoji selection
  document.querySelectorAll('.emoji-option').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.emoji-option').forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');
      selectedEmoji = btn.dataset.emoji;
    });
  });
  
  // Cancel
  document.getElementById('modal-cancel')?.addEventListener('click', () => {
    modalContainer.classList.add('hidden');
  });
  
  // Close on overlay click
  document.getElementById('habit-modal-overlay')?.addEventListener('click', (e) => {
    if (e.target.id === 'habit-modal-overlay') {
      modalContainer.classList.add('hidden');
    }
  });
  
  // Save
  document.getElementById('modal-save')?.addEventListener('click', () => {
    const name = document.getElementById('new-habit-name')?.value?.trim();
    if (!name) return;
    
    const habits = getHabits();
    habits.push({
      id: 'h' + Date.now(),
      name,
      emoji: selectedEmoji,
      streak: 0,
      completedToday: false,
    });
    saveHabits(habits);
    modalContainer.classList.add('hidden');
    render();
  });
}

export function cleanup() {}
