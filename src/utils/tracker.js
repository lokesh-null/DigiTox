// Simulated real-time usage tracker

import { save, load, STORAGE_KEYS } from './storage.js';

class UsageTracker {
  constructor() {
    this.sessionStart = Date.now();
    this.totalTodaySeconds = load(STORAGE_KEYS.SETTINGS + '_today_seconds', 0);
    this.listeners = [];
    this.tickInterval = null;
    
    // Check if it's a new day
    const lastDate = load(STORAGE_KEYS.LAST_DATE);
    const today = new Date().toDateString();
    if (lastDate !== today) {
      this.totalTodaySeconds = 0;
      save(STORAGE_KEYS.LAST_DATE, today);
    }
    
    this.startTicking();
  }
  
  startTicking() {
    this.tickInterval = setInterval(() => {
      this.totalTodaySeconds++;
      save(STORAGE_KEYS.SETTINGS + '_today_seconds', this.totalTodaySeconds);
      this.notify();
    }, 1000);
  }
  
  getSessionTime() {
    return Math.floor((Date.now() - this.sessionStart) / 1000);
  }
  
  getTodayTime() {
    return this.totalTodaySeconds;
  }
  
  formatTime(totalSeconds) {
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return `${hours}h ${minutes.toString().padStart(2, '0')}m ${seconds.toString().padStart(2, '0')}s`;
    }
    return `${minutes}m ${seconds.toString().padStart(2, '0')}s`;
  }
  
  formatTimeShort(totalMinutes) {
    const hours = Math.floor(totalMinutes / 60);
    const minutes = totalMinutes % 60;
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  }
  
  subscribe(callback) {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(l => l !== callback);
    };
  }
  
  notify() {
    this.listeners.forEach(cb => cb(this.totalTodaySeconds));
  }
  
  destroy() {
    if (this.tickInterval) clearInterval(this.tickInterval);
  }
}

// Singleton
let instance = null;
export function getTracker() {
  if (!instance) instance = new UsageTracker();
  return instance;
}
