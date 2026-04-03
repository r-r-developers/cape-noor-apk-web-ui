// API Module
class APIClient {
    async request(endpoint, options = {}) {
        const {
            method = 'GET',
            body = null,
            headers = {},
            retry = true
        } = options;

        const url = `${CONFIG.API_BASE_URL}${endpoint}`;
        const requestHeaders = {
            ...headers,
            ...auth.getAuthHeaders()
        };

        try {
            const response = await fetch(url, {
                method,
                headers: requestHeaders,
                body: body ? JSON.stringify(body) : null
            });

            // Handle 401 - token expired
            if (response.status === 401 && retry) {
                const refreshed = await auth.refreshAccessToken();
                if (refreshed) {
                    return this.request(endpoint, { ...options, retry: false });
                } else {
                    window.location.reload();
                    throw new Error('Session expired');
                }
            }

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.message || `API Error: ${response.status}`);
            }

            return data;
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    }

    // Users endpoints
    async getUsers(page = 1, limit = 20, role = null) {
        let endpoint = `/v2/admin/users?page=${page}&limit=${limit}`;
        if (role) {
            endpoint += `&role=${role}`;
        }
        return this.request(endpoint);
    }

    async getUser(id) {
        return this.request(`/v2/admin/users/${id}`);
    }

    async createUser(userData) {
        return this.request('/v2/admin/users', {
            method: 'POST',
            body: userData
        });
    }

    async updateUser(id, userData) {
        return this.request(`/v2/admin/users/${id}`, {
            method: 'PUT',
            body: userData
        });
    }

    async deleteUser(id) {
        return this.request(`/v2/admin/users/${id}`, {
            method: 'DELETE'
        });
    }

    // Mosques endpoints
    async getMosques() {
        return this.request('/v2/admin/mosques');
    }

    // Pending changes endpoints
    async getPendingChanges(page = 1, limit = 20) {
        return this.request(`/v2/admin/pending-changes?page=${page}&limit=${limit}`);
    }

    async approvePendingChange(id) {
        return this.request(`/v2/admin/pending-changes/${id}/approve`, {
            method: 'POST'
        });
    }

    async rejectPendingChange(id, reason = '') {
        return this.request(`/v2/admin/pending-changes/${id}/reject`, {
            method: 'POST',
            body: { reason }
        });
    }
}

// Global instance
const api = new APIClient();
