// Authentication Module
class AuthManager {
    constructor() {
        this.accessToken = localStorage.getItem(CONFIG.ACCESS_TOKEN_KEY);
        this.refreshToken = localStorage.getItem(CONFIG.REFRESH_TOKEN_KEY);
        this.user = JSON.parse(localStorage.getItem(CONFIG.USER_KEY) || 'null');
    }

    setTokens(accessToken, refreshToken) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        localStorage.setItem(CONFIG.ACCESS_TOKEN_KEY, accessToken);
        localStorage.setItem(CONFIG.REFRESH_TOKEN_KEY, refreshToken);
    }

    setUser(user) {
        this.user = user;
        localStorage.setItem(CONFIG.USER_KEY, JSON.stringify(user));
    }

    isAuthenticated() {
        return !!this.accessToken;
    }

    getAuthHeaders() {
        return {
            'Authorization': `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json'
        };
    }

    logout() {
        this.accessToken = null;
        this.refreshToken = null;
        this.user = null;
        localStorage.removeItem(CONFIG.ACCESS_TOKEN_KEY);
        localStorage.removeItem(CONFIG.REFRESH_TOKEN_KEY);
        localStorage.removeItem(CONFIG.USER_KEY);
    }

    async login(username, password) {
        let lastError = null;

        for (const base of window.getApiBaseCandidates()) {
            try {
                const response = await fetch(`${base}/v2/auth/admin/login`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ username, password })
                });

                const data = await response.json();

                if (!response.ok) {
                    if (response.status === 404) {
                        lastError = new Error('API login route not found for current base path');
                        continue;
                    }
                    throw new Error(data.error || 'Login failed');
                }

                window.setResolvedApiBase?.(base);
                this.setTokens(data.tokens.access_token, data.tokens.refresh_token);
                this.setUser(data.user);

                return { success: true, user: data.user };
            } catch (error) {
                lastError = error;
            }
        }

        console.error('Login error:', lastError);
        throw lastError || new Error('Login failed');
    }

    async refreshAccessToken() {
        let lastError = null;
        const bases = [window.getResolvedApiBase?.(), ...window.getApiBaseCandidates()].filter(Boolean);

        for (const base of [...new Set(bases)]) {
            try {
                const response = await fetch(`${base}/v2/auth/refresh`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ refresh_token: this.refreshToken })
                });

                const data = await response.json();

                if (!response.ok) {
                    if (response.status === 404) {
                        lastError = new Error('API refresh route not found for current base path');
                        continue;
                    }
                    this.logout();
                    throw new Error('Token refresh failed');
                }

                window.setResolvedApiBase?.(base);
                this.setTokens(data.tokens.access_token, data.tokens.refresh_token);
                return true;
            } catch (error) {
                lastError = error;
            }
        }

        console.error('Token refresh error:', lastError);
        return false;
    }
}

// Global instance
const auth = new AuthManager();
