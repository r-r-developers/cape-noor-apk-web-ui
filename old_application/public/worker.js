// ─────────────────────────────────────────────────────────────────────────────
// Adhan Alert Web Worker
// Runs on a separate thread — much less throttled than the main page thread.
// Schedules precise setTimeout for every alert AND runs a 60-second watchdog
// setInterval so throttled timers are caught within a 1-minute window.
// ─────────────────────────────────────────────────────────────────────────────

let pendingAlerts = []; // [{ targetMs, label, fired }]
let watchdogTimer = null;

// ── Scheduling ────────────────────────────────────────────────────────────────

function clearAll() {
  pendingAlerts.forEach(a => { if (a.timerId) clearTimeout(a.timerId); });
  pendingAlerts = [];
}

function fireAlert(alert) {
  if (alert.fired) return;
  alert.fired = true;
  self.postMessage({ type: 'adhan', label: alert.label, targetMs: alert.targetMs });
}

function buildSchedule(alerts) {
  clearAll();
  const now = Date.now();

  alerts.forEach(a => {
    const delay = a.targetMs - now;
    const entry = { targetMs: a.targetMs, label: a.label, fired: false, timerId: null };

    if (delay <= 0) {
      // Already passed — skip (page load recovery handles this separately)
      entry.fired = true;
    } else {
      entry.timerId = setTimeout(() => fireAlert(entry), delay);
    }

    pendingAlerts.push(entry);
  });
}

// Watchdog: every 60 s, fire any alert whose target has passed but wasn't fired
// (catches cases where setTimeout was heavily throttled)
function startWatchdog() {
  if (watchdogTimer) clearInterval(watchdogTimer);
  watchdogTimer = setInterval(() => {
    const now = Date.now();
    pendingAlerts.forEach(a => {
      if (!a.fired && now >= a.targetMs) fireAlert(a);
    });
  }, 60_000);
}

// ── Message handler ───────────────────────────────────────────────────────────

self.addEventListener('message', (e) => {
  if (e.data?.type === 'schedule') {
    buildSchedule(e.data.alerts); // alerts = [{ targetMs, label }]
    startWatchdog();
  } else if (e.data?.type === 'stop') {
    clearAll();
    if (watchdogTimer) clearInterval(watchdogTimer);
    watchdogTimer = null;
  }
});
