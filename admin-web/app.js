// Main Application
class AdminApp {
    constructor() {
        this.currentPage = 1;
        this.usersPerPage = 20;
        this.mosques = [];
        this.currentUserId = null;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.checkAuth();
    }

    setupEventListeners() {
        // Navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => this.handleNavigation(e));
        });

        // Users section
        document.getElementById('create-user-btn').addEventListener('click', () => this.openUserModal());
        document.getElementById('create-mosque-btn')?.addEventListener('click', () => this.createMosquePrompt());
        document.getElementById('user-form').addEventListener('submit', (e) => this.handleUserFormSubmit(e));
        document.getElementById('add-assignment-btn').addEventListener('click', () => this.addAssignmentRow());

        // Pagination
        document.getElementById('prev-page').addEventListener('click', () => this.previousPage());
        document.getElementById('next-page').addEventListener('click', () => this.nextPage());

        // Modal
        document.querySelector('.modal-close')?.addEventListener('click', () => this.closeUserModal());

        // Login
        document.getElementById('login-form').addEventListener('submit', (e) => this.handleLogin(e));

        // Logout
        document.getElementById('logout-btn').addEventListener('click', () => this.logout());

        // Confirmation
        document.getElementById('confirm-yes').addEventListener('click', () => this.confirmDelete());
        document.getElementById('confirm-no').addEventListener('click', () => this.closeConfirmModal());

        // Mosque modal
        document.querySelectorAll('.mosque-modal-close, .mosque-modal-close-btn').forEach(btn => {
            btn.addEventListener('click', () => this.closeMosqueModal());
        });
        document.getElementById('mosque-form')?.addEventListener('submit', (e) => this.handleMosqueFormSubmit(e));
    }

    checkAuth() {
        if (!auth.isAuthenticated()) {
            this.showLoginModal();
        } else {
            this.hideLoginModal();
            document.getElementById('logged-user').textContent = auth.user?.username || 'Admin';
            this.loadUsers();
            this.loadMosques();
        }
    }

    async handleLogin(e) {
        e.preventDefault();
        const username = document.getElementById('login-username').value;
        const password = document.getElementById('login-password').value;

        try {
            const errorEl = document.getElementById('login-error');
            errorEl.textContent = '';

            await auth.login(username, password);
            this.hideLoginModal();
            document.getElementById('logged-user').textContent = auth.user.username;
            this.loadUsers();
            this.loadMosques();
            
            // Reset form
            document.getElementById('login-form').reset();
        } catch (error) {
            document.getElementById('login-error').textContent = error.message;
        }
    }

    async logout() {
        auth.logout();
        this.showLoginModal();
        document.getElementById('users-tbody').innerHTML = '';
    }

    showLoginModal() {
        document.getElementById('login-modal').classList.add('active');
        document.querySelector('.admin-container').style.display = 'none';
    }

    hideLoginModal() {
        document.getElementById('login-modal').classList.remove('active');
        document.querySelector('.admin-container').style.display = 'flex';
    }

    async handleNavigation(e) {
        e.preventDefault();
        const section = e.target.dataset.section;

        // Update nav links
        document.querySelectorAll('.nav-link').forEach(link => link.classList.remove('active'));
        e.target.classList.add('active');

        // Update sections
        document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
        document.getElementById(`${section}-section`).classList.add('active');

        if (section === 'mosques') {
            await this.loadMosques();
        }
        if (section === 'pending') {
            await this.loadPendingChanges();
        }
    }

    async loadUsers() {
        try {
            const tbody = document.getElementById('users-tbody');
            tbody.innerHTML = '<tr class="loading"><td colspan="7">Loading users...</td></tr>';

            const response = await api.getUsers(this.currentPage, this.usersPerPage);
            const users = response.data || [];
            const totalPages = response.total_pages || 1;

            if (users.length === 0) {
                tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; color: #7f8c8d;">No users found</td></tr>';
                return;
            }

            tbody.innerHTML = users.map(user => `
                <tr>
                    <td>${user.id}</td>
                    <td>${user.username}</td>
                    <td>${user.email}</td>
                    <td><span class="badge badge-info">${this.formatRole(user.role)}</span></td>
                    <td>
                        ${user.assignments?.length > 0 
                            ? user.assignments.map(a => a.mosque_name).join(', ') 
                            : '<em style="color: #7f8c8d;">None</em>'}
                    </td>
                    <td>
                        <span class="badge ${user.is_active ? 'badge-success' : 'badge-danger'}">
                            ${user.is_active ? 'Active' : 'Inactive'}
                        </span>
                    </td>
                    <td>
                        <div class="action-buttons">
                            <button class="btn btn-secondary btn-small" onclick="app.editUser(${user.id})">Edit</button>
                            <button class="btn btn-danger btn-small" onclick="app.deleteUserConfirm(${user.id}, '${user.username}')">Delete</button>
                        </div>
                    </td>
                </tr>
            `).join('');

            // Update pagination
            document.getElementById('page-info').textContent = `Page ${this.currentPage} of ${totalPages}`;
            document.getElementById('prev-page').disabled = this.currentPage <= 1;
            document.getElementById('next-page').disabled = this.currentPage >= totalPages;
        } catch (error) {
            document.getElementById('users-tbody').innerHTML = `
                <tr><td colspan="7" style="color: #e74c3c;">Error loading users: ${error.message}</td></tr>
            `;
        }
    }

    async loadMosques() {
        try {
            const response = await api.getMosques();
            this.mosques = response.data || [];
            this.updateAssignmentOptions();
            this.renderMosquesTable();
        } catch (error) {
            console.error('Error loading mosques:', error);
            const tbody = document.getElementById('mosques-tbody');
            if (tbody) {
                tbody.innerHTML = `<tr><td colspan="6" style="color: #e74c3c;">Error loading mosques: ${error.message}</td></tr>`;
            }
        }
    }

    renderMosquesTable() {
        const tbody = document.getElementById('mosques-tbody');
        if (!tbody) return;

        if (!this.mosques.length) {
            tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; color:#7f8c8d;">No mosques found</td></tr>';
            return;
        }

        tbody.innerHTML = this.mosques.map(m => `
            <tr>
                <td>${m.slug}</td>
                <td>${m.name}</td>
                <td>${m.phone || '<em style="color:#7f8c8d;">-</em>'}</td>
                <td>${m.website || '<em style="color:#7f8c8d;">-</em>'}</td>
                <td>${m.isDefault ? '<span class="badge badge-success">Default</span>' : '<span class="badge badge-info">No</span>'}</td>
                <td style="display:flex;gap:4px;flex-wrap:wrap;">
                    <button class="btn btn-secondary btn-small" onclick="app.openMosqueEditModal('${m.slug}')">Edit</button>
                    ${!m.isDefault && auth.user?.role === 'super_admin' ? `<button class="btn btn-secondary btn-small" onclick="app.setDefaultMosque('${m.slug}')">Set Default</button>` : ''}
                    ${auth.user?.role === 'super_admin' ? `<button class="btn btn-danger btn-small" onclick="app.deleteMosquePrompt('${m.slug}')">Delete</button>` : ''}
                </td>
            </tr>
        `).join('');
    }

    async setDefaultMosque(slug) {
        try {
            await api.setDefaultMosque(slug);
            await this.loadMosques();
            alert(`Default mosque updated to ${slug}`);
        } catch (error) {
            alert('Error setting default mosque: ' + error.message);
        }
    }

    async createMosquePrompt() {
        if (auth.user?.role !== 'super_admin') {
            alert('Only super_admin can create mosques.');
            return;
        }

        const slug = prompt('Mosque slug (lowercase, e.g. green-point):');
        if (!slug) return;
        const name = prompt('Mosque name:');
        if (!name) return;

        try {
            await api.createMosque({ slug, name });
            await this.loadMosques();
            alert('Mosque created successfully');
        } catch (error) {
            alert('Error creating mosque: ' + error.message);
        }
    }

    openMosqueEditModal(slug) {
        const mosque = this.mosques.find(m => m.slug === slug);
        if (!mosque) { alert('Mosque not found'); return; }

        document.getElementById('mosque-slug').value = mosque.slug;
        document.getElementById('mosque-name').value = mosque.name || '';
        document.getElementById('mosque-address').value = mosque.address || '';
        document.getElementById('mosque-phone').value = mosque.phone || '';
        document.getElementById('mosque-website').value = mosque.website || '';
        document.getElementById('mosque-fasting').checked = !!mosque.showFasting;
        document.getElementById('mosque-modal').classList.add('active');
    }

    closeMosqueModal() {
        document.getElementById('mosque-modal').classList.remove('active');
    }

    async handleMosqueFormSubmit(e) {
        e.preventDefault();
        const slug = document.getElementById('mosque-slug').value;
        const data = {
            name: document.getElementById('mosque-name').value,
            show_fasting: document.getElementById('mosque-fasting').checked ? 1 : 0,
        };
        const address = document.getElementById('mosque-address').value;
        const phone = document.getElementById('mosque-phone').value;
        const website = document.getElementById('mosque-website').value;
        if (address) data.address = address;
        if (phone) data.phone = phone;
        if (website) data.website = website;

        try {
            await api.updateMosque(slug, data);
            this.closeMosqueModal();
            await this.loadMosques();
        } catch (error) {
            alert('Error updating mosque: ' + error.message);
        }
    }

    async deleteMosquePrompt(slug) {
        if (!confirm(`Delete mosque "${slug}"? This cannot be undone.`)) return;
        try {
            await api.deleteMosque(slug);
            await this.loadMosques();
        } catch (error) {
            alert('Error deleting mosque: ' + error.message);
        }
    }

    async loadPendingChanges() {
        const tbody = document.getElementById('pending-tbody');
        if (!tbody) return;

        try {
            tbody.innerHTML = '<tr class="loading"><td colspan="6">Loading pending changes...</td></tr>';
            const response = await api.getPendingChanges(1, 50);
            const pending = response.data || [];

            if (!pending.length) {
                tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; color:#7f8c8d;">No pending changes</td></tr>';
                return;
            }

            tbody.innerHTML = pending.map(item => `
                <tr>
                    <td>${item.id}</td>
                    <td>${item.mosque_slug}</td>
                    <td>${item.submitter_name || item.submitted_by || '-'}</td>
                    <td><span class="badge badge-info">${item.status}</span></td>
                    <td>${item.created_at || '-'}</td>
                    <td>
                        ${item.status === 'pending' ? `
                            <button class="btn btn-success btn-small" onclick="app.approvePending(${item.id})">Approve</button>
                            <button class="btn btn-danger btn-small" onclick="app.rejectPending(${item.id})">Reject</button>
                        ` : '<em style="color:#7f8c8d;">Processed</em>'}
                    </td>
                </tr>
            `).join('');
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="6" style="color:#e74c3c;">Error loading pending changes: ${error.message}</td></tr>`;
        }
    }

    async approvePending(id) {
        try {
            await api.approvePendingChange(id);
            await this.loadPendingChanges();
        } catch (error) {
            alert('Error approving change: ' + error.message);
        }
    }

    async rejectPending(id) {
        const note = prompt('Optional rejection note:') || '';
        try {
            await api.rejectPendingChange(id, note);
            await this.loadPendingChanges();
        } catch (error) {
            alert('Error rejecting change: ' + error.message);
        }
    }

    updateAssignmentOptions() {
        // This will be called when updating the form
        const container = document.getElementById('assignments-container');
        if (container && this.mosques.length > 0) {
            container.dataset.mosques = 'loaded';
        }
    }

    openUserModal() {
        this.currentUserId = null;
        document.getElementById('modal-title').textContent = 'Create New User';
        document.getElementById('user-form').reset();
        document.getElementById('user-password').required = true;
        document.getElementById('assignments-container').innerHTML = '';
        this.renderAssignmentSelects();
        document.getElementById('user-modal').classList.add('active');
    }

    closeUserModal() {
        this.currentUserId = null;
        document.getElementById('user-modal').classList.remove('active');
    }

    async editUser(id) {
        try {
            const user = await api.getUser(id);
            this.currentUserId = id;

            document.getElementById('modal-title').textContent = 'Edit User';
            document.getElementById('user-username').value = user.username;
            document.getElementById('user-email').value = user.email;
            document.getElementById('user-password').value = '';
            document.getElementById('user-password').required = false;
            document.getElementById('user-role').value = user.role;
            document.getElementById('user-status').checked = user.is_active;

            // Load assignments
            document.getElementById('assignments-container').innerHTML = '';
            if (user.assignments && user.assignments.length > 0) {
                user.assignments.forEach(assignment => {
                    this.addAssignmentRow(assignment.mosque_slug, assignment.can_approve);
                });
            } else {
                this.addAssignmentRow();
            }

            document.getElementById('user-modal').classList.add('active');
        } catch (error) {
            alert('Error loading user: ' + error.message);
        }
    }

    renderAssignmentSelects() {
        const container = document.getElementById('assignments-container');
        container.innerHTML = '';
        this.addAssignmentRow();
    }

    addAssignmentRow(mosqueSlug = '', canApprove = false) {
        const container = document.getElementById('assignments-container');
        const row = document.createElement('div');
        row.className = 'assignment-item';

        const options = this.mosques
            .map(m => `<option value="${m.slug}" ${m.slug === mosqueSlug ? 'selected' : ''}>${m.name}</option>`)
            .join('');

        row.innerHTML = `
            <select class="mosque-select" required>
                <option value="">Select Mosque</option>
                ${options}
            </select>
            <label>
                <input type="checkbox" class="can-approve-check" ${canApprove ? 'checked' : ''}>
                Can Approve
            </label>
            <button type="button" class="btn btn-danger btn-small btn-remove" onclick="this.parentElement.remove()">Remove</button>
        `;

        container.appendChild(row);
    }

    async handleUserFormSubmit(e) {
        e.preventDefault();

        const formData = new FormData(e.target);
        const userData = {
            username: formData.get('username'),
            email: formData.get('email'),
            role: formData.get('role'),
            is_active: formData.get('is_active') === 'on'
        };

        // Add password only if provided
        const password = formData.get('password');
        if (password) {
            userData.password = password;
        }

        // Collect assignments
        const assignments = [];
        document.querySelectorAll('.assignment-item').forEach(item => {
            const mosqueSelect = item.querySelector('.mosque-select');
            const canApproveCheck = item.querySelector('.can-approve-check');

            if (mosqueSelect.value) {
                assignments.push({
                    mosque_slug: mosqueSelect.value,
                    can_approve: canApproveCheck.checked
                });
            }
        });

        if (assignments.length > 0) {
            userData.assignments = assignments;
        }

        try {
            if (this.currentUserId) {
                await api.updateUser(this.currentUserId, userData);
                alert('User updated successfully!');
            } else {
                await api.createUser(userData);
                alert('User created successfully!');
            }

            this.closeUserModal();
            this.loadUsers();
        } catch (error) {
            alert('Error saving user: ' + error.message);
        }
    }

    deleteUserConfirm(id, username) {
        this.deleteUserId = id;
        document.getElementById('confirm-message').textContent = 
            `Are you sure you want to delete user "${username}"? This action cannot be undone.`;
        document.getElementById('confirm-modal').classList.add('active');
    }

    async confirmDelete() {
        try {
            await api.deleteUser(this.deleteUserId);
            alert('User deleted successfully!');
            this.closeConfirmModal();
            this.loadUsers();
        } catch (error) {
            alert('Error deleting user: ' + error.message);
        }
    }

    closeConfirmModal() {
        document.getElementById('confirm-modal').classList.remove('active');
        this.deleteUserId = null;
    }

    nextPage() {
        this.currentPage++;
        this.loadUsers();
    }

    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadUsers();
        }
    }

    formatRole(role) {
        const roleMap = {
            'super_admin': 'Super Admin',
            'mosque_admin': 'Mosque Admin',
            'maintainer': 'Maintainer'
        };
        return roleMap[role] || role;
    }
}

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.app = new AdminApp();
});
