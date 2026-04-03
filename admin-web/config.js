// Configuration
const CONFIG = {
    API_BASE_URL: localStorage.getItem('api_base_url') || 'http://localhost:8080/api',
    ACCESS_TOKEN_KEY: 'admin_access_token',
    REFRESH_TOKEN_KEY: 'admin_refresh_token',
    USER_KEY: 'admin_user',
    TOKEN_EXPIRY_KEY: 'admin_token_expiry'
};

// Allow setting API base URL
window.setApiBaseUrl = function(url) {
    CONFIG.API_BASE_URL = url;
    localStorage.setItem('api_base_url', url);
    console.log('API Base URL set to:', url);
};

console.log('Using API:', CONFIG.API_BASE_URL);
