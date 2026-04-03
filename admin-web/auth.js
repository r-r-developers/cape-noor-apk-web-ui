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
        try {
            const response = await fetch(`${CONFIG.API_BASE_URL}/v2/admin/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ username, password })
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.message || 'Login failed');
            }

            this.setTokens(data.accessToken, data.refreshToken);
            this.setUser(data.user);
            
            return { success: true, user: data.user };
        } catch (error) {
            console.error('Login error:', error);
            throw error;
        }
    }

    async refreshAccessToken() {
        try {
            const response = await fetch(`${CONFIG.API_BASE_URL}/v2/admin/auth/refresh`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ refreshToken: this.refreshToken })
            });

            const data = await response.json();

            if (!response.ok) {
                this.logout();
                throw new Error('Token refresh failed');
            }

            this.setTokens(data.accessToken, data.refreshToken);
            return true;
        } catch (error) {
            console.error('Token refresh error:', error);
            return false;
        }
    }
}

// Global instance
const auth = new AuthManager();
