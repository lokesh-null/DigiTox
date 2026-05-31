// localStorage persistence layer for DigiTox

const STORAGE_KEYS = {
  HABITS: 'digitox_habits',
  FOCUS_SESSIONS: 'digitox_focus_sessions',
  STREAK: 'digitox_streak',
  WEEKLY_DATA: 'digitox_weekly_data',
  TODAY_USAGE: 'digitox_today_usage',
  SETTINGS: 'digitox_settings',
  LAST_DATE: 'digitox_last_date',
  INTERVENTION_COUNT: 'digitox_intervention_count',
  BLOCKED_APPS: 'digitox_blocked_apps',
};

export function save(key, data) {
  try {
    localStorage.setItem(key, JSON.stringify(data));
  } catch (e) {
    console.warn('Storage save failed:', e);
  }
}

export function load(key, fallback = null) {
  try {
    const data = localStorage.getItem(key);
    return data ? JSON.parse(data) : fallback;
  } catch (e) {
    console.warn('Storage load failed:', e);
    return fallback;
  }
}

export function remove(key) {
  localStorage.removeItem(key);
}

export { STORAGE_KEYS };
