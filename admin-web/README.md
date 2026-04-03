# Cape Noor Admin Dashboard

A modern web-based admin interface for managing Cape Noor mosque system users and configurations.

## Features

- **User Management**: Create, edit, delete admin users with role-based access control
- **Mosque Assignments**: Assign mosques to admins with granular approval permissions
- **Role Management**: Support for Super Admin, Mosque Admin, and Maintainer roles
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **JWT Authentication**: Secure token-based authentication with automatic refresh
- **Real-time Updates**: Instant user list updates after changes

## Requirements

- Web server (Apache, Nginx, or local development server)
- Modern web browser (Chrome, Firefox, Safari, Edge)
- Cape Noor API running with the new admin endpoints

## Installation

### Option 1: Standalone Folder (Recommended)

1. Copy the entire `admin-web/` folder to your web server's public directory
2. Update the API base URL in `config.js` or set it via:
   ```javascript
   window.setApiBaseUrl('https://your-api-domain.com/api');
   ```
3. Open `index.html` in your browser

### Option 2: With Docker

Create a simple Dockerfile in the admin-web directory:

```dockerfile
FROM nginx:alpine
COPY ./ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

Then run:
```bash
docker build -t cape-noor-admin .
docker run -p 8080:80 cape-noor-admin
```

### Option 3: PHP Development Server

```bash
cd admin-web
php -S localhost:8000
# Then open http://localhost:8000 in your browser
```

## Configuration

### API Base URL

By default, the dashboard tries to connect to `http://localhost:8080/api`. To change this:

1. **Permanent**: Edit `config.js` and update `API_BASE_URL`
2. **Temporary (Runtime)**: In browser console:
   ```javascript
   window.setApiBaseUrl('https://your-api.com/api');
   ```

### CORS Configuration

Make sure your API server has CORS headers configured to accept requests from the admin dashboard:

```php
// In your API's CORS middleware
header('Access-Control-Allow-Origin: *'); // or specific domain
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
```

## Usage

### Logging In

1. Open the dashboard
2. Login modal will appear automatically if not authenticated
3. Enter your super admin credentials
4. Click "Login"

### Managing Users

#### Create User
1. Click "Create User" button
2. Fill in username and email
3. Set a secure password
4. Choose role (Super Admin, Mosque Admin, Maintainer)
5. Select mosques to assign
6. Check "Can Approve" for mosques where user can approve pending changes
7. Click "Save User"

#### Edit User
1. Find user in the list
2. Click "Edit" button
3. Update details as needed
4. Modify assigned mosques and permissions
5. Click "Save User"

#### Delete User
1. Find user in the list
2. Click "Delete" button
3. Confirm deletion in the popup

### Understanding Roles

- **Super Admin**: Full system access, can manage all users and mosques
- **Mosque Admin**: Can manage specific assigned mosques
- **Maintainer**: Can view assigned mosques and submit changes

### Approval Permissions

When assigning a mosque to a user, you can grant them the "Can Approve" permission:
- Checked: User can approve pending changes for that mosque
- Unchecked: User cannot approve changes but can submit them

## File Structure

```
admin-web/
├── index.html      # Main HTML template
├── styles.css      # Responsive styling
├── config.js       # Configuration (API URL, storage keys)
├── auth.js         # Authentication management
├── api.js          # API client for backend communication
├── app.js          # Main application logic
└── README.md       # This file
```

## API Endpoints Used

### Authentication
- `POST /v2/admin/auth/login` - User login
- `POST /v2/admin/auth/refresh` - Refresh access token

### User Management
- `GET /v2/admin/users` - List all users (paginated)
- `GET /v2/admin/users/{id}` - Get user details
- `POST /v2/admin/users` - Create new user
- `PUT /v2/admin/users/{id}` - Update user
- `DELETE /v2/admin/users/{id}` - Delete user

### Mosques
- `GET /v2/admin/mosques` - List all mosques

## Troubleshooting

### "Connection refused" error
- Verify the API base URL is correct
- Check if the API server is running
- Ensure CORS is properly configured in the API

### 401 Unauthorized errors
- Your session has expired
- Log out and log back in
- Check if the API is still running

### Blank page after login
- Check browser console for JavaScript errors
- Verify API endpoints are correct
- Try clearing browser cache and localStorage

### localStorage issues
- The dashboard stores session tokens in browser localStorage
- Clearing browser data will log you out
- Different tabs share the same localStorage

## Security Considerations

1. **Always use HTTPS** in production
2. **Don't share your login credentials** - each admin should have their own account
3. **Regular password changes** - encourage strong, unique passwords
4. **Review user assignments** - audit who has access to which mosques
5. **Use role appropriately** - don't give everyone super admin access

## Development

### Adding Features

To add new features:

1. Add API methods to `APIClient` class in `api.js`
2. Add UI elements to `index.html`
3. Add styling to `styles.css`
4. Add functionality to `AdminApp` class in `app.js`

### Testing

Open browser console (F12) and use these commands to test:

```javascript
// Test API connection
api.getMosques().then(r => console.log(r));

// Check auth status
console.log(auth.user);

// Change API URL
window.setApiBaseUrl('https://new-url.com/api');
```

## Browser Support

- Chrome/Chromium 90+
- Firefox 88+
- Safari 14+
- Edge 90+

Does NOT support Internet Explorer.

## License

Proprietary - Cape Noor Project

## Support

For issues or questions, contact the development team or create an issue in the project repository.
