// ─────────────────────────────────────────────────────────────────────────────
// Salaah Times — Admin Panel JS
// Role-aware, session-based auth (no Basic Auth headers needed).
// ─────────────────────────────────────────────────────────────────────────────

// ── State ─────────────────────────────────────────────────────────────────────
let currentUser     = null;
let mosques         = [];
let editingSlug     = null;
let socialMedia     = [];
let sponsors        = [];
let currentLogoPath = '';
let allMosques      = [];  // used when populating user-mosque dropdowns
let mosqueAdhanOffsets = {}; // per-prayer adhan offsets for the mosque currently being edited

const PRAYER_KEYS_ADMIN  = ['fajr', 'thuhr', 'asr', 'maghrib', 'isha'];
const PRAYER_NAMES_ADMIN = ['Fajr', 'Thuhr', 'Asr', 'Maghrib', 'Isha'];
const DEFAULT_ADHAN_OFFSETS = { fajr: [15, 0], thuhr: [10, 0], asr: [10, 0], maghrib: [0], isha: [15, 0] };

// ── Boot ──────────────────────────────────────────────────────────────────────
(async function boot() {
  // Use the user object injected by index.php — avoids a redundant round-trip.
  // Falls back to an API call when the page is served without PHP (e.g. dev server).
  if (window.__CURRENT_USER__) {
    currentUser = window.__CURRENT_USER__;
  } else {
    const res = await fetch('/api/auth/me');
    if (!res.ok) {
      window.location.replace('/admin/login.php');
      return;
    }
    const json = await res.json();
    currentUser = json.user;
  }

  // Tabs and buttons are already shown/hidden server-side via PHP, but we keep
  // the JS logic as a safety net for the fallback path above.
  if (currentUser.role === 'super_admin') {
    document.getElementById('tab-users').hidden      = false;
    document.getElementById('tab-settings').hidden   = false;
    document.getElementById('add-mosque-btn').hidden = false;
  } else if (currentUser.role === 'mosque_admin') {
    document.getElementById('tab-users').hidden = false;
  }
  document.getElementById('tab-pending').hidden = false;

  initTabs();
  loadMosques();
  loadPendingChanges();
  if (currentUser.role === 'super_admin') loadSettings();

  document.getElementById('logout-btn').addEventListener('click', logout);
})();

// ── Tab navigation ────────────────────────────────────────────────────────────
function initTabs() {
  document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-panel').forEach(p => p.hidden = true);
      btn.classList.add('active');
      document.getElementById('tab-panel-' + btn.dataset.tab).hidden = false;

      if (btn.dataset.tab === 'users') loadUsers();
    });
  });
}

async function logout() {
  await fetch('/api/auth/logout', { method: 'POST' });
  window.location.replace('/admin/login.php');
}

// ── API helper ────────────────────────────────────────────────────────────────
async function api(url, opts = {}) {
  const res  = await fetch(url, { headers: { 'Content-Type': 'application/json' }, ...opts });
  const json = await res.json().catch(() => ({}));
  if (res.status === 401) { window.location.replace('/admin/login.php'); }
  return { ok: res.ok, status: res.status, json };
}

// ── MOSQUES ───────────────────────────────────────────────────────────────────
async function loadMosques() {
  const { ok, json } = await api('/api/admin/mosques');
  if (!ok) { alert('Failed to load mosques: ' + json.error); return; }
  mosques    = json.mosques;
  allMosques = json.mosques;
  renderMosqueList();
  populateMosqueDropdowns();
}

function renderMosqueList() {
  const list = document.getElementById('mosque-list');
  if (!mosques.length) {
    list.innerHTML = '<p style="color:var(--text-muted)">No mosques yet. Click "+ Add Mosque" to create one.</p>';
    return;
  }
  list.innerHTML = mosques.map(m => `
    <div class="mosque-card ${m.isDefault ? 'is-default' : ''}">
      <div class="mosque-card-info">
        <h3>${esc(m.name)} ${m.isDefault ? '<span class="default-badge">Default</span>' : ''}</h3>
        <p>
          ${m.shortId ? `<strong>/${esc(m.shortId)}</strong> &middot; ` : ''}/?mosque=${esc(m.slug)}
          | <a href="${m.shortId ? '/' + esc(m.shortId) : '/?mosque=' + esc(m.slug)}" target="_blank">View →</a>
        </p>
        ${m.autoApprove ? '<p style="color:var(--success);font-size:.85rem;">&#x2705; Auto-approve on</p>' : ''}
        ${m.features?.showSidebars === false ? '<p style="font-size:.85rem;color:var(--text-muted)">🖥️ Full-screen mode</p>' : ''}
      </div>
      <div class="mosque-card-actions">
        <button class="btn btn-primary" onclick="editMosque('${m.slug}')">Edit</button>
        ${currentUser.role === 'super_admin' && !m.isDefault
          ? `<button class="btn btn-secondary" onclick="setDefault('${m.slug}')">Set Default</button>`
          : ''}
      </div>
    </div>
  `).join('');
}

window.editMosque = async function(slug) {
  const { ok, json } = await api(`/api/admin/mosques/${slug}`);
  if (!ok) { alert('Failed to load mosque: ' + json.error); return; }
  const mosque = json.profile;
  editingSlug     = slug;
  currentLogoPath = mosque.logo || '';

  document.getElementById('form-title').textContent = 'Edit Mosque';
  document.getElementById('edit-slug').value         = slug;
  document.getElementById('slug').value              = mosque.slug;
  document.getElementById('slug').disabled           = true;
  document.getElementById('name').value              = mosque.name;
  document.getElementById('address').value           = mosque.contact?.address || '';
  document.getElementById('phone').value             = mosque.contact?.phone   || '';
  document.getElementById('website').value           = mosque.contact?.website || '';
  document.getElementById('show-fasting').checked    = mosque.features?.showFasting  !== false;
  document.getElementById('show-sidebars').checked   = mosque.features?.showSidebars !== false;

  // Load per-prayer adhan offsets; fall back to sensible defaults if not yet configured
  mosqueAdhanOffsets = (mosque.adhanOffsets && typeof mosque.adhanOffsets === 'object' && !Array.isArray(mosque.adhanOffsets))
    ? JSON.parse(JSON.stringify(mosque.adhanOffsets)) // deep clone
    : JSON.parse(JSON.stringify(DEFAULT_ADHAN_OFFSETS));
  renderMosqueAdhanOffsets();
  document.getElementById('color-primary').value     = mosque.colors?.primary    || '#22c55e';
  document.getElementById('color-gold').value        = mosque.colors?.gold       || '#d4af37';
  document.getElementById('color-bg').value          = mosque.colors?.background || '#0a0f1a';
  document.getElementById('announcements').value     = (mosque.announcements || []).join('\n');

  if (mosque.logo) {
    document.getElementById('logo-current').textContent = `Current: ${mosque.logo}`;
    document.getElementById('logo-preview').style.display = 'none';
  } else {
    document.getElementById('logo-current').textContent = '';
  }

  // Auto-approve toggle — only visible to admins
  const aaRow = document.getElementById('auto-approve-row');
  if (currentUser.role === 'super_admin' || currentUser.role === 'mosque_admin') {
    aaRow.hidden = false;
    document.getElementById('auto-approve').checked = !!mosque.autoApprove;
  } else {
    aaRow.hidden = true;
  }

  socialMedia = mosque.socialMedia || [];
  sponsors    = mosque.sponsors    || [];
  renderSocialMedia();
  renderSponsors();

  document.getElementById('delete-mosque-btn').hidden = (currentUser.role !== 'super_admin');
  document.getElementById('edit-section').hidden = false;
  window.scrollTo({ top: 0, behavior: 'smooth' });
};

document.getElementById('add-mosque-btn').addEventListener('click', () => {
  editingSlug     = null;
  currentLogoPath = '';
  document.getElementById('form-title').textContent = 'Add Mosque';
  document.getElementById('mosque-form').reset();
  document.getElementById('slug').disabled     = false;
  document.getElementById('delete-mosque-btn').hidden = true;
  document.getElementById('logo-preview').style.display = 'none';
  document.getElementById('logo-current').textContent  = '';
  document.getElementById('auto-approve-row').hidden = false;
  socialMedia = [];
  sponsors    = [];
  renderSocialMedia();
  renderSponsors();
  mosqueAdhanOffsets = JSON.parse(JSON.stringify(DEFAULT_ADHAN_OFFSETS));
  renderMosqueAdhanOffsets();
  document.getElementById('edit-section').hidden = false;
  window.scrollTo({ top: 0, behavior: 'smooth' });
});

document.getElementById('cancel-edit-btn').addEventListener('click', () => {
  document.getElementById('edit-section').hidden = true;
});

document.getElementById('mosque-form').addEventListener('submit', async (e) => {
  e.preventDefault();

  // Handle auto-approve toggle separately if changed (admin only)
  if (editingSlug && !document.getElementById('auto-approve-row').hidden) {
    const wantsAA    = document.getElementById('auto-approve').checked;
    const currentRow = mosques.find(m => m.slug === editingSlug);
    if (currentRow && !!currentRow.autoApprove !== wantsAA) {
      await api(`/api/admin/mosques/${editingSlug}/auto-approve`, { method: 'POST' });
    }
  }

  const payload = {
    slug: document.getElementById('slug').value,
    name: document.getElementById('name').value,
    logo: currentLogoPath || null,
    contact: {
      address: document.getElementById('address').value,
      phone:   document.getElementById('phone').value,
      website: document.getElementById('website').value,
    },
    features:      {
      showFasting:  document.getElementById('show-fasting').checked,
      showSidebars: document.getElementById('show-sidebars').checked,
    },
    colors:        {
      primary:    document.getElementById('color-primary').value,
      gold:       document.getElementById('color-gold').value,
      background: document.getElementById('color-bg').value,
    },
    announcements: document.getElementById('announcements').value.split('\n').map(s => s.trim()).filter(Boolean),
    socialMedia,
    sponsors,
    adhanOffsets: mosqueAdhanOffsets,
  };

  const method = editingSlug ? 'PUT'  : 'POST';
  const url    = editingSlug ? `/api/admin/mosques/${editingSlug}` : '/api/admin/mosques';

  const { ok, json } = await api(url, { method, body: JSON.stringify(payload) });

  if (ok && json.success) {
    if (json.pending) {
      alert('✅ Change submitted for approval! An admin will review it shortly.');
    } else {
      alert('Mosque saved successfully!');
    }
    document.getElementById('edit-section').hidden = true;
    loadMosques();
    loadPendingChanges();
  } else {
    alert('Error: ' + (json.error || 'Unknown error'));
  }
});

document.getElementById('logo-upload').addEventListener('change', async (e) => {
  const file = e.target.files[0];
  if (!file) return;
  const fd = new FormData();
  fd.append('logo', file);
  const res  = await fetch('/api/admin/upload/logo', { method: 'POST', body: fd });
  const json = await res.json();
  if (res.ok && json.success) {
    currentLogoPath = json.path;
    document.getElementById('logo-preview').src          = json.path;
    document.getElementById('logo-preview').style.display = 'block';
    document.getElementById('logo-current').textContent  = `New: ${json.path}`;
  } else {
    alert('Error uploading logo: ' + (json.error || 'Unknown'));
  }
});

document.getElementById('delete-mosque-btn').addEventListener('click', async () => {
  if (!confirm(`Delete ${editingSlug}? This cannot be undone.`)) return;
  const { ok, json } = await api(`/api/admin/mosques/${editingSlug}`, { method: 'DELETE' });
  if (ok && json.success) {
    alert('Mosque deleted');
    document.getElementById('edit-section').hidden = true;
    loadMosques();
  } else {
    alert('Error: ' + (json.error || 'Unknown'));
  }
});

window.setDefault = async function(slug) {
  const { ok, json } = await api('/api/admin/set-default', { method: 'POST', body: JSON.stringify({ slug }) });
  if (ok && json.success) loadMosques();
  else alert('Error: ' + (json.error || 'Unknown'));
};

// ── SOCIAL MEDIA ──────────────────────────────────────────────────────────────
function renderSocialMedia() {
  const c = document.getElementById('social-list');
  if (!socialMedia.length) {
    c.innerHTML = '<p style="color:var(--text-muted);font-size:.9rem">No social media yet.</p>';
    return;
  }
  c.innerHTML = socialMedia.map((s, i) => `
    <div class="sponsor-item">
      <img src="${esc(s.image)}" alt="${esc(s.alt || 'Social')}" />
      <input type="text"  placeholder="Alt text" value="${esc(s.alt   || '')}" onchange="socialMedia[${i}].alt  = this.value" />
      <input type="url"   placeholder="Link"      value="${esc(s.link  || '')}" onchange="socialMedia[${i}].link = this.value" />
      <button type="button" class="btn btn-danger" onclick="socialMedia.splice(${i},1);renderSocialMedia()">✕</button>
    </div>`).join('');
}

document.getElementById('add-social-btn').addEventListener('click', () => uploadFile('sponsor', path => {
  socialMedia.push({ image: path, alt: '', link: '' });
  renderSocialMedia();
}));

document.getElementById('download-from-url-btn').addEventListener('click', async () => {
  const input = prompt('Paste image URL(s) — one per line:');
  if (!input?.trim()) return;
  const urls = input.split('\n').map(u => u.trim()).filter(Boolean);
  let ok = 0, fail = 0;
  for (const url of urls) {
    const r = await api('/api/admin/download-image', { method: 'POST', body: JSON.stringify({ url }) });
    if (r.ok && r.json.success) { socialMedia.push({ image: r.json.path, alt: '', link: '' }); ok++; }
    else fail++;
  }
  renderSocialMedia();
  alert(`Downloaded ${ok} image(s).${fail ? ` Failed: ${fail}.` : ''}`);
});

// ── SPONSORS ──────────────────────────────────────────────────────────────────
function renderSponsors() {
  const c = document.getElementById('sponsors-list');
  if (!sponsors.length) {
    c.innerHTML = '<p style="color:var(--text-muted);font-size:.9rem">No sponsors yet.</p>';
    return;
  }
  c.innerHTML = sponsors.map((s, i) => `
    <div class="sponsor-item">
      <img src="${esc(s.image)}" alt="${esc(s.alt || 'Sponsor')}" />
      <input type="text" placeholder="Alt text" value="${esc(s.alt  || '')}" onchange="sponsors[${i}].alt  = this.value" />
      <input type="url"  placeholder="Link"      value="${esc(s.link || '')}" onchange="sponsors[${i}].link = this.value" />
      <button type="button" class="btn btn-danger" onclick="sponsors.splice(${i},1);renderSponsors()">✕</button>
    </div>`).join('');
}

document.getElementById('add-sponsor-btn').addEventListener('click', () => uploadFile('sponsor', path => {
  sponsors.push({ image: path, alt: '', link: '' });
  renderSponsors();
}));

// ── PENDING CHANGES ───────────────────────────────────────────────────────────
window.loadPendingChanges = async function() {
  const { ok, json } = await api('/api/admin/pending-changes');
  if (!ok) return;
  const pending = (json.changes || []).filter(c => c.status === 'pending');

  // Update badge
  const badge = document.getElementById('pending-badge');
  if (pending.length) {
    badge.textContent = pending.length;
    badge.hidden = false;
  } else {
    badge.hidden = true;
  }

  const list = document.getElementById('pending-list');
  if (!json.changes?.length) {
    list.innerHTML = '<p style="color:var(--text-muted)">No changes yet.</p>';
    return;
  }

  const canApprove = currentUser.role === 'super_admin' || currentUser.role === 'mosque_admin';

  list.innerHTML = json.changes.map(c => {
    const statusColor = { pending: '#f59e0b', approved: '#22c55e', rejected: '#ef4444' }[c.status] || '#64748b';
    return `
    <div class="change-card">
      <div class="change-header">
        <strong>${esc(c.mosque_name)}</strong>
        <span class="change-status" style="color:${statusColor}">${c.status.toUpperCase()}</span>
      </div>
      <p class="change-meta">
        Submitted by <strong>${esc(c.submitter_name)}</strong> on ${new Date(c.created_at).toLocaleString()}
        ${c.reviewer_name ? `<br>Reviewed by <strong>${esc(c.reviewer_name)}</strong> on ${new Date(c.reviewed_at).toLocaleString()}` : ''}
        ${c.review_note   ? `<br><em>Note: ${esc(c.review_note)}</em>` : ''}
      </p>
      <details style="margin-top:.5rem;">
        <summary style="cursor:pointer;font-size:.85rem;color:var(--text-muted)">View change details</summary>
        <pre style="font-size:.75rem;overflow:auto;background:#f8fafc;padding:.5rem;border-radius:4px;margin-top:.5rem">${esc(JSON.stringify(c.changes, null, 2))}</pre>
      </details>
      ${canApprove && c.status === 'pending' ? `
        <div class="change-actions">
          <button class="btn btn-primary" onclick="reviewChange(${c.id},'approve')">✅ Approve</button>
          <button class="btn btn-danger"  onclick="reviewChange(${c.id},'reject')">❌ Reject</button>
        </div>` : ''}
    </div>`;
  }).join('');
};

window.reviewChange = async function(id, action) {
  let note = '';
  if (action === 'reject') {
    note = prompt('Optional: Enter a reason for rejection:') || '';
  }
  const { ok, json } = await api(
    `/api/admin/pending-changes/${id}/${action}`,
    { method: 'POST', body: JSON.stringify({ note }) }
  );
  if (ok && json.success) {
    loadPendingChanges();
    loadMosques();
  } else {
    alert('Error: ' + (json.error || 'Unknown'));
  }
};

// ── USERS ─────────────────────────────────────────────────────────────────────
async function loadUsers() {
  const { ok, json } = await api('/api/admin/users');
  if (!ok) { document.getElementById('user-list').innerHTML = '<p>Error loading users.</p>'; return; }
  const list = document.getElementById('user-list');
  if (!json.users?.length) {
    list.innerHTML = '<p style="color:var(--text-muted)">No users yet.</p>';
    return;
  }
  list.innerHTML = json.users.map(u => `
    <div class="mosque-card ${!u.is_active ? 'is-inactive' : ''}">
      <div class="mosque-card-info">
        <h3>${esc(u.username)} ${!u.is_active ? '<span class="inactive-badge">Inactive</span>' : ''}</h3>
        <p>${esc(u.email)} · <strong>${esc(u.role.replace('_',' '))}</strong></p>
        ${u.mosques?.length ? `<p style="font-size:.8rem;color:var(--text-muted)">Mosques: ${u.mosques.map(m => m.mosque_slug).join(', ')}</p>` : ''}
      </div>
      <div class="mosque-card-actions">
        <button class="btn btn-primary" onclick="editUser(${u.id})">Edit</button>
      </div>
    </div>`).join('');
}

document.getElementById('add-user-btn').addEventListener('click', () => openUserForm(null));

document.getElementById('cancel-user-btn').addEventListener('click', () => {
  document.getElementById('user-edit-section').hidden = true;
});

window.editUser = async function(id) {
  const { ok, json } = await api(`/api/admin/users/${id}`);
  if (!ok) { alert('Failed to load user'); return; }
  openUserForm(json.user);
};

function openUserForm(user) {
  const isNew = !user;
  document.getElementById('user-form-title').textContent = isNew ? 'Add User' : 'Edit User';
  document.getElementById('user-edit-id').value          = user?.id || '';
  document.getElementById('user-username').value         = user?.username || '';
  document.getElementById('user-username').disabled      = !isNew;
  document.getElementById('user-email').value            = user?.email    || '';
  document.getElementById('user-role').value             = user?.role     || 'maintainer';
  document.getElementById('user-password').value         = '';
  document.getElementById('pw-hint').textContent         = isNew ? '(min 8 chars, required)' : '(leave blank to keep current)';

  const toggleBtn = document.getElementById('toggle-active-btn');
  toggleBtn.hidden = isNew;
  if (!isNew) {
    toggleBtn.textContent = user.is_active ? 'Deactivate User' : 'Reactivate User';
  }

  // Mosque assignment
  const mosqueSelect = document.getElementById('user-mosque');
  mosqueSelect.innerHTML = '<option value="">— none —</option>' +
    allMosques.map(m => `<option value="${m.slug}" ${user?.mosques?.find(um => um.mosque_slug === m.slug) ? 'selected' : ''}>${esc(m.name)}</option>`).join('');

  const userMosque = user?.mosques?.[0];
  document.getElementById('user-can-approve').checked = !!userMosque?.can_approve;

  // super_admin only shows role selector for super_admins themselves
  document.getElementById('user-role').disabled = (currentUser.role !== 'super_admin');
  document.getElementById('user-edit-section').hidden = false;
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

document.getElementById('user-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const id       = document.getElementById('user-edit-id').value;
  const isNew    = !id;
  const password = document.getElementById('user-password').value;
  const mosqueSlug   = document.getElementById('user-mosque').value;
  const canApprove   = document.getElementById('user-can-approve').checked;

  if (isNew && password.length < 8) {
    alert('Password must be at least 8 characters for new users.');
    return;
  }

  const payload = {
    username: document.getElementById('user-username').value,
    email:    document.getElementById('user-email').value,
    role:     document.getElementById('user-role').value,
  };
  if (password) payload.password = password;

  const { ok, json } = isNew
    ? await api('/api/admin/users',      { method: 'POST', body: JSON.stringify(payload) })
    : await api(`/api/admin/users/${id}`, { method: 'PUT',  body: JSON.stringify(payload) });

  if (!ok) { alert('Error: ' + (json.error || 'Unknown')); return; }

  const userId = json.user.id;

  // Assign / update mosque
  if (mosqueSlug) {
    await api(`/api/admin/users/${userId}/assign`, {
      method: 'POST',
      body: JSON.stringify({ mosqueSlug, canApprove }),
    });
  }

  alert(isNew
    ? 'User created! A welcome email with a temporary password has been sent.'
    : 'User updated!');
  document.getElementById('user-edit-section').hidden = true;
  loadUsers();
});

document.getElementById('toggle-active-btn').addEventListener('click', async () => {
  const id   = document.getElementById('user-edit-id').value;
  const user = await api(`/api/admin/users/${id}`).then(r => r.json.user);
  await api(`/api/admin/users/${id}`, { method: 'PUT', body: JSON.stringify({ is_active: !user.is_active }) });
  document.getElementById('user-edit-section').hidden = true;
  loadUsers();
});

// ── SETTINGS ──────────────────────────────────────────────────────────────────
async function loadSettings() {
  const { ok, json } = await api('/api/admin/settings');
  if (!ok) return;
  const s = json.settings || {};
  document.getElementById('smtp-host').value       = s.smtp_host       || '';
  document.getElementById('smtp-port').value       = s.smtp_port       || '587';
  document.getElementById('smtp-secure').value     = s.smtp_secure     || 'tls';
  document.getElementById('smtp-username').value   = s.smtp_username   || '';
  document.getElementById('smtp-password').value   = '';  // never pre-fill password
  document.getElementById('smtp-from-email').value = s.smtp_from_email || '';
  document.getElementById('smtp-from-name').value  = s.smtp_from_name  || '';
}

// ── MOSQUE ADHAN OFFSETS (per prayer) ────────────────────────────────────────
function renderMosqueAdhanOffsets() {
  const container = document.getElementById('mosque-adhan-offsets');
  if (!container) return;
  container.innerHTML = PRAYER_KEYS_ADMIN.map((key, ki) => {
    const name    = PRAYER_NAMES_ADMIN[ki];
    const offsets = mosqueAdhanOffsets[key] || [];
    const chips   = offsets.map((mins, i) => `
      <span style="display:inline-flex;align-items:center;gap:.25rem;background:var(--green-dim,rgba(34,197,94,.15));
        border:1px solid var(--green,#22c55e);border-radius:20px;padding:.2rem .6rem;font-size:.8rem;">
        ${mins === 0 ? 'At prayer time' : `${mins} min before`}
        <button type="button" style="background:none;border:none;cursor:pointer;color:var(--error,#ef4444);font-size:.9rem;padding:0;line-height:1;"
          onclick="removeMosqueOffset('${key}',${i})">&#x2715;</button>
      </span>`).join(' ');
    return `
      <div style="display:flex;align-items:center;flex-wrap:wrap;gap:.5rem;padding:.5rem 0;border-bottom:1px solid var(--card-border,#1e293b);">
        <span style="width:72px;font-weight:600;font-size:.875rem;flex-shrink:0;">${name}</span>
        <div style="display:flex;flex-wrap:wrap;gap:.35rem;flex:1;min-width:0;">${chips || '<span style="color:var(--text-muted);font-size:.8rem">No alerts</span>'}</div>
        <div style="display:flex;gap:.35rem;align-items:center;flex-shrink:0;">
          <input type="number" class="adhan-min-input" data-key="${key}" min="0" max="1440" placeholder="mins"
            style="width:70px;padding:.3rem .5rem;border:1px solid var(--card-border,#334155);border-radius:6px;background:var(--card-bg,#111827);color:inherit;font-size:.85rem;"
            onkeydown="if(event.key==='Enter'){event.preventDefault();addMosqueOffset('${key}');}" />
          <button type="button" class="btn btn-secondary" style="padding:.3rem .6rem;font-size:.8rem;"
            onclick="addMosqueOffset('${key}')">+ Add</button>
        </div>
      </div>`;
  }).join('');
}

window.addMosqueOffset = function(key) {
  const input = document.querySelector(`.adhan-min-input[data-key="${key}"]`);
  const val = parseInt(input.value, 10);
  if (isNaN(val) || val < 0 || val > 1440) { alert('Enter a number of minutes between 0 and 1440.'); return; }
  if (!mosqueAdhanOffsets[key]) mosqueAdhanOffsets[key] = [];
  if (mosqueAdhanOffsets[key].includes(val)) { alert('That offset is already added for this prayer.'); return; }
  mosqueAdhanOffsets[key].push(val);
  mosqueAdhanOffsets[key].sort((a, b) => b - a);
  input.value = '';
  renderMosqueAdhanOffsets();
};

window.removeMosqueOffset = function(key, idx) {
  if (mosqueAdhanOffsets[key]) mosqueAdhanOffsets[key].splice(idx, 1);
  renderMosqueAdhanOffsets();
};

document.getElementById('smtp-form')?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const payload = {
    smtp_host:       document.getElementById('smtp-host').value,
    smtp_port:       document.getElementById('smtp-port').value,
    smtp_secure:     document.getElementById('smtp-secure').value,
    smtp_username:   document.getElementById('smtp-username').value,
    smtp_password:   document.getElementById('smtp-password').value,
    smtp_from_email: document.getElementById('smtp-from-email').value,
    smtp_from_name:  document.getElementById('smtp-from-name').value,
    test_email:      document.getElementById('smtp-test-email').value,
  };
  const { ok, json } = await api('/api/admin/settings', { method: 'PUT', body: JSON.stringify(payload) });
  if (ok && json.success) {
    alert(json.test ? json.test : 'Settings saved!');
    document.getElementById('smtp-password').value   = '';
    document.getElementById('smtp-test-email').value = '';
  } else {
    alert('Error: ' + (json.error || 'Unknown'));
  }
});

document.getElementById('password-form')?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const np = document.getElementById('new-password').value;
  const cp = document.getElementById('confirm-password').value;
  if (np !== cp)            { alert('Passwords do not match'); return; }
  if (np.length < 8)        { alert('Password must be at least 8 characters'); return; }

  const { ok, json } = await api(`/api/admin/users/${currentUser.id}`, {
    method: 'PUT', body: JSON.stringify({ password: np }),
  });
  if (ok && json.success) {
    alert('Password changed successfully!');
    document.getElementById('password-form').reset();
  } else {
    alert('Error: ' + (json.error || 'Unknown'));
  }
});

// ── Helper: file upload ───────────────────────────────────────────────────────
function uploadFile(field, callback) {
  const input = document.createElement('input');
  input.type   = 'file';
  input.accept = 'image/*';
  input.style.display = 'none';
  document.body.appendChild(input);
  input.onchange = async (e) => {
    document.body.removeChild(input);
    const file = e.target.files[0];
    if (!file) return;
    const fd = new FormData();
    fd.append(field, file);
    try {
      const res  = await fetch(`/api/admin/upload/${field}`, { method: 'POST', body: fd });
      const json = await res.json();
      if (res.ok && json.success) callback(json.path);
      else alert('Upload failed: ' + (json.error || 'Unknown'));
    } catch (err) {
      alert('Upload error: ' + err.message);
    }
  };
  input.click();
}

// ── Helper: populate mosque dropdowns ─────────────────────────────────────────
function populateMosqueDropdowns() {
  const sel = document.getElementById('user-mosque');
  if (!sel) return;
  sel.innerHTML = '<option value="">— none —</option>' +
    allMosques.map(m => `<option value="${m.slug}">${esc(m.name)}</option>`).join('');
}

// ── Utility: escape HTML ──────────────────────────────────────────────────────
function esc(str) {
  return String(str ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
