// ── CONSTANTS ──────────────────────────────────────────────────────────────

const PRAYER_NAMES = ['Fajr', 'Thuhr', 'Asr', 'Maghrib', 'Isha'];
const PRAYER_KEYS  = ['fajr', 'thuhr', 'asr', 'maghrib', 'isha'];

// Abbreviated month names matching the masjids.co.za date format ("20 Mar")
const MONTH_ABBR = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

// Alert timing fallback (used when a mosque has no per-prayer offsets configured).
const DEFAULT_OFFSET_MINS = [15, 0];

// Build a human-readable label for an offset.
function alertLabel(prayerName, mins) {
  if (mins === 0) return `Time for ${prayerName}!`;
  if (mins % 60 === 0) {
    const h = mins / 60;
    return `${prayerName} in ${h} hour${h !== 1 ? 's' : ''}`;
  }
  return `${prayerName} in ${mins} minute${mins !== 1 ? 's' : ''}`;
}

// Build ALERT_OFFSETS compat shim (still used by the fallback path).
function buildAlertOffsets(minutesArray) {
  return minutesArray.map(mins => ({
    ms: mins * 60 * 1000,
    label: (name) => alertLabel(name, mins),
  }));
}
let ALERT_OFFSETS = buildAlertOffsets(DEFAULT_OFFSET_MINS);

// ── MUTABLE STATE ──────────────────────────────────────────────────────────

let alertsEnabled    = false;
let audioUnlocked    = false;
let alertTimeouts    = [];     // fallback setTimeout IDs (used if Worker unavailable)
let countdownTimer   = null;   // setInterval ID for the countdown display
let bannerTimeout    = null;   // setTimeout ID for auto-dismissing the toast
let currentDayData   = null;   // today's row { fajr, thuhr, asr, maghrib, isha, ... }
let tomorrowDayData  = null;   // tomorrow's row (used after Isha for next-Fajr)
let currentProfile   = null;   // mosque profile data
let adhanWorker      = null;   // Web Worker for reliable background scheduling

// ── DATE HELPERS ───────────────────────────────────────────────────────────

// Returns 'YYYY-MM' string from a Date object
function toYearMonth(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

// Converts "HH:MM" string to a Date object set on the given base date
function parseTimeToDate(timeStr, baseDate) {
  const [h, m] = timeStr.split(':').map(Number);
  const d = new Date(baseDate);
  d.setHours(h, m, 0, 0);
  return d;
}

// Returns the date string the site uses in column 0 — e.g. "20 Mar"
function formatDateForMatch(date) {
  return `${date.getDate()} ${MONTH_ABBR[date.getMonth()]}`;
}

// Returns a Date set to midnight on the day after 'now'
function getTomorrow() {
  const t = new Date();
  t.setDate(t.getDate() + 1);
  t.setHours(0, 0, 0, 0);
  return t;
}

// Left-pad a number to 2 digits
function pad(n) {
  return String(n).padStart(2, '0');
}

// ── API HELPERS ────────────────────────────────────────────────────────────

async function fetchMonthFromAPI(yearMonth) {
  const res = await fetch(`/api/times?month=${yearMonth}`);
  if (!res.ok) {
    throw new Error(`Server returned HTTP ${res.status} for month ${yearMonth}`);
  }
  const json = await res.json();
  if (!json.success) {
    throw new Error(json.error || 'Unknown server error');
  }
  return json.data; // array of day objects
}

// Finds today's row by matching the "20 Mar" date string
function findDayRow(monthData, targetDate) {
  const target = formatDateForMatch(targetDate);

  // Primary: exact string match
  let row = monthData.find(r => r.date.trim() === target);
  if (row) return row;

  // Fallback: match numeric day only
  const dayNum = targetDate.getDate();
  return monthData.find(r => parseInt(r.date.trim().split(' ')[0], 10) === dayNum) || null;
}

// ── PRAYER LOGIC ───────────────────────────────────────────────────────────

// Build an array of { name, key, dateObj } for the 5 daily prayers
function buildPrayerList(dayRow, baseDate) {
  const today = new Date(baseDate);
  today.setHours(0, 0, 0, 0);
  return PRAYER_KEYS.map((key, i) => ({
    name:    PRAYER_NAMES[i],
    key,
    dateObj: parseTimeToDate(dayRow[key], today)
  }));
}

// Determine which prayer is 'current' (most recently passed) and 'next'
// Returns { currentIdx, nextIdx }
//   currentIdx: -1 = before Fajr
//   nextIdx:    -1 = after Isha (use tomorrow's Fajr)
function getCurrentAndNext(prayers, now) {
  let currentIdx = -1;

  for (let i = 0; i < prayers.length; i++) {
    if (prayers[i].dateObj <= now) {
      currentIdx = i;
    }
  }

  const nextIdx = currentIdx === prayers.length - 1
    ? -1                      // after Isha — next is tomorrow's Fajr
    : currentIdx + 1;         // includes before-Fajr case: -1+1=0 (Fajr)

  return { currentIdx, nextIdx };
}

// ── RENDER ─────────────────────────────────────────────────────────────────

function renderPrayerCards(prayers, currentIdx, nextIdx) {
  const grid = document.getElementById('prayer-grid');
  grid.innerHTML = '';

  prayers.forEach((p, i) => {
    const card = document.createElement('div');
    card.className = 'prayer-card';
    if (i === currentIdx) card.classList.add('is-current');
    if (i === nextIdx)    card.classList.add('is-next');

    const timeStr = p.dateObj.toLocaleTimeString('en-ZA', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
      timeZone: 'Africa/Johannesburg'
    });

    card.innerHTML = `
      <div class="prayer-name">${p.name}</div>
      <div class="prayer-time">${timeStr}</div>
    `;
    grid.appendChild(card);
  });
}

function renderFasting(dayRow) {
  document.getElementById('sehri-time').textContent = dayRow.fajr;
  document.getElementById('iftar-time').textContent = dayRow.maghrib;
}

// ── COUNTDOWN ──────────────────────────────────────────────────────────────

function startCountdown(nextPrayer, tomorrowFajrDateObj) {
  if (countdownTimer) {
    clearInterval(countdownTimer);
    countdownTimer = null;
  }

  const targetDate = nextPrayer ? nextPrayer.dateObj : tomorrowFajrDateObj;
  const targetName = nextPrayer ? nextPrayer.name    : 'Fajr (tomorrow)';

  const labelEl = document.getElementById('next-label');
  const countEl = document.getElementById('countdown');

  if (!targetDate) {
    labelEl.textContent = 'Next Prayer';
    countEl.textContent = '--:--:--';
    return;
  }

  function tick() {
    const now  = new Date();
    const diff = targetDate.getTime() - now.getTime();

    if (diff <= 0) {
      clearInterval(countdownTimer);
      countdownTimer = null;
      // Prayer has arrived — reinitialise the whole display
      initDisplay().catch(err => showError(err.message));
      return;
    }

    const h = Math.floor(diff / 3600000);
    const m = Math.floor((diff % 3600000) / 60000);
    const s = Math.floor((diff % 60000)   / 1000);

    labelEl.textContent = `Next: ${targetName}`;
    countEl.textContent = `${pad(h)}:${pad(m)}:${pad(s)}`;
  }

  tick(); // run immediately to avoid 1-second blank
  countdownTimer = setInterval(tick, 1000);
}

// ── AUDIO ──────────────────────────────────────────────────────────────────

// We use the Web Audio API so that playback can be triggered from Worker
// messages / setTimeout callbacks without needing another user gesture.
// The AudioContext is created and resumed during the button click (user
// gesture), after which it stays "running" for the lifetime of the page.

let audioCtx    = null;
let audioBuffer = null; // decoded PCM data for adhan.mp3

async function unlockAudio() {
  try {
    if (!audioCtx) {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    // Resume inside the user-gesture handler — this is the key step that
    // grants the context permission to play audio at any future time.
    if (audioCtx.state === 'suspended') await audioCtx.resume();

    // Fetch + decode the MP3 once; reuse the buffer for every playback.
    if (!audioBuffer) {
      const res = await fetch('/audio/adhan.mp3');
      if (res.ok) {
        const arrayBuf = await res.arrayBuffer();
        audioBuffer = await audioCtx.decodeAudioData(arrayBuf);
      }
    }
    audioUnlocked = true;
  } catch (err) {
    console.warn('Audio unlock failed:', err.message);
    // Still mark unlocked so we don't block the alert flow entirely
    audioUnlocked = true;
  }
}

function playAdhan() {
  if (!audioUnlocked || !audioCtx || !audioBuffer) return;
  try {
    // Each play needs a fresh BufferSourceNode (they are one-shot by spec)
    const source = audioCtx.createBufferSource();
    source.buffer = audioBuffer;
    source.connect(audioCtx.destination);
    source.start(0);
  } catch (err) {
    console.warn('Adhan playback failed:', err.message);
  }
}

// ── ALERT TOAST ────────────────────────────────────────────────────────────

function showAlertBanner(message) {
  const banner = document.getElementById('alert-banner');
  banner.textContent = message;
  banner.classList.add('visible');

  if (bannerTimeout) clearTimeout(bannerTimeout);
  bannerTimeout = setTimeout(() => {
    banner.classList.remove('visible');
  }, 5000);
}

// ── ADHAN SCHEDULING ───────────────────────────────────────────────────────

// ── ALERT SCHEDULE HELPERS ────────────────────────────────────────────────

// Build a flat list of { targetMs, label } for every prayer × every offset.
function buildAlertList(prayers, tomorrowFajrDateObj) {
  const allTargets = [
    ...prayers,
    ...(tomorrowFajrDateObj
      ? [{ name: 'Fajr (tomorrow)', key: 'fajr', dateObj: tomorrowFajrDateObj }]
      : [])
  ];

  const alerts = [];
  allTargets.forEach(prayer => {
    const perPrayer = currentProfile?.adhanOffsets?.[prayer.key];
    const minsList  = (Array.isArray(perPrayer) && perPrayer.length > 0)
      ? perPrayer
      : DEFAULT_OFFSET_MINS;

    minsList.forEach(mins => {
      alerts.push({
        targetMs: prayer.dateObj.getTime() - mins * 60_000,
        label:    alertLabel(prayer.name, mins),
      });
    });
  });
  return alerts;
}

// Persist the current alert schedule to localStorage so page refresh can
// recover any prayer that fired while the page was reloading.
function saveSchedule(alerts) {
  try {
    localStorage.setItem('adhan_schedule', JSON.stringify(alerts));
  } catch (_) {}
}

function clearAllAlerts() {
  if (adhanWorker) adhanWorker.postMessage({ type: 'stop' });
  alertTimeouts.forEach(clearTimeout);
  alertTimeouts = [];
}

function scheduleAlerts(prayers, tomorrowFajrDateObj) {
  clearAllAlerts();
  if (!alertsEnabled) return;

  const alerts = buildAlertList(prayers, tomorrowFajrDateObj);
  saveSchedule(alerts);

  if (adhanWorker) {
    // Primary path: hand off to Web Worker (background-thread, less throttled)
    adhanWorker.postMessage({ type: 'schedule', alerts });
  } else {
    // Fallback: main-thread setTimeout (may be throttled in background tabs)
    const now = Date.now();
    alerts.forEach(a => {
      const delay = a.targetMs - now;
      if (delay > 0) {
        alertTimeouts.push(setTimeout(() => {
          showAlertBanner(a.label);
          playAdhan();
        }, delay));
      }
    });
  }
}

// On page load (or tab regain focus), check if any alert fired in the last
// 2 minutes while the page was not running — play it immediately if so.
function checkMissedAlerts() {
  if (!alertsEnabled) return;
  try {
    const raw = localStorage.getItem('adhan_schedule');
    if (!raw) return;
    const alerts = JSON.parse(raw);
    const now    = Date.now();
    const TWO_MIN = 2 * 60_000;
    alerts.forEach(a => {
      if (a.targetMs <= now && now - a.targetMs < TWO_MIN) {
        showAlertBanner(a.label);
        playAdhan();
      }
    });
  } catch (_) {}
}

// ── WEB WORKER + NOTIFICATION SETUP ──────────────────────────────────────

async function requestNotificationPermission() {
  if (!('Notification' in window)) return;
  if (Notification.permission === 'default') {
    await Notification.requestPermission();
  }
}

function showSystemNotification(label) {
  if (!('Notification' in window) || Notification.permission !== 'granted') return;
  try {
    new Notification('Salaah Time', {
      body:              label,
      icon:              '/favicon.ico',
      tag:               label,      // collapses duplicate notifications
      renotify:          true,
      requireInteraction: false,
    });
  } catch (_) {}
}

function startWorker() {
  if (adhanWorker) return; // already running
  try {
    adhanWorker = new Worker('/worker.js');
    adhanWorker.addEventListener('message', (e) => {
      if (e.data?.type === 'adhan') {
        showAlertBanner(e.data.label);
        showSystemNotification(e.data.label);
        playAdhan();
      }
    });
    adhanWorker.addEventListener('error', () => {
      // Worker failed — fall back to main-thread scheduling
      adhanWorker = null;
    });
  } catch (_) {
    adhanWorker = null;
  }
}

function stopWorker() {
  if (adhanWorker) {
    adhanWorker.postMessage({ type: 'stop' });
    adhanWorker.terminate();
    adhanWorker = null;
  }
}

// ── ALERTS BUTTON ──────────────────────────────────────────────────────────

document.getElementById('alerts-btn').addEventListener('click', async () => {
  const btn = document.getElementById('alerts-btn');

  if (!alertsEnabled) {
    // Required user-gesture: unlock audio, start worker, request notifications
    await unlockAudio();
    await requestNotificationPermission();
    startWorker();
    alertsEnabled = true;
    btn.textContent = '🔕 Disable Adhan Alerts';
    btn.classList.add('is-active');

    // Schedule alerts using current state
    if (currentDayData) {
      const prayers          = buildPrayerList(currentDayData, new Date());
      const tomorrow         = getTomorrow();
      const tomorrowFajrDate = tomorrowDayData
        ? parseTimeToDate(tomorrowDayData.fajr, tomorrow)
        : null;
      scheduleAlerts(prayers, tomorrowFajrDate);
    }
  } else {
    alertsEnabled = false;
    clearAllAlerts();
    stopWorker();
    localStorage.removeItem('adhan_schedule');
    btn.textContent = '🔔 Enable Adhan Alerts';
    btn.classList.remove('is-active');
  }
});

// When the tab regains visibility (user switches back, screen wakes), check
// if any alert fired while the page was hidden / reloading.
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') checkMissedAlerts();
});

// ── ERROR DISPLAY ──────────────────────────────────────────────────────────

function showError(message) {
  document.getElementById('loading-state').hidden  = true;
  document.getElementById('main-content').hidden   = true;
  const errEl = document.getElementById('error-state');
  errEl.textContent = `Could not load prayer times: ${message}`;
  errEl.hidden = false;
}

// ── LIVE CLOCK ─────────────────────────────────────────────────────────────

function startLiveClock() {
  const el = document.getElementById('live-clock');

  function tick() {
    el.textContent = new Date().toLocaleString('en-ZA', {
      weekday: 'long',
      year:    'numeric',
      month:   'long',
      day:     'numeric',
      hour:    '2-digit',
      minute:  '2-digit',
      second:  '2-digit',
      timeZone: 'Africa/Johannesburg'
    });
  }

  tick();
  setInterval(tick, 1000);
}

// ── PROFILE LOADING ────────────────────────────────────────────────────────

async function loadProfile() {
  // Prefer the slug injected by PHP (handles short URLs like /000 transparently)
  const mosqueSlug = window.__MOSQUE_SLUG__ || new URLSearchParams(window.location.search).get('mosque');

  try {
    const res = await fetch(`/api/profile${mosqueSlug ? `?mosque=${encodeURIComponent(mosqueSlug)}` : ''}`);
    if (!res.ok) {
      // No profile found, use defaults
      return null;
    }
    const json = await res.json();
    return json.success ? json.profile : null;
  } catch (err) {
    console.warn('Could not load mosque profile:', err);
    return null;
  }
}

function applyProfile(profile) {
  if (!profile) return;

  currentProfile = profile;

  // Apply CSS color overrides
  if (profile.colors) {
    const style = document.createElement('style');
    style.id = 'profile-colors';
    style.textContent = `
      :root {
        ${profile.colors.primary ? `--green: ${profile.colors.primary};` : ''}
        ${profile.colors.gold ? `--gold: ${profile.colors.gold}; --gold-text: ${profile.colors.gold};` : ''}
        ${profile.colors.background ? `--bg: ${profile.colors.background};` : ''}
      }
    `;
    document.head.appendChild(style);
  }

  // Show/hide fasting section
  const fastingSection = document.querySelector('.fasting-section');
  if (fastingSection && profile.features && profile.features.showFasting === false) {
    fastingSection.style.display = 'none';
  }

  // Render mosque logo and contact
  if (profile.logo) {
    const logoContainer = document.getElementById('mosque-profile');
    const logoImg = document.getElementById('mosque-logo');
    logoImg.src = profile.logo;
    logoImg.alt = profile.name;
    logoContainer.hidden = false;
  }

  if (profile.contact) {
    const contactDiv = document.getElementById('mosque-contact');
    contactDiv.innerHTML = `
      <h2>${profile.name}</h2>
      ${profile.contact.address ? `<p>${profile.contact.address}</p>` : ''}
      ${profile.contact.phone ? `<p><a href="tel:${profile.contact.phone}">${profile.contact.phone}</a></p>` : ''}
      ${profile.contact.website ? `<p><a href="${profile.contact.website}" target="_blank" rel="noopener">${profile.contact.website}</a></p>` : ''}
    `;
  }

  // Render announcements
  if (profile.announcements && profile.announcements.length > 0) {
    const announcements = document.getElementById('announcements');
    announcements.innerHTML = '<h2 class="section-title">Announcements</h2>' +
      profile.announcements.map(text => `<p class="announcement">${text}</p>`).join('');
    announcements.hidden = false;
  }

  // Show/hide sponsor sidebars
  const socialMedia = profile.socialMedia || [];
  const sponsors    = profile.sponsors    || [];

  if (profile.features?.showSidebars === false) {
    // Full-screen mode: collapse sidebars via CSS class
    document.body.classList.add('no-sidebars');
  } else if (socialMedia.length > 0 || sponsors.length > 0) {
    initSponsorSidebars(socialMedia, sponsors);
  }
}

// ── SPONSOR SIDEBARS ───────────────────────────────────────────────────────

function initSponsorSidebars(socialMedia, sponsors) {
  const leftSidebar = document.getElementById('sponsors-left');
  const rightSidebar = document.getElementById('sponsors-right');
  const leftImg = document.getElementById('sponsor-left-img');
  const rightImg = document.getElementById('sponsor-right-img');

  // Left sidebar: Social Media
  if (socialMedia.length > 0) {
    leftSidebar.hidden = false;
    let currentLeftIndex = 0;

    function showSocial(img, item) {
      img.src = item.image;
      img.alt = item.alt || 'Social Media';
      if (item.link) {
        img.style.cursor = 'pointer';
        img.onclick = () => window.open(item.link, '_blank');
      }
    }

    function rotateSocial() {
      showSocial(leftImg, socialMedia[currentLeftIndex]);
      currentLeftIndex = (currentLeftIndex + 1) % socialMedia.length;
    }

    rotateSocial();
    setInterval(rotateSocial, 7000);
  }

  // Right sidebar: Sponsors
  if (sponsors.length > 0) {
    rightSidebar.hidden = false;
    let currentRightIndex = 0;

    function showSponsor(img, item) {
      img.src = item.image;
      img.alt = item.alt || 'Sponsor';
      if (item.link) {
        img.style.cursor = 'pointer';
        img.onclick = () => window.open(item.link, '_blank');
      }
    }

    function rotateSponsor() {
      showSponsor(rightImg, sponsors[currentRightIndex]);
      currentRightIndex = (currentRightIndex + 1) % sponsors.length;
    }

    rotateSponsor();
    setInterval(rotateSponsor, 7000);
  }
}

// ── MAIN INIT ──────────────────────────────────────────────────────────────

async function initDisplay() {
  const now           = new Date();
  const todayMonth    = toYearMonth(now);
  const tomorrow      = getTomorrow();
  const tomorrowMonth = toYearMonth(tomorrow);

  // Fetch this month's prayer times
  const thisMonthData = await fetchMonthFromAPI(todayMonth);
  currentDayData      = findDayRow(thisMonthData, now);

  if (!currentDayData) {
    throw new Error(
      `No data found for today (${formatDateForMatch(now)}) — site may not have updated yet`
    );
  }

  // Fetch tomorrow's row — may need next month if today is last day of the month
  if (tomorrowMonth !== todayMonth) {
    try {
      const nextMonthData = await fetchMonthFromAPI(tomorrowMonth);
      tomorrowDayData     = findDayRow(nextMonthData, tomorrow);
    } catch {
      tomorrowDayData = null; // non-fatal — countdown just won't show tomorrow's Fajr
    }
  } else {
    tomorrowDayData = findDayRow(thisMonthData, tomorrow);
  }

  // Build prayer Date objects for today
  const prayers              = buildPrayerList(currentDayData, now);
  const { currentIdx, nextIdx } = getCurrentAndNext(prayers, now);

  // Tomorrow's Fajr as a Date (used when nextIdx === -1, i.e. after Isha)
  const tomorrowFajrDateObj = tomorrowDayData
    ? parseTimeToDate(tomorrowDayData.fajr, tomorrow)
    : null;

  const nextPrayer = nextIdx >= 0 ? prayers[nextIdx] : null;

  // ── RENDER ──
  renderPrayerCards(prayers, currentIdx, nextIdx);
  renderFasting(currentDayData);
  startCountdown(nextPrayer, tomorrowFajrDateObj);

  // Re-schedule alerts if they were already enabled before this re-init
  if (alertsEnabled) {
    scheduleAlerts(prayers, tomorrowFajrDateObj);
  }

  // Show main content
  document.getElementById('loading-state').hidden = true;
  document.getElementById('error-state').hidden   = true;
  document.getElementById('main-content').hidden  = false;
}

// ── ENTRY POINT ────────────────────────────────────────────────────────────

(async function main() {
  startLiveClock();

  // Load and apply profile first
  const profile = await loadProfile();
  applyProfile(profile);

  // Then load prayer times
  try {
    await initDisplay();
  } catch (err) {
    console.error(err);
    showError(err.message);
  }

  // If the user had alerts enabled before a refresh, re-enable them automatically.
  // We detect this by the presence of a saved schedule in localStorage.
  if (localStorage.getItem('adhan_schedule')) {
    const btn = document.getElementById('alerts-btn');
    unlockAudio();
    // Note: can't re-request notification permission here (no user gesture),
    // but permission was already granted in the previous session.
    startWorker();
    alertsEnabled = true;
    if (btn) {
      btn.textContent = '🔕 Disable Adhan Alerts';
      btn.classList.add('is-active');
    }
    // Re-schedule using fresh prayer times (initDisplay already set currentDayData)
    if (currentDayData) {
      const prayers          = buildPrayerList(currentDayData, new Date());
      const tomorrow         = getTomorrow();
      const tomorrowFajrDate = tomorrowDayData
        ? parseTimeToDate(tomorrowDayData.fajr, tomorrow)
        : null;
      scheduleAlerts(prayers, tomorrowFajrDate);
    }
    // Also immediately fire any alert missed during the reload window
    checkMissedAlerts();
  }
})();
