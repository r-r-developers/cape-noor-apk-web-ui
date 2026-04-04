// Configuration
const CONFIG = {
    API_BASE_URL: localStorage.getItem('api_base_url') || window.location.origin,
    ACCESS_TOKEN_KEY: 'admin_access_token',
    REFRESH_TOKEN_KEY: 'admin_refresh_token',
    USER_KEY: 'admin_user',
    TOKEN_EXPIRY_KEY: 'admin_token_expiry'
};

function trimTrailingSlash(value) {
    return (value || '').replace(/\/+$/, '');
}

function getApiBaseCandidates() {
    const base = trimTrailingSlash(CONFIG.API_BASE_URL);
    const candidates = [base];

    if (!base.endsWith('/api')) {
        candidates.push(`${base}/api`);
    } else {
        candidates.push(base.slice(0, -4));
    }

    return [...new Set(candidates)];
}

window.getApiBaseCandidates = getApiBaseCandidates;
window.getResolvedApiBase = () => localStorage.getItem('resolved_api_base') || '';
window.setResolvedApiBase = (base) => {
    if (base) {
        localStorage.setItem('resolved_api_base', trimTrailingSlash(base));
    }
};

// Allow setting API base URL
window.setApiBaseUrl = function(url) {
    CONFIG.API_BASE_URL = trimTrailingSlash(url);
    localStorage.setItem('api_base_url', CONFIG.API_BASE_URL);
    localStorage.removeItem('resolved_api_base');
    console.log('API Base URL set to:', url);
};

console.log('Using API:', CONFIG.API_BASE_URL);
