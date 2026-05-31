// Emergency Lock Mode — Hard reset distraction blocker

let emergencyInterval = null;
let emergencyRemaining = 0;
let isEmergencyActive = false;

const EMERGENCY_DURATIONS = [
  { value: 15, label: 'min' },
  { value: 30, label: 'min' },
  { value: 60, label: 'min' },
  { value: 120, label: 'min' },
];

const CANCEL_PHRASE = 'I can wait';

function formatEmergencyTimer(seconds) {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
}

export function showEmergencySetup() {
  if (isEmergencyActive) {
    showEmergencyLock();
    return;
  }
  
  const overlay = document.getElementById('emergency-overlay');
  if (!overlay) return;
  
  let selectedDuration = 30;
  
  overlay.classList.remove('hidden');
  overlay.innerHTML = `
    <div class="emergency-setup">
      <div class="emergency-setup-icon">🔒</div>
      <div class="emergency-setup-title">Emergency Lock</div>
      <div class="emergency-setup-desc">
        Lock all distracting apps for a set duration. This cannot be easily bypassed — you'll need to type a phrase to cancel.
      </div>
      
      <div class="emergency-duration-grid">
        ${EMERGENCY_DURATIONS.map(d => `
          <button class="emergency-duration-btn ${d.value === selectedDuration ? 'selected' : ''}" 
                  data-duration="${d.value}" id="emg-dur-${d.value}">
            <div class="emergency-duration-value">${d.value}</div>
            <div class="emergency-duration-label">${d.label}</div>
          </button>
        `).join('')}
      </div>
      
      <button class="emergency-activate-btn" id="emergency-activate">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
          <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
        </svg>
        Activate Emergency Lock
      </button>
      
      <button style="margin-top:var(--space-lg); padding:var(--space-sm) var(--space-md); font-size:0.8rem; color:var(--text-tertiary); background:none; border:none; cursor:pointer;" id="emergency-close">
        Cancel
      </button>
    </div>
  `;
  
  // Duration selection
  overlay.querySelectorAll('.emergency-duration-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      selectedDuration = parseInt(btn.dataset.duration);
      overlay.querySelectorAll('.emergency-duration-btn').forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');
    });
  });
  
  // Activate
  document.getElementById('emergency-activate')?.addEventListener('click', () => {
    activateEmergency(selectedDuration);
  });
  
  // Close
  document.getElementById('emergency-close')?.addEventListener('click', () => {
    overlay.classList.add('hidden');
  });
}

function activateEmergency(durationMinutes) {
  isEmergencyActive = true;
  emergencyRemaining = durationMinutes * 60;
  
  showEmergencyLock();
  
  emergencyInterval = setInterval(() => {
    emergencyRemaining--;
    
    if (emergencyRemaining <= 0) {
      deactivateEmergency();
      return;
    }
    
    const timerEl = document.getElementById('emergency-countdown');
    if (timerEl) timerEl.textContent = formatEmergencyTimer(emergencyRemaining);
  }, 1000);
}

function showEmergencyLock() {
  const overlay = document.getElementById('emergency-overlay');
  if (!overlay) return;
  
  overlay.classList.remove('hidden');
  overlay.innerHTML = `
    <div style="display:flex; flex-direction:column; align-items:center; justify-content:center; height:100%; padding:var(--space-xl);">
      <div class="emergency-icon">
        <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
          <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
        </svg>
      </div>
      <div class="emergency-title">LOCKED</div>
      <div class="emergency-subtitle">All distracting apps are blocked. Stay focused — you've got this.</div>
      <div class="emergency-timer" id="emergency-countdown">${formatEmergencyTimer(emergencyRemaining)}</div>
      
      <div style="width:100%; max-width:300px; background:var(--surface); border-radius:var(--radius-lg); height:6px; overflow:hidden; margin-bottom:var(--space-xl);">
        <div style="height:100%; background:var(--gradient-danger); width:${((emergencyRemaining) / (emergencyRemaining + 1) * 100)}%; transition:width 1s linear; border-radius:var(--radius-lg);" id="emergency-progress"></div>
      </div>
      
      <div class="emergency-cancel-zone">
        <div class="emergency-cancel-label">Type "${CANCEL_PHRASE}" to cancel early</div>
        <input type="text" class="emergency-cancel-input" id="emergency-cancel-input" placeholder='Type the phrase...' autocomplete="off" />
      </div>
    </div>
  `;
  
  // Cancel handler
  document.getElementById('emergency-cancel-input')?.addEventListener('input', (e) => {
    if (e.target.value.toLowerCase().trim() === CANCEL_PHRASE.toLowerCase()) {
      deactivateEmergency();
    }
  });
}

function deactivateEmergency() {
  isEmergencyActive = false;
  if (emergencyInterval) clearInterval(emergencyInterval);
  emergencyInterval = null;
  
  const overlay = document.getElementById('emergency-overlay');
  if (overlay) {
    overlay.innerHTML = `
      <div style="display:flex; flex-direction:column; align-items:center; justify-content:center; height:100%; text-align:center; padding:var(--space-xl);">
        <div style="font-size:4rem; margin-bottom:var(--space-lg);">🎉</div>
        <div style="font-family:var(--font-heading); font-size:1.5rem; font-weight:700; margin-bottom:var(--space-sm);">Lock Complete!</div>
        <div style="font-size:0.85rem; color:var(--text-secondary); margin-bottom:var(--space-xl); max-width:280px;">
          Great job staying focused! Every session builds stronger discipline.
        </div>
        <button style="padding:var(--space-md) var(--space-xl); border-radius:var(--radius-lg); font-size:0.9rem; font-weight:600; background:var(--gradient-primary); color:white; border:none; cursor:pointer;" id="emergency-done">
          Continue
        </button>
      </div>
    `;
    
    document.getElementById('emergency-done')?.addEventListener('click', () => {
      overlay.classList.add('hidden');
    });
  }
}

export function isActive() {
  return isEmergencyActive;
}
