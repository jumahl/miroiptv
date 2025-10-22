# MiroIPTV

Modern IPTV player for Roku with clean interface

## Features

- ✅ **Simple List Interface** - Clean channel list with easy navigation
- ✅ **Multiple Playlists** - Save and switch between different M3U lists
- ✅ **Quick Switching** - Easy access to all your playlists from sidebar
- ✅ **Multi-format Support** - HLS, MP4, MKV, AVI, and 20+ formats
- ✅ **Side Navigation** - Easy playlist browsing
- ✅ **Fast Loading** - Optimized for large playlists
- ✅ **URL Validation** - Smart error handling
- ✅ **Default Playlist** - Colombian channels (CO.m3u) included

## Installation

### Quick Install (Sideload)

1. Enable Developer Mode on your Roku:
   - Press Home 3x, Up 2x, Right, Left, Right, Left, Right
   - Follow the on-screen instructions
2. Build the package:

   ```powershell
   .\build.ps1
   ```

   This creates `SimpleIPTVRoku.zip`

3. Install on Roku:
   - Go to `http://YOUR_ROKU_IP` in your browser
   - Upload `SimpleIPTVRoku.zip`

Detailed tutorial: https://www.howtogeek.com/290787/how-to-enable-developer-mode-and-sideload-roku-apps/

## Usage

### Navigation

- **Left/Right Arrows**: Switch between playlist menu and channel list
- **Up/Down Arrows**: Navigate through playlists or channels
- **OK/Select**: Play selected channel
- **Back**: Return from fullscreen video to main menu
- **Options**: Add new M3U playlist

### During Video Playback

- **← (Left Arrow)**: Show/hide channel overlay menu (video keeps playing!)
  - Browse channels while watching
  - Press OK to switch to another channel
  - Press → or ← again to hide overlay
- **Back**: Stop video and return to main menu

### Features

1. **Category Filtering**: Select from the left sidebar

   - 📺 All Channels
   - 🎬 Movies
   - 📺 Series
   - ⚽ Sports
   - 📰 News
   - 🎵 Music
   - ➕ Add New Playlist

2. **Multiple Playlists**:

   - Add as many M3U lists as you want
   - Switch between them from the sidebar
   - Lists are saved automatically

3. **Smart Search**: Categories auto-detect based on group-title in M3U

## Custom Playlist

You can use your own M3U playlist or your IPTV provider's URL. The app supports:

- HTTP and HTTPS URLs
- M3U format with EXTINF tags
- Group categorization (group-title attribute)
- Channel logos (tvg-logo attribute)

### Test Playlist

The included `test.m3u` file has only 5 channels for quick testing.
The default `CO.m3u` contains Colombian TV channels and loads quickly.

For other countries, you can find playlists at:

- https://github.com/iptv-org/iptv (Warning: Very large, may cause loading issues)
- https://m3u.cl/ (Regional playlists by country)

## Troubleshooting

### App crashes on startup

1. Check your internet connection
2. Try using a smaller playlist first (like `test.m3u`)
3. Connect to telnet port 8085 on your Roku to see debug logs:
   ```
   telnet YOUR_ROKU_IP 8085
   ```
4. Look for error messages in the console

### Playlist not loading

- Verify the URL is accessible from a browser
- Make sure the playlist is in M3U format
- Check if the server supports HTTPS with valid certificates
- Try the "Set back to Demo" button to use the default playlist

## Version History

### v2.0.0 (October 2025) 🎉

- **NEW:** Multiple playlist management system
- **NEW:** Side panel with playlist switcher
- **NEW:** Clean text-based channel list (removed grid)
- **NEW:** Simplified interface focused on functionality
- **REMOVED:** Category filters (movies, series, etc.)
- **CHANGED:** Renamed to MiroIPTV
- Improved performance for large playlists
- Better keyboard dialogs
- Fullscreen video playback

### v1.0.2 (October 2025)

- Changed default playlist to CO.m3u (Colombian channels) for faster loading
- Fixed crash on startup with invalid content
- Improved error handling and null checks
- Increased HTTP timeout to 60 seconds for large playlists
- Added build script for easy packaging
- Better validation in M3U parser
- Replaced BusySpinner with simple loading text

### v1.0.1 (2025)

- Changed default playlist to IPTV-ORG collection
- Added URL validation
- Improved HTTP error handling with timeout
- Added loading spinner
- Enhanced M3U parser to extract channel logos
- Better user feedback on errors

### v1.0.0

- Initial release
- Basic M3U playlist support
- Multiple video format support
