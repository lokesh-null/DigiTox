// Insights Screen — AI behavior analysis, charts, heatmap, weekly report

import { Chart, registerables } from 'chart.js';
import { generateWeeklyData, generateHeatmapData, getAISuggestions, getWeeklyGrade } from '../data/mockData.js';

Chart.register(...registerables);

let weeklyChart = null;
let donutChart = null;

export function render() {
  const weeklyData = generateWeeklyData();
  const heatmapData = generateHeatmapData();
  const suggestions = getAISuggestions(heatmapData);
  const grade = getWeeklyGrade(weeklyData);
  
  const totalProductive = weeklyData.reduce((s, d) => s + d.productive, 0);
  const totalAddictive = weeklyData.reduce((s, d) => s + d.addictive, 0);
  const totalNeutral = weeklyData.reduce((s, d) => s + d.neutral, 0);
  
  const container = document.getElementById('screen-container');
  container.innerHTML = `
    <div class="screen" id="insights-view">
      <div class="screen-title">Insights</div>
      <div class="screen-subtitle">AI-powered behavior analysis</div>
      
      <!-- Weekly Report Card -->
      <div class="report-card">
        <div class="report-grade">${grade.grade}</div>
        <div class="report-title">${grade.title}</div>
        <div class="report-desc">${grade.desc}</div>
      </div>
      
      <!-- Weekly Usage Chart -->
      <div class="glass-card insights-chart-card">
        <div class="section-title"><span class="icon">📊</span> Weekly Usage</div>
        <div class="chart-wrapper">
          <canvas id="weekly-chart"></canvas>
        </div>
      </div>
      
      <!-- Time Split Donut -->
      <div class="glass-card insights-chart-card">
        <div class="section-title"><span class="icon">🍩</span> Time Wasted vs Invested</div>
        <div class="chart-wrapper" style="height:180px; display:flex; align-items:center; justify-content:center;">
          <canvas id="donut-chart" style="max-width:180px; max-height:180px;"></canvas>
          <div style="margin-left:var(--space-lg); font-size:0.8rem; color:var(--text-secondary);">
            <div style="margin-bottom:8px;"><span style="color:var(--secondary);font-weight:600;">${Math.round(totalProductive/60)}h</span> Productive</div>
            <div style="margin-bottom:8px;"><span style="color:var(--danger);font-weight:600;">${Math.round(totalAddictive/60)}h</span> Addictive</div>
            <div><span style="color:var(--warning);font-weight:600;">${Math.round(totalNeutral/60)}h</span> Neutral</div>
          </div>
        </div>
      </div>
      
      <!-- Distraction Heatmap -->
      <div class="glass-card" style="margin-bottom:var(--space-lg)">
        <div class="section-title"><span class="icon">🔥</span> Peak Distraction Hours</div>
        <div class="heatmap-labels">
          <span>12AM</span><span>4AM</span><span>8AM</span><span>12PM</span><span>4PM</span><span>8PM</span><span>12AM</span>
        </div>
        <div class="heatmap-grid">
          ${heatmapData.map((d, i) => `
            <div class="heatmap-cell level-${d.level}" title="${i}:00 - ${i+1}:00" style="grid-column: span 1;"></div>
          `).join('')}
        </div>
        <div style="display:flex; justify-content:space-between; align-items:center; margin-top:var(--space-sm); font-size:0.65rem; color:var(--text-tertiary)">
          <span>Low</span>
          <div style="display:flex; gap:3px;">
            <div style="width:12px;height:12px;border-radius:2px;background:rgba(255,255,255,0.03)"></div>
            <div style="width:12px;height:12px;border-radius:2px;background:rgba(108,92,231,0.2)"></div>
            <div style="width:12px;height:12px;border-radius:2px;background:rgba(108,92,231,0.4)"></div>
            <div style="width:12px;height:12px;border-radius:2px;background:rgba(255,107,107,0.4)"></div>
            <div style="width:12px;height:12px;border-radius:2px;background:rgba(255,107,107,0.7)"></div>
          </div>
          <span>High</span>
        </div>
      </div>
      
      <!-- AI Suggestions -->
      <div class="section-title"><span class="icon">🤖</span> AI Recommendations</div>
      <div class="ai-suggestions">
        ${suggestions.map(s => `
          <div class="ai-suggestion-card">
            <div class="ai-suggestion-icon">${s.icon}</div>
            <div class="ai-suggestion-text">${s.text}</div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
  
  // Render charts after DOM is ready
  requestAnimationFrame(() => {
    renderWeeklyChart(weeklyData);
    renderDonutChart(totalProductive, totalAddictive, totalNeutral);
  });
}

function renderWeeklyChart(weeklyData) {
  const ctx = document.getElementById('weekly-chart');
  if (!ctx) return;
  
  if (weeklyChart) weeklyChart.destroy();
  
  weeklyChart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: weeklyData.map(d => d.day),
      datasets: [
        {
          label: 'Productive',
          data: weeklyData.map(d => d.productive),
          backgroundColor: 'rgba(0, 206, 201, 0.7)',
          borderRadius: 4,
          borderSkipped: false,
        },
        {
          label: 'Addictive',
          data: weeklyData.map(d => d.addictive),
          backgroundColor: 'rgba(255, 107, 107, 0.7)',
          borderRadius: 4,
          borderSkipped: false,
        },
        {
          label: 'Neutral',
          data: weeklyData.map(d => d.neutral),
          backgroundColor: 'rgba(253, 203, 110, 0.5)',
          borderRadius: 4,
          borderSkipped: false,
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: true,
          position: 'bottom',
          labels: {
            color: 'rgba(240,240,245,0.5)',
            font: { size: 10, family: 'Inter' },
            boxWidth: 8,
            boxHeight: 8,
            borderRadius: 2,
            useBorderRadius: true,
            padding: 12,
          }
        }
      },
      scales: {
        x: {
          stacked: true,
          grid: { display: false },
          ticks: { color: 'rgba(240,240,245,0.4)', font: { size: 11, family: 'Inter' } },
          border: { display: false },
        },
        y: {
          stacked: true,
          grid: { color: 'rgba(255,255,255,0.04)' },
          ticks: { 
            color: 'rgba(240,240,245,0.3)', 
            font: { size: 10, family: 'Inter' },
            callback: v => `${Math.round(v / 60)}h`
          },
          border: { display: false },
        }
      },
      animation: {
        duration: 1000,
        easing: 'easeOutQuart'
      }
    }
  });
}

function renderDonutChart(productive, addictive, neutral) {
  const ctx = document.getElementById('donut-chart');
  if (!ctx) return;
  
  if (donutChart) donutChart.destroy();
  
  donutChart = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: ['Productive', 'Addictive', 'Neutral'],
      datasets: [{
        data: [productive, addictive, neutral],
        backgroundColor: [
          'rgba(0, 206, 201, 0.8)',
          'rgba(255, 107, 107, 0.8)',
          'rgba(253, 203, 110, 0.6)',
        ],
        borderWidth: 0,
        borderRadius: 4,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      cutout: '70%',
      plugins: {
        legend: { display: false }
      },
      animation: {
        animateRotate: true,
        duration: 1200,
        easing: 'easeOutQuart'
      }
    }
  });
}

export function cleanup() {
  if (weeklyChart) { weeklyChart.destroy(); weeklyChart = null; }
  if (donutChart) { donutChart.destroy(); donutChart = null; }
}
