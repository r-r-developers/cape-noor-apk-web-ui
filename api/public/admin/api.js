// API Module
class APIClient {
    constructor() {
        this.resolvedBase = window.getResolvedApiBase?.() || '';
    }

    getBaseCandidates() {
        const candidates = window.getApiBaseCandidates ? window.getApiBaseCandidates() : [CONFIG.API_BASE_URL];
        if (this.resolvedBase && candidates.includes(this.resolvedBase)) {
            return [this.resolvedBase, ...candidates.filter(c => c !== this.resolvedBase)];
        }
        return candidates;
    }

    normalizeUser(raw) {
        return {
            id: raw.id,
            username: raw.username,
            email: raw.email,
            role: raw.role,
            is_active: !!raw.isActive,
            assignments: (raw.assignments || []).map(a => ({
                mosque_slug: a.mosqueSlug,
                mosque_name: a.mosqueName,
                can_approve: !!a.canApprove
            }))
        };
    }

    async request(endpoint, options = {}) {
        const {
            method = 'GET',
            body = null,
            headers = {},
            retry = true
        } = options;
        const requestHeaders = {
            ...headers,
            ...auth.getAuthHeaders()
        };

        let lastError = null;
        const bases = this.getBaseCandidates();
        const alreadyResolved = !!this.resolvedBase;

        for (const base of bases) {
            const url = `${base}${endpoint}`;
            let response;
            try {
                response = await fetch(url, {
                    method,
                    headers: requestHeaders,
                    body: body ? JSON.stringify(body) : null
                });
            } catch (networkError) {
                // Network-level failure (CORS, unreachable) – try next base candidate
                lastError = networkError;
                continue;
            }

            // Handle 401 – token expired
            if (response.status === 401 && retry) {
                const refreshed = await auth.refreshAccessToken();
                if (refreshed) {
                    return this.request(endpoint, { ...options, retry: false });
                }
                window.location.reload();
                throw new Error('Session expired');
            }

            const data = await response.json();

            if (!response.ok) {
                // Only fall back to next base on 404 when the base URL is not yet resolved.
                // Once the base is known a 404 means the route is genuinely missing on the server.
                if (response.status === 404 && !alreadyResolved) {
                    lastError = new Error('API route not found for current base path');
                    continue;
                }
                throw new Error(data.error || `API Error: ${response.status}`);
            }

            this.resolvedBase = base;
            window.setResolvedApiBase?.(base);
            return data;
        }

        console.error('API Error:', lastError);
        throw lastError || new Error('API request failed');
    }

    // Users endpoints
    async getUsers(page = 1, limit = 20, role = null) {
        let endpoint = `/v2/admin/users?page=${page}&limit=${limit}`;
        if (role) {
            endpoint += `&role=${role}`;
        }
        const res = await this.request(endpoint);
        const users = (res.users || []).map(u => this.normalizeUser(u));
        return { data: users, total_pages: 1 };
    }

    async getUser(id) {
        const res = await this.request(`/v2/admin/users/${id}`);
        return this.normalizeUser(res.user);
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
        const res = await this.request('/v2/admin/mosques');
        return { data: res.mosques || [] };
    }

    async updateMosque(slug, data) {
        return this.request(`/v2/admin/mosques/${slug}`, {
            method: 'PUT',
            body: data
        });
    }

    async deleteMosque(slug) {
        return this.request(`/v2/admin/mosques/${slug}`, {
            method: 'DELETE'
        });
    }

    async createMosque(mosqueData) {
        return this.request('/v2/admin/mosques', {
            method: 'POST',
            body: mosqueData
        });
    }

    async setDefaultMosque(slug) {
        return this.request(`/v2/admin/mosques/${slug}/set-default`, {
            method: 'POST'
        });
    }

    // Pending changes endpoints
    async getPendingChanges(page = 1, limit = 20) {
        const res = await this.request(`/v2/admin/pending-changes?page=${page}&limit=${limit}`);
        return { data: res.pending || [] };
    }

    async approvePendingChange(id) {
        return this.request(`/v2/admin/pending-changes/${id}/approve`, {
            method: 'POST'
        });
    }

    async rejectPendingChange(id, reason = '') {
        return this.request(`/v2/admin/pending-changes/${id}/reject`, {
            method: 'POST',
            body: { note: reason }
        });
    }
}

// Global instance
const api = new APIClient();
