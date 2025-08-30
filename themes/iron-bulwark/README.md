# Iron Bulwark - Iron County Utah Community Blog

A customized Ghost theme for the Iron County, Utah community blog. This site serves as a platform to inform residents about local government decisions, taxes, community news, and provide space for local voices and opinions.

## Features

- **News & Updates**: Latest information about Iron County government, taxes, and community events
- **Opinions**: Platform for community voices and local perspectives
- **Facebook Integration**: Automatic feed from the Iron County Facebook group
- **Newsletter**: Mailgun-powered email newsletters
- **Admin Authentication**: Secure admin area for content management
- **Responsive Design**: Mobile-friendly layout optimized for all devices

## Quick Setup

1. Upload the theme zip file to your Ghost admin panel under `Design > Themes`
2. Activate the "Iron Bulwark" theme
3. Configure the theme settings in `Design > Theme Settings`:
   - Set your county name and tagline
   - Configure Facebook integration
   - Enable/disable newsletter signup
4. Create the following tags for content organization:
   - `news-updates` - For community news and government updates
   - `opinions` - For community opinions and perspectives

## Development

Styles are compiled using Gulp/PostCSS. You'll need Node.js, Yarn, and Gulp installed globally.

```bash
# Install dependencies
yarn install

# Run development server with live reload
yarn dev

# Build for production
yarn build

# Create theme zip for upload
yarn zip
```

## Content Management

### Categories/Tags Setup

Create these tags in your Ghost admin to organize content:

1. **news-updates** - Government decisions, tax information, community announcements
2. **opinions** - Local perspectives, editorials, community discussions

### Image Management

Place images in `/content/images/` directory:
- Post featured images
- Author profile pictures
- Custom graphics and logos

### Facebook Integration

The theme includes configuration for Facebook group integration:
- Set the Facebook Group ID in theme settings
- Toggle Facebook feed visibility
- Posts from the group will be displayed on the site

### Newsletter Setup

Configure Mailgun in your Ghost admin:
- Go to `Settings > Email newsletter`
- Select Mailgun as your email provider
- Enter your Mailgun API credentials
- Create newsletter campaigns from the admin panel

## VPS Deployment

See the main project README.md for complete VPS deployment instructions including:
- Minimum server requirements
- Docker setup
- SSL configuration
- Backup procedures

## Support

For theme-specific issues, check the Ghost documentation or create an issue in the theme repository.

## License

Copyright (c) 2024 Iron County Community - Released under the MIT license.
