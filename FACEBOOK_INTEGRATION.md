# Facebook Integration Guide

This guide explains how to integrate Facebook group feeds with your Iron Bulwark blog.

## Overview

The theme includes built-in support for displaying Facebook group posts on your blog. This creates a seamless connection between your Facebook community and your blog audience.

## Prerequisites

1. A Facebook Developer account
2. A Facebook App with appropriate permissions
3. Access to the Iron County Facebook group (ID: 1465849137537076)

## Step 1: Create a Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click "Create App" → "Consumer" → "Yourself or your own business"
3. Enter app details:
   - **App name**: "Iron Bulwark Blog"
   - **App contact email**: Your email
   - **Business account**: Select or create if needed

## Step 2: Configure App Permissions

1. In your app dashboard, go to "App Settings" → "Basic"
2. Note down your **App ID** and **App Secret**

3. Go to "Products" → "Facebook Login" → "Settings"
4. Add your domain to "Valid OAuth Redirect URIs":
   - `https://your-domain.com`
   - `https://your-domain.com/ghost`

## Step 3: Set up Facebook Login for Ghost

1. In your Facebook app, go to "Products" → "Facebook Login" → "Settings"
2. Configure OAuth settings:
   - **Valid OAuth Redirect URIs**: Add your Ghost admin URL
   - **Login with Facebook**: Enable

## Step 4: Configure Group Access

For accessing Facebook group content, you need:

1. **Group Admin Access**: You must be an admin of the Facebook group
2. **App Review**: For production use, submit your app for review with these permissions:
   - `groups_access_member_info`
   - `pages_read_engagement`
   - `pages_manage_posts`

## Step 5: Configure Theme Settings

1. In your Ghost admin, go to **Design** → **Theme Settings**
2. Configure the following:
   - **Facebook Group ID**: `1465849137537076`
   - **Show Facebook Feed**: Enable
   - **Facebook App ID**: Your app ID from step 2
   - **Facebook App Secret**: Your app secret from step 2

## Step 6: Implement Facebook Feed (Technical)

The theme includes a placeholder for Facebook integration. For full functionality, you'll need to implement the JavaScript SDK:

### Option 1: Basic Implementation

Add this to your theme's JavaScript file:

```javascript
// Load Facebook SDK
window.fbAsyncInit = function() {
  FB.init({
    appId: '{{@custom.facebook_app_id}}',
    cookie: true,
    xfbml: true,
    version: 'v18.0'
  });

  // Get group posts
  FB.api(
    '/{{@custom.facebook_group_id}}/feed',
    'GET',
    {"fields":"message,created_time,from,link,attachments{url,title,description}"},
    function(response) {
      if (response && !response.error) {
        displayFacebookPosts(response.data);
      }
    }
  );
};

function displayFacebookPosts(posts) {
  const container = document.getElementById('facebook-feed-container');
  if (!container || !posts.length) return;

  const postsHtml = posts.slice(0, 5).map(post => `
    <div class="facebook-post">
      <div class="post-header">
        <strong>${post.from.name}</strong>
        <time>${new Date(post.created_time).toLocaleDateString()}</time>
      </div>
      <div class="post-content">
        ${post.message ? `<p>${post.message}</p>` : ''}
        ${post.link ? `<a href="${post.link}" target="_blank">Read more →</a>` : ''}
      </div>
    </div>
  `).join('');

  container.innerHTML = postsHtml;
}

// Load SDK
(function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = "https://connect.facebook.net/en_US/sdk.js";
  fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));
```

### Option 2: Use a Third-Party Service

For easier implementation, consider using services like:
- **EmbedSocial** - Facebook embed service
- **SocialBee** - Social media management with API
- **Custom API endpoint** - Create your own service to fetch and cache Facebook posts

## Step 7: Privacy and Compliance

### Data Privacy Considerations

1. **User Consent**: Inform users about Facebook data collection
2. **Cookie Compliance**: Ensure GDPR/CCPA compliance for cookies
3. **Data Minimization**: Only collect necessary data

### Facebook Platform Policy

Ensure your implementation complies with:
- [Facebook Platform Terms](https://developers.facebook.com/terms/)
- [Facebook Login Permissions](https://developers.facebook.com/docs/facebook-login/permissions/)
- [Group API Policies](https://developers.facebook.com/docs/groups-api/)

## Step 8: Testing

1. **Local Testing**: Test with Facebook's test groups
2. **Staging Environment**: Deploy to staging before production
3. **Permissions Testing**: Verify all required permissions are granted
4. **Error Handling**: Test scenarios when Facebook API is unavailable

## Troubleshooting

### Common Issues

**"App Not Setup" Error:**
- Verify your app is properly configured in Facebook Developers
- Check that your domain is added to app settings

**"Permissions Denied":**
- Ensure you have admin access to the Facebook group
- Submit for app review if using restricted permissions

**"Invalid Redirect URI":**
- Add all your domains to Valid OAuth Redirect URIs
- Include both HTTP and HTTPS versions during development

### Debug Tools

- [Facebook Graph API Explorer](https://developers.facebook.com/tools/explorer/)
- Browser developer tools for JavaScript errors
- Facebook's [Debug Tool](https://developers.facebook.com/tools/debug/)

## Advanced Configuration

### Caching Strategy

Implement caching to reduce API calls and improve performance:

```javascript
// Cache Facebook posts for 30 minutes
const CACHE_KEY = 'facebook_posts';
const CACHE_DURATION = 30 * 60 * 1000; // 30 minutes

function getCachedPosts() {
  const cached = localStorage.getItem(CACHE_KEY);
  if (cached) {
    const { data, timestamp } = JSON.parse(cached);
    if (Date.now() - timestamp < CACHE_DURATION) {
      return data;
    }
  }
  return null;
}

function cachePosts(posts) {
  localStorage.setItem(CACHE_KEY, JSON.stringify({
    data: posts,
    timestamp: Date.now()
  }));
}
```

### Rate Limiting

Facebook API has rate limits. Implement proper error handling:

```javascript
function handleApiError(error) {
  console.error('Facebook API Error:', error);

  if (error.code === 4) { // Rate limit exceeded
    // Implement exponential backoff
    setTimeout(() => fetchFacebookPosts(), 60000);
  } else if (error.code === 190) { // Invalid access token
    // Refresh token or re-authenticate
    refreshAccessToken();
  }
}
```

## Support

For issues with Facebook integration:
1. Check [Facebook Developers Documentation](https://developers.facebook.com/docs/)
2. Review [Ghost Theme Documentation](https://ghost.org/docs/themes/)
3. Test with Facebook's developer tools

## Security Best Practices

1. **Never expose app secrets** in client-side code
2. **Use HTTPS** for all Facebook integrations
3. **Validate all data** received from Facebook API
4. **Implement proper error handling** to prevent information leakage
5. **Regular security audits** of your Facebook app configuration
