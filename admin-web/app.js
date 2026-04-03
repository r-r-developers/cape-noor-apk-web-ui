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

    handleNavigation(e) {
        e.preventDefault();
        const section = e.target.dataset.section;

        // Update nav links
        document.querySelectorAll('.nav-link').forEach(link => link.classList.remove('active'));
        e.target.classList.add('active');

        // Update sections
        document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
        document.getElementById(`${section}-section`).classList.add('active');
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
        } catch (error) {
            console.error('Error loading mosques:', error);
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
