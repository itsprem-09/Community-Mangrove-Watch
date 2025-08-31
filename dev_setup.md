# Mangrove Watch - Development Setup Guide

## Android Emulator Connectivity Fix

The authentication errors you were experiencing are caused by network connectivity issues between the Android emulator and your development server. Here's what was fixed and how to ensure it works:

### What Was Fixed

1. **Updated API Configuration (`lib/services/api_config.dart`)**:
   - Added Android emulator special IP (`10.0.2.2:5000`)
   - Added fallback URL system
   - Configured proper URLs for different platforms

2. **Enhanced AuthService (`lib/services/auth_service.dart`)**:
   - Added intelligent URL testing with fallbacks
   - Improved error handling and debugging
   - Added URL caching to avoid repeated tests

3. **Updated Express Server (`lib/backend/express_backend/server.js`)**:
   - Changed from listening on `127.0.0.1` to `0.0.0.0` (all interfaces)
   - Now accepts connections from Android emulator

### Key Network Details

- **Android Emulator**: Uses `10.0.2.2` to reach host machine's localhost
- **iOS Simulator**: Can use `localhost` directly
- **Physical Devices**: Need your machine's IP address (`10.167.224.61`)

### How to Start Development Server

1. **Start Express Backend**:
   ```bash
   cd "lib/backend/express_backend"
   npm install  # if packages aren't installed
   npm start
   ```

2. **Verify Server is Running**:
   The server should show:
   ```
   Express server running on all interfaces:5000
   Server accessible at:
     - http://localhost:5000 (for web/desktop)
     - http://10.0.2.2:5000 (for Android emulator)
     - http://127.0.0.1:5000 (local loopback)
   ```

### Troubleshooting

If you still have connection issues:

1. **Check Windows Firewall**:
   ```bash
   # Run as Administrator
   netsh advfirewall firewall add rule name="Flutter Dev Server" dir=in action=allow protocol=TCP localport=5000
   ```

2. **Test Server Manually**:
   ```bash
   curl http://localhost:5000/health
   curl http://10.0.2.2:5000/health  # This should work if emulator networking is correct
   ```

3. **For Physical Devices**:
   - Make sure your phone and computer are on the same WiFi network
   - Update `_localMachineIp` in `api_config.dart` if your IP changes
   - Allow firewall access for the Flutter development server

### URLs the App Will Try (in order)

For Android Emulator:
1. `http://10.0.2.2:5000` (primary)
2. `http://localhost:5000` (fallback)
3. `http://127.0.0.1:5000` (fallback)
4. `http://10.167.224.61:5000` (your machine's IP)

### Environment Variables

Make sure you have a `.env` file in `lib/backend/` with:
```
NODE_ENV=development
CORS_ORIGINS=*
MONGODB_URI=your_mongodb_connection_string
PORT=5000
```

### Testing the Fix

1. Start the Express server
2. Launch your Flutter app in Android emulator
3. Try to sign up/sign in
4. Check the console logs - you should see successful URL testing

The app will now automatically find the working URL and provide better error messages if none work.
